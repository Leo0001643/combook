import 'package:get/get.dart';
import '../../../core/auth/auth_controller.dart';
import 'merchant_home_state.dart';

/// 多语言服务名映射（模拟后端 namesJson 字段）
const _svcAromaSpa = {
  'zh': '精油香薰SPA',     'en': 'Aromatherapy SPA',
  'vi': 'Liệu pháp hương thơm',  'km': 'ស្ប៉ាក្រអូប',
};
const _svcThaiMassage = {
  'zh': '泰式传统按摩',    'en': 'Traditional Thai Massage',
  'vi': 'Massage Thái truyền thống', 'km': 'ម៉ាស្សាថៃប្រពៃណី',
};
const _svcHotStone = {
  'zh': '热石按摩',        'en': 'Hot Stone Massage',
  'vi': 'Massage đá nóng',          'km': 'ម៉ាស្សាថ្មក្ដៅ',
};
const _svcReflexology = {
  'zh': '脚底反射疗法',    'en': 'Foot Reflexology',
  'vi': 'Bấm huyệt bàn chân',       'km': 'ការព្យាបាលជើង',
};
const _svcPostnatal = {
  'zh': '产后修复套餐',    'en': 'Postnatal Recovery Package',
  'vi': 'Gói phục hồi sau sinh',    'km': 'កញ្ចប់ស្ដារក្រោយសម្រាល',
};
const _svcDeepTissue = {
  'zh': '深部组织按摩',    'en': 'Deep Tissue Massage',
  'vi': 'Massage mô sâu',            'km': 'ម៉ាស្សាជ្រៅ',
};

/// 多语言分类
const _catFullBody  = {'zh': '全身按摩',  'en': 'Full Body Massage',  'vi': 'Massage toàn thân',    'km': 'ម៉ាស្សាទូទៅ'};
const _catThai      = {'zh': '泰式按摩',  'en': 'Thai Massage',       'vi': 'Massage Thái',          'km': 'ម៉ាស្សាថៃ'};
const _catHotStone  = {'zh': '热石理疗',  'en': 'Hot Stone Therapy',  'vi': 'Trị liệu đá nóng',     'km': 'ការព្យាបាលថ្មក្ដៅ'};
const _catFoot      = {'zh': '脚部护理',  'en': 'Foot Care',          'vi': 'Chăm sóc bàn chân',    'km': 'ការថែទាំជើង'};
const _catSpecial   = {'zh': '专项护理',  'en': 'Specialist Care',    'vi': 'Chăm sóc chuyên biệt', 'km': 'ការថែទាំពិសេស'};
const _catSports    = {'zh': '运动恢复',  'en': 'Sports Recovery',    'vi': 'Phục hồi thể thao',    'km': 'ការស្ដារកីឡា'};

class MerchantHomeLogic extends GetxController {
  final state = MerchantHomeState();

  @override
  void onInit() {
    super.onInit();
    _loadUserInfo();
    _loadMockData();
  }

  void _loadUserInfo() {
    final auth = AuthController.to;
    state.shopName.value = auth.nickname.value ?? '我的店铺';
  }

  void _loadMockData() {
    // 大盘数据
    state.todayOrders.value   = 24;
    state.todayRevenue.value  = 3680.0;
    state.onlineTechs.value   = 6;
    state.totalTechs.value    = 10;
    state.avgRating.value     = 4.8;
    state.monthRevenue.value  = 78400.0;
    state.pendingCount.value  = 3;
    state.walletBalance.value = 12480.0;

    state.weekRevenue.value = [2400.0, 3200.0, 2800.0, 4100.0, 3680.0, 5200.0, 4800.0];
    state.weekOrders.value  = [16, 21, 18, 27, 24, 35, 31];

    // 技师列表
    state.techs.value = [
      const MerchantTech(id: '1', name: '陈秀玲', skill: '精油按摩 / 热石', status: 2, todayOrders: 5, todayIncome: 425.0, rating: 4.9),
      const MerchantTech(id: '2', name: '蔡庆',   skill: '泰式按摩 / 脚底', status: 1, todayOrders: 4, todayIncome: 280.0, rating: 4.7),
      const MerchantTech(id: '3', name: '任菁',   skill: '香薰SPA / 面部',  status: 0, todayOrders: 2, todayIncome: 160.0, rating: 4.8),
      const MerchantTech(id: '4', name: '曾海秀', skill: '深部按摩 / 拉伸', status: 1, todayOrders: 3, todayIncome: 210.0, rating: 4.6),
      const MerchantTech(id: '5', name: '林梅',   skill: '产后修复 / 淋巴', status: 0, todayOrders: 0, todayIncome: 0.0,   rating: 4.9),
      const MerchantTech(id: '6', name: '黄丽',   skill: '经络疏通 / 艾灸', status: 2, todayOrders: 6, todayIncome: 510.0, rating: 5.0),
    ];

    // 服务项目（含多语言）
    state.services.value = [
      const MerchantService(id: '1', names: _svcAromaSpa,    categories: _catFullBody,  price: 85.0,  duration: 90,  isActive: true,  orderCount: 342),
      const MerchantService(id: '2', names: _svcThaiMassage, categories: _catThai,      price: 55.0,  duration: 60,  isActive: true,  orderCount: 256),
      const MerchantService(id: '3', names: _svcHotStone,    categories: _catHotStone,  price: 110.0, duration: 120, isActive: true,  orderCount: 198),
      const MerchantService(id: '4', names: _svcReflexology, categories: _catFoot,      price: 45.0,  duration: 60,  isActive: true,  orderCount: 423),
      const MerchantService(id: '5', names: _svcPostnatal,   categories: _catSpecial,   price: 220.0, duration: 150, isActive: false, orderCount: 87),
      const MerchantService(id: '6', names: _svcDeepTissue,  categories: _catSports,    price: 95.0,  duration: 90,  isActive: true,  orderCount: 165),
    ];

    // 订单列表（含多语言服务名）
    state.orders.value = [
      const MerchantOrder(id: 'ORD-001', clientName: '王女士', techName: '陈秀玲', serviceNames: _svcAromaSpa,    time: '今天 15:00', amount: 85.0,  status: 0),
      const MerchantOrder(id: 'ORD-002', clientName: '李先生', techName: '黄丽',   serviceNames: _svcHotStone,    time: '今天 13:00', amount: 110.0, status: 2),
      const MerchantOrder(id: 'ORD-003', clientName: '张女士', techName: '蔡庆',   serviceNames: _svcThaiMassage, time: '今天 11:00', amount: 55.0,  status: 3),
      const MerchantOrder(id: 'ORD-004', clientName: '赵先生', techName: '任菁',   serviceNames: _svcReflexology, time: '昨天 16:00', amount: 45.0,  status: 3),
      const MerchantOrder(id: 'ORD-005', clientName: '周女士', techName: '曾海秀', serviceNames: _svcDeepTissue,  time: '今天 16:30', amount: 95.0,  status: 0),
    ];
  }

  // ── 技师上下线切换 ──────────────────────────────────────────────
  void toggleTechStatus(String techId) {
    final idx = state.techs.indexWhere((t) => t.id == techId);
    if (idx == -1) return;
    final t         = state.techs[idx];
    final newStatus = t.status == 0 ? 1 : 0;
    state.techs[idx] = MerchantTech(
      id:           t.id,
      name:         t.name,
      skill:        t.skill,
      status:       newStatus,
      todayOrders:  t.todayOrders,
      todayIncome:  t.todayIncome,
      rating:       t.rating,
    );
    state.onlineTechs.value = state.techs.where((t) => t.status > 0).length;
  }

  // ── 服务上下架 ──────────────────────────────────────────────────
  void toggleService(String serviceId) {
    final idx = state.services.indexWhere((s) => s.id == serviceId);
    if (idx == -1) return;
    state.services[idx] = state.services[idx].copyWith(isActive: !state.services[idx].isActive);
  }

  // ── 确认订单 ────────────────────────────────────────────────────
  void confirmOrder(String orderId) {
    final idx = state.orders.indexWhere((o) => o.id == orderId);
    if (idx == -1) return;
    state.orders[idx] = state.orders[idx].copyWith(status: 1);
    state.pendingCount.value = state.orders.where((o) => o.status == 0).length;
    Get.snackbar('已确认', '订单 ${state.orders[idx].id} 已确认', snackPosition: SnackPosition.TOP);
  }

  // ── 过滤当前 Tab 的订单 ─────────────────────────────────────────
  List<MerchantOrder> get filteredOrders {
    final tab = state.orderTab.value;
    return state.orders.where((o) {
      if (tab == 0) return o.status == 0;
      if (tab == 1) return o.status == 1 || o.status == 2;
      return o.status == 3;
    }).toList();
  }
}
