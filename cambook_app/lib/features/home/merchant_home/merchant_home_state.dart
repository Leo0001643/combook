import 'package:get/get.dart';

/// 技师状态：0=离线 1=在线 2=服务中
class MerchantTech {
  final String id;
  final String name;
  final String skill;
  final int status;
  final int todayOrders;
  final double todayIncome;
  final double rating;

  const MerchantTech({
    required this.id,
    required this.name,
    required this.skill,
    required this.status,
    required this.todayOrders,
    required this.todayIncome,
    required this.rating,
  });
}

/// 商家订单
class MerchantOrder {
  final String id;
  final String clientName;
  final String techName;

  /// 多语言服务名
  final Map<String, String> serviceNames;

  final String time;
  final double amount;
  final int status; // 0=待确认 1=已确认 2=服务中 3=已完成 4=已取消

  const MerchantOrder({
    required this.id,
    required this.clientName,
    required this.techName,
    required this.serviceNames,
    required this.time,
    required this.amount,
    required this.status,
  });

  String localizedServiceName(String lang) =>
      serviceNames[lang] ?? serviceNames['zh'] ?? serviceNames.values.firstOrNull ?? '';

  String get serviceName => localizedServiceName('zh');

  MerchantOrder copyWith({int? status}) => MerchantOrder(
        id:           id,
        clientName:   clientName,
        techName:     techName,
        serviceNames: serviceNames,
        time:         time,
        amount:       amount,
        status:       status ?? this.status,
      );
}

/// 服务项目（商户维度）
class MerchantService {
  final String id;

  /// 多语言服务名：{'zh': '精油香薰SPA', 'en': 'Aromatherapy SPA', ...}
  final Map<String, String> names;

  /// 多语言分类名：{'zh': '全身按摩', 'en': 'Full Body Massage', ...}
  final Map<String, String> categories;

  final double price;
  final int duration; // 分钟
  final bool isActive;
  final int orderCount;

  const MerchantService({
    required this.id,
    required this.names,
    required this.categories,
    required this.price,
    required this.duration,
    required this.isActive,
    required this.orderCount,
  });

  String localizedName(String lang) =>
      names[lang] ?? names['zh'] ?? names.values.firstOrNull ?? '';

  String localizedCategory(String lang) =>
      categories[lang] ?? categories['zh'] ?? categories.values.firstOrNull ?? '';

  /// 默认中文（向后兼容）
  String get name => localizedName('zh');
  String get category => localizedCategory('zh');

  MerchantService copyWith({bool? isActive}) => MerchantService(
        id:         id,
        names:      names,
        categories: categories,
        price:      price,
        duration:   duration,
        isActive:   isActive ?? this.isActive,
        orderCount: orderCount,
      );
}

class MerchantHomeState {
  // ── 底部导航 ──────────────────────────────────────────────────────
  final currentTab = 0.obs;

  // ── 大盘数据 ──────────────────────────────────────────────────────
  final todayOrders    = 0.obs;
  final todayRevenue   = 0.0.obs;
  final onlineTechs    = 0.obs;
  final totalTechs     = 0.obs;
  final avgRating      = 0.0.obs;
  final monthRevenue   = 0.0.obs;
  final pendingCount   = 0.obs;

  // 本周每天数据（周一到周日）
  final weekRevenue = <double>[].obs;
  final weekOrders  = <int>[].obs;

  // ── 技师列表 ──────────────────────────────────────────────────────
  final techs             = <MerchantTech>[].obs;
  final isLoadingTechs    = false.obs;

  // ── 订单列表 ──────────────────────────────────────────────────────
  final orderTab      = 0.obs;    // 0=待确认 1=进行中 2=已完成
  final orders        = <MerchantOrder>[].obs;
  final isLoadingOrders = false.obs;

  // ── 服务项目 ──────────────────────────────────────────────────────
  final services         = <MerchantService>[].obs;

  // ── 商家信息 ──────────────────────────────────────────────────────
  final shopName     = ''.obs;
  final shopLogo     = ''.obs;
  final walletBalance = 0.0.obs;

  MerchantHomeState();
}
