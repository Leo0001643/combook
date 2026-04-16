import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/auth/auth_controller.dart';
import '../../../l10n/app_localizations.dart';
import '../../technician/technician_list/technician_list_page.dart';
import '../../discover/discover/discover_page.dart';
import '../../order/order_list/order_list_page.dart';
import '../../profile/profile/profile_page.dart';
import 'member_home_logic.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Shell（带底部导航）- 使用 GetX + IndexedStack 替代 go_router StatefulShellRoute
// ─────────────────────────────────────────────────────────────────────────────
class MemberHomePage extends GetView<MemberHomeLogic> {
  const MemberHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() => IndexedStack(
        index: controller.state.currentTab.value,
        children: const [
          MemberHomeTab(),        // 首页
          TechnicianListPage(),   // 技师
          DiscoverPage(),         // 发现
          OrderListPage(),        // 订单
          ProfilePage(),          // 我的
        ],
      )),
      bottomNavigationBar: Obx(() => _BottomNav(
        currentIndex: controller.state.currentTab.value,
        onTap: controller.changeTab,
      )),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final items = [
      {'icon': Icons.home_outlined, 'active': Icons.home, 'label': l.navHome},
      {'icon': Icons.people_outline, 'active': Icons.people, 'label': l.navTechnician},
      {'icon': Icons.explore_outlined, 'active': Icons.explore, 'label': l.navDiscover},
      {'icon': Icons.receipt_long_outlined, 'active': Icons.receipt_long, 'label': l.navOrder},
      {'icon': Icons.person_outline, 'active': Icons.person, 'label': l.navProfile},
    ];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 16, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 60,
          child: Row(
            children: List.generate(items.length, (i) {
              final isActive = currentIndex == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isActive ? items[i]['active'] as IconData : items[i]['icon'] as IconData,
                        size: 24,
                        color: isActive ? AppTheme.primaryColor : AppTheme.gray400,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        items[i]['label'] as String,
                        style: TextStyle(
                          fontSize: 11,
                          color: isActive ? AppTheme.primaryColor : AppTheme.gray400,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 首页 Tab
// ─────────────────────────────────────────────────────────────────────────────
class MemberHomeTab extends StatefulWidget {
  const MemberHomeTab({super.key});

  @override
  State<MemberHomeTab> createState() => _MemberHomeTabState();
}

class _MemberHomeTabState extends State<MemberHomeTab> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _bannerCtrl = PageController();
  Timer? _bannerTimer;
  int _bannerPage = 0;
  int _selectedTab = 0;

  // 技师数据（tag 改用 key，运行时根据语言翻译）
  static const _techData = [
    {'id': '1', 'name': '陈秀玲', 'age': '90后', 'rating': 4.9, 'orders': 226, 'tagKey': 'returnFavorite', 'tagColor': Color(0xFF5B5BD6), 'price': 28.6, 'emoji': '👩'},
    {'id': '2', 'name': '阿丽达', 'age': '00后', 'rating': 4.8, 'orders': 140, 'tagKey': 'newRecommended', 'tagColor': Color(0xFF0D9488), 'price': 22.0, 'emoji': '👩🏻'},
    {'id': '3', 'name': '赵丹',   'age': '85后', 'rating': 4.7, 'orders': 89,  'tagKey': 'newRecommended', 'tagColor': Color(0xFF0D9488), 'price': 19.0, 'emoji': '👩🏼'},
    {'id': '4', 'name': '任菁',   'age': '85后', 'rating': 4.8, 'orders': 67,  'tagKey': 'qualityService', 'tagColor': Color(0xFFD97706), 'price': 21.0, 'emoji': '👩🏽'},
  ];

  String _tagLabel(String key, AppLocalizations l) {
    switch (key) {
      case 'returnFavorite': return l.tagFavoriteReturner;
      case 'newRecommended': return l.tagNewRecommended;
      case 'qualityService': return l.tagQualityService;
      default: return key;
    }
  }

  List<_BannerData> _getBanners(AppLocalizations l) => [
    _BannerData(
      colors: const [Color(0xFF5B5BD6), Color(0xFF8B5CF6)],
      emoji: '💆‍♀️',
      title: l.banner1Title,
      sub: l.banner1Sub,
      cta: l.banner1Cta,
    ),
    _BannerData(
      colors: const [Color(0xFF0D9488), Color(0xFF059669)],
      emoji: '🌸',
      title: l.banner2Title,
      sub: l.banner2Sub,
      cta: l.banner2Cta,
    ),
    _BannerData(
      colors: const [Color(0xFFD97706), Color(0xFFDC2626)],
      emoji: '🎁',
      title: l.banner3Title,
      sub: l.banner3Sub,
      cta: l.banner3Cta,
    ),
  ];

  List<Map<String, dynamic>> _getPackages(AppLocalizations l) => [
    {
      'name': l.pkg1Name,
      'desc': l.pkg1Desc,
      'price': r'$28.60',
      'orders': '279',
      'color': const Color(0xFF5B5BD6),
      'emoji': '🌸',
      'label': l.memberPriceLabel,
    },
    {
      'name': l.pkg2Name,
      'desc': l.pkg2Desc,
      'price': r'$19.00',
      'orders': '139',
      'color': const Color(0xFF0D9488),
      'emoji': '💆',
      'label': l.hotPackage,
    },
  ];

  List<Map<String, dynamic>> _getServices(AppLocalizations l) => [
    {'emoji': '💆', 'label': l.catFullBodyMassage, 'color': const Color(0xFF5B5BD6)},
    {'emoji': '🌸', 'label': l.catOilSpa,          'color': const Color(0xFFD97706)},
    {'emoji': '🦶', 'label': l.catFootMassage,      'color': const Color(0xFF0D9488)},
    {'emoji': '🤰', 'label': l.catPostnatalCare,    'color': const Color(0xFFEC4899)},
    {'emoji': '🏢', 'label': l.catMerchantPartner,  'color': const Color(0xFF8B5CF6)},
  ];

  @override
  void initState() {
    super.initState();
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_bannerCtrl.hasClients) return;
      final next = (_bannerPage + 1) % 3;
      _bannerCtrl.animateToPage(next, duration: const Duration(milliseconds: 600), curve: Curves.easeInOut);
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final banners = _getBanners(l);
    final packages = _getPackages(l);
    final services = _getServices(l);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF6F7FA),
      endDrawer: _buildLanguageDrawer(context, l),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(context, l)),
          SliverToBoxAdapter(child: _buildHeroBanner(banners)),
          SliverToBoxAdapter(child: _buildServiceCategories(services)),
          SliverToBoxAdapter(child: _buildGuestBanner(context, l)),
          SliverToBoxAdapter(child: _buildTechSection(context, l)),
          SliverToBoxAdapter(child: _buildPackagesSection(context, l, packages)),
          const SliverToBoxAdapter(child: SizedBox(height: 28)),
        ],
      ),
    );
  }

  // ── 语言抽屉 ─────────────────────────────────────────────────────────────
  Widget _buildLanguageDrawer(BuildContext context, AppLocalizations l) {
    final languages = [
      {'code': 'zh-CN', 'flag': '🇨🇳', 'name': '中文简体', 'native': 'Chinese (Simplified)'},
      {'code': 'en',    'flag': '🇺🇸', 'name': 'English', 'native': 'English'},
      {'code': 'vi',    'flag': '🇻🇳', 'name': 'Tiếng Việt', 'native': 'Vietnamese'},
      {'code': 'km',    'flag': '🇰🇭', 'name': 'ភាសាខ្មែរ', 'native': 'Khmer'},
    ];

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.75,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topLeft: Radius.circular(20), bottomLeft: Radius.circular(20)),
      ),
      child: Obx(() {
        final auth = AuthController.to;
        return Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 20,
                left: 20, right: 20, bottom: 20,
              ),
              decoration: const BoxDecoration(
                gradient: AppColors.darkHeaderGradient,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(20)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🌐', style: TextStyle(fontSize: 36)),
                  const SizedBox(height: 8),
                  Text(l.languageSettings, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(l.langAndLanguage, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Language options
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                children: languages.map((lang) {
                  final isSelected = auth.appLocale.value == lang['code'];
                  return GestureDetector(
                    onTap: () {
                      auth.switchLanguage(lang['code']!);
                      Navigator.of(context).pop();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary.withValues(alpha: 0.08) : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : Colors.grey.shade200,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(lang['flag']!, style: const TextStyle(fontSize: 26)),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(lang['name']!, style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected ? AppColors.primary : const Color(0xFF333333),
                                )),
                                Text(lang['native']!, style: const TextStyle(fontSize: 12, color: Color(0xFF999999))),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            // Footer
            Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 16, left: 16, right: 16),
              child: Text(
                l.selectPreferredLang,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, color: Color(0xFFBBBBBB)),
              ),
            ),
          ],
        );
      }),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, AppLocalizations l) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1F2E), Color(0xFF2A3348)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top row
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppTheme.primaryColor, AppTheme.accentColor]),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: const Text('CamBook', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 0.3)),
                  ),
                  const SizedBox(width: 10),
                  // Location (fills remaining space)
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.location_on_rounded, color: AppTheme.primaryColor, size: 14),
                        SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            'Phnom Penh, Cambodia',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Colors.white54),
                      ],
                    ),
                  ),
                  // Auth buttons + language button
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 多语言按钮
                      _NavIconBtn(
                        icon: Icons.language_rounded,
                        onTap: () => _scaffoldKey.currentState?.openEndDrawer(),
                      ),
                      const SizedBox(width: 6),
                      Obx(() {
                        final auth = AuthController.to;
                        if (auth.isLoggedIn.value) {
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _NavIconBtn(icon: Icons.card_giftcard_outlined, badge: true, onTap: () {}),
                              const SizedBox(width: 6),
                              _NavIconBtn(icon: Icons.chat_bubble_outline_rounded, onTap: () => Get.toNamed(AppRoutes.imList)),
                            ],
                          );
                        }
                        return GestureDetector(
                          onTap: () => Get.toNamed(AppRoutes.login),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(l.login, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                          ),
                        );
                      }),
                    ],
                  ),
                ],
              ),
            ),
            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: GestureDetector(
                onTap: () => Get.toNamed(AppRoutes.search),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.12)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search_rounded, color: Colors.white38, size: 18),
                      const SizedBox(width: 8),
                      Text(l.searchHint, style: TextStyle(color: Colors.white.withOpacity(0.38), fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Hero Banner ───────────────────────────────────────────────────────────
  Widget _buildHeroBanner(List<_BannerData> banners) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      height: 164,
      child: Stack(
        children: [
          PageView.builder(
            controller: _bannerCtrl,
            itemCount: banners.length,
            onPageChanged: (i) => setState(() => _bannerPage = i),
            itemBuilder: (ctx, i) {
              final b = banners[i];
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(colors: b.colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(b.title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, height: 1.2)),
                          const SizedBox(height: 4),
                          Text(b.sub, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12, height: 1.35)),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(color: Colors.white.withOpacity(0.35)),
                            ),
                            child: Text(b.cta, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ),
                    Text(b.emoji, style: const TextStyle(fontSize: 74)),
                  ],
                ),
              );
            },
          ),
          // Page dots
          Positioned(
            bottom: 10,
            right: 14,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(banners.length, (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: i == _bannerPage ? 18 : 6,
                height: 6,
                margin: const EdgeInsets.only(left: 4),
                decoration: BoxDecoration(
                  color: i == _bannerPage ? Colors.white : Colors.white38,
                  borderRadius: BorderRadius.circular(3),
                ),
              )),
            ),
          ),
        ],
      ),
    );
  }

  // ── Service Categories ────────────────────────────────────────────────────
  Widget _buildServiceCategories(List<Map<String, dynamic>> services) {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: services.map((s) {
          final color = s['color'] as Color;
          return GestureDetector(
            onTap: () {},
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                  child: Center(child: Text(s['emoji'] as String, style: const TextStyle(fontSize: 26))),
                ),
                const SizedBox(height: 7),
                Text(s['label'] as String, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppTheme.gray700)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Guest Promo Banner ────────────────────────────────────────────────────
  Widget _buildGuestBanner(BuildContext context, AppLocalizations l) {
    return Obx(() {
      if (AuthController.to.isLoggedIn.value) return const SizedBox.shrink();
      return GestureDetector(
        onTap: () => Get.toNamed(AppRoutes.register),
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A1F2E), Color(0xFF2D3748)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(color: AppTheme.primaryColor, borderRadius: BorderRadius.circular(5)),
                      child: Text(l.newUserExclusive, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(height: 10),
                    Text(l.newUserRegisterOffer, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(l.unlockFeaturesDiscount, style: TextStyle(color: Colors.white.withOpacity(0.58), fontSize: 12.5)),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [AppTheme.primaryColor, AppTheme.accentColor]),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Text(l.registerNowArrow, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Text('💆', style: TextStyle(fontSize: 62)),
            ],
          ),
        ),
      );
    });
  }

  // ── Featured Technicians ──────────────────────────────────────────────────
  Widget _buildTechSection(BuildContext context, AppLocalizations l) {
    final tabs = [l.recommended, l.nearby, l.newUser, l.specialOffer];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 22, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l.featuredTech, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.gray900)),
              GestureDetector(
                onTap: () => Get.toNamed(AppRoutes.technicianList),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l.viewAll, style: const TextStyle(fontSize: 13, color: AppTheme.primaryColor, fontWeight: FontWeight.w500)),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppTheme.primaryColor),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Filter tabs
        SizedBox(
          height: 36,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 16),
            itemCount: tabs.length,
            itemBuilder: (_, i) {
              final isSelected = _selectedTab == i;
              return GestureDetector(
                onTap: () => setState(() => _selectedTab = i),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryColor : const Color(0xFFEDF0F4),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    tabs[i],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : AppTheme.gray600,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        // Tech cards
        SizedBox(
          height: 240,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 16, right: 4),
            itemCount: _techData.length,
            itemBuilder: (ctx, i) => _buildTechCard(context, l, _techData[i]),
          ),
        ),
      ],
    );
  }

  Widget _buildTechCard(BuildContext context, AppLocalizations l, Map<String, dynamic> tech) {
    final tagColor = tech['tagColor'] as Color;
    final tagLabel = _tagLabel(tech['tagKey'] as String, l);
    return GestureDetector(
      onTap: () => Get.toNamed(AppRoutes.technicianDetail, arguments: {'id': tech['id']}),
      child: Container(
        width: 154,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 14, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo area
            Stack(
              children: [
                Container(
                  height: 118,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    gradient: LinearGradient(
                      colors: [tagColor.withOpacity(0.22), tagColor.withOpacity(0.07)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Center(child: Text(tech['emoji'] as String, style: const TextStyle(fontSize: 56))),
                ),
                // Tag label
                Positioned(
                  top: 9, left: 9,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(color: tagColor, borderRadius: BorderRadius.circular(6)),
                    child: Text(tagLabel, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
                  ),
                ),
                // Rating badge
                Positioned(
                  top: 9, right: 9,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), borderRadius: BorderRadius.circular(6)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 11),
                        const SizedBox(width: 2),
                        Text('${tech['rating']}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Info
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
              child: Row(
                children: [
                  Text(tech['name'] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.gray900)),
                  const SizedBox(width: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(4)),
                    child: Text(tech['age'] as String, style: const TextStyle(fontSize: 10, color: AppTheme.gray500)),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 3, 10, 0),
              child: Text(l.servedTimes(tech['orders'] as int), style: const TextStyle(fontSize: 11, color: AppTheme.gray500)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '\$${tech['price']}',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFFDC2626)),
                  ),
                  GestureDetector(
                    onTap: () {
                      if (!AuthController.to.isLoggedIn.value) {
                        Get.toNamed(AppRoutes.login);
                        return;
                      }
                      Get.toNamed(AppRoutes.createOrder, arguments: {'technicianId': tech['id']});
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(l.book, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Hot Packages ──────────────────────────────────────────────────────────
  Widget _buildPackagesSection(BuildContext context, AppLocalizations l, List<Map<String, dynamic>> packages) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l.hotPackage, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.gray900)),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l.allPackages, style: const TextStyle(fontSize: 13, color: AppTheme.primaryColor, fontWeight: FontWeight.w500)),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppTheme.primaryColor),
                ],
              ),
            ],
          ),
        ),
        ...packages.map((pkg) => _buildPackageCard(context, l, pkg)),
      ],
    );
  }

  Widget _buildPackageCard(BuildContext context, AppLocalizations l, Map<String, dynamic> pkg) {
    final color = pkg['color'] as Color;
    return GestureDetector(
      onTap: () {
        if (!AuthController.to.isLoggedIn.value) {
          Get.toNamed(AppRoutes.login);
          return;
        }
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 14, offset: const Offset(0, 3))],
        ),
        child: Row(
          children: [
            // Left icon area
            Container(
              width: 76,
              height: 86,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
              child: Center(child: Text(pkg['emoji'] as String, style: const TextStyle(fontSize: 32))),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pkg['name'] as String, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.gray900)),
                    const SizedBox(height: 4),
                    Text(pkg['desc'] as String, style: const TextStyle(fontSize: 12, color: AppTheme.gray500, height: 1.3)),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(Icons.shopping_bag_outlined, size: 12, color: AppTheme.gray400),
                        const SizedBox(width: 3),
                        Text(l.alreadyBooked(int.parse(pkg['orders'] as String)), style: const TextStyle(fontSize: 11, color: AppTheme.gray400)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Price + CTA
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 14, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(5)),
                    child: Text(pkg['label'] as String, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
                  ),
                  const SizedBox(height: 6),
                  Text(pkg['price'] as String, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFFDC2626))),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppTheme.primaryColor, AppTheme.accentColor]),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(l.banner1Cta, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper widgets
// ─────────────────────────────────────────────────────────────────────────────

class _NavIconBtn extends StatelessWidget {
  final IconData icon;
  final bool badge;
  final VoidCallback onTap;
  const _NavIconBtn({required this.icon, this.badge = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(icon, size: 18, color: Colors.white),
          ),
          if (badge)
            Positioned(
              right: 3,
              top: 3,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
              ),
            ),
        ],
      ),
    );
  }
}

class _BannerData {
  final List<Color> colors;
  final String emoji;
  final String title;
  final String sub;
  final String cta;
  const _BannerData({required this.colors, required this.emoji, required this.title, required this.sub, required this.cta});
}
