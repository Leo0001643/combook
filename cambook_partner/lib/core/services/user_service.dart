import 'package:get/get.dart';
import '../models/models.dart';
import '../mock/mock_data.dart';
import '../events/app_events.dart';
import '../utils/event_bus_util.dart';
import 'storage_service.dart';
import '../routes/app_routes.dart';

/// 用户服务 —— 管理当前登录技师信息及状态（全局单例）
class UserService extends GetxService {
  final Rx<TechnicianModel?> technician = Rx(null);
  final Rx<TechStatus>       status     = TechStatus.online.obs;

  bool get isLoggedIn => technician.value != null;

  Future<UserService> init() async {
    if (Get.find<StorageService>().hasToken) {
      technician.value = MockData.technician;
    }
    return this;
  }

  void login(TechnicianModel user, String token) {
    technician.value = user;
    Get.find<StorageService>().saveToken(token);
  }

  void logout() {
    technician.value = null;
    Get.find<StorageService>().clear();
    Get.offAllNamed(AppRoutes.login);
  }

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
    technician.value = TechnicianModel(
      id: t.id, nickname: t.nickname, techNo: t.techNo, phone: t.phone,
      avatar: t.avatar, level: t.level, rating: t.rating,
      completedOrders: t.completedOrders + 1,
      balance: t.balance + amount,
      skills: t.skills, memberSince: t.memberSince,
      merchantId: t.merchantId, merchantName: t.merchantName,
      telegram: t.telegram, facebook: t.facebook, email: t.email,
    );
  }
}
