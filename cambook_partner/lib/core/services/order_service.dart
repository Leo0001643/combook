import 'dart:async';
import 'package:get/get.dart';
import '../models/models.dart';
import '../mock/mock_data.dart';
import '../events/app_events.dart';
import '../utils/event_bus_util.dart';
import 'user_service.dart';

/// 订单服务 —— 跨页面共享订单数据（全局单例）
/// 每次状态变更都通过 EventBus 广播，解耦各模块
class OrderService extends GetxService {
  final RxList<OrderModel> orders = <OrderModel>[].obs;
  Timer? _grabTimer;

  Future<OrderService> init() async {
    orders.assignAll(MockData.orders);
    return this;
  }

  @override
  void onClose() {
    _grabTimer?.cancel();
    super.onClose();
  }

  // ── 查询 ──────────────────────────────────────────────────────────────────
  List<OrderModel> byStatus(OrderStatus s) =>
      orders.where((o) => o.status == s).toList()
        ..sort((a, b) => b.createTime.compareTo(a.createTime));

  OrderModel? getById(int id) {
    try { return orders.firstWhere((o) => o.id == id); } catch (_) { return null; }
  }

  OrderModel? getByOrderNo(String no) {
    try { return orders.firstWhere((o) => o.orderNo == no); } catch (_) { return null; }
  }

  OrderModel? get activeOrder {
    try { return orders.firstWhere((o) => o.status == OrderStatus.inService); }
    catch (_) { return null; }
  }

  // ── 今日统计 ──────────────────────────────────────────────────────────────
  int get todayCount {
    final d = DateTime.now();
    return orders.where((o) =>
      o.status == OrderStatus.completed &&
      o.endTime != null && _sameDay(o.endTime!, d)).length;
  }

  double get todayIncome {
    final d = DateTime.now();
    return orders.where((o) =>
      o.status == OrderStatus.completed &&
      o.endTime != null && _sameDay(o.endTime!, d))
        .fold(0.0, (s, o) => s + o.totalAmount);
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // ── 状态变更（所有操作都广播 OrderStatusChangedEvent）────────────────────
  void _update(int id, OrderModel Function(OrderModel) fn) {
    final i = orders.indexWhere((o) => o.id == id);
    if (i < 0) return;
    final old = orders[i];
    orders[i] = fn(old);
    EventBusUtil.fire(OrderStatusChangedEvent(id, old.status, orders[i].status));
  }

  void accept(int id)   => _update(id, (o) => o.copyWith(status: OrderStatus.accepted));
  void reject(int id)   => _update(id, (o) => o.copyWith(status: OrderStatus.cancelled));
  void start(int id)    => _update(id, (o) => o.copyWith(status: OrderStatus.inService, startTime: DateTime.now()));

  void complete(int id) {
    final order = getById(id);
    if (order == null) return;
    _update(id, (o) => o.copyWith(status: OrderStatus.completed, endTime: DateTime.now()));
    // 更新技师余额
    final user = Get.find<UserService>();
    user.addBalance(order.totalAmount);
    final newBal = user.technician.value?.balance ?? 0;
    // 广播余额变动 + 服务完成
    EventBusUtil.fire(ServiceCompletedEvent(id, order.totalAmount));
    EventBusUtil.fire(BalanceChangedEvent(newBal - order.totalAmount, newBal, '订单 ${order.orderNo} 完成'));
    EventBusUtil.fire(SystemNoticeEvent('服务完成', '订单 ${order.orderNo} 已完成，收入 \$${order.totalAmount}', level: NoticeLevel.success));
  }

  // ── 推送新订单（模拟后端推送）—— 调用此方法触发抢单弹窗 ─────────────────
  void pushNewOrder(OrderModel order, {bool grabMode = false}) {
    if (!orders.any((o) => o.id == order.id)) {
      orders.add(order);
    }
    EventBusUtil.fire(NewOrderEvent(order, isGrabMode: grabMode, grabCountdownSecs: 30));

    if (grabMode) {
      _startGrabCountdown(order.id, 30);
    }
  }

  void _startGrabCountdown(int orderId, int total) {
    _grabTimer?.cancel();
    var remaining = total;
    _grabTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      remaining--;
      EventBusUtil.fire(GrabCountdownTickEvent(orderId, remaining));
      if (remaining <= 0) {
        t.cancel();
        // 超时：如果仍为 pending 则自动取消
        final o = getById(orderId);
        if (o?.status == OrderStatus.pending) {
          _update(orderId, (o) => o.copyWith(status: OrderStatus.cancelled));
          EventBusUtil.fire(GrabExpiredEvent(orderId));
          EventBusUtil.fire(const SystemNoticeEvent('抢单超时', '订单已被其他技师接走', level: NoticeLevel.warning));
        }
      }
    });
  }
}
