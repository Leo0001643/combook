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
    // 订阅订单状态变更 → 自动刷新列表（Obx 已监听 _svc.orders，此处仅做日志）
    subscribe<OrderStatusChangedEvent>((e) {
      // 当有新的 pending 订单时，自动切换到"待接单" Tab
      if (e.newStatus == OrderStatus.pending) state.tabIndex.value = 0;
    });
  }

  @override
  void onClose() {
    cancelAllSubscriptions();
    super.onClose();
  }

@override
  Future<void> refresh() => Future.delayed(const Duration(milliseconds: 600));

  Future<void> accept(int id) async {
    _svc.accept(id);
    ToastUtil.success(gL10n.success);
  }

  Future<void> reject(int id) async {
    _svc.reject(id);
    ToastUtil.info(gL10n.btnReject);
  }

  Future<void> start(int id) async {
    _svc.start(id);
    Get.find<UserService>().setStatus(TechStatus.busy);
    Get.toNamed(AppRoutes.serviceActive);
  }
}
