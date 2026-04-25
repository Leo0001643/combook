import 'package:get/get.dart';
import '../models/models.dart';
import '../events/app_events.dart';
import '../utils/event_bus_util.dart';
import 'order_service.dart';
import 'storage_service.dart';
import 'tech_ws_service.dart';
import '../routes/app_routes.dart';

/// 用户服务 —— 管理当前登录技师信息及状态（全局单例）
class UserService extends GetxService {
  final Rx<TechnicianModel?> technician = Rx(null);
  final Rx<TechStatus>       status     = TechStatus.online.obs;

  /// true = 曾处于登录状态但被强制登出（401 / token 过期）
  /// AuthGuardService 监听此字段弹出"已登出"提示
  final isSessionExpired = false.obs;

  bool get isLoggedIn => technician.value != null;

  Future<UserService> init() async {
    // 若 token 已存在（App 重启），WS 连接由 TechWsService.init() 负责
    // 此处只做状态恢复标记，待 WS 首次 HOME_DATA 到达时 HomeLogic 会刷新数据
    return this;
  }

  void login(TechnicianModel user, String token) {
    technician.value = user;
    Get.find<StorageService>().saveToken(token);
    _connectWs();
    _fetchOrders();
  }

  /// 从后端 API 响应（TechLoginVO）登录
  void loginFromApi(Map<String, dynamic> data, String token) {
    technician.value = TechnicianModel(
      id:              (data['techId']  as num?)?.toInt()    ?? 0,
      nickname:         data['nickname'] as String?           ?? '',
      techNo:           data['techNo']   as String?           ?? '',
      phone:            data['mobile']   as String?           ?? '',
      avatar:           data['avatar']   as String?,
      level:            TechLevel.normal,
      rating:          (data['rating']  as num?)?.toDouble() ?? 0.0,
      completedOrders: (data['orderCount'] as num?)?.toInt() ?? 0,
      balance:         (data['balance'] as num?)?.toDouble() ?? 0.0,
      skills:           const [],
      memberSince:      '',
      merchantId:      (data['merchantId'] ?? '').toString(),
      merchantName:     '',
    );
    Get.find<StorageService>().saveToken(token);
    _connectWs();
    _fetchOrders();
  }

  void logout() {
    _disconnectWs();
    _clearSession();
    Get.offAllNamed(AppRoutes.login);
  }

  /// 被动登出（服务端 401 / token 过期）—— 触发"已登出"模态弹窗
  /// 由 HttpUtil._AuthInterceptor 调用，业务层无需关心
  void onSessionExpired() {
    if (technician.value == null) return; // 已经是未登录状态，避免重复触发
    _disconnectWs();
    _clearSession();
    isSessionExpired.value = true;
  }

  /// 用户在弹窗中确认后重置标志位，再跳转登录页
  void clearSessionExpired() {
    isSessionExpired.value = false;
  }

  void _clearSession() {
    technician.value = null;
    isSessionExpired.value = false; // 防止 ever() worker 在会话清除后再次触发
    Get.find<StorageService>().clear();
  }

  void _connectWs()    => Get.find<TechWsService>().connect();
  void _disconnectWs() => Get.find<TechWsService>().disconnect();
  void _fetchOrders()  => Get.find<OrderService>().fetchFromApi();

  void setStatus(TechStatus newStatus) {
    if (status.value == newStatus) return;
    final old = status.value;
    status.value = newStatus;
    EventBusUtil.fire(TechStatusChangedEvent(old, newStatus));
  }

  /// 更新技师余额（订单完成后由 OrderService 调用）
  void addBalance(double amount) {
    final t = technician.value;
    if (t == null) return;
    technician.value = t.copyWith(
      completedOrders: t.completedOrders + 1,
      balance:         t.balance + amount,
    );
  }
}
