import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/auth/auth_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/language_switcher_button.dart';
import '../../../l10n/app_localizations.dart';
import 'merchant_home_logic.dart';
import 'merchant_home_state.dart';

// ─────────────────────────────────────────────────────────────────────────────
// 商户端颜色体系
// ─────────────────────────────────────────────────────────────────────────────
const _indigo      = Color(0xFF4F46E5);
const _indigoDark  = Color(0xFF3730A3);
const _indigoLight = Color(0xFFEEF2FF);
const _violet      = Color(0xFF7C3AED);
const _green       = Color(0xFF10B981);
const _greenLight  = Color(0xFFD1FAE5);
const _amber       = Color(0xFFF59E0B);
const _amberLight  = Color(0xFFFEF3C7);
const _red         = Color(0xFFEF4444);
const _redLight    = Color(0xFFFEE2E2);
const _blue        = Color(0xFF3B82F6);
const _orange      = Color(0xFFFF8C00);
const _bg          = Color(0xFFF4F6F8);

// ─────────────────────────────────────────────────────────────────────────────
// 商户端主页（4-Tab 底部导航）
// 核心修复：Obx 内读取 appLocale.value 订阅语言变化，
// 直接从 AuthController.locale 构建 l，使语言切换时所有子 Widget 随之重建。
// ─────────────────────────────────────────────────────────────────────────────
class MerchantHomePage extends StatelessWidget {
  const MerchantHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final logic = Get.find<MerchantHomeLogic>();
    return Obx(() {
      // 订阅语言变化：读取 appLocale.value 使 Obx 在语言切换时重建整个 Scaffold
      AuthController.to.appLocale.value;
      final l   = AppLocalizations(AuthController.to.locale);
      final tab = logic.state.currentTab.value;
      return Scaffold(
        backgroundColor: _bg,
        body: IndexedStack(
          index: tab,
          children: [
            _DashboardTab(logic: logic, l: l),
            _TechsTab(logic: logic, l: l),
            _OrdersTab(logic: logic, l: l),
            _ProfileTab(logic: logic, l: l),
          ],
        ),
        bottomNavigationBar: _buildBottomNav(logic, tab, l),
      );
    });
  }

  Widget _buildBottomNav(MerchantHomeLogic logic, int tab, AppLocalizations l) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 20, offset: Offset(0, -4))],
      ),
      child: SafeArea(
        top: false,
        child: Obx(() => BottomNavigationBar(
          currentIndex: tab,
          onTap: (i) => logic.state.currentTab.value = i,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: _indigo,
          unselectedItemColor: AppTheme.gray400,
          elevation: 0,
          selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          items: [
            BottomNavigationBarItem(icon: const Icon(Icons.dashboard_rounded), label: l.merchantHub),
            BottomNavigationBarItem(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.people_rounded),
                  if (logic.state.onlineTechs.value > 0)
                    Positioned(
                      right: -4, top: -4,
                      child: Container(
                        width: 16, height: 16,
                        decoration: const BoxDecoration(color: _green, shape: BoxShape.circle),
                        child: Center(
                          child: Text('${logic.state.onlineTechs.value}',
                              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ),
                ],
              ),
              label: l.techMgmt,
            ),
            BottomNavigationBarItem(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.receipt_long_rounded),
                  if (logic.state.pendingCount.value > 0)
                    Positioned(
                      right: -4, top: -4,
                      child: Container(
                        width: 16, height: 16,
                        decoration: const BoxDecoration(color: _red, shape: BoxShape.circle),
                        child: Center(
                          child: Text('${logic.state.pendingCount.value}',
                              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ),
                ],
              ),
              label: l.orderMgmt,
            ),
            BottomNavigationBarItem(icon: const Icon(Icons.store_rounded), label: l.navProfile),
          ],
        )),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 1 · 大盘
// ─────────────────────────────────────────────────────────────────────────────
class _DashboardTab extends StatelessWidget {
  final MerchantHomeLogic logic;
  final AppLocalizations l;
  const _DashboardTab({required this.logic, required this.l});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildHeader()),
        SliverToBoxAdapter(child: _buildKPICards()),
        SliverToBoxAdapter(child: _buildRevenueChart()),
        SliverToBoxAdapter(child: _buildTopTechs()),
        SliverToBoxAdapter(child: _buildQuickOps()),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_indigoDark, _indigo, _violet],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Obx(() => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.merchantHub, style: const TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 1)),
                        const SizedBox(height: 4),
                        Text(
                          logic.state.shopName.value.isEmpty ? l.myShop : logic.state.shopName.value,
                          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
                        ),
                      ],
                    )),
                  ),
                  const LanguageSwitcherButton(showLabel: true),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(20)),
                    child: IconButton(
                      icon: const Icon(Icons.notifications_outlined, color: Colors.white70, size: 22),
                      onPressed: () {},
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white30, width: 2),
                    ),
                    child: const Center(child: Icon(Icons.store, color: Colors.white, size: 24)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Obx(() => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.todayRevenue, style: const TextStyle(color: Colors.white60, fontSize: 13)),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${logic.state.todayRevenue.value.toStringAsFixed(0)}',
                        style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w800, letterSpacing: -1),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        margin: const EdgeInsets.only(bottom: 6),
                        decoration: BoxDecoration(
                          color: _green.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.trending_up_rounded, color: _green, size: 14),
                            SizedBox(width: 4),
                            Text('+12%', style: TextStyle(color: _green, fontSize: 12, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKPICards() {
    return Transform.translate(
      offset: const Offset(0, -20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 24, offset: const Offset(0, 4))],
          ),
          child: Obx(() => Column(
            children: [
              Row(
                children: [
                  _kpiItem(l.todayOrders,     '${logic.state.todayOrders.value}',  Icons.receipt_long_rounded, _blue,   '+12%'),
                  _vDivider(),
                  _kpiItem(l.monthlyRevenue,  '\$${(logic.state.monthRevenue.value / 1000).toStringAsFixed(1)}K', Icons.bar_chart_rounded, _green, '+8%'),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: Color(0xFFF0F0F0)),
              const SizedBox(height: 16),
              Row(
                children: [
                  _kpiItem(l.onlineTechsLabel, '${logic.state.onlineTechs.value}/${logic.state.totalTechs.value}', Icons.people_rounded, _indigo, ''),
                  _vDivider(),
                  _kpiItem(l.avgRatingLabel,   '${logic.state.avgRating.value}★', Icons.star_rounded, _amber, ''),
                ],
              ),
            ],
          )),
        ),
      ),
    );
  }

  Widget _kpiItem(String label, String value, IconData icon, Color color, String trend) {
    return Expanded(
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
                    if (trend.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Text(trend, style: const TextStyle(fontSize: 11, color: _green, fontWeight: FontWeight.w600)),
                    ],
                  ],
                ),
                Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.gray500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _vDivider() => Container(width: 1, height: 44, color: const Color(0xFFF0F0F0), margin: const EdgeInsets.symmetric(horizontal: 16));

  Widget _buildRevenueChart() {
    return _Card(
      title: l.weeklyRevenue,
      trailing: Text(l.unitDollar, style: const TextStyle(fontSize: 11, color: AppTheme.gray400)),
      child: Obx(() {
        final revenue = logic.state.weekRevenue;
        if (revenue.isEmpty) return const SizedBox(height: 120);
        final days    = l.daysShort;
        final peak    = revenue.reduce((a, b) => a > b ? a : b);
        final maxVal  = peak == 0 ? 1.0 : peak;
        const double barMax    = 70.0;
        const double colHeight = 110.0;
        const int today = 4;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(7, (i) {
            final ratio   = revenue[i] / maxVal;
            final isToday = i == today;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: SizedBox(
                  height: colHeight,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      if (isToday)
                        Text('\$${revenue[i].toInt()}',
                            style: const TextStyle(fontSize: 9, color: _indigo, fontWeight: FontWeight.w700))
                      else
                        const SizedBox(height: 12),
                      const SizedBox(height: 3),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        height: ratio * barMax,
                        decoration: BoxDecoration(
                          gradient: isToday
                              ? const LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [_indigo, _violet],
                                )
                              : null,
                          color: isToday ? null : _indigoLight,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        days[i],
                        style: TextStyle(
                          fontSize: 10,
                          color: isToday ? _indigo : AppTheme.gray400,
                          fontWeight: isToday ? FontWeight.w700 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        );
      }),
    );
  }

  Widget _buildTopTechs() {
    return _Card(
      title: l.dailyRanking,
      trailing: GestureDetector(
        onTap: () => logic.state.currentTab.value = 1,
        child: Text(l.viewAll, style: const TextStyle(fontSize: 12, color: _indigo, fontWeight: FontWeight.w600)),
      ),
      child: Obx(() {
        final sorted = [...logic.state.techs]
          ..sort((a, b) => b.todayIncome.compareTo(a.todayIncome));
        return Column(
          children: sorted.take(3).toList().asMap().entries.map((e) {
            final rank = e.key + 1;
            final t    = e.value;
            final rankColors = [_amber, AppTheme.gray500, const Color(0xFFCD7F32)];
            final rankColor  = rank <= 3 ? rankColors[rank - 1] : AppTheme.gray400;
            final statusColor = t.status == 2 ? _orange : t.status == 1 ? _green : AppTheme.gray300;
            final statusText  = t.status == 2 ? l.inService : t.status == 1 ? l.online : l.offline;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(color: rankColor.withOpacity(0.1), shape: BoxShape.circle),
                    child: Center(child: Text('$rank', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: rankColor))),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: [_indigo.withOpacity(0.7), _violet]),
                    ),
                    child: const Center(child: Icon(Icons.person, color: Colors.white, size: 20)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                        Row(
                          children: [
                            Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: statusColor)),
                            const SizedBox(width: 4),
                            Text(statusText, style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w600)),
                            const SizedBox(width: 8),
                            Text(l.nOrdersCount(t.todayOrders), style: const TextStyle(fontSize: 11, color: AppTheme.gray400)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Text('\$${t.todayIncome.toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: _green)),
                ],
              ),
            );
          }).toList(),
        );
      }),
    );
  }

  Widget _buildQuickOps() {
    final ops = [
      {'label': l.financialReport, 'icon': Icons.bar_chart_rounded,      'color': _blue},
      {'label': l.couponsLabel,    'icon': Icons.local_offer_rounded,    'color': _red},
      {'label': l.messages,        'icon': Icons.chat_bubble_rounded,    'color': _indigo},
      {'label': l.settings,        'icon': Icons.settings_rounded,       'color': AppTheme.gray500},
    ];
    return _Card(
      title: l.quickEntry,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: ops.map((op) => GestureDetector(
          onTap: () {},
          child: Column(
            children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: (op['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(op['icon'] as IconData, color: op['color'] as Color, size: 26),
              ),
              const SizedBox(height: 8),
              Text(op['label'] as String, style: const TextStyle(fontSize: 11, color: AppTheme.gray600, fontWeight: FontWeight.w600)),
            ],
          ),
        )).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 2 · 技师管理
// ─────────────────────────────────────────────────────────────────────────────
class _TechsTab extends StatelessWidget {
  final MerchantHomeLogic logic;
  final AppLocalizations l;
  const _TechsTab({required this.logic, required this.l});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        Expanded(child: _buildList()),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [_indigoDark, _indigo]),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Row(
            children: [
              Expanded(
                child: Text(l.techMgmt, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
              ),
              Container(
                decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(20)),
                child: IconButton(
                  icon: const Icon(Icons.person_add_rounded, color: Colors.white, size: 20),
                  onPressed: () => _showAddTechDialog(l),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList() {
    return Obx(() => ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: logic.state.techs.length,
      itemBuilder: (_, i) => _TechCard(tech: logic.state.techs[i], logic: logic),
    ));
  }

  void _showAddTechDialog(AppLocalizations l) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l.addTechDialog, style: const TextStyle(fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(decoration: InputDecoration(labelText: l.techNameField, prefixIcon: const Icon(Icons.person_outline))),
            const SizedBox(height: 12),
            TextField(decoration: InputDecoration(labelText: l.phone, prefixIcon: const Icon(Icons.phone_outlined))),
            const SizedBox(height: 12),
            TextField(decoration: InputDecoration(labelText: l.skillTags, prefixIcon: const Icon(Icons.spa_outlined))),
          ],
        ),
        actions: [
          TextButton(onPressed: Get.back, child: Text(l.cancel)),
          ElevatedButton(
            onPressed: () {
              Get.back();
              Get.snackbar(l.success, l.inviteSent, snackPosition: SnackPosition.TOP);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _indigo,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              minimumSize: const Size(80, 40),
            ),
            child: Text(l.sendInvite),
          ),
        ],
      ),
    );
  }
}

class _TechCard extends StatelessWidget {
  final MerchantTech tech;
  final MerchantHomeLogic logic;
  const _TechCard({required this.tech, required this.logic});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations(AuthController.to.locale);
    final isOnline    = tech.status > 0;
    final statusColor = tech.status == 2 ? _orange : tech.status == 1 ? _green : AppTheme.gray300;
    final statusText  = tech.status == 2 ? l.inService : tech.status == 1 ? l.online : l.offline;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 52, height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: isOnline ? [_indigo, _violet] : [AppTheme.gray300, AppTheme.gray400],
                        ),
                      ),
                      child: const Center(child: Icon(Icons.person, color: Colors.white, size: 30)),
                    ),
                    Positioned(
                      right: 0, bottom: 0,
                      child: Container(
                        width: 14, height: 14,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: statusColor,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(tech.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                            child: Text(statusText, style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(tech.skill, style: const TextStyle(fontSize: 12, color: AppTheme.gray500)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('\$${tech.todayIncome.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: _green)),
                    Text(l.nOrdersCount(tech.todayOrders), style: const TextStyle(fontSize: 11, color: AppTheme.gray400)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(color: const Color(0xFFF8F9FB), borderRadius: BorderRadius.circular(10)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _mini(Icons.star_rounded,         _amber, '${tech.rating}★',                  l.rating),
                  _mini(Icons.receipt_long_rounded, _blue,  '${tech.todayOrders}',              l.todayOrders),
                  _mini(Icons.attach_money_rounded, _green, '\$${tech.todayIncome.toInt()}',    l.todayIncome),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.chat_outlined, size: 14),
                    label: Text(l.contact),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _indigo,
                      side: const BorderSide(color: _indigoLight),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      minimumSize: const Size(0, 38),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.bar_chart_rounded, size: 14),
                    label: Text(l.performance),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _green,
                      side: const BorderSide(color: _greenLight),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      minimumSize: const Size(0, 38),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: tech.status != 2
                      ? ElevatedButton(
                          onPressed: () => logic.toggleTechStatus(tech.id),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isOnline ? _red : _green,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 38),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text(isOnline ? l.goOffline : l.goOnline, style: const TextStyle(fontWeight: FontWeight.w700)),
                        )
                      : OutlinedButton(
                          onPressed: null,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _orange,
                            side: const BorderSide(color: _orange),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            minimumSize: const Size(0, 38),
                          ),
                          child: Text(l.inService),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _mini(IconData icon, Color color, String value, String label) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 3),
            Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.gray400)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 3 · 订单管理
// ─────────────────────────────────────────────────────────────────────────────
class _OrdersTab extends StatelessWidget {
  final MerchantHomeLogic logic;
  final AppLocalizations l;
  const _OrdersTab({required this.logic, required this.l});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        _buildTabBar(),
        Expanded(child: _buildList()),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [_indigoDark, _indigo]),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Row(
            children: [
              Expanded(
                child: Text(l.orderMgmt, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
              ),
              Obx(() => logic.state.pendingCount.value > 0
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: _red, borderRadius: BorderRadius.circular(12)),
                      child: Text(
                        '${logic.state.pendingCount.value} ${l.pendingConfirm}',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    )
                  : const SizedBox.shrink()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: _indigoDark,
      child: Obx(() => Row(
        children: [
          _oTab(0, l.pendingConfirm),
          _oTab(1, l.inProgress),
          _oTab(2, l.completed),
        ],
      )),
    );
  }

  Widget _oTab(int idx, String label) {
    final selected = logic.state.orderTab.value == idx;
    return Expanded(
      child: GestureDetector(
        onTap: () => logic.state.orderTab.value = idx,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: selected ? Colors.white : Colors.transparent, width: 2.5),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : Colors.white38,
              fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildList() {
    return Obx(() {
      final orders = logic.filteredOrders;
      if (orders.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.inbox_rounded, size: 64, color: AppTheme.gray300),
              const SizedBox(height: 12),
              Text(l.noOrders, style: const TextStyle(color: AppTheme.gray400, fontSize: 15)),
            ],
          ),
        );
      }
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (_, i) => _MerchantOrderCard(order: orders[i], logic: logic),
      );
    });
  }
}

class _MerchantOrderCard extends StatelessWidget {
  final MerchantOrder order;
  final MerchantHomeLogic logic;
  const _MerchantOrderCard({required this.order, required this.logic});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations(AuthController.to.locale);
    final (statusColor, statusBg, statusText) = order.status == 0
        ? (_red,            _redLight,              l.pendingConfirm)
        : order.status == 1
            ? (_amber,      _amberLight,             l.completed)
            : order.status == 2
                ? (_green,  _greenLight,             l.inService)
                : (AppTheme.gray500, const Color(0xFFF0F0F0), l.completed);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 3))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            decoration: BoxDecoration(
              color: statusBg.withOpacity(0.6),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(6)),
                  child: Text(statusText, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 8),
                Text(order.id, style: const TextStyle(fontSize: 11, color: AppTheme.gray400)),
                const Spacer(),
                Text(order.time, style: const TextStyle(fontSize: 12, color: AppTheme.gray500)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(color: _indigoLight, borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.spa_rounded, color: _indigo, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(order.localizedServiceName(AuthController.to.appLocale.value), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                          Row(
                            children: [
                              const Icon(Icons.person_outline, size: 12, color: AppTheme.gray400),
                              const SizedBox(width: 3),
                              Text('${l.clientLabel}: ${order.clientName}', style: const TextStyle(fontSize: 11, color: AppTheme.gray500)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Text('\$${order.amount.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _green)),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: const Color(0xFFF8F9FB), borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    children: [
                      const Icon(Icons.engineering_rounded, size: 14, color: _indigo),
                      const SizedBox(width: 6),
                      Text('${l.assignedTech}: ${order.techName}',
                          style: const TextStyle(fontSize: 12, color: AppTheme.gray600, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                if (order.status == 0) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _red,
                            side: const BorderSide(color: _red),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            minimumSize: const Size(0, 40),
                          ),
                          child: Text(l.rejectOrder, style: const TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () => logic.confirmOrder(order.id),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _indigo,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 40),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text(l.confirmOrder, style: const TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 4 · 我的
// ─────────────────────────────────────────────────────────────────────────────
class _ProfileTab extends StatelessWidget {
  final MerchantHomeLogic logic;
  final AppLocalizations l;
  const _ProfileTab({required this.logic, required this.l});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildHeader()),
        SliverToBoxAdapter(child: _buildWalletCard()),
        SliverToBoxAdapter(child: _buildServiceManage()),
        SliverToBoxAdapter(child: _buildMenus()),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_indigoDark, _indigo, _violet],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
          child: Obx(() => Row(
            children: [
              Container(
                width: 70, height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white24,
                  border: Border.all(color: Colors.white38, width: 2),
                ),
                child: const Center(child: Icon(Icons.store, color: Colors.white, size: 38)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      logic.state.shopName.value.isEmpty ? l.myShop : logic.state.shopName.value,
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.star_rounded, color: _amber, size: 14),
                        const SizedBox(width: 4),
                        Obx(() => Text(
                          '${logic.state.avgRating.value} ${l.rating}  ·  ${logic.state.totalTechs.value} ${l.techMgmt}',
                          style: const TextStyle(color: Colors.white60, fontSize: 12),
                        )),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.white60),
                onPressed: () {},
              ),
            ],
          )),
        ),
      ),
    );
  }

  Widget _buildWalletCard() {
    return Transform.translate(
      offset: const Offset(0, -16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 24, offset: const Offset(0, 4))],
          ),
          child: Obx(() => Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.account_balance_wallet_rounded, color: _indigo, size: 22),
                  const SizedBox(width: 8),
                  Text(l.merchantWallet, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  const Spacer(),
                  Text('\$${logic.state.walletBalance.value.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _indigo)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _StatChip(
                      label: l.monthlyRevenue,
                      value: '\$${(logic.state.monthRevenue.value / 1000).toStringAsFixed(1)}K',
                      color: _green,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatChip(
                      label: l.todayRevenueShort,
                      value: '\$${logic.state.todayRevenue.value.toStringAsFixed(0)}',
                      color: _blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.bar_chart_rounded, size: 16),
                      label: Text(l.financialReport),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _indigo,
                        side: const BorderSide(color: _indigoLight),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        minimumSize: const Size(0, 44),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.account_balance_rounded, size: 16),
                      label: Text(l.applyWithdraw),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _indigo,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 44),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          )),
        ),
      ),
    );
  }

  Widget _buildServiceManage() {
    return _Card(
      title: l.serviceManagement,
      trailing: GestureDetector(
        onTap: () => _showAddServiceDialog(l),
        child: Row(
          children: [
            const Icon(Icons.add_circle_rounded, color: _indigo, size: 18),
            const SizedBox(width: 4),
            Text(l.addItem, style: const TextStyle(fontSize: 12, color: _indigo, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      child: Obx(() => Column(
        children: logic.state.services.map((s) => _ServiceRow(service: s, logic: logic)).toList(),
      )),
    );
  }

  Widget _buildMenus() {
    final groups = [
      {
        'title': l.marketingTools,
        'items': [
          {'icon': Icons.local_offer_rounded,  'color': _red,    'label': l.couponManagement, 'onTap': () {}},
          {'icon': Icons.campaign_rounded,     'color': _orange, 'label': l.promotions,       'onTap': () {}},
          {'icon': Icons.star_rate_rounded,    'color': _amber,  'label': l.reviewManagement, 'onTap': () {}},
        ],
      },
      {
        'title': l.shopSettings,
        'items': [
          {'icon': Icons.store_mall_directory_rounded, 'color': _indigo, 'label': l.shopInfo,            'onTap': () {}},
          {'icon': Icons.location_on_rounded,          'color': _blue,   'label': l.addressMgmt,         'onTap': () {}},
          {'icon': Icons.access_time_rounded,          'color': _green,  'label': l.businessHoursLabel,  'onTap': () {}},
          {'icon': Icons.notifications_outlined,       'color': _violet, 'label': l.notifications,       'onTap': () {}},
        ],
      },
      {
        'title': l.accountGroup,
        'items': [
          {'icon': Icons.help_outline_rounded, 'color': _green,  'label': l.helpCenter,     'onTap': () {}},
          {'icon': Icons.security_rounded,     'color': _amber,  'label': l.accountSecurity,'onTap': () {}},
          {'icon': Icons.logout_rounded,       'color': _red,    'label': l.logout,         'onTap': () => AuthController.to.logout()},
        ],
      },
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: groups.map((g) {
          final items = g['items'] as List;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 16, 0, 8),
                child: Text(
                  g['title'] as String,
                  style: const TextStyle(fontSize: 12, color: AppTheme.gray500, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
                ),
                child: Column(
                  children: items.asMap().entries.map((e) {
                    final item   = e.value as Map;
                    final isLast = e.key == items.length - 1;
                    return Column(
                      children: [
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          leading: Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: (item['color'] as Color).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(item['icon'] as IconData, color: item['color'] as Color, size: 20),
                          ),
                          title: Text(item['label'] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          trailing: Icon(Icons.chevron_right_rounded, color: AppTheme.gray300, size: 20),
                          onTap: item['onTap'] as VoidCallback?,
                        ),
                        if (!isLast) const Divider(height: 1, indent: 68, endIndent: 16, color: Color(0xFFF5F5F5)),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  void _showAddServiceDialog(AppLocalizations l) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l.addServiceDialog, style: const TextStyle(fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(decoration: InputDecoration(labelText: l.serviceNameField, prefixIcon: const Icon(Icons.spa_outlined))),
            const SizedBox(height: 12),
            TextField(decoration: InputDecoration(labelText: l.priceUSD, prefixIcon: const Icon(Icons.attach_money)), keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            TextField(decoration: InputDecoration(labelText: l.durationMinField, prefixIcon: const Icon(Icons.access_time)), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: Get.back, child: Text(l.cancel)),
          ElevatedButton(
            onPressed: () {
              Get.back();
              Get.snackbar(l.success, l.serviceAdded, snackPosition: SnackPosition.TOP);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _indigo,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              minimumSize: const Size(80, 40),
            ),
            child: Text(l.confirmAdd),
          ),
        ],
      ),
    );
  }
}

class _ServiceRow extends StatelessWidget {
  final MerchantService service;
  final MerchantHomeLogic logic;
  const _ServiceRow({required this.service, required this.logic});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations(AuthController.to.locale);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: service.isActive ? _indigoLight : const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.spa_rounded, color: service.isActive ? _indigo : AppTheme.gray300, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(service.localizedName(AuthController.to.appLocale.value), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                Row(
                  children: [
                    Text('\$${service.price.toStringAsFixed(0)}', style: const TextStyle(color: _green, fontSize: 13, fontWeight: FontWeight.w600)),
                    const Text(' · ', style: TextStyle(color: AppTheme.gray300)),
                    Text(l.nMinutes(service.duration), style: const TextStyle(color: AppTheme.gray400, fontSize: 12)),
                    const Text(' · ', style: TextStyle(color: AppTheme.gray300)),
                    Text(l.nOrdersCount(service.orderCount), style: const TextStyle(color: AppTheme.gray400, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.85,
            child: Switch(
              value: service.isActive,
              onChanged: (_) => logic.toggleService(service.id),
              activeColor: _indigo,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 共用组件
// ─────────────────────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final Widget child;

  const _Card({required this.title, this.trailing, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1A1F2E))),
                const Spacer(),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
          Text(label, style: TextStyle(fontSize: 11, color: color.withOpacity(0.7))),
        ],
      ),
    );
  }
}
