import 'package:get/get.dart';
import '../../../core/models/models.dart';
import '../../../core/services/order_service.dart';
import '../../../core/services/user_service.dart';
import '../../../core/utils/event_bus_util.dart';
import '../../../core/utils/toast_util.dart';
import '../../../core/events/app_events.dart';
import '../../../core/routes/app_routes.dart';
import 'state.dart';
import '../../../core/i18n/l10n_ext.dart';

class OrderListLogic extends GetxController with EventBusMixin {
  final OrderListState state = OrderListState();

  OrderService get _svc => Get.find<OrderService>();

  List<OrderModel> byStatus(OrderStatus s) => _svc.byStatus(s);
  int countOf(OrderStatus s) => _svc.orders.where((o) => o.status == s).length;

  @override
  void onInit() {
    super.onInit();
    subscribe<OrderStatusChangedEvent>((e) {
      // 新 pending 订单 → 自动跳到"待接单" Tab
      if (e.newStatus == OrderStatus.pending) state.tabIndex.value = 0;
    });
    // 订单完成 → 自动跳到"已完成" Tab 并刷新列表
    subscribe<ServiceCompletedEvent>((_) {
      state.tabIndex.value = 3; // 已完成 tab index
      _svc.fetchFromApi();
    });
  }

  @override
  void onClose() {
    cancelAllSubscriptions();
    super.onClose();
  }

  @override
  Future<void> refresh() => _svc.fetchFromApi();

  Future<void> accept(int id) async {
    final ok = await _svc.accept(id);
    if (ok) ToastUtil.success(gL10n.success);
  }

  Future<void> reject(int id) async {
    final ok = await _svc.reject(id);
    if (ok) ToastUtil.info(gL10n.btnReject);
  }

  Future<void> start(int id) async {
    final ok = await _svc.start(id);
    if (!ok) return;  // API 失败时不进入服务模式
    Get.find<UserService>().setStatus(TechStatus.busy);
    Get.toNamed(AppRoutes.serviceActive);
  }
}
