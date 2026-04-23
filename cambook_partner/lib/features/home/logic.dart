import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/models.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/http_util.dart';
import '../../../core/services/order_service.dart';
import '../../../core/services/user_service.dart';
import '../../../core/utils/event_bus_util.dart';
import '../../../core/utils/log_util.dart';
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

  // ── 统计数据 getter（供 Obx 之外使用）────────────────────────────────────
  String get todayRatingStr {
    final r = state.todayRating.value;
    return r != null ? r.toStringAsFixed(1) : '--';
  }

  @override
  void onInit() {
    super.onInit();
    Get.find<ShellController>().registerRefresh(ShellController.tabHome, silentRefresh);
    subscribe<ServiceCompletedEvent>((_) => _fetchAll());
    subscribe<NewMessageEvent>((_) {
      state.refreshing.value = !state.refreshing.value;
    });
    _fetchAll();
  }

  @override
  void onClose() {
    Get.find<ShellController>().unregisterRefresh(ShellController.tabHome);
    cancelAllSubscriptions();
    super.onClose();
  }

  // ── 状态切换 ──────────────────────────────────────────────────────────────
  void changeStatus(TechStatus s) {
    _user.setStatus(s);
    final (icon, color, label) = switch (s) {
      TechStatus.online => (Icons.wifi_rounded,      AppColors.online, gL10n.statusOnline),
      TechStatus.busy   => (Icons.timelapse_rounded, AppColors.busy,   gL10n.statusBusy),
      TechStatus.rest   => (Icons.bedtime_rounded,   AppColors.rest,   gL10n.statusRest),
    };
    AppStatusToast.show(icon: icon, color: color, label: label);
  }

  void startAccepting() {
    if (techStatus != TechStatus.online) changeStatus(TechStatus.online);
    Get.find<ShellController>().switchTab(ShellController.tabOrders);
  }

  // ── 刷新 ─────────────────────────────────────────────────────────────────
  @override
  Future<void> refresh() async {
    await _fetchAll();
    ToastUtil.success(gL10n.refreshed);
  }

  void silentRefresh() => _fetchAll();

  // ── 私有：并发拉取三个接口 ────────────────────────────────────────────────
  Future<void> _fetchAll() async {
    await Future.wait([_fetchStats(), _fetchSchedule(), _fetchPendingCount()]);
  }

  Future<void> _fetchStats() async {
    state.statsLoading.value = true;
    try {
      final data = await HttpUtil.get<Map<String, dynamic>>(
        ApiEndpoints.techHomeStats,
        fromJson: (d) => d as Map<String, dynamic>,
      );
      state.todayOrders.value       = _int(data['todayOrders']);
      state.todayCompleted.value    = _int(data['todayCompleted']);
      state.todayAppointments.value = _int(data['todayAppointments']);
      state.todayCancelled.value    = _int(data['todayCancelled']);
      state.todayIncome.value       = _double(data['todayIncome']);
      final r = data['todayRating'];
      state.todayRating.value = r != null ? _double(r) : null;
    } catch (e) {
      LogUtil.e('[HomeLogic] fetchStats error: $e');
    } finally {
      state.statsLoading.value = false;
    }
  }

  Future<void> _fetchSchedule() async {
    state.scheduleLoading.value = true;
    try {
      final list = await HttpUtil.get<List<HomeScheduleItem>>(
        ApiEndpoints.techHomeSchedule,
        fromJson: (d) {
          if (d is! List) return <HomeScheduleItem>[];
          return d
              .whereType<Map<String, dynamic>>()
              .map(HomeScheduleItem.fromJson)
              .toList();
        },
      );
      state.schedule.assignAll(list);
    } catch (e) {
      LogUtil.e('[HomeLogic] fetchSchedule error: $e');
    } finally {
      state.scheduleLoading.value = false;
    }
  }

  // ── 问候语 ────────────────────────────────────────────────────────────────
  String greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return gL10n.greetingMorning;
    if (h < 18) return gL10n.greetingAfternoon;
    return gL10n.greetingEvening;
  }

  // ── 模拟推单（仅开发调试用）──────────────────────────────────────────────
  void mockPushNewOrder() {
    _order.pushNewOrder(
      OrderModel(
        id: DateTime.now().millisecondsSinceEpoch,
        orderNo: 'ORD${DateTime.now().millisecondsSinceEpoch}',
        status: OrderStatus.pending,
        serviceMode: ServiceMode.home,
        customer: const CustomerModel(
            id: 99, nickname: 'Test User',
            phone: '+855 12 000 000', address: 'Test Address'),
        services: const [
          ServiceItemModel(id: 1, name: 'Swedish Massage', duration: 60, price: 80)
        ],
        totalAmount: 80, distance: 2.5,
        appointTime: DateTime.now().add(const Duration(hours: 1)),
        createTime: DateTime.now(),
      ),
      grabMode: true,
    );
  }

  Future<void> _fetchPendingCount() async {
    try {
      final count = await HttpUtil.get<int>(
        ApiEndpoints.techPendingOrderCount,
        fromJson: (d) => d is int ? d : int.tryParse(d.toString()) ?? 0,
      );
      Get.find<ShellController>().updateOrderBadge(count);
    } catch (e) {
      LogUtil.e('[HomeLogic] fetchPendingCount error: $e');
    }
  }

  // ── 私有类型转换工具 ──────────────────────────────────────────────────────
  static int    _int(dynamic v)    => v == null ? 0 : (v is int ? v : int.tryParse(v.toString()) ?? 0);
  static double _double(dynamic v) => v == null ? 0.0 : (v is double ? v : double.tryParse(v.toString()) ?? 0.0);
}
