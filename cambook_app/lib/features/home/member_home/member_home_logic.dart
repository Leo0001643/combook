import 'package:get/get.dart';
import '../../../core/auth/auth_controller.dart';
import '../../../core/routes/app_routes.dart';
import 'member_home_state.dart';

/// 会员首页逻辑
/// 吸收了原 HomeController（features/home/controllers/）的全部内容
/// 同时管理底部导航 Tab 切换
class MemberHomeLogic extends GetxController {
  static MemberHomeLogic get to => Get.find();

  final state = MemberHomeState();

  // ── 数据（TODO: 替换为接口返回数据） ─────────────────────────────
  final technicians = <Map<String, dynamic>>[
    {'id': '1', 'name': '陈秀玲', 'age': '90后', 'rating': 4.9, 'orders': 226,
     'tag': '回头客最爱', 'tagKey': 0, 'price': 28.6, 'emoji': '👩'},
    {'id': '2', 'name': '阿丽达',  'age': '00后', 'rating': 4.8, 'orders': 140,
     'tag': '新人推荐',   'tagKey': 1, 'price': 22.0, 'emoji': '👩🏻'},
    {'id': '3', 'name': '赵丹',    'age': '85后', 'rating': 4.7, 'orders': 89,
     'tag': '新人推荐',   'tagKey': 1, 'price': 19.0, 'emoji': '👩🏼'},
    {'id': '4', 'name': '任菁',    'age': '85后', 'rating': 4.8, 'orders': 67,
     'tag': '优质服务',   'tagKey': 2, 'price': 21.0, 'emoji': '👩🏽'},
  ].obs;

  final hotPackages = <Map<String, dynamic>>[
    {
      'name': '香薰精油全身按摩',
      'desc': '90分钟 · 专业精油 · 深层放松',
      'price': r'$28.60',
      'orders': '279',
      'colorKey': 0,
      'emoji': '🌸',
      'label': '会员价',
    },
    {
      'name': '全身经络疏通',
      'desc': '60分钟 · 经络调理 · 缓解疲劳',
      'price': r'$19.00',
      'orders': '139',
      'colorKey': 1,
      'emoji': '💆',
      'label': '热门套餐',
    },
  ].obs;

  // ── Tab 切换 ───────────────────────────────────────────────────────
  void changeTab(int tab) {
    // 需要登录的 Tab（订单=3、我的=4）
    if (tab >= 3 && !AuthController.to.isLoggedIn.value) {
      Get.toNamed(AppRoutes.login);
      return;
    }
    state.currentTab.value = tab;
  }

  // ── Banner 页码 ───────────────────────────────────────────────────
  void onBannerPageChanged(int page) => state.bannerPage.value = page;

  // ── 技师 Tab ─────────────────────────────────────────────────────
  void onTechTabChanged(int tab) => state.selectedTab.value = tab;
}
