import 'package:flutter/material.dart';
import '../../../core/widgets/app_dialog.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/app_colors.dart';
import '../../core/extensions/theme_ext.dart';import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/i18n/l10n_ext.dart';
import '../../../core/models/models.dart';
import '../../../core/utils/date_util.dart';
import '../../../core/utils/format_util.dart';
import '../../../core/widgets/common_widgets.dart';
import 'logic.dart';

class IncomePage extends StatelessWidget {
  const IncomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final logic  = Get.find<IncomeLogic>();
    final topPad = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(slivers: [
        SliverPersistentHeader(
          pinned: true,
          delegate: _IncomeHeaderDelegate(logic: logic, topPadding: topPad),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(AppSizes.pagePadding),
          sliver: SliverList(delegate: SliverChildListDelegate([
            _ChartCard(logic: logic),
            const SizedBox(height: 16),
            SectionTitle(title: context.l10n.incomeRecords),
            const SizedBox(height: 12),
            _RecordsList(logic: logic),
            const SizedBox(height: 30),
          ])),
        ),
      ]),
    );
  }
}

void _showWithdraw(BuildContext context, double balance) {
  Get.bottomSheet(
    _WithdrawSheet(balance: balance),
    backgroundColor: const Color(0xFF1A1A2E),
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
  );
}

// ── 固定头部 delegate ──────────────────────────────────────────────────────────
class _IncomeHeaderDelegate extends SliverPersistentHeaderDelegate {
  final IncomeLogic logic;
  final double topPadding;
  const _IncomeHeaderDelegate({required this.logic, required this.topPadding});

  static const double _contentH = 242.0;

  @override double get minExtent => topPadding + _contentH;
  @override double get maxExtent => topPadding + _contentH;
  @override bool shouldRebuild(_IncomeHeaderDelegate old) => old.topPadding != topPadding;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final l = context.l10n;
    return PremiumHeaderBg(
      colors: const [Color(0xFF052E16), Color(0xFF064E3B), Color(0xFF065F46)],
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, topPadding + 10, 4, 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Title row + actions
          Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.account_balance_wallet_rounded,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Text(l.incomeOverview,
                style: const TextStyle(
                    color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
            const Spacer(),
            const MainAppBarActions(),
          ]),
          const SizedBox(height: 20),
          // Stats row
          Obx(() => Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _StatItem(l.todayIncomeLabel, FormatUtil.money(logic.state.todayIncome.value)),
            Container(width: 1, height: 32, color: Colors.white24),
            _StatItem(l.weekIncomeLabel,  FormatUtil.money(logic.state.weekIncome.value)),
            Container(width: 1, height: 32, color: Colors.white24),
            _StatItem(l.monthIncomeLabel, FormatUtil.money(logic.state.monthIncome.value)),
          ])),
          const SizedBox(height: 18),
          // Balance card
          Obx(() {
            final bal = logic.state.balance.value;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(l.availableBalance, style: AppTextStyles.whiteSm),
                  const SizedBox(height: 2),
                  Text(FormatUtil.moneyFull(bal),
                      style: const TextStyle(
                          color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
                ]),
                const Spacer(),
                BounceTap(
                  child: OutlinedButton(
                    onPressed: () => _showWithdraw(context, bal),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      side: const BorderSide(color: Colors.white70),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  ),
                  child: Text(l.withdraw,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  ),
                ),
              ]),
            );
          }),
        ]),
      ),
    );
  }
}

// ── 统计项 ────────────────────────────────────────────────────────────────────
class _StatItem extends StatelessWidget {
  final String label, value;
  const _StatItem(this.label, this.value);
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: AppTextStyles.whiteMd),
    const SizedBox(height: 2),
    Text(label, style: AppTextStyles.whiteXs),
  ]);
}

// ── 折线图 ────────────────────────────────────────────────────────────────────
class _ChartCard extends StatelessWidget {
  final IncomeLogic logic;
  const _ChartCard({required this.logic});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AppCard(
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(l.incomeTrend, style: AppTextStyles.label1),
          Row(children: [
            _Tab(l.periodWeek,  0, logic),
            const SizedBox(width: 6),
            _Tab(l.periodMonth, 1, logic),
          ]),
        ]),
        const SizedBox(height: 20),
        Obx(() {
          final data = logic.trend;
          return SizedBox(
            height: 180,
            child: LineChart(LineChartData(
              gridData: FlGridData(
                  show: true, drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) =>
                      const FlLine(color: Color(0xFFE5E7EB), strokeWidth: 1)),
              titlesData: FlTitlesData(
                leftTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(sideTitles: SideTitles(
                  showTitles: true, reservedSize: 26,
                  interval: data.length <= 7 ? 1 : (data.length / 5).ceilToDouble(),
                  getTitlesWidget: (v, _) {
                    final i = v.toInt();
                    if (i < 0 || i >= data.length) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(data[i].label,
                          style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
                    );
                  },
                )),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [LineChartBarData(
                spots: data.asMap().entries
                    .map((e) => FlSpot(e.key.toDouble(), e.value.amount)).toList(),
                isCurved: true, curveSmoothness: 0.3,
                color: context.primary, barWidth: 2.5,
                belowBarData: BarAreaData(show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [
                      context.primary.withValues(alpha: 0.25),
                      context.primary.withValues(alpha: 0),
                    ],
                  )),
                dotData: const FlDotData(show: false),
              )],
            )),
          );
        }),
      ]),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label; final int idx; final IncomeLogic logic;
  const _Tab(this.label, this.idx, this.logic);
  @override
  Widget build(BuildContext context) => Obx(() {
    final active = logic.state.period.value == idx;
    return BounceTap(
      onTap: () => logic.setPeriod(idx),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: active ? context.primary : AppColors.background,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(label, style: TextStyle(
          fontSize: 12, fontWeight: FontWeight.w600,
          color: active ? Colors.white : AppColors.textSecond,
        )),
      ),
    );
  });
}

// ── 收入明细列表 ──────────────────────────────────────────────────────────────
class _RecordsList extends StatelessWidget {
  final IncomeLogic logic;
  const _RecordsList({required this.logic});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final records = logic.records.take(20).toList();
    if (records.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 20),
        child: EmptyView(message: l.noRecords, icon: Icons.receipt_long_rounded),
      );
    }
    return Column(children: records.map((r) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: _typeColor(r.type).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(_typeIcon(r.type), color: _typeColor(r.type), size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(r.orderNo,
                style: AppTextStyles.label3.copyWith(color: AppColors.textPrimary)),
            Text(DateUtil.format(r.date), style: AppTextStyles.caption),
          ])),
          Text(
            '${r.type == IncomeType.deduction ? '-' : '+'}${FormatUtil.money(r.amount)}',
            style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w700,
              color: r.type == IncomeType.deduction ? AppColors.danger : AppColors.success,
            ),
          ),
        ]),
      ),
    )).toList());
  }

  Color _typeColor(IncomeType t) => switch (t) {
    IncomeType.order     => AppColors.success,
    IncomeType.bonus     => AppColors.warning,
    IncomeType.deduction => AppColors.danger,
  };
  IconData _typeIcon(IncomeType t) => switch (t) {
    IncomeType.order     => Icons.receipt_long_rounded,
    IncomeType.bonus     => Icons.star_rounded,
    IncomeType.deduction => Icons.remove_circle_rounded,
  };
}

// ── 提现底部弹窗 ──────────────────────────────────────────────────────────────
class _WithdrawSheet extends StatefulWidget {
  final double balance;
  const _WithdrawSheet({required this.balance});
  @override
  State<_WithdrawSheet> createState() => _WithdrawSheetState();
}

class _WithdrawSheetState extends State<_WithdrawSheet> {
  final _ctrl = TextEditingController();
  int _method = 0;

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Text(l.withdraw,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('${l.availableBalance}: \$${widget.balance.toStringAsFixed(2)}',
              style: const TextStyle(color: Colors.white54, fontSize: 13)),
          const SizedBox(height: 20),
          TextField(
            controller: _ctrl, keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              prefixText: '\$ ',
              prefixStyle: const TextStyle(color: Colors.white70, fontSize: 24, fontWeight: FontWeight.w700),
              hintText: '0.00', hintStyle: const TextStyle(color: Colors.white30, fontSize: 24),
              filled: true, fillColor: Colors.white10,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),
          Text(l.withdrawMethod, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 8),
          Row(children: [
            _methodBtn(0, Icons.account_balance_rounded, l.bankCard),
            const SizedBox(width: 10),
            _methodBtn(1, Icons.currency_bitcoin_rounded, l.usdtLabel),
          ]),
          const SizedBox(height: 20),
          BounceTap(
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Get.back();
                  AppToast.success(l.withdrawSuccess);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(l.withdrawConfirm,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _methodBtn(int idx, IconData icon, String label) => Expanded(
    child: BounceTap(
      onTap: () => setState(() => _method = idx),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: _method == idx
              ? context.primary.withValues(alpha: 0.2) : Colors.white10,
          borderRadius: BorderRadius.circular(10),
          border: _method == idx
              ? Border.all(color: context.primary) : Border.all(color: Colors.white24),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: _method == idx ? context.primaryLt : Colors.white60, size: 18),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(
              color: _method == idx ? Colors.white : Colors.white60,
              fontWeight: FontWeight.w600, fontSize: 13)),
        ]),
      ),
    ),
  );
}
