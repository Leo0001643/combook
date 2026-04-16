import 'package:get/get.dart';

/// 订单模型（简化版，用于页面展示）
class TechOrder {
  final String id;
  final String clientName;

  /// 多语言服务名：{'zh': '精油香薰SPA', 'en': 'Aromatherapy SPA', 'vi': '...', 'km': '...'}
  /// 后端返回时填充此字段；fallback 取 zh 或第一个值
  final Map<String, String> serviceNames;

  final String address;
  final String time;
  final double amount;
  final int status; // 0=待接单 1=已接单 2=服务中 3=已完成 4=已取消
  final double? lat;
  final double? lng;

  const TechOrder({
    required this.id,
    required this.clientName,
    required this.serviceNames,
    required this.address,
    required this.time,
    required this.amount,
    required this.status,
    this.lat,
    this.lng,
  });

  /// 当前语言的服务名；未找到时降级到 zh，再降级到第一个
  String localizedServiceName(String lang) =>
      serviceNames[lang] ?? serviceNames['zh'] ?? serviceNames.values.firstOrNull ?? '';

  /// 默认中文服务名（向后兼容）
  String get serviceName => localizedServiceName('zh');

  /// 用于 Logic 层重建不可变对象（状态变更时）
  TechOrder copyWith({
    String? id,
    String? clientName,
    Map<String, String>? serviceNames,
    String? address,
    String? time,
    double? amount,
    int? status,
    double? lat,
    double? lng,
  }) =>
      TechOrder(
        id:           id           ?? this.id,
        clientName:   clientName   ?? this.clientName,
        serviceNames: serviceNames ?? this.serviceNames,
        address:      address      ?? this.address,
        time:         time         ?? this.time,
        amount:       amount       ?? this.amount,
        status:       status       ?? this.status,
        lat:          lat          ?? this.lat,
        lng:          lng          ?? this.lng,
      );
}

/// 收益流水模型
class IncomeRecord {
  final String id;
  final String title;
  final String date;
  final double amount;
  final bool isIncome; // true=收入 false=提现

  const IncomeRecord({
    required this.id,
    required this.title,
    required this.date,
    required this.amount,
    required this.isIncome,
  });
}

class TechHomeState {
  // ── 底部导航 ──────────────────────────────────────────────────────
  final currentTab = 0.obs;

  // ── 在线状态 ──────────────────────────────────────────────────────
  final isOnline      = false.obs;
  final isToggling    = false.obs;

  // ── 今日统计 ──────────────────────────────────────────────────────
  final todayOrders   = 0.obs;
  final todayIncome   = 0.0.obs;
  final rating        = 4.9.obs;
  final completedTotal= 0.obs;

  // ── 订单列表 ──────────────────────────────────────────────────────
  final orderTab         = 0.obs;   // 0=待处理 1=服务中 2=已完成
  final pendingOrders    = <TechOrder>[].obs;
  final activeOrders     = <TechOrder>[].obs;
  final completedOrders  = <TechOrder>[].obs;
  final isLoadingOrders  = false.obs;

  /// 地理编码后的本地化地址缓存：orderId → 本地化地址文本
  /// GeocodingService 解析完成后异步填充，UI 通过 Obx 自动刷新
  final resolvedAddresses = <String, String>{}.obs;

  // ── 收益 ──────────────────────────────────────────────────────────
  final walletBalance    = 0.0.obs;
  final monthIncome      = 0.0.obs;
  final withdrawable     = 0.0.obs;
  final incomeRecords    = <IncomeRecord>[].obs;
  final isLoadingIncome  = false.obs;

  // ── 技师资料 ──────────────────────────────────────────────────────
  final techName         = ''.obs;
  final techAvatar       = ''.obs;
  final certStatus       = 0.obs; // 0=未认证 1=待审核 2=已认证

  TechHomeState();
}
