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
import 'state.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final logic   = Get.find<HomeLogic>();
    final topPad  = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
          slivers: [
            SliverPersistentHeader(
              pinned: true,
              delegate: _HomeHeaderDelegate(logic: logic, topPadding: topPad),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              sliver: SliverList(delegate: SliverChildListDelegate([
                _StatsSection(logic: logic),
                const SizedBox(height: 16),
                _QuickActions(logic: logic),
                const SizedBox(height: 22),
                _TodayScheduleSection(logic: logic),
                const SizedBox(height: 20),
                _TechnicianHighlightCard(logic: logic),
                const SizedBox(height: 30),
              ])),
            ),
          ],
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
              fontSize: 13, fontWeight: FontWeight.w700,
              color: active ? color : Colors.white.withValues(alpha: 0.65),
            )),
          ]),
        ),
      ),
    );
  }
}

// ── 今日统计（两行布局） ────────────────────────────────────────────────────────
class _StatsSection extends StatelessWidget {
  final HomeLogic logic;
  const _StatsSection({required this.logic});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Obx(() {
      final loading = logic.state.statsLoading.value;
      final s       = logic.state;

      String v(dynamic raw) => loading ? '--' : raw.toString();
      String money(double raw) => loading ? '--' : FormatUtil.money(raw);

      return Column(children: [
        // ── 第一行：预约类指标（3 格）──────────────────────────────────────
        Row(children: [
          _StatCard(
            label: l.statTodayAppointments,
            value: v(s.todayAppointments.value),
            icon:  Icons.event_available_rounded,
            gradient: AppColors.gradientPrimary,
          ),
          const SizedBox(width: 10),
          _StatCard(
            label: l.statTodayCompleted,
            value: v(s.todayCompleted.value),
            icon:  Icons.task_alt_rounded,
            gradient: AppColors.gradientSuccess,
          ),
          const SizedBox(width: 10),
          _StatCard(
            label: l.statTodayCancelled,
            value: v(s.todayCancelled.value),
            icon:  Icons.cancel_outlined,
            gradient: const LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Color(0xFFF97316), Color(0xFFEA580C)],
            ),
          ),
        ]),
        const SizedBox(height: 10),
        // ── 第二行：收入与评分（2 格，更宽）────────────────────────────────
        Row(children: [
          _StatCard(
            label: l.todayIncome,
            value: money(s.todayIncome.value),
            icon:  Icons.account_balance_wallet_rounded,
            gradient: const LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Color(0xFF0EA5E9), Color(0xFF0369A1)],
            ),
            valueFontSize: 18,
          ),
          const SizedBox(width: 10),
          _StatCard(
            label: l.todayRating,
            value: loading ? '--' : logic.todayRatingStr,
            icon:  Icons.star_rounded,
            gradient: AppColors.gradientWarm,
            valueFontSize: 18,
          ),
        ]),
      ]);
    });
  }
}

class _StatCard extends StatelessWidget {
  final String          label, value;
  final IconData        icon;
  final LinearGradient  gradient;
  final double          valueFontSize;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.gradient,
    this.valueFontSize = 22,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        boxShadow: [BoxShadow(
          color: gradient.colors.first.withValues(alpha: 0.38),
          blurRadius: 14, offset: const Offset(0, 5),
        )],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: Colors.white, fontSize: valueFontSize,
              fontWeight: FontWeight.w900, height: 1.1,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 12, fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
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
                  color: color, fontSize: 13, fontWeight: FontWeight.w700)),
        ]),
      ),
    ),
  );
}

// ── 今日安排（时间轴版） ───────────────────────────────────────────────────────
class _TodayScheduleSection extends StatelessWidget {
  final HomeLogic logic;
  const _TodayScheduleSection({required this.logic});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Row(children: [
          Container(
            width: 4, height: 20,
            decoration: BoxDecoration(
              gradient: AppColors.gradientPrimary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(l.todaySchedule, style: const TextStyle(
            fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary,
          )),
          const SizedBox(width: 8),
          Obx(() {
            final n = logic.state.schedule.length;
            if (n == 0) return const SizedBox.shrink();
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                gradient: AppColors.gradientPrimary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(context.l10n.schedOrderCount(n), style: const TextStyle(
                color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
            );
          }),
        ]),
        BounceTap(
          onTap: () => Get.find<ShellController>().switchTab(ShellController.tabOrders),
          child: Row(children: [
            Text(l.allOrders, style: const TextStyle(
              color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.w600)),
            const Icon(Icons.chevron_right_rounded, color: AppColors.primary, size: 20),
          ]),
        ),
      ]),
      const SizedBox(height: 14),
      Obx(() {
        if (logic.state.scheduleLoading.value) return const _ScheduleSkeleton();
        final list = logic.state.schedule;
        if (list.isEmpty) return const _EmptyScheduleCard();
        return _ScheduleTimeline(items: list);
      }),
    ]);
  }
}

// ── 订单类型主题色 ─────────────────────────────────────────────────────────────
extension _OrderTypeTheme on HomeScheduleItem {
  /// 在线=紫蓝，门店=琥珀金
  Color get typeAccent => isWalkin ? const Color(0xFFF59E0B) : const Color(0xFF6366F1);
  List<Color> get typeGradient => isWalkin
      ? const [Color(0xFFF59E0B), Color(0xFFD97706)]
      : const [Color(0xFF6366F1), Color(0xFF4F46E5)];
}

// ── 时间轴容器 ─────────────────────────────────────────────────────────────────
class _ScheduleTimeline extends StatelessWidget {
  final List<HomeScheduleItem> items;
  const _ScheduleTimeline({required this.items});

  @override
  Widget build(BuildContext context) {
    final completed = items.where((i) => i.rawStatus == 6).length;
    final inService = items.where((i) => i.rawStatus == 5).length;
    final pending   = items.where((i) => i.rawStatus >= 1 && i.rawStatus <= 4).length;
    final totalMins = items.fold<int>(0, (s, i) => s + i.effectiveTotalDuration);

    // 统计在线 vs 门店数量，供摘要条展示
    final onlineCount = items.where((i) => !i.isWalkin).length;
    final walkinCount = items.where((i) => i.isWalkin).length;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _SummaryBar(
        completed: completed, inService: inService,
        pending: pending, total: items.length, totalMins: totalMins,
        onlineCount: onlineCount, walkinCount: walkinCount,
      ),
      const SizedBox(height: 16),
      ...items.asMap().entries.map((e) =>
        _TimelineEntry(item: e.value, isLast: e.key == items.length - 1)),
    ]);
  }
}

// ── 今日进度摘要条 ─────────────────────────────────────────────────────────────
class _SummaryBar extends StatelessWidget {
  final int completed, inService, pending, total, totalMins;
  final int onlineCount, walkinCount;
  const _SummaryBar({
    required this.completed, required this.inService,
    required this.pending,   required this.total, required this.totalMins,
    required this.onlineCount, required this.walkinCount,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? completed / total : 0.0;
    final l = context.l10n;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _SummaryChip(icon: Icons.check_circle_rounded, label: l.orderStatusCompleted, count: completed, color: AppColors.orderCompleted),
          _SummaryChip(icon: Icons.timelapse_rounded,    label: l.schedInService,        count: inService, color: AppColors.orderInService),
          _SummaryChip(icon: Icons.schedule_rounded,     label: l.schedPending,          count: pending,   color: AppColors.orderPending),
          _SummaryChip(
            icon: Icons.access_time_rounded, label: l.totalDuration, count: null,
            label2: totalMins > 0 ? '${totalMins}m' : '--', color: AppColors.primary,
          ),
        ]),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress, minHeight: 5,
            backgroundColor: AppColors.border,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.orderCompleted),
          ),
        ),
        const SizedBox(height: 8),
        // ── 订单来源分布条 ────────────────────────────────────────────────
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(l.scheduleProgress(completed, total),
            style: const TextStyle(fontSize: 12, color: AppColors.textHint, fontWeight: FontWeight.w500)),
          // 在线 vs 门店小标签
          if (onlineCount > 0 || walkinCount > 0)
            Row(mainAxisSize: MainAxisSize.min, children: [
              if (onlineCount > 0) _MiniTypeBadge(
                icon: Icons.phone_android_rounded,
                label: '$onlineCount',
                colors: const [Color(0xFF6366F1), Color(0xFF4F46E5)],
              ),
              if (onlineCount > 0 && walkinCount > 0) const SizedBox(width: 5),
              if (walkinCount > 0) _MiniTypeBadge(
                icon: Icons.storefront_rounded,
                label: '$walkinCount',
                colors: const [Color(0xFFF59E0B), Color(0xFFD97706)],
              ),
            ]),
        ]),
      ]),
    );
  }
}

/// 摘要条内的迷你类型标记（图标 + 数量）
class _MiniTypeBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final List<Color> colors;
  const _MiniTypeBadge({required this.icon, required this.label, required this.colors});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: colors),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: Colors.white, size: 11),
      const SizedBox(width: 3),
      Text(label, style: const TextStyle(
        color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
    ]),
  );
}

class _SummaryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final int? count;
  final String? label2;
  final Color color;
  const _SummaryChip({required this.icon, required this.label, required this.count, required this.color, this.label2});

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 40, height: 40,
        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 20),
      ),
      const SizedBox(height: 4),
      Text(
        count != null ? '$count' : (label2 ?? '--'),
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
      ),
      Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textHint, fontWeight: FontWeight.w500)),
    ],
  );
}

// ── 单条时间轴条目 ─────────────────────────────────────────────────────────────
class _TimelineEntry extends StatelessWidget {
  final HomeScheduleItem item;
  final bool isLast;
  const _TimelineEntry({required this.item, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _TimelineCard(item: item),
    );
  }
}

// ── 时间轴卡片 ─────────────────────────────────────────────────────────────────
class _TimelineCard extends StatelessWidget {
  final HomeScheduleItem item;
  const _TimelineCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final l           = context.l10n;
    final isDone      = item.rawStatus == 6;
    final isActive    = item.rawStatus == 5;
    final isCancelled = item.rawStatus >= 7;

    // 在线订单用状态色；门店订单用琥珀金为主色
    final sc      = item.isWalkin ? item.typeAccent : orderStatusColor(item.orderStatus);
    final initial = item.memberNickname.isNotEmpty ? item.memberNickname[0].toUpperCase() : '?';
    final endTime = item.effectiveTotalDuration > 0
        ? item.appointTime.add(Duration(minutes: item.effectiveTotalDuration))
        : null;

    // 门店订单的状态标签更贴近前台术语
    final statusLabel = item.isWalkin
        ? switch (item.rawStatus) {
            2 => l.statusReception, 5 => l.tabInService, 6 => l.tabCompleted, _ => '--',
          }
        : switch (item.rawStatus) {
            1 => l.tabPending,      2 => l.tabAccepted,
            3 => l.statusOnWay,     4 => l.stepArrived,
            5 => l.tabInService,    6 => l.tabCompleted,
            7 => l.statusCancelling, 8 => l.statusRefunding,
            9 => l.statusRefunded,  _ => '--',
          };

    // 所有订单（在线 + 门店散客）均跳转到订单详情页
    void handleTap() {
      Get.toNamed(AppRoutes.orderDetail, arguments: {'id': item.orderId});
    }

    return Opacity(
      opacity: isCancelled ? 0.55 : 1.0,
      child: BounceTap(
        onTap: handleTap,
        // Flutter 不允许 borderRadius + 非统一颜色边框同时使用，
        // 故用 ClipRRect 处理圆角，左侧色条作为 Row 独立子元素。
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(
              color:      isActive || item.isWalkin
                  ? sc.withValues(alpha: item.isWalkin ? 0.18 : 0.12)
                  : const Color(0x08000000),
              blurRadius: isActive || item.isWalkin ? 16 : 8,
              offset:     const Offset(0, 3),
            )],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 左侧色条（替代原 left Border）
                  Container(
                    width: isActive || item.isWalkin ? 4.0 : 3.0,
                    color: sc,
                  ),
                  // 主内容区（三面细边 + 背景色，无 borderRadius，由 ClipRRect 负责圆角）
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: item.isWalkin
                            ? const Color(0xFFFFFBEB)
                            : (isActive ? sc.withValues(alpha: 0.04) : AppColors.surface),
                        border: Border(
                          top:    BorderSide(color: item.isWalkin ? const Color(0xFFFDE68A) : AppColors.border, width: 0.8),
                          right:  BorderSide(color: item.isWalkin ? const Color(0xFFFDE68A) : AppColors.border, width: 0.8),
                          bottom: BorderSide(color: item.isWalkin ? const Color(0xFFFDE68A) : AppColors.border, width: 0.8),
                        ),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            // ── 顶行：时间 + 状态 badge ─────────────────────────────────────
            Row(children: [
              // 预约时间（从左侧移入卡片）
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: sc.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.schedule_rounded, size: 12, color: sc),
                  const SizedBox(width: 4),
                  Text(DateUtil.timeOnly(item.appointTime),
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: sc)),
                ]),
              ),
              const Spacer(),
              // 状态 badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: sc.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (isActive) ...[
                    Container(width: 6, height: 6, decoration: BoxDecoration(color: sc, shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                  ],
                  if (isDone) ...[
                    Icon(Icons.check_circle_rounded, color: sc, size: 12),
                    const SizedBox(width: 3),
                  ],
                  Text(statusLabel,
                    style: TextStyle(color: sc, fontSize: 12, fontWeight: FontWeight.w700)),
                ]),
              ),
            ]),
            const SizedBox(height: 10),
            // ── 第二行：头像 + 客户名 ──────────────────────────────────────────
            Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              // 头像（门店：门店图标；在线：客户首字母）
              Stack(clipBehavior: Clip.none, children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: sc.withValues(alpha: 0.15),
                  child: item.isWalkin
                      ? Icon(Icons.storefront_rounded, color: sc, size: 18)
                      : Text(initial, style: TextStyle(
                          color: sc, fontWeight: FontWeight.w800, fontSize: 16)),
                ),
                // 右下角类型小点
                Positioned(right: -1, bottom: -1,
                  child: Container(
                    width: 13, height: 13,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: item.typeGradient),
                      border: const Border.fromBorderSide(BorderSide(color: Colors.white, width: 1.5)),
                    ),
                    child: Icon(
                      item.isWalkin ? Icons.storefront_rounded : Icons.phone_android_rounded,
                      color: Colors.white, size: 7,
                    ),
                  ),
                ),
              ]),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Row(children: [
                  _OrderTypeBadge(item: item),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      item.memberNickname.isNotEmpty
                          ? item.memberNickname
                          : (item.isWalkin ? l.walkinGuest : '--'),
                      style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700,
                        color:      isCancelled ? AppColors.textSecond : AppColors.textPrimary,
                        decoration: isCancelled ? TextDecoration.lineThrough : null,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ]),
                const SizedBox(height: 2),
                if (item.isWalkin)
                  Row(children: [
                    Icon(Icons.qr_code_2_rounded, size: 12, color: sc.withValues(alpha: 0.7)),
                    const SizedBox(width: 3),
                    Text(item.orderNo, style: TextStyle(
                      fontSize: 12, color: sc.withValues(alpha: 0.8), fontWeight: FontWeight.w600,
                      fontFamily: 'monospace',
                    )),
                  ])
                else if (endTime != null)
                  Text(l.schedEndTime(DateUtil.timeOnly(endTime), '${item.effectiveTotalDuration}'),
                    style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
              ])),
            ]),
            const SizedBox(height: 9),
            // ── 服务项标签 ─────────────────────────────────────────────────
            _buildServiceChips(sc),
            // ── 底行：收入 / 金额 + 结束时间 ───────────────────────────────────
            if (!isCancelled) ...[
              const SizedBox(height: 8),
              Row(children: [
                Icon(
                  isDone ? Icons.check_circle_outline_rounded : Icons.monetization_on_outlined,
                  size: 13,
                  color: isDone ? AppColors.success : AppColors.textHint,
                ),
                const SizedBox(width: 4),
                Text(
                  item.isWalkin
                      ? FormatUtil.money(item.payAmount)
                      : (isDone
                          ? FormatUtil.money(item.techIncome)
                          : isActive
                              ? l.serviceInProgress
                              : l.estimatedIncome(FormatUtil.money(item.techIncome))),
                  style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700,
                    color: isDone ? AppColors.success : AppColors.textHint,
                  ),
                ),
                if (endTime != null) ...[
                  const Spacer(),
                  const Icon(Icons.timer_outlined, size: 12, color: AppColors.textHint),
                  const SizedBox(width: 3),
                  Text(
                    l.schedEndTime(DateUtil.timeOnly(endTime), '${item.effectiveTotalDuration}'),
                    style: const TextStyle(fontSize: 12, color: AppColors.textHint, fontWeight: FontWeight.w500),
                  ),
                ],
              ]),
            ],
          ]),
                    ),  // inner Container
                  ),    // Expanded
                ],      // Row.children
              ),        // Row
            ),          // IntrinsicHeight
          ),            // ClipRRect
        ),              // DecoratedBox
      ),                // BounceTap
    );                  // Opacity
  }

  Widget _buildServiceChips(Color sc) {
    return Builder(builder: (ctx) {
      final chips = <Widget>[];
      if (item.items.isNotEmpty) {
        for (var i = 0; i < item.items.length && i < 2; i++) {
          chips.add(_ServiceChip(name: item.items[i].localizedName(ctx), color: sc));
        }
        if (item.items.length > 2) {
          chips.add(_ServiceChip(name: '+${item.items.length - 2}', color: AppColors.textSecond));
        }
      } else if (item.serviceName.isNotEmpty) {
        chips.add(_ServiceChip(name: item.serviceName, color: sc));
      }
      return Wrap(spacing: 5, runSpacing: 4, children: chips);
    });
  }
}

/// 订单类型徽章 —— 在线预约（紫蓝渐变）/ 门店散客（琥珀金渐变）
class _OrderTypeBadge extends StatelessWidget {
  final HomeScheduleItem item;
  const _OrderTypeBadge({required this.item});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: item.typeGradient),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(
          item.isWalkin ? Icons.storefront_rounded : Icons.phone_android_rounded,
          color: Colors.white, size: 10,
        ),
        const SizedBox(width: 3),
        Text(
          item.isWalkin ? l.orderTypeWalkin : l.orderTypeOnline,
          style: const TextStyle(
            color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
      ]),
    );
  }
}

class _ServiceChip extends StatelessWidget {
  final String name;
  final Color color;
  const _ServiceChip({required this.name, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.09),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withValues(alpha: 0.2)),
    ),
    child: Text(name, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
  );
}

/// 加载中骨架屏（时间轴样式）
class _ScheduleSkeleton extends StatelessWidget {
  const _ScheduleSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _SkeletonRow(isTimeline: true),
      SizedBox(height: 12),
      _SkeletonRow(isTimeline: true),
    ]);
  }
}

class _SkeletonRow extends StatelessWidget {
  final bool isTimeline;
  const _SkeletonRow({this.isTimeline = false});

  Widget _box({required double w, required double h, required double r}) =>
      Container(width: w, height: h,
        decoration: BoxDecoration(color: const Color(0xFFEEEEEE), borderRadius: BorderRadius.circular(r)));

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (isTimeline) ...[
        SizedBox(width: 54, child: Column(children: [
          _box(w: 38, h: 13, r: 5),
          const SizedBox(height: 5),
          _box(w: 11, h: 11, r: 6),
        ])),
        const SizedBox(width: 8),
      ],
      Expanded(
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: const Border(left: BorderSide(color: Color(0xFFEEEEEE), width: 3)),
            boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 3))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              _box(w: 32, h: 32, r: 16),
              const SizedBox(width: 8),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _box(w: 100, h: 13, r: 6),
                const SizedBox(height: 5),
                _box(w: 70, h: 10, r: 5),
              ])),
              _box(w: 52, h: 22, r: 10),
            ]),
            const SizedBox(height: 9),
            _box(w: 140, h: 22, r: 8),
          ]),
        ),
      ),
    ]);
  }
}

class _EmptyScheduleCard extends StatelessWidget {
  const _EmptyScheduleCard();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(
          color: Color(0x0E000000), blurRadius: 24, offset: Offset(0, 6))],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 62, height: 62,
          decoration: BoxDecoration(
            gradient: AppColors.gradientPrimary,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.32),
              blurRadius: 18, offset: const Offset(0, 6),
            )],
          ),
          child: const Icon(Icons.calendar_today_rounded, color: Colors.white, size: 26),
        ),
        const SizedBox(height: 16),
        Text(l.noScheduleToday, style: const TextStyle(
          fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary,
        )),
        const SizedBox(height: 6),
        Text(l.keepOnlineHint, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecond)),
      ]),
    );
  }
}

// ── 技师数据概览卡 ─────────────────────────────────────────────────────────────
class _TechnicianHighlightCard extends StatelessWidget {
  final HomeLogic logic;
  const _TechnicianHighlightCard({required this.logic});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Obx(() {
      final tech = logic.technician;
      if (tech == null) return const SizedBox.shrink();

      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1744), Color(0xFF2D2880), Color(0xFF5B21B6)],
          ),
          boxShadow: const [BoxShadow(
            color: Color(0x552D2880), blurRadius: 28, offset: Offset(0, 10))],
        ),
        child: Stack(children: [
          // 装饰圆圈
          Positioned(top: -24, right: -16,
            child: Container(width: 110, height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(bottom: -18, right: 60,
            child: Container(width: 70, height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          // 内容
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // 头部
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.auto_graph_rounded, color: Colors.white, size: 13),
                    const SizedBox(width: 5),
                    Text(l.myStats, style: const TextStyle(
                      color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                  ]),
                ),
              ]),
              const SizedBox(height: 20),
              // 三列数据
              Row(children: [
                _HighlightItem(
                  value: '${tech.completedOrders}',
                  label: l.totalOrders,
                  icon: Icons.receipt_long_rounded,
                ),
                const _VerticalDivider(),
                _HighlightItem(
                  value: tech.rating > 0
                      ? tech.rating.toStringAsFixed(1)
                      : '--',
                  label: l.overallRating,
                  icon: Icons.star_rounded,
                ),
                const _VerticalDivider(),
                _HighlightItem(
                  value: FormatUtil.money(tech.balance),
                  label: l.currentBalance,
                  icon: Icons.account_balance_wallet_rounded,
                ),
              ]),
              const SizedBox(height: 18),
              // 底部进度条装饰
              Container(
                height: 3,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  gradient: LinearGradient(colors: [
                    Colors.white.withValues(alpha: 0.0),
                    Colors.white.withValues(alpha: 0.5),
                    Colors.white.withValues(alpha: 0.0),
                  ]),
                ),
              ),
            ]),
          ),
        ]),
      );
    });
  }
}

class _HighlightItem extends StatelessWidget {
  final String value, label;
  final IconData icon;
  const _HighlightItem({required this.value, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
      const SizedBox(height: 8),
      Text(value, style: const TextStyle(
        color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, height: 1.1,
      )),
      const SizedBox(height: 3),
      Text(label, style: TextStyle(
        color: Colors.white.withValues(alpha: 0.65), fontSize: 13, fontWeight: FontWeight.w500,
      )),
    ]),
  );
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();
  @override
  Widget build(BuildContext context) => Container(
    width: 1, height: 52,
    color: Colors.white.withValues(alpha: 0.15),
  );
}
