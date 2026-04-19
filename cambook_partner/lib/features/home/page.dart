import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/i18n/l10n_ext.dart';
import '../../../core/models/models.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/utils/date_util.dart';
import '../../../core/utils/format_util.dart';
import '../../../core/widgets/common_widgets.dart';
import '../shell/shell_controller.dart';
import 'logic.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final logic   = Get.find<HomeLogic>();
    final topPad  = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: Colors.white,
        backgroundColor: AppColors.primary,
        onRefresh: logic.refresh,
        child: CustomScrollView(
          slivers: [
            SliverPersistentHeader(
              pinned: true,
              delegate: _HomeHeaderDelegate(logic: logic, topPadding: topPad),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              sliver: SliverList(delegate: SliverChildListDelegate([
                _StatsRow(logic: logic),
                const SizedBox(height: 16),
                _QuickActions(logic: logic),
                const SizedBox(height: 20),
                _RecentOrders(logic: logic),
                const SizedBox(height: 30),
              ])),
            ),
          ],
        ),
      ),
    );
  }
}

String _greeting(BuildContext context, int hour) {
  final l = context.l10n;
  if (hour < 12) return l.greetingMorning;
  if (hour < 18) return l.greetingAfternoon;
  return l.greetingEvening;
}

// ── 固定头部 delegate ──────────────────────────────────────────────────────────
class _HomeHeaderDelegate extends SliverPersistentHeaderDelegate {
  final HomeLogic logic;
  final double topPadding;
  const _HomeHeaderDelegate({required this.logic, required this.topPadding});

  static const double _contentH = 158.0;

  @override
  double get minExtent => topPadding + _contentH;
  @override
  double get maxExtent => topPadding + _contentH;
  @override
  bool shouldRebuild(_HomeHeaderDelegate old) =>
      old.topPadding != topPadding;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return PremiumHeaderBg(
      colors: const [Color(0xFF1A1744), Color(0xFF2D2880), Color(0xFF4C1D95)],
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, topPadding + 10, 4, 16),
        child: Obx(() {
          final tech   = logic.technician;
          final status = logic.techStatus;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Row: avatar + greeting + action buttons
              Row(children: [
                Stack(children: [
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: statusColor(status), width: 2.5),
                    ),
                    child: CircleAvatar(
                      backgroundColor: Colors.white24,
                      child: Text(
                        (tech?.nickname ?? 'T').substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                            color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  Positioned(right: 1, bottom: 1,
                    child: Container(
                      width: 13, height: 13,
                      decoration: BoxDecoration(
                        color: statusColor(status), shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ]),
                const SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_greeting(context, DateTime.now().hour)}，${tech?.nickname ?? ''}',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 3),
                    Row(children: [
                      const Icon(Icons.badge_rounded, color: Colors.white60, size: 12),
                      const SizedBox(width: 4),
                      Text(tech?.techNo ?? '', style: AppTextStyles.whiteXs),
                    ]),
                  ],
                )),
                const MainAppBarActions(showLang: true),
              ]),
              const SizedBox(height: 14),
              // Status toggle
              _StatusToggle(logic: logic),
            ],
          );
        }),
      ),
    );
  }
}

// ── 状态切换（精品卡片版） ─────────────────────────────────────────────────────
class _StatusToggle extends StatelessWidget {
  final HomeLogic logic;
  const _StatusToggle({required this.logic});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Obx(() {
      final cur = logic.techStatus;
      return Row(children: [
        _StatusCard(cur: cur, target: TechStatus.online, label: l.statusOnline,
            icon: Icons.wifi_rounded,      color: AppColors.online,  logic: logic),
        const SizedBox(width: 8),
        _StatusCard(cur: cur, target: TechStatus.busy,   label: l.statusBusy,
            icon: Icons.timelapse_rounded, color: AppColors.busy,    logic: logic),
        const SizedBox(width: 8),
        _StatusCard(cur: cur, target: TechStatus.rest,   label: l.statusRest,
            icon: Icons.bedtime_rounded,   color: AppColors.rest,    logic: logic),
      ]);
    });
  }
}

class _StatusCard extends StatelessWidget {
  final TechStatus cur, target;
  final String label;
  final IconData icon;
  final Color color;
  final HomeLogic logic;
  const _StatusCard({
    required this.cur, required this.target, required this.label,
    required this.icon, required this.color, required this.logic,
  });

  @override
  Widget build(BuildContext context) {
    final active = cur == target;
    return Expanded(
      child: BounceTap(
        onTap: () => logic.changeStatus(target),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.white.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: active ? Colors.white : Colors.white.withValues(alpha: 0.22),
            ),
            boxShadow: active
                ? [BoxShadow(
                    color: color.withValues(alpha: 0.45),
                    blurRadius: 12, offset: const Offset(0, 3))]
                : null,
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 18,
                color: active ? color : Colors.white.withValues(alpha: 0.65)),
            const SizedBox(height: 3),
            Text(label, style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700,
              color: active ? color : Colors.white.withValues(alpha: 0.65),
            )),
          ]),
        ),
      ),
    );
  }
}

// ── 今日统计 ───────────────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final HomeLogic logic;
  const _StatsRow({required this.logic});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Obx(() => Row(children: [
      _StatCard(
        label: l.todayOrders, value: '${logic.todayCount}',
        icon: Icons.receipt_long_rounded, gradient: AppColors.gradientPrimary,
      ),
      const SizedBox(width: 10),
      _StatCard(
        label: l.todayIncome, value: FormatUtil.money(logic.todayIncome),
        icon: Icons.attach_money_rounded, gradient: AppColors.gradientSuccess,
      ),
      const SizedBox(width: 10),
      _StatCard(
        label: l.todayRating, value: logic.todayRating,
        icon: Icons.star_rounded, gradient: AppColors.gradientWarm,
      ),
    ]));
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final LinearGradient gradient;
  const _StatCard({required this.label, required this.value, required this.icon, required this.gradient});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        boxShadow: [BoxShadow(
          color: gradient.colors.first.withValues(alpha: 0.35),
          blurRadius: 14, offset: const Offset(0, 5),
        )],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 17),
        ),
        const SizedBox(height: 10),
        Text(value, style: const TextStyle(
            color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(
            color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500)),
      ]),
    ),
  );
}

// ── 快捷操作 ───────────────────────────────────────────────────────────────────
class _QuickActions extends StatelessWidget {
  final HomeLogic logic;
  const _QuickActions({required this.logic});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SectionTitle(title: l.quickActions),
      const SizedBox(height: 12),
      Row(children: [
        _Action(icon: Icons.play_circle_fill_rounded, label: l.startAccepting,
            color: AppColors.primary,    onTap: logic.startAccepting),
        const SizedBox(width: 10),
        _Action(icon: Icons.calendar_month_rounded, label: l.appointments,
            color: AppColors.info,       onTap: () => Get.toNamed(AppRoutes.schedule)),
        const SizedBox(width: 10),
        _Action(icon: Icons.schedule_rounded, label: l.viewSchedule,
            color: AppColors.secondary,  onTap: () => Get.toNamed(AppRoutes.schedule)),
      ]),
    ]);
  }
}

class _Action extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _Action({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
    child: BounceTap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(color: color.withValues(alpha: 0.18)),
        ),
        child: Column(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [color, color.withValues(alpha: 0.75)],
              ),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(
                color: color.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Icon(icon, color: Colors.white, size: 21),
          ),
          const SizedBox(height: 8),
          Text(label, textAlign: TextAlign.center,
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.w700)),
        ]),
      ),
    ),
  );
}

// ── 最近订单 ───────────────────────────────────────────────────────────────────
class _RecentOrders extends StatelessWidget {
  final HomeLogic logic;
  const _RecentOrders({required this.logic});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Obx(() {
      final recent = logic.recentOrders.take(5).toList();
      return Column(children: [
        SectionTitle(
          title: l.recentOrders,
          trailing: TextButton(
            onPressed: () =>
                Get.find<ShellController>().switchTab(ShellController.tabOrders),
            child: Text(l.viewAll,
                style: const TextStyle(color: AppColors.primary, fontSize: 13)),
          ),
        ),
        const SizedBox(height: 10),
        if (recent.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: EmptyView(message: l.noOrdersToday, icon: Icons.inbox_rounded),
          )
        else
          ...recent.map((o) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _OrderMiniCard(order: o),
          )),
      ]);
    });
  }
}

class _OrderMiniCard extends StatelessWidget {
  final OrderModel order;
  const _OrderMiniCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final sc = orderStatusColor(order.status);
    return BounceTap(
      onTap: () => Get.toNamed(AppRoutes.orderDetail, arguments: {'id': order.id}),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 2))],
          border: Border(left: BorderSide(color: sc, width: 3.5)),
        ),
        padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
        child: Row(children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: sc.withValues(alpha: 0.15),
            child: Text(order.customer.nickname.substring(0, 1).toUpperCase(),
                style: TextStyle(color: sc, fontWeight: FontWeight.w800, fontSize: 14)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(order.customer.nickname, style: AppTextStyles.label2),
            const SizedBox(height: 2),
            Text(order.services.map((s) => s.name).join(' · '),
                style: AppTextStyles.body3, overflow: TextOverflow.ellipsis),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(FormatUtil.money(order.totalAmount), style: AppTextStyles.amountSm),
            const SizedBox(height: 2),
            Text(DateUtil.timeOnly(order.appointTime), style: AppTextStyles.caption),
          ]),
        ]),
      ),
    );
  }
}
