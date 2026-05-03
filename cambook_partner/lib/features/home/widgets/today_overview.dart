part of '../page.dart';

// ════════════════════════════════════════════════════════════════════════════
// TODAY OVERVIEW  ── 5 stat cards in single horizontal scroll row
// ════════════════════════════════════════════════════════════════════════════
abstract class _TodayOverview {
  static Widget headerRow(BuildContext context, HomeLogic logic) {
    final l = context.l10n;
    return Row(children: [
      Expanded(child: _SectionHeader(title: l.todayStats)),
      Obx(() => Text('${l.dataUpdated} ${_now()}',
          style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: AppThemeController.to.primary.withValues(alpha: .65)))),
      const SizedBox(width: 4),
      BounceTap(
        pressScale: 0.80,
        onTap: logic.refresh,
        child: Obx(() => Icon(Icons.refresh_rounded,
            size: 16,
            color: AppThemeController.to.primary.withValues(alpha: .65))),
      ),
    ]);
  }

  static String _now() {
    final t = DateTime.now();
    String pad(int n) => n.toString().padLeft(2, '0');
    return '${pad(t.hour)}:${pad(t.minute)}';
  }
}

class _TodayOverviewCards extends StatelessWidget {
  final HomeLogic logic;
  const _TodayOverviewCards({required this.logic});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Obx(() {
      final s       = logic.state;
      final ok      = !s.statsLoading.value;
      final primary = AppThemeController.to.primary;
      final income  = s.todayIncome.value;   // RxDouble — guaranteed reactive
      final stats   = <_StatItem>[
        (icon: Icons.calendar_today_rounded,         color: primary,                 value: ok ? '${s.todayAppointments.value}' : '--',                    label: l.statTodayAppointments, compact: false),
        (icon: Icons.check_circle_rounded,           color: const Color(0xFF58B5A8), value: ok ? '${s.todayCompleted.value}'    : '--',                    label: l.statTodayCompleted,    compact: false),
        (icon: Icons.remove_circle_rounded,          color: const Color(0xFF7B9FDC), value: ok ? '${s.todayCancelled.value}'    : '--',                    label: l.statTodayCancelled,    compact: false),
        (icon: Icons.account_balance_wallet_rounded, color: const Color(0xFFF5A830), value: FormatUtil.money(income),                                      label: l.todayIncome,           compact: true),
        (icon: Icons.star_rounded,                   color: const Color(0xFFBB98E0), value: ok ? (s.todayRating.value?.toStringAsFixed(1) ?? '--') : '--', label: l.todayRating,           compact: false),
      ];
      return Row(
        children: stats.expand((e) sync* {
          if (e != stats.first) yield const SizedBox(width: 8);
          yield _StatCard2(icon: e.icon, color: e.color,
              value: e.value, label: e.label, compact: e.compact);
        }).toList(),
      );
    });
  }
}

class _StatCard2 extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value, label;
  final bool compact;
  const _StatCard2({
    required this.icon, required this.color,
    required this.value, required this.label,
    this.compact = false,
  });

  static Color _darken(Color c) {
    final h = HSLColor.fromColor(c);
    return h.withLightness((h.lightness - 0.10).clamp(0.0, 1.0)).toColor();
  }

  @override
  Widget build(BuildContext context) => Expanded(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withValues(alpha: .58),
                    _darken(color).withValues(alpha: .72),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: Colors.white.withValues(alpha: .55), width: 1.0),
                boxShadow: [
                  BoxShadow(
                      color: color.withValues(alpha: .25),
                      blurRadius: 10, offset: const Offset(0, 3)),
                ],
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: .45),
                        Colors.white.withValues(alpha: .22),
                      ],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white.withValues(alpha: .65), width: 0.8),
                  ),
                  child: Icon(icon, color: Colors.white, size: 16),
                ),
                const SizedBox(height: 7),
                Text(value,
                    style: TextStyle(
                        fontSize: compact ? 13 : 17,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.1),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1),
                const SizedBox(height: 3),
                Text(label,
                    style: TextStyle(
                        fontSize: 9.5,
                        color: Colors.white.withValues(alpha: .85),
                        fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ]),
            ),
          ),
        ),
      );
}
