import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/models.dart';
import '../../../core/services/user_service.dart';
import '../../../core/services/order_service.dart';
import '../../../core/utils/event_bus_util.dart';
import '../../../core/utils/toast_util.dart';
import '../../../core/events/app_events.dart';
import '../../../core/widgets/app_dialog.dart';
import '../shell/shell_controller.dart';
import 'state.dart';
import '../../core/i18n/l10n_ext.dart';

class HomeLogic extends GetxController with EventBusMixin {
  final HomeState state = HomeState();

  UserService  get _user  => Get.find<UserService>();
  OrderService get _order => Get.find<OrderService>();

  TechnicianModel? get technician => _user.technician.value;
  TechStatus       get techStatus => _user.status.value;
  int    get todayCount  => _order.todayCount;
  double get todayIncome => _order.todayIncome;
  String get todayRating {
    final r = technician?.rating ?? 0.0;
    return r > 0 ? r.toStringAsFixed(1) : '--';
  }

  /// 开始接单：设置状态 online 并跳转到订单 Tab
  void startAccepting() {
    if (techStatus != TechStatus.online) changeStatus(TechStatus.online);
    Get.find<ShellController>().switchTab(ShellController.tabOrders);
  }

  List<OrderModel> get recentOrders => _order.orders
      .where((o) => o.status != OrderStatus.cancelled)
      .toList()
    ..sort((a, b) => b.createTime.compareTo(a.createTime));

  @override
  void onInit() {
    super.onInit();
    // 订阅订单完成事件 → 自动更新今日统计
    subscribe<ServiceCompletedEvent>((e) {
      state.refreshing.value = !state.refreshing.value; // 触发 Obx 重绘
    });
    // 订阅新消息 → 首页可展示角标更新
    subscribe<NewMessageEvent>((_) {
      state.refreshing.value = !state.refreshing.value;
    });
  }

  @override
  void onClose() {
    cancelAllSubscriptions();
    super.onClose();
  }

  void changeStatus(TechStatus s) {
    _user.setStatus(s);
    final (icon, color, label) = switch (s) {
      TechStatus.online => (Icons.wifi_rounded,      AppColors.online, gL10n.statusOnline),
      TechStatus.busy   => (Icons.timelapse_rounded, AppColors.busy,   gL10n.statusBusy),
      TechStatus.rest   => (Icons.bedtime_rounded,   AppColors.rest,   gL10n.statusRest),
    };
    AppStatusToast.show(icon: icon, color: color, label: label);
  }

@override
  Future<void> refresh() async {
    state.refreshing.value = true;
    await Future.delayed(const Duration(milliseconds: 800));
    state.refreshing.value = false;
    ToastUtil.success(gL10n.refreshed);
  }

  /// 模拟后端推送新订单（开发测试用，正式版接 WebSocket）
  void mockPushNewOrder() {
    Get.find<OrderService>().pushNewOrder(
      OrderModel(
        id: DateTime.now().millisecondsSinceEpoch,
        orderNo: 'ORD${DateTime.now().millisecondsSinceEpoch}',
        status: OrderStatus.pending,
        serviceMode: ServiceMode.home,
        customer: const CustomerModel(id: 99, nickname: 'Test User', phone: '+855 12 000 000', address: 'Test Address'),
        services: const [ServiceItemModel(id: 1, name: 'Swedish Massage', duration: 60, price: 80)],
        totalAmount: 80, distance: 2.5,
        appointTime: DateTime.now().add(const Duration(hours: 1)),
        createTime: DateTime.now(),
      ),
      grabMode: true,
    );
  }

  String greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return gL10n.greetingMorning;
    if (h < 18) return gL10n.greetingAfternoon;
    return gL10n.greetingEvening;
  }
}
