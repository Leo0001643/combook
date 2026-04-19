import 'package:get/get.dart';
import '../../../core/models/models.dart';
import '../../../core/services/order_service.dart';
import '../../../core/services/user_service.dart';
import '../../../core/utils/toast_util.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/utils/event_bus_util.dart';
import '../../../core/events/app_events.dart';
import 'state.dart';
import '../../../core/i18n/l10n_ext.dart';

class OrderDetailLogic extends GetxController with EventBusMixin {
  final OrderDetailState state = OrderDetailState();

  OrderService get _svc => Get.find<OrderService>();

  @override
  void onInit() {
    super.onInit();
    final id = Get.arguments?['id'] as int?;
    if (id != null) _loadOrder(id);

    // 订阅状态变更 → 实时刷新详情页
    subscribe<OrderStatusChangedEvent>((e) {
      if (e.orderId == state.order.value?.id) {
        _loadOrder(e.orderId);
      }
    });
  }

  @override
  void onClose() {
    cancelAllSubscriptions();
    super.onClose();
  }

  void _loadOrder(int id) {
    state.loading.value = true;
    state.order.value = _svc.getById(id);
    state.loading.value = false;
  }

  Future<void> accept() async {
    final id = state.order.value?.id; if (id == null) return;
    _svc.accept(id);
    state.order.value = _svc.getById(id);
    ToastUtil.success(gL10n.success);
  }

  Future<void> reject() async {
    final id = state.order.value?.id; if (id == null) return;
    final ok = await ToastUtil.confirm(gL10n.rejectOrder, gL10n.rejectConfirm, okText: gL10n.confirm);
    if (!ok) return;
    _svc.reject(id);
    ToastUtil.info(gL10n.btnReject);
    Get.back();
  }

  /// 已到达客户位置 —— 更新进度但不改 OrderStatus（仍为 accepted）
  void arrive() {
    state.arrived.value = true;
    ToastUtil.success(gL10n.confirmArrival);
    EventBusUtil.fire(SystemNoticeEvent(gL10n.confirmArrival, gL10n.arrivalNotice));
  }

  Future<void> startService() async {
    final id = state.order.value?.id; if (id == null) return;
    _svc.start(id);
    state.order.value = _svc.getById(id);
    Get.find<UserService>().setStatus(TechStatus.busy);
    Get.toNamed(AppRoutes.serviceActive);
  }

  Future<void> complete() async {
    final id = state.order.value?.id; if (id == null) return;
    final ok = await ToastUtil.confirm(gL10n.btnComplete, gL10n.completeConfirm);
    if (!ok) return;
    _svc.complete(id);
    state.order.value = _svc.getById(id);
    final still = _svc.activeOrder;
    if (still == null) Get.find<UserService>().setStatus(TechStatus.online);
    Get.back();
  }

  void callCustomer() {
    final phone = state.order.value?.customer.phone;
    if (phone != null) _launchPhone(phone);
  }

  void navigateToCustomer() {
    final addr = state.order.value?.customer.address;
    if (addr != null) _launchMaps(addr);
  }

  void _launchPhone(String phone) {
    final uri = Uri(scheme: 'tel', path: phone.replaceAll(' ', ''));
    _tryLaunch(uri);
  }

  void _launchMaps(String address) {
    final encoded = Uri.encodeComponent(address);
    final uri = Uri.parse('https://maps.google.com/?q=$encoded');
    _tryLaunch(uri);
  }

  void _tryLaunch(Uri uri) {
    // url_launcher 集成点 —— 正式版启用
    // if (await canLaunchUrl(uri)) launchUrl(uri);
    ToastUtil.info(gL10n.launchingApp);
  }
}
