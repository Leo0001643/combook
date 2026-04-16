import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/auth/auth_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/language_switcher_button.dart';
import '../../../l10n/app_localizations.dart';
import 'tech_home_logic.dart';
import 'tech_home_state.dart';

// ─────────────────────────────────────────────────────────────────────────────
// 颜色常量
// ─────────────────────────────────────────────────────────────────────────────
const _navyDark   = Color(0xFF1A1F2E);
const _navyMid    = Color(0xFF2D3748);
const _amber      = Color(0xFFFFBF00);
const _amberLight = Color(0xFFFFF8E1);
const _green      = Color(0xFF10B981);
const _greenLight = Color(0xFFD1FAE5);
const _red        = Color(0xFFEF4444);
const _redLight   = Color(0xFFFEE2E2);
const _blue       = Color(0xFF3B82F6);
const _blueLight  = Color(0xFFDBEAFE);
const _purple     = Color(0xFF8B5CF6);
const _bg         = Color(0xFFF4F6F8);

// ─────────────────────────────────────────────────────────────────────────────
// 技师端主页（4-Tab 底部导航）
// 核心修复：在 Obx 内读取 appLocale.value 订阅语言变化，并直接从 AuthController.locale 构建 l，
// 使得切换语言时整个 Scaffold 连同所有子 Widget 都随之重建。
// ─────────────────────────────────────────────────────────────────────────────
class TechHomePage extends StatelessWidget {
  const TechHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final logic = Get.find<TechHomeLogic>();
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
            _OrdersTab(logic: logic, l: l),
            _IncomeTab(logic: logic, l: l),
            _ProfileTab(logic: logic, l: l),
          ],
        ),
        bottomNavigationBar: _buildBottomNav(logic, tab, l),
      );
    });
  }

  Widget _buildBottomNav(TechHomeLogic logic, int tab, AppLocalizations l) {
    final items = [
      BottomNavigationBarItem(icon: const Icon(Icons.dashboard_rounded),              label: l.workspace),
      BottomNavigationBarItem(icon: const Icon(Icons.receipt_long_rounded),            label: l.myOrders),
      BottomNavigationBarItem(icon: const Icon(Icons.account_balance_wallet_rounded),  label: l.income),
      BottomNavigationBarItem(icon: const Icon(Icons.person_rounded),                  label: l.navProfile),
    ];
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 20, offset: Offset(0, -4))],
      ),
      child: SafeArea(
        top: false,
        child: BottomNavigationBar(
          currentIndex: tab,
          onTap: (i) => logic.state.currentTab.value = i,
          items: items,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: _navyDark,
          unselectedItemColor: AppTheme.gray400,
          elevation: 0,
          selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 1 · 工作台
// ─────────────────────────────────────────────────────────────────────────────
class _DashboardTab extends StatelessWidget {
  final TechHomeLogic logic;
  final AppLocalizations l;
  const _DashboardTab({required this.logic, required this.l});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildHeader()),
        SliverToBoxAdapter(child: _buildStatsCard()),
        SliverToBoxAdapter(child: _buildPendingSection()),
        SliverToBoxAdapter(child: _buildActiveSection()),
        SliverToBoxAdapter(child: _buildQuickActions()),
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
          colors: [_navyDark, _navyMid],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Obx(() => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.workspace, style: const TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 1)),
                        const SizedBox(height: 4),
                        Text(
                          logic.state.techName.value.isEmpty ? l.techDefaultName : logic.state.techName.value,
                          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
                        ),
                      ],
                    )),
                  ),
                  const LanguageSwitcherButton(showLabel: true),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.notifications_outlined, color: Colors.white70),
                      onPressed: () {},
                    ),
                  ),
                  const SizedBox(width: 10),
                  Stack(
                    children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(colors: [_amber, Color(0xFFFF8F00)]),
                          boxShadow: [BoxShadow(color: _amber.withOpacity(0.4), blurRadius: 12)],
                        ),
                        child: const Center(child: Icon(Icons.person, color: Colors.white, size: 26)),
                      ),
                      Positioned(
                        right: 0, bottom: 0,
                        child: Obx(() => Container(
                          width: 13, height: 13,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: logic.state.isOnline.value ? _green : AppTheme.gray400,
                            border: Border.all(color: _navyDark, width: 2),
                          ),
                        )),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Obx(() => GestureDetector(
                onTap: logic.toggleOnline,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    color: logic.state.isOnline.value
                        ? _green.withOpacity(0.15)
                        : Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: logic.state.isOnline.value ? _green : Colors.white24,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (logic.state.isToggling.value)
                        const SizedBox(
                          width: 12, height: 12,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      else
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 10, height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: logic.state.isOnline.value ? _green : Colors.grey,
                            boxShadow: logic.state.isOnline.value
                                ? [const BoxShadow(color: _green, blurRadius: 8)]
                                : null,
                          ),
                        ),
                      const SizedBox(width: 10),
                      Text(
                        logic.state.isOnline.value ? l.onlineWithTap : l.offlineWithTap,
                        style: TextStyle(
                          color: logic.state.isOnline.value ? _green : Colors.white60,
                          fontSize: 14, fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    return Transform.translate(
      offset: const Offset(0, -16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 4))],
          ),
          child: Obx(() => Row(
            children: [
              _statItem(l.todayOrders, '${logic.state.todayOrders.value}', Icons.receipt_long_rounded, _blue),
              _divider(),
              _statItem(l.todayIncome, '\$${logic.state.todayIncome.value.toStringAsFixed(0)}', Icons.attach_money_rounded, _green),
              _divider(),
              _statItem(l.rating, '${logic.state.rating.value}★', Icons.star_rounded, _amber),
              _divider(),
              _statItem(l.totalOrders, '${logic.state.completedTotal.value}', Icons.check_circle_rounded, _purple),
            ],
          )),
        ),
      ),
    );
  }

  Widget _statItem(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.gray500), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _divider() => Container(width: 1, height: 48, color: const Color(0xFFF0F0F0));

  Widget _buildPendingSection() {
    return Obx(() {
      if (logic.state.pendingOrders.isEmpty) return const SizedBox.shrink();
      return _Section(
        title: l.pendingOrders,
        badge: '${logic.state.pendingOrders.length}',
        badgeColor: _red,
        child: Column(
          children: logic.state.pendingOrders
              .map((o) => _PendingOrderCard(order: o, logic: logic))
              .toList(),
        ),
      );
    });
  }

  Widget _buildActiveSection() {
    return Obx(() {
      if (logic.state.activeOrders.isEmpty) {
        return _Section(
          title: l.activeOrdersTitle,
          child: _EmptyCard(icon: Icons.spa_outlined, text: l.noActiveOrders, hint: l.activeOrderHint),
        );
      }
      return _Section(
        title: l.activeOrdersTitle,
        badge: '${logic.state.activeOrders.length}',
        badgeColor: _green,
        child: Column(
          children: logic.state.activeOrders
              .map((o) => _ActiveOrderCard(order: o, logic: logic))
              .toList(),
        ),
      );
    });
  }

  Widget _buildQuickActions() {
    final actions = [
      {'label': l.mySchedule,   'icon': Icons.calendar_today_rounded,        'color': _blue},
      {'label': l.serviceRange, 'icon': Icons.radio_button_checked_rounded,  'color': _purple},
      {'label': l.skillSettings,'icon': Icons.build_rounded,                 'color': _amber},
      {'label': l.onlineMap,    'icon': Icons.map_rounded,                   'color': _green},
    ];
    return _Section(
      title: l.quickActions,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: actions.map((a) => _QuickActionItem(
          label: a['label'] as String,
          icon: a['icon'] as IconData,
          color: a['color'] as Color,
        )).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 2 · 我的订单
// ─────────────────────────────────────────────────────────────────────────────
class _OrdersTab extends StatelessWidget {
  final TechHomeLogic logic;
  final AppLocalizations l;
  const _OrdersTab({required this.logic, required this.l});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        _buildTabBar(),
        Expanded(child: _buildOrderList()),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      color: _navyDark,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Row(
            children: [
              Text(l.myOrders, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
              const Spacer(),
              Container(
                decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(20)),
                child: IconButton(
                  icon: const Icon(Icons.search_rounded, color: Colors.white70, size: 20),
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: _navyDark,
      child: Obx(() => Row(
        children: [
          _tab(0, l.pending,   logic.state.pendingOrders.length),
          _tab(1, l.inService, logic.state.activeOrders.length),
          _tab(2, l.completed, logic.state.completedOrders.length),
        ],
      )),
    );
  }

  Widget _tab(int idx, String label, int count) {
    return Obx(() {
      final selected = logic.state.orderTab.value == idx;
      return Expanded(
        child: GestureDetector(
          onTap: () => logic.state.orderTab.value = idx,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: selected ? _amber : Colors.transparent,
                  width: 3,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: selected ? _amber : Colors.white54,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
                if (count > 0) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: selected ? _amber : Colors.white24,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(fontSize: 10, color: selected ? _navyDark : Colors.white70, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildOrderList() {
    return Obx(() {
      final tab = logic.state.orderTab.value;
      final orders = tab == 0
          ? logic.state.pendingOrders
          : tab == 1
              ? logic.state.activeOrders
              : logic.state.completedOrders;

      if (orders.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inbox_rounded, size: 64, color: AppTheme.gray300),
              const SizedBox(height: 12),
              Text(l.noOrders, style: TextStyle(color: AppTheme.gray400, fontSize: 15)),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (_, i) {
          final o = orders[i];
          if (tab == 0) return _PendingOrderCard(order: o, logic: logic);
          if (tab == 1) return _ActiveOrderCard(order: o, logic: logic);
          return _CompletedOrderCard(order: o, logic: logic);
        },
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 3 · 收益
// ─────────────────────────────────────────────────────────────────────────────
class _IncomeTab extends StatelessWidget {
  final TechHomeLogic logic;
  final AppLocalizations l;
  const _IncomeTab({required this.logic, required this.l});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildHeader()),
        SliverToBoxAdapter(child: _buildWalletCard()),
        SliverToBoxAdapter(child: _buildMonthChart()),
        SliverToBoxAdapter(child: _buildRecordList()),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF059669), Color(0xFF10B981)]),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.myIncome, style: const TextStyle(color: Colors.white70, fontSize: 13, letterSpacing: 0.5)),
              const SizedBox(height: 8),
              Obx(() => Text(
                '\$${logic.state.walletBalance.value.toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800, letterSpacing: -1),
              )),
              const SizedBox(height: 4),
              Text(l.accountBalance, style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ],
          ),
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
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 4))],
          ),
          child: Obx(() => Column(
            children: [
              Row(
                children: [
                  _walletItem(l.monthIncome,   '\$${logic.state.monthIncome.value.toStringAsFixed(0)}', _green),
                  Container(width: 1, height: 40, color: AppTheme.gray200),
                  _walletItem(l.withdrawable,  '\$${logic.state.withdrawable.value.toStringAsFixed(0)}', _blue),
                ],
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => _showWithdrawDialog(l),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [_green, Color(0xFF059669)]),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: _green.withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.account_balance_rounded, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(l.applyWithdraw, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                    ],
                  ),
                ),
              ),
            ],
          )),
        ),
      ),
    );
  }

  Widget _walletItem(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.gray500)),
        ],
      ),
    );
  }

  Widget _buildMonthChart() {
    const weeks = ['W1', 'W2', 'W3', 'W4'];
    const values = [820.0, 1240.0, 960.0, 1600.0];
    final max = values.reduce((a, b) => a > b ? a : b);
    const double barMax = 70.0;
    const double colHeight = 115.0;
    return _Section(
      title: l.monthlyTrend,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(4, (i) {
          final ratio = values[i] / max;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: SizedBox(
                height: colHeight,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Text(
                      '\$${values[i].toInt()}',
                      style: const TextStyle(fontSize: 10, color: AppTheme.gray500, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: ratio,
                        minHeight: ratio * barMax,
                        backgroundColor: _greenLight,
                        color: _green,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(weeks[i], style: const TextStyle(fontSize: 11, color: AppTheme.gray400)),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildRecordList() {
    return _Section(
      title: l.incomeDetails,
      child: Obx(() => Column(
        children: logic.state.incomeRecords.map((r) => _IncomeRecordItem(record: r)).toList(),
      )),
    );
  }

  void _showWithdrawDialog(AppLocalizations l) {
    final ctrl = TextEditingController();
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l.applyWithdraw, style: const TextStyle(fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Obx(() => Text(
              '${l.availableHint}\$${logic.state.withdrawable.value.toStringAsFixed(2)}',
              style: const TextStyle(color: AppTheme.gray600, fontSize: 13),
            )),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: l.withdrawAmount,
                prefixText: '\$ ',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _green, width: 1.5),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: Get.back, child: Text(l.cancel)),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(ctrl.text) ?? 0;
              Get.back();
              logic.applyWithdraw(amount);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _green,
              minimumSize: const Size(80, 40),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(l.confirm),
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
  final TechHomeLogic logic;
  final AppLocalizations l;
  const _ProfileTab({required this.logic, required this.l});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildHeader()),
        SliverToBoxAdapter(child: _buildCertStatus()),
        SliverToBoxAdapter(child: _buildMenus()),
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
          colors: [_navyDark, _navyMid],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Obx(() => Row(
            children: [
              Container(
                width: 70, height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(colors: [_amber, Color(0xFFFF8F00)]),
                  boxShadow: [BoxShadow(color: _amber.withOpacity(0.4), blurRadius: 16)],
                ),
                child: const Center(child: Icon(Icons.person, color: Colors.white, size: 40)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      logic.state.techName.value.isEmpty ? l.techDefaultName : logic.state.techName.value,
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.star_rounded, color: _amber, size: 14),
                        const SizedBox(width: 4),
                        Obx(() => Text(
                          '${logic.state.rating.value} ${l.rating}  |  ${logic.state.completedTotal.value} ${l.totalOrders}',
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

  Widget _buildCertStatus() {
    return Transform.translate(
      offset: const Offset(0, -16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Obx(() {
          final status = logic.state.certStatus.value;
          final (bg, fg, icon, text, sub) = status == 2
              ? (_greenLight, _green, Icons.verified_rounded,     l.certifiedTech, l.certPassed)
              : status == 1
                  ? (_amberLight, _amber, Icons.access_time_rounded, l.underReview,   l.reviewWaiting)
                  : (_blueLight,  _blue,  Icons.assignment_outlined, l.completeCert,  l.certHint);
          return GestureDetector(
            onTap: status == 0 ? () {} : null,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: fg.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(color: fg.withOpacity(0.15), shape: BoxShape.circle),
                    child: Icon(icon, color: fg, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(text, style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 14)),
                        Text(sub,  style: TextStyle(color: fg.withOpacity(0.7), fontSize: 12)),
                      ],
                    ),
                  ),
                  if (status == 0) Icon(Icons.chevron_right_rounded, color: fg),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildMenus() {
    final groups = [
      {
        'title': l.myServices,
        'items': [
          {'icon': Icons.spa_rounded,                  'color': _purple,  'label': l.serviceItems,    'sub': '', 'onTap': () {}},
          {'icon': Icons.calendar_month_rounded,       'color': _blue,    'label': l.mySchedule,      'sub': '', 'onTap': () {}},
          {'icon': Icons.radio_button_checked_rounded, 'color': _green,   'label': l.serviceRange,    'sub': '', 'onTap': () {}},
        ],
      },
      {
        'title': l.personalInfo,
        'items': [
          {'icon': Icons.person_outline_rounded, 'color': _amber,    'label': l.personalProfile, 'sub': '', 'onTap': () {}},
          {'icon': Icons.star_border_rounded,    'color': _red,      'label': l.myReviews,       'sub': '', 'onTap': () {}},
          {'icon': Icons.badge_rounded,          'color': _navyDark, 'label': l.certMaterials,   'sub': '', 'onTap': () {}},
        ],
      },
      {
        'title': l.settings,
        'items': [
          {'icon': Icons.notifications_outlined, 'color': _blue,   'label': l.notifications,    'sub': '', 'onTap': () {}},
          {'icon': Icons.language_rounded,       'color': _purple, 'label': l.languageSettings, 'sub': '', 'onTap': () {}},
          {'icon': Icons.help_outline_rounded,   'color': _green,  'label': l.helpCenter,        'sub': '', 'onTap': () {}},
          {'icon': Icons.logout_rounded,         'color': _red,    'label': l.logout,            'sub': '', 'onTap': () => AuthController.to.logout()},
        ],
      },
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Column(
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
                    final item = e.value as Map;
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
                          subtitle: (item['sub'] as String).isNotEmpty
                              ? Text(item['sub'] as String, style: const TextStyle(fontSize: 11, color: AppTheme.gray400))
                              : null,
                          trailing: Icon(Icons.chevron_right_rounded, color: AppTheme.gray300, size: 20),
                          onTap: item['onTap'] as VoidCallback?,
                        ),
                        if (!isLast)
                          const Divider(height: 1, indent: 68, endIndent: 16, color: Color(0xFFF5F5F5)),
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
}

// ─────────────────────────────────────────────────────────────────────────────
// 公共卡片组件
// ─────────────────────────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  final String? badge;
  final Color? badgeColor;

  const _Section({required this.title, required this.child, this.badge, this.badgeColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1A1F2E))),
                if (badge != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: badgeColor ?? AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(badge!, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                ],
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _PendingOrderCard extends StatelessWidget {
  final TechOrder order;
  final TechHomeLogic logic;
  const _PendingOrderCard({required this.order, required this.logic});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations(AuthController.to.locale);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _red.withOpacity(0.2)),
        boxShadow: [BoxShadow(color: _red.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            decoration: BoxDecoration(
              color: _red.withOpacity(0.06),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: _red, borderRadius: BorderRadius.circular(6)),
                  child: Text(l.newOrder, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                ),
                const Spacer(),
                Text(order.id, style: const TextStyle(fontSize: 11, color: AppTheme.gray400)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 20,
                      backgroundColor: Color(0xFFF0F0F0),
                      child: Icon(Icons.person_outline, size: 20, color: AppTheme.gray500),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(order.clientName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                          Text(order.localizedServiceName(AuthController.to.appLocale.value), style: const TextStyle(color: AppTheme.gray500, fontSize: 12)),
                        ],
                      ),
                    ),
                    Text('\$${order.amount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _green)),
                  ],
                ),
                const SizedBox(height: 12),
                _infoRow(Icons.access_time_rounded, order.time, _blue),
                const SizedBox(height: 6),
                Obx(() {
                  final addr = logic.state.resolvedAddresses[order.id] ?? order.address;
                  return _infoRow(Icons.location_on_rounded, addr, _red);
                }),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => logic.rejectOrder(order),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _red,
                          side: const BorderSide(color: _red),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          minimumSize: const Size(0, 44),
                        ),
                        child: Text(l.rejectOrder, style: const TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () => logic.acceptOrder(order),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _green,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 44),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(l.acceptOrder, style: const TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 12, color: AppTheme.gray600))),
      ],
    );
  }
}

class _ActiveOrderCard extends StatelessWidget {
  final TechOrder order;
  final TechHomeLogic logic;
  const _ActiveOrderCard({required this.order, required this.logic});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations(AuthController.to.locale);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _green.withOpacity(0.3)),
        boxShadow: [BoxShadow(color: _green.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            decoration: BoxDecoration(
              color: _green.withOpacity(0.06),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: _green,
                      boxShadow: [const BoxShadow(color: _green, blurRadius: 4)]),
                ),
                const SizedBox(width: 8),
                Text(l.serviceInProgress, style: const TextStyle(color: _green, fontWeight: FontWeight.w700, fontSize: 13)),
                const Spacer(),
                Text(order.id, style: const TextStyle(fontSize: 11, color: AppTheme.gray400)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    const CircleAvatar(radius: 20, backgroundColor: _greenLight, child: Icon(Icons.person, color: _green, size: 20)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(order.clientName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                          Text(order.localizedServiceName(AuthController.to.appLocale.value), style: const TextStyle(color: AppTheme.gray500, fontSize: 12)),
                        ],
                      ),
                    ),
                    Text('\$${order.amount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _green)),
                  ],
                ),
                const SizedBox(height: 12),
                Obx(() {
                  final addr = logic.state.resolvedAddresses[order.id] ?? order.address;
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: _greenLight, borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on_rounded, size: 14, color: _green),
                        const SizedBox(width: 6),
                        Expanded(child: Text(addr, style: const TextStyle(fontSize: 12, color: Color(0xFF065F46)))),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.navigation_rounded, size: 16),
                        label: Text(l.navigateBtn),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _blue,
                          side: const BorderSide(color: _blue),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          minimumSize: const Size(0, 44),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () => logic.completeOrder(order),
                        icon: const Icon(Icons.check_circle_rounded, size: 16),
                        label: Text(l.completeService, style: const TextStyle(fontWeight: FontWeight.w700)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _green,
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
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletedOrderCard extends StatelessWidget {
  final TechOrder order;
  final TechHomeLogic logic;
  const _CompletedOrderCard({required this.order, required this.logic});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations(AuthController.to.locale);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: _greenLight, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.check_circle_rounded, color: _green, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order.localizedServiceName(AuthController.to.appLocale.value), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 3),
                Text('${order.clientName}  ·  ${order.time}', style: const TextStyle(fontSize: 11, color: AppTheme.gray400)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('+\$${order.amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w800, color: _green, fontSize: 16)),
              Text(l.completed, style: const TextStyle(fontSize: 11, color: AppTheme.gray400)),
            ],
          ),
        ],
      ),
    );
  }
}

class _IncomeRecordItem extends StatelessWidget {
  final IncomeRecord record;
  const _IncomeRecordItem({required this.record});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: record.isIncome ? _greenLight : _redLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              record.isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
              color: record.isIncome ? _green : _red,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(record.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                Text(record.date, style: const TextStyle(fontSize: 11, color: AppTheme.gray400)),
              ],
            ),
          ),
          Text(
            '${record.isIncome ? '+' : '-'}\$${record.amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontWeight: FontWeight.w800, fontSize: 16,
              color: record.isIncome ? _green : _red,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String text;
  final String hint;
  const _EmptyCard({required this.icon, required this.text, required this.hint});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(icon, size: 52, color: AppTheme.gray300),
          const SizedBox(height: 10),
          Text(text, style: const TextStyle(color: AppTheme.gray500, fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(hint, style: const TextStyle(color: AppTheme.gray400, fontSize: 12)),
        ],
      ),
    );
  }
}

class _QuickActionItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _QuickActionItem({required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Column(
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.gray600, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
