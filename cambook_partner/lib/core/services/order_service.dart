import 'dart:async';
import 'package:get/get.dart';
import '../models/models.dart';
import '../events/app_events.dart';
import '../network/api_endpoints.dart';
import '../network/http_util.dart';
import '../utils/event_bus_util.dart';
import '../utils/log_util.dart';
import 'user_service.dart';

/// 订单服务 —— 跨页面共享订单数据（全局单例）
/// 每次状态变更都通过 EventBus 广播，解耦各模块
class OrderService extends GetxService {
  final RxList<OrderModel> orders = <OrderModel>[].obs;
  final Map<int, Timer>    _grabTimers = {};        // 每个抢单订单独立计时器
  final Map<int, DateTime> _serviceStartCache = {}; // 服务开始时间本地缓存，防止 fetchFromApi 丢失

  Future<OrderService> init() async {
    return this;
  }

  /// 从后端拉取订单列表（登录后调用一次，WS 推送到来时可重新拉取）
  Future<void> fetchFromApi() async {
    try {
      final list = await HttpUtil.get<List<OrderModel>>(
        ApiEndpoints.techOrders,
        fromJson: (d) => (d is List ? d : <dynamic>[])
            .whereType<Map<String, dynamic>>()
            .map(OrderModel.fromJson)
            .toList(),
      );
      // 服务端可能不返回 startTime（如 walkin 未执行 migration），
      // 用本地缓存补全，保证专注模式计时不归零
      final restored = list.map((o) {
        if (o.startTime == null && _serviceStartCache.containsKey(o.id)) {
          return o.copyWith(startTime: _serviceStartCache[o.id]);
        }
        if (o.startTime != null) {
          // 服务端有值时同步写入缓存，保持缓存最新
          _serviceStartCache[o.id] = o.startTime!;
        }
        return o;
      }).toList();
      orders.assignAll(restored);
    } catch (e) {
      LogUtil.e('[OrderService] fetchFromApi error: $e');
    }
  }

  @override
  void onClose() {
    for (final t in _grabTimers.values) { t.cancel(); }
    _grabTimers.clear();
    _serviceStartCache.clear();
    super.onClose();
  }

  // ── 查询 ──────────────────────────────────────────────────────────────────
  List<OrderModel> byStatus(OrderStatus s) =>
      orders.where((o) => o.status == s).toList()
        ..sort((a, b) => b.createTime.compareTo(a.createTime));

  OrderModel? getById(int id) {
    final i = orders.indexWhere((o) => o.id == id);
    return i >= 0 ? orders[i] : null;
  }

  OrderModel? getByOrderNo(String no) {
    final i = orders.indexWhere((o) => o.orderNo == no);
    return i >= 0 ? orders[i] : null;
  }

  OrderModel? get activeOrder {
    final i = orders.indexWhere((o) => o.status == OrderStatus.inService);
    return i >= 0 ? orders[i] : null;
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

  /// 接单：乐观更新本地状态，同时异步通知后端持久化。
  /// 返回 true 表示后端确认成功；false 表示失败（已自动回滚本地状态）。
  /// 门店散客订单（orderType == 2）调用 walkin 接口；在线订单调用普通接口。
  Future<bool> accept(int id) async {
    final order = getById(id);
    if (order == null) return false;
    _update(id, (o) => o.copyWith(status: OrderStatus.accepted));
    try {
      final url = order.orderType == 2
          ? ApiEndpoints.techAcceptWalkin(id)
          : ApiEndpoints.techAcceptOnline(id);
      await HttpUtil.post(url);
      return true;
    } catch (e) {
      LogUtil.e('[OrderService] accept($id) API failed: $e');
      _update(id, (o) => o.copyWith(status: OrderStatus.pending));
      return false;
    }
  }

  /// 拒单：乐观更新本地状态，同时异步通知后端持久化。
  /// 返回 true 表示后端确认成功；false 表示失败（已自动回滚本地状态）。
  Future<bool> reject(int id) async {
    final order = getById(id);
    if (order == null) return false;
    _update(id, (o) => o.copyWith(status: OrderStatus.cancelled));
    try {
      final url = order.orderType == 2
          ? ApiEndpoints.techRejectWalkin(id)
          : ApiEndpoints.techRejectOnline(id);
      await HttpUtil.post(url);
      return true;
    } catch (e) {
      LogUtil.e('[OrderService] reject($id) API failed: $e');
      _update(id, (o) => o.copyWith(status: OrderStatus.pending));
      return false;
    }
  }

  /// 开始服务：乐观更新并通知后端。
  /// 返回 true 表示后端确认成功；false 表示失败（本地保留乐观状态以维持 UX 连续性）。
  Future<bool> start(int id) async {
    final order = getById(id);
    if (order == null) return false;
    final now = DateTime.now();
    _serviceStartCache[id] = now; // 持久化到缓存，fetchFromApi 时不丢失
    _update(id, (o) => o.copyWith(status: OrderStatus.inService, startTime: now));
    try {
      final url = order.orderType == 2
          ? ApiEndpoints.techStartWalkin(id)
          : ApiEndpoints.techStartOnline(id);
      await HttpUtil.post(url);
      return true;
    } catch (e) {
      LogUtil.e('[OrderService] start($id) API failed: $e');
      // 不回滚本地状态，保留乐观更新以保证 UX 连续性。
      // completeOnline/completeWalkin 已兼容 ACCEPTED 状态，即使 start 未持久化也可完成。
      return false;
    }
  }

  Future<void> complete(int id) async {
    final order = getById(id);
    if (order == null) return;
    // 乐观更新
    _update(id, (o) => o.copyWith(status: OrderStatus.completed, endTime: DateTime.now()));
    try {
      final url = order.orderType == 2
          ? ApiEndpoints.techCompleteWalkin(id)
          : ApiEndpoints.techCompleteOnline(id);
      await HttpUtil.post(url);
    } catch (e) {
      LogUtil.e('[OrderService] complete($id) API failed: $e');
      // 回滚本地状态
      _update(id, (o) => o.copyWith(status: OrderStatus.inService, endTime: null));
      rethrow; // 让调用方感知失败，避免误导航
    }
    _serviceStartCache.remove(id); // 服务结束，清理缓存
    final user = Get.find<UserService>();
    user.addBalance(order.totalAmount);
    final newBal = user.technician.value?.balance ?? 0;
    EventBusUtil.fire(ServiceCompletedEvent(id, order.totalAmount));
    EventBusUtil.fire(BalanceChangedEvent(newBal - order.totalAmount, newBal, order.orderNo));
  }

  // ── 推送新订单（WS 到达后由 GlobalNotificationService 调用）────────────────
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
    // 取消同一订单的旧计时器（防重复）
    _grabTimers[orderId]?.cancel();
    var remaining = total;
    _grabTimers[orderId] = Timer.periodic(const Duration(seconds: 1), (t) {
      remaining--;
      EventBusUtil.fire(GrabCountdownTickEvent(orderId, remaining));
      if (remaining <= 0) {
        t.cancel();
        _grabTimers.remove(orderId);
        final o = getById(orderId);
        if (o?.status == OrderStatus.pending) {
          _update(orderId, (o) => o.copyWith(status: OrderStatus.cancelled));
          EventBusUtil.fire(GrabExpiredEvent(orderId));
        }
      }
    });
  }
}
