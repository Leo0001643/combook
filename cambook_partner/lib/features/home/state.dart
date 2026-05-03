import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import '../../../core/models/models.dart'; // also exports JsonUtil

// UTC 秒级时间戳 → DateTime（可空；null 或无效值返回 null）
DateTime? _fromUnixSecsNullable(dynamic v) {
  if (v == null) return null;
  final secs = v is num ? v.toInt() : int.tryParse(v.toString());
  if (secs == null || secs == 0) return null;
  return DateTime.fromMillisecondsSinceEpoch(secs * 1000);
}

// ── 服务项模型（与后端 OrderItemVO 一一对应）─────────────────────────────────
class ScheduleServiceItem {
  final int id;
  final int? serviceItemId;
  /// 订单快照名称（单语言，兜底显示）
  final String serviceName;
  final int serviceDuration;
  final double unitPrice;
  final int qty;
  /// 0=待服务 1=服务中 2=已完成
  final int svcStatus;
  /// 多语言名称映射，key=语言码(zh/en/vi/km/ja/ko)，后端有数据时才非空
  final Map<String, String>? nameI18n;
  /// 实际服务开始时间（后端 startTime，UTC 秒级时间戳转换后；用于精确进度计算）
  final DateTime? startTime;
  /// 实际服务结束时间（后端 endTime）
  final DateTime? endTime;

  const ScheduleServiceItem({
    required this.id,
    this.serviceItemId,
    required this.serviceName,
    required this.serviceDuration,
    required this.unitPrice,
    required this.qty,
    required this.svcStatus,
    this.nameI18n,
    this.startTime,
    this.endTime,
  });

  factory ScheduleServiceItem.fromJson(Map<String, dynamic> j) {
    Map<String, String>? i18n;
    final raw = j['nameI18n'];
    if (raw is Map) {
      i18n = raw.map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''))
               .cast<String, String>();
    }
    return ScheduleServiceItem(
      id:              JsonUtil.intFrom(j['id']),
      serviceItemId:   j['serviceItemId'] != null ? JsonUtil.intFrom(j['serviceItemId']) : null,
      serviceName:     JsonUtil.strFrom(j['serviceName']),
      serviceDuration: JsonUtil.intFrom(j['serviceDuration']),
      unitPrice:       JsonUtil.dblFrom(j['unitPrice']),
      qty:             JsonUtil.intFrom(j['qty'] ?? 1),
      svcStatus:       JsonUtil.intFrom(j['svcStatus']),
      nameI18n:        i18n,
      startTime:       _fromUnixSecsNullable(j['startTime']),
      endTime:         _fromUnixSecsNullable(j['endTime']),
    );
  }

  // ── 语义状态 getter（消除调用侧魔法数字）─────────────────────────────────
  bool get isPending  => svcStatus == 0;
  bool get isServing  => svcStatus == 1;
  bool get isDone     => svcStatus == 2;

  /// 根据 svcStatus 合成对应的整型值（供 fallback ScheduleServiceItem 构造使用）
  static int svcStatusFor({required bool isDone, required bool isServing}) =>
      isDone ? 2 : isServing ? 1 : 0;

  /// 根据当前 locale 返回服务项名称。
  /// 回退顺序：当前语言 → 英文 → 中文 → serviceName 快照。
  String localizedName(BuildContext context) {
    if (nameI18n == null || nameI18n!.isEmpty) return serviceName;
    final lang = Localizations.localeOf(context).languageCode;
    return nameI18n![lang]
        ?? nameI18n!['en']
        ?? nameI18n!['zh']
        ?? serviceName;
  }
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
  /// 1=在线预约订单  2=门店散客订单（walkin session）
  final int orderType;

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
    this.orderType = 1,
  });

  bool get isWalkin => orderType == 2;

  factory HomeScheduleItem.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final List<ScheduleServiceItem> items = rawItems is List
        ? rawItems
            .whereType<Map<String, dynamic>>()
            .map(ScheduleServiceItem.fromJson)
            .toList()
        : [];

    return HomeScheduleItem(
      orderId:         JsonUtil.intFrom(json['orderId']),
      orderNo:         JsonUtil.strFrom(json['orderNo']),
      appointTime:     _fromUnixSecs(json['appointTime']),
      rawStatus:       JsonUtil.intFrom(json['status']),
      payAmount:       JsonUtil.dblFrom(json['payAmount']),
      techIncome:      JsonUtil.dblFrom(json['techIncome']),
      memberNickname:  JsonUtil.strFrom(json['memberNickname']),
      memberAvatar:    json['memberAvatar'] as String?,
      items:           items,
      itemCount:       JsonUtil.intFrom(json['itemCount'] ?? items.length),
      totalDuration:   JsonUtil.intFrom(json['totalDuration']),
      serviceName:     JsonUtil.strFrom(json['serviceName']),
      serviceDuration: JsonUtil.intFrom(json['serviceDuration']),
      orderType:       JsonUtil.intFrom(json['orderType'] ?? 1),
    );
  }

  // ── 语义状态 getter（rawStatus 说明：
  //    0=待支付 1=待接单 2=已接单 3=前往 4=到达 5=服务中 6=已完成 7=取消中 8=已取消 9=已退款）
  bool get isActive      => rawStatus == 5;
  bool get isCompleted   => rawStatus == 6;
  bool get isCancelled   => rawStatus >= 7;
  /// 待接单且未被接受（rawStatus ≤ 1）
  bool get isUnaccepted  => rawStatus <= 1;

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
  /// 0=待支付 1=待接单 2=已接单 3=前往 4=到达 5=服务中 6=已完成 7=取消中 8=已取消 9=已退款
  OrderStatus get orderStatus => switch (rawStatus) {
        0 || 1       => OrderStatus.pending,   // 0=待支付 1=待接单
        2 || 3 || 4  => OrderStatus.accepted,
        5            => OrderStatus.inService,
        6            => OrderStatus.completed,
        _            => OrderStatus.cancelled, // 7/8/9
      };

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
