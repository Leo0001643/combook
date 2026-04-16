import 'package:get/get.dart';
import '../../../core/auth/auth_controller.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/geocoding_service.dart';
import 'tech_home_state.dart';

/// 金边各地标坐标（用于模拟数据地理编码演示）
const _mockLocations = {
  'vattanac': (lat: 11.570621, lng: 104.921251),
  'bkk1':     (lat: 11.568818, lng: 104.929029),
  'aeon':     (lat: 11.563580, lng: 104.909090),
  'central':  (lat: 11.556374, lng: 104.928228),
};

/// 多语言服务名映射（模拟后端返回的 namesJson）
const _svcAromaSpa = {
  'zh': '精油香薰SPA (90分钟)',
  'en': 'Aromatherapy SPA (90 min)',
  'vi': 'Liệu pháp hương thơm (90 phút)',
  'km': 'ស្ប៉ាក្រអូប (90 នាទី)',
};
const _svcThaiMassage = {
  'zh': '泰式传统按摩 (60分钟)',
  'en': 'Traditional Thai Massage (60 min)',
  'vi': 'Massage Thái truyền thống (60 phút)',
  'km': 'ម៉ាស្សាថៃប្រពៃណី (60 នាទី)',
};
const _svcHotStone = {
  'zh': '热石按摩 (120分钟)',
  'en': 'Hot Stone Massage (120 min)',
  'vi': 'Massage đá nóng (120 phút)',
  'km': 'ម៉ាស្សាថ្មក្ដៅ (120 នាទី)',
};
const _svcDeepTissue = {
  'zh': '深部组织按摩 (90分钟)',
  'en': 'Deep Tissue Massage (90 min)',
  'vi': 'Massage mô sâu (90 phút)',
  'km': 'ម៉ាស្សាជ្រៅ (90 នាទី)',
};
const _svcReflexology = {
  'zh': '脚底反射疗法 (60分钟)',
  'en': 'Foot Reflexology (60 min)',
  'vi': 'Bấm huyệt bàn chân (60 phút)',
  'km': 'ការព្យាបាលជើង (60 នាទី)',
};

class TechHomeLogic extends GetxController {
  final state = TechHomeState();

  @override
  void onInit() {
    super.onInit();
    _loadUserInfo();
    _loadMockData();
    _resolveAllAddresses();
    // 语言切换时：清空缓存并重新地理编码
    ever(AuthController.to.appLocale, (_) {
      GeocodingService.to.clearCache();
      _resolveAllAddresses();
    });
  }

  void _loadUserInfo() {
    final auth = AuthController.to;
    state.techName.value   = auth.nickname.value ?? '技师';
    state.techAvatar.value = auth.avatar.value ?? '';
  }

  // ── 模拟数据（真实环境从 API 获取） ────────────────────────────────
  void _loadMockData() {
    state.todayOrders.value    = 8;
    state.todayIncome.value    = 320.0;
    state.rating.value         = 4.9;
    state.completedTotal.value = 1256;
    state.walletBalance.value  = 2480.50;
    state.monthIncome.value    = 4620.0;
    state.withdrawable.value   = 1800.0;
    state.certStatus.value     = 2;

    final loc = _mockLocations;
    state.pendingOrders.value = [
      TechOrder(
        id:           'ORD-20240412-001',
        clientName:   '王女士',
        serviceNames: _svcAromaSpa,
        address:      '金边市7月7日大道 Vattanac Capital 2208室',
        time:         '今天 15:00 - 16:30',
        amount:       85.0,
        status:       0,
        lat:          loc['vattanac']!.lat,
        lng:          loc['vattanac']!.lng,
      ),
      TechOrder(
        id:           'ORD-20240412-002',
        clientName:   '李先生',
        serviceNames: _svcThaiMassage,
        address:      '金边市BKK1 Naga World 旁',
        time:         '今天 17:30 - 18:30',
        amount:       55.0,
        status:       0,
        lat:          loc['bkk1']!.lat,
        lng:          loc['bkk1']!.lng,
      ),
    ];

    state.activeOrders.value = [
      TechOrder(
        id:           'ORD-20240412-003',
        clientName:   '陈女士',
        serviceNames: _svcHotStone,
        address:      '金边市俄罗斯大道 Aeon Mall 附近',
        time:         '今天 13:00 - 15:00',
        amount:       110.0,
        status:       2,
        lat:          loc['aeon']!.lat,
        lng:          loc['aeon']!.lng,
      ),
    ];

    state.completedOrders.value = [
      TechOrder(
        id:           'ORD-20240411-001',
        clientName:   '张先生',
        serviceNames: _svcDeepTissue,
        address:      '金边市中央商务区',
        time:         '昨天 10:00',
        amount:       95.0,
        status:       3,
        lat:          loc['central']!.lat,
        lng:          loc['central']!.lng,
      ),
      TechOrder(
        id:           'ORD-20240411-002',
        clientName:   '赵女士',
        serviceNames: _svcReflexology,
        address:      '金边市中央商务区',
        time:         '昨天 14:30',
        amount:       45.0,
        status:       3,
        lat:          loc['central']!.lat,
        lng:          loc['central']!.lng,
      ),
    ];

    state.incomeRecords.value = [
      const IncomeRecord(id: '1', title: '热石按摩服务',  date: '今天 13:00',   amount: 110.0, isIncome: true),
      const IncomeRecord(id: '2', title: '精油香薰SPA',   date: '昨天 16:00',   amount: 85.0,  isIncome: true),
      const IncomeRecord(id: '3', title: '提现到银行',    date: '2024-04-10',  amount: 500.0, isIncome: false),
      const IncomeRecord(id: '4', title: '泰式按摩',      date: '2024-04-09',  amount: 55.0,  isIncome: true),
      const IncomeRecord(id: '5', title: '深部组织按摩',  date: '2024-04-08',  amount: 95.0,  isIncome: true),
    ];
  }

  // ── 地理编码：将所有订单的 lat/lng 转换为当前语言的地址文本 ────────
  Future<void> _resolveAllAddresses() async {
    final allOrders = [
      ...state.pendingOrders,
      ...state.activeOrders,
      ...state.completedOrders,
    ];
    for (final order in allOrders) {
      if (order.lat != null && order.lng != null) {
        final localized = await GeocodingService.to.reverseGeocode(
          order.lat!,
          order.lng!,
          fallback: order.address,
        );
        state.resolvedAddresses[order.id] = localized;
      }
    }
  }

  // ── 切换在线状态 ─────────────────────────────────────────────────
  Future<void> toggleOnline() async {
    if (state.isToggling.value) return;
    state.isToggling.value = true;
    final before    = state.isOnline.value;
    final newStatus = !before;
    state.isOnline.value = newStatus;
    try {
      await ApiClient.instance.put(
        '/api/app/technicians/online',
        queryParameters: {'online': newStatus},
      );
    } catch (e) {
      state.isOnline.value = before;
      Get.snackbar('网络异常', '切换状态失败，请检查网络', snackPosition: SnackPosition.TOP);
    } finally {
      state.isToggling.value = false;
    }
  }

  // ── 接受订单 ─────────────────────────────────────────────────────
  Future<void> acceptOrder(TechOrder order) async {
    try {
      await ApiClient.instance.post('/api/app/orders/${order.id}/accept');
    } catch (_) {}
    state.pendingOrders.remove(order);
    final active = order.copyWith(status: 2);
    state.activeOrders.add(active);
    if (state.resolvedAddresses.containsKey(order.id)) {
      state.resolvedAddresses[active.id] = state.resolvedAddresses[order.id]!;
    }
    Get.snackbar('已接单', '订单 ${order.id} 已确认接受', snackPosition: SnackPosition.TOP);
  }

  // ── 拒绝订单 ─────────────────────────────────────────────────────
  Future<void> rejectOrder(TechOrder order) async {
    try {
      await ApiClient.instance.post('/api/app/orders/${order.id}/reject');
    } catch (_) {}
    state.pendingOrders.remove(order);
    Get.snackbar('已拒绝', '订单 ${order.id} 已拒绝', snackPosition: SnackPosition.TOP);
  }

  // ── 完成订单 ─────────────────────────────────────────────────────
  Future<void> completeOrder(TechOrder order) async {
    try {
      await ApiClient.instance.post('/api/app/orders/${order.id}/complete');
    } catch (_) {}
    state.activeOrders.remove(order);
    final done = order.copyWith(status: 3);
    state.completedOrders.insert(0, done);
    state.todayIncome.value   = state.todayIncome.value + order.amount;
    state.todayOrders.value   = state.todayOrders.value + 1;
    state.walletBalance.value = state.walletBalance.value + order.amount;
    Get.snackbar('服务完成', '\$${order.amount.toStringAsFixed(0)} 已到账', snackPosition: SnackPosition.TOP);
  }

  // ── 申请提现 ─────────────────────────────────────────────────────
  Future<void> applyWithdraw(double amount) async {
    if (amount > state.withdrawable.value) {
      Get.snackbar('提示', '提现金额超出可用余额', snackPosition: SnackPosition.TOP);
      return;
    }
    try {
      await ApiClient.instance.post(
        '/api/app/wallet/withdraw',
        data: {'amount': amount},
      );
    } catch (_) {}
    state.withdrawable.value  = state.withdrawable.value - amount;
    state.walletBalance.value = state.walletBalance.value - amount;
    state.incomeRecords.insert(0, IncomeRecord(
      id:       DateTime.now().millisecondsSinceEpoch.toString(),
      title:    '提现到银行',
      date:     '申请中',
      amount:   amount,
      isIncome: false,
    ));
    Get.snackbar('提现申请已提交', '预计 1-3 个工作日到账', snackPosition: SnackPosition.TOP);
  }
}
