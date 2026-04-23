import 'package:get/get.dart';
import '../../../core/models/models.dart';

// ── 服务项模型（与后端 OrderItemVO 一一对应）─────────────────────────────────
class ScheduleServiceItem {
  final int id;
  final int? serviceItemId;
  final String serviceName;
  final int serviceDuration;
  final double unitPrice;
  final int qty;
  /// 0=待服务 1=服务中 2=已完成
  final int svcStatus;

  const ScheduleServiceItem({
    required this.id,
    this.serviceItemId,
    required this.serviceName,
    required this.serviceDuration,
    required this.unitPrice,
    required this.qty,
    required this.svcStatus,
  });

  factory ScheduleServiceItem.fromJson(Map<String, dynamic> j) =>
      ScheduleServiceItem(
        id:              _int(j['id']),
        serviceItemId:   j['serviceItemId'] != null ? _int(j['serviceItemId']) : null,
        serviceName:     _str(j['serviceName']),
        serviceDuration: _int(j['serviceDuration']),
        unitPrice:       _double(j['unitPrice']),
        qty:             _int(j['qty'] ?? 1),
        svcStatus:       _int(j['svcStatus']),
      );

  static int    _int(dynamic v)    => v is int ? v : int.tryParse(v.toString()) ?? 0;
  static double _double(dynamic v) => v is double ? v : double.tryParse(v.toString()) ?? 0.0;
  static String _str(dynamic v)    => v?.toString() ?? '';
}

// ── 今日安排数据模型（与后端 ScheduleItemVO 一一对应）────────────────────────
class HomeScheduleItem {
  final int orderId;
  final String orderNo;
  final DateTime appointTime;
  final int rawStatus;
  final double payAmount;
  final double techIncome;
  final String memberNickname;
  final String? memberAvatar;
  /// 一单多项的服务项列表（后端 items 字段）
  final List<ScheduleServiceItem> items;
  final int itemCount;
  final int totalDuration;
  // 兼容旧字段（后端无 items 时 fallback）
  final String serviceName;
  final int serviceDuration;

  const HomeScheduleItem({
    required this.orderId,
    required this.orderNo,
    required this.appointTime,
    required this.rawStatus,
    required this.payAmount,
    required this.techIncome,
    required this.memberNickname,
    this.memberAvatar,
    this.items = const [],
    this.itemCount = 0,
    this.totalDuration = 0,
    this.serviceName = '',
    this.serviceDuration = 0,
  });

  factory HomeScheduleItem.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final List<ScheduleServiceItem> items = rawItems is List
        ? rawItems
            .whereType<Map<String, dynamic>>()
            .map(ScheduleServiceItem.fromJson)
            .toList()
        : [];

    return HomeScheduleItem(
      orderId:         _int(json['orderId']),
      orderNo:         _str(json['orderNo']),
      appointTime:     _fromUnixSecs(json['appointTime']),
      rawStatus:       _int(json['status']),
      payAmount:       _double(json['payAmount']),
      techIncome:      _double(json['techIncome']),
      memberNickname:  _str(json['memberNickname']),
      memberAvatar:    json['memberAvatar'] as String?,
      items:           items,
      itemCount:       _int(json['itemCount'] ?? items.length),
      totalDuration:   _int(json['totalDuration']),
      serviceName:     _str(json['serviceName']),
      serviceDuration: _int(json['serviceDuration']),
    );
  }

  /// 展示用服务名称列表（最多取前 2 项，其余显示 "+N"）
  String get displayServiceNames {
    if (items.isEmpty) return serviceName.isNotEmpty ? serviceName : '--';
    final names = items.map((e) => e.serviceName).toList();
    if (names.length <= 2) return names.join(' · ');
    return '${names.take(2).join(' · ')} +${names.length - 2}';
  }

  /// 实际总时长（分钟）
  int get effectiveTotalDuration {
    if (totalDuration > 0) return totalDuration;
    if (items.isNotEmpty) return items.fold(0, (s, e) => s + e.serviceDuration * e.qty);
    return serviceDuration;
  }

  /// 原始整型状态映射到 Flutter 枚举：
  /// 0=待支付 1=已支付 2=接单 3=前往 4=到达 5=服务中 6=已完成 7=取消 8=退款中 9=已退款
  OrderStatus get orderStatus => switch (rawStatus) {
        1            => OrderStatus.pending,
        2 || 3 || 4  => OrderStatus.accepted,
        5            => OrderStatus.inService,
        6            => OrderStatus.completed,
        _            => OrderStatus.cancelled,
      };

  static int    _int(dynamic v)    { if (v == null) return 0; return v is int ? v : int.tryParse(v.toString()) ?? 0; }
  static double _double(dynamic v) { if (v == null) return 0.0; return v is double ? v : double.tryParse(v.toString()) ?? 0.0; }
  static String _str(dynamic v)    => v?.toString() ?? '';

  static DateTime _fromUnixSecs(dynamic v) {
    if (v == null) return DateTime.now();
    final secs = v is num ? v.toInt() : int.tryParse(v.toString()) ?? 0;
    return DateTime.fromMillisecondsSinceEpoch(secs * 1000);
  }
}

// ── HomeState ─────────────────────────────────────────────────────────────────
class HomeState {
  // 刷新触发器（用于 Tab 切换静默刷新）
  final RxBool refreshing = false.obs;

  // 今日统计（第一行）
  final RxInt    todayOrders       = 0.obs;   // 有效订单（非待支付/取消/退款）
  final RxInt    todayAppointments = 0.obs;   // 全部预约订单
  final RxInt    todayCancelled    = 0.obs;   // 今日取消/退款

  // 今日统计（第二行）
  final RxDouble todayIncome    = 0.0.obs;
  final Rxn<double> todayRating = Rxn<double>();

  // 今日已完成（辅助字段，不单独展示，供统计备用）
  final RxInt todayCompleted = 0.obs;

  // 今日安排
  final RxList<HomeScheduleItem> schedule = <HomeScheduleItem>[].obs;

  // 加载状态
  final RxBool statsLoading    = true.obs;
  final RxBool scheduleLoading = true.obs;
}
