import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/models.dart'; // also exports JsonUtil
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/http_util.dart';
import '../../../core/services/order_service.dart';
import '../../../core/services/tech_ws_service.dart';
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

  UserService     get _user  => Get.find<UserService>();
  OrderService    get _order => Get.find<OrderService>();
  TechWsService   get _ws    => Get.find<TechWsService>();
  ShellController get _shell => Get.find<ShellController>();

  TechnicianModel? get technician => _user.technician.value;
  TechStatus       get techStatus => _user.status.value;

  StreamSubscription? _wsSub;

  String get todayRatingStr {
    final r = state.todayRating.value;
    return r != null ? r.toStringAsFixed(1) : '--';
  }

  @override
  void onInit() {
    super.onInit();
    _shell.registerRefresh(ShellController.tabHome, refresh);
    subscribe<NewMessageEvent>((_) {
      state.refreshing.value = !state.refreshing.value;
    });

    // 订单完成 → 立即更新本地统计和日程状态，无需等待 WS 推送
    subscribe<ServiceCompletedEvent>((e) => _onOrderCompleted(e));

    // WebSocket 是唯一自动数据通道，连接成功后服务端立即推送一次
    _wsSub = _ws.homeDataStream.listen(_applyWsHomeData);

    // 若 WS 已在本次生命周期推送过数据（App 重启或先于此页面连接），立即应用缓存
    final cached = _ws.lastHomeData;
    if (cached != null) _applyWsHomeData(cached);
  }

  @override
  void onClose() {
    _wsSub?.cancel();
    _shell.unregisterRefresh(ShellController.tabHome);
    cancelAllSubscriptions();
    super.onClose();
  }

  // ── 订单完成本地即时刷新 ──────────────────────────────────────────────────

  void _onOrderCompleted(ServiceCompletedEvent e) {
    // 1. 统计数字即时更新
    state.todayCompleted.value += 1;
    state.todayIncome.value    += e.earnedAmount;

    // 2. 日程列表中将匹配的订单状态改为 6（已完成）
    final idx = state.schedule.indexWhere((s) => s.orderId == e.orderId);
    if (idx != -1) {
      final old = state.schedule[idx];
      // 用新 rawStatus=6 重建一个同字段的副本
      state.schedule[idx] = HomeScheduleItem(
        orderId:         old.orderId,
        orderNo:         old.orderNo,
        appointTime:     old.appointTime,
        rawStatus:       6,
        payAmount:       old.payAmount,
        techIncome:      old.techIncome,
        memberNickname:  old.memberNickname,
        memberAvatar:    old.memberAvatar,
        items:           old.items,
        itemCount:       old.itemCount,
        totalDuration:   old.totalDuration,
        serviceName:     old.serviceName,
        serviceDuration: old.serviceDuration,
        orderType:       old.orderType,
      );
    }

    // 3. 后台异步拉一次最新数据（兜底，不阻塞 UI）
    Future.microtask(_fetchAll);
  }

  // ── WS 数据处理 ───────────────────────────────────────────────────────────

  void _applyWsHomeData(Map<String, dynamic> data) {
    // ── stats ──────────────────────────────────────────────────────────────
    final stats = data['stats'];
    if (stats is Map<String, dynamic>) {
      state.statsLoading.value   = false;
      state.todayOrders.value       = JsonUtil.intFrom(stats['todayOrders']);
      state.todayCompleted.value    = JsonUtil.intFrom(stats['todayCompleted']);
      state.todayAppointments.value = JsonUtil.intFrom(stats['todayAppointments']);
      state.todayCancelled.value    = JsonUtil.intFrom(stats['todayCancelled']);
      state.todayIncome.value       = JsonUtil.dblFrom(stats['todayIncome']);
      final r = stats['todayRating'];
      state.todayRating.value = r != null ? JsonUtil.dblFrom(r) : null;
    }

    // ── schedule ───────────────────────────────────────────────────────────
    final raw = data['schedule'];
    if (raw is List) {
      state.scheduleLoading.value = false;
      final list = raw
          .whereType<Map<String, dynamic>>()
          .map(HomeScheduleItem.fromJson)
          .toList();
      state.schedule.assignAll(list);
    }

    // ── pendingCount → 订单角标 ────────────────────────────────────────────
    final pending = data['pendingCount'];
    if (pending != null) {
      _shell.updateOrderBadge(JsonUtil.intFrom(pending));
    }
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
    _shell.switchTab(ShellController.tabOrders);
  }

  // ── 手动下拉刷新（HTTP 兜底，WS 推送才是主通道）────────────────────────

  @override
  Future<void> refresh() async {
    await _fetchAll();
    ToastUtil.success(gL10n.refreshed);
  }

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
      state.todayOrders.value       = JsonUtil.intFrom(data['todayOrders']);
      state.todayCompleted.value    = JsonUtil.intFrom(data['todayCompleted']);
      state.todayAppointments.value = JsonUtil.intFrom(data['todayAppointments']);
      state.todayCancelled.value    = JsonUtil.intFrom(data['todayCancelled']);
      state.todayIncome.value       = JsonUtil.dblFrom(data['todayIncome']);
      final r = data['todayRating'];
      state.todayRating.value = r != null ? JsonUtil.dblFrom(r) : null;
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

  Future<void> _fetchPendingCount() async {
    try {
      final count = await HttpUtil.get<int>(
        ApiEndpoints.techPendingOrderCount,
        fromJson: (d) => d is int ? d : int.tryParse(d.toString()) ?? 0,
      );
      _shell.updateOrderBadge(count);
    } catch (e) {
      LogUtil.e('[HomeLogic] fetchPendingCount error: $e');
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
}
