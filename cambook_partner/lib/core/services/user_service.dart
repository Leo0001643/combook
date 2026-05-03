import 'dart:async';

import 'package:get/get.dart';
import '../models/models.dart';
import '../events/app_events.dart';
import '../network/api_endpoints.dart';
import '../network/http_util.dart';
import '../utils/event_bus_util.dart';
import '../utils/log_util.dart';
import 'order_service.dart';
import 'storage_service.dart';
import 'tech_ws_service.dart';
import '../routes/app_routes.dart';

/// 用户服务 —— 管理当前登录技师信息及状态（全局单例）
///
/// ## 会话恢复流程（冷启动高可用）
///
/// 1. `init()` 从 `StorageService.technicianCache` 立即恢复本地缓存（同步，不阻塞 UI）
/// 2. 后台异步调用 `/tech/auth/me` 验证 token 并同步最新资料
/// 3. 若 token 被服务端拒绝（401）→ 触发 `onSessionExpired()` 展示会话过期弹窗
/// 4. 若网络不可用 → 保留本地缓存，用户继续使用，重连后自动同步
class UserService extends GetxService {
  final Rx<TechnicianModel?> technician = Rx(null);
  final Rx<TechStatus>       status     = TechStatus.online.obs;

  /// true = 曾处于登录状态但被强制登出（401 / token 过期）
  /// AuthGuardService 监听此字段弹出"已登出"提示
  final isSessionExpired = false.obs;

  bool get isLoggedIn => technician.value != null;

  Future<UserService> init() async {
    final storage = Get.find<StorageService>();
    if (!storage.hasToken) return this;

    // ── 步骤 1：本地缓存即时恢复（同步，零延迟）──────────────────────────────
    final cached = storage.technicianCache;
    if (cached != null) {
      try {
        technician.value = TechnicianModel.fromJson(cached);
        LogUtil.i('[UserService] 本地缓存恢复会话 techId=${technician.value?.id}');
      } catch (e) {
        LogUtil.w('[UserService] 本地缓存解析失败: $e');
      }
    }

    // ── 步骤 2：后台异步验证 token + 同步最新技师资料 ─────────────────────────
    // 使用 microtask 确保不阻塞 init() 链，在所有服务初始化完成后才执行
    Future.microtask(_refreshProfileAsync);
    return this;
  }

  /// 后台异步更新技师资料并验证 token 有效性。
  Future<void> _refreshProfileAsync() async {
    final storage = Get.find<StorageService>();
    if (!storage.hasToken) return;
    try {
      final data = await HttpUtil.get<Map<String, dynamic>>(
        ApiEndpoints.techMe,
        fromJson: (d) => d as Map<String, dynamic>,
      );
      final updated = TechnicianModel.fromJson(data);
      technician.value = updated;
      storage.saveTechnician(updated.toJson());
      LogUtil.i('[UserService] 后台资料同步 ✓ techId=${updated.id}');
    } catch (e) {
      LogUtil.w('[UserService] 后台资料同步失败: $e');
      if (e is ApiException) {
        // token 被服务端明确拒绝 → 触发登出弹窗
        onSessionExpired();
      }
      // 网络不可用时保留本地缓存，用户可正常使用
    }
  }

  void login(TechnicianModel user, String token) {
    technician.value = user;
    final storage = Get.find<StorageService>();
    storage.saveToken(token);
    storage.saveTechnician(user.toJson());
    _connectWs();
    _fetchOrders();
  }

  /// 从后端 API 响应（TechLoginVO）登录
  void loginFromApi(Map<String, dynamic> data, String token) {
    final tech = TechnicianModel(
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
    technician.value = tech;
    final storage = Get.find<StorageService>();
    storage.saveToken(token);
    storage.saveTechnician(tech.toJson()); // 持久化资料，冷启动时恢复
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
    Get.find<StorageService>().clear(); // 清除 token + 技师缓存 + 所有存储
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
    final updated = t.copyWith(
      completedOrders: t.completedOrders + 1,
      balance:         t.balance + amount,
    );
    technician.value = updated;
    // 同步更新本地缓存
    Get.find<StorageService>().saveTechnician(updated.toJson());
  }
}
