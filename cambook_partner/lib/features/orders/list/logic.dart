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
    _refresh();

    // 新订单到达（WS 推送）→ 自动切换到"待处理"Tab 并刷新列表
    subscribe<NewOrderEvent>((_) {
      state.tabIndex.value = 0;
    });

    // 订单状态变更为 pending（如接单失败回滚）→ 切换到待处理 Tab
    subscribe<OrderStatusChangedEvent>((e) {
      if (e.newStatus == OrderStatus.pending) state.tabIndex.value = 0;
    });

    subscribe<ServiceCompletedEvent>((_) {
      state.tabIndex.value = 3;
      _refresh();
    });
  }

  @override
  void onClose() {
    cancelAllSubscriptions();
    super.onClose();
  }

  Future<void> _refresh() async {
    state.loading.value = true;
    try {
      await _svc.fetchFromApi();
    } finally {
      state.loading.value = false;
    }
  }

  @override
  Future<void> refresh() => _refresh();

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
    if (!ok) return;
    Get.find<UserService>().setStatus(TechStatus.busy);
    Get.toNamed(AppRoutes.serviceActive);
  }
}
