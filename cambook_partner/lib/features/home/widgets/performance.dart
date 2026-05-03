part of '../page.dart';

// ════════════════════════════════════════════════════════════════════════════
// PERFORMANCE CARD — dark purple gradient, 4 stats
// ════════════════════════════════════════════════════════════════════════════
abstract class _PerformanceCard {
  static Widget headerRow(BuildContext context, HomeLogic logic) {
    final l = context.l10n;
    return _SectionHeader(
      title: l.performance,
      trailing: _PrimaryChevron(
        label: l.thisWeek,
        onTap: () => Get.find<ShellController>().switchTab(ShellController.tabIncome),
      ),
    );
  }
}

class _PerformanceContent extends StatelessWidget {
  final HomeLogic logic;
  const _PerformanceContent({required this.logic});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Obx(() {
      final tech  = logic.technician;
      final perfs = <_PerfItem>[
        (icon: Icons.assignment_turned_in_rounded, value: tech != null ? '${tech.completedOrders}'      : '--', label: l.totalOrders,   sub: '',             compact: false, compactSub: false),
        (icon: Icons.star_rounded,                 value: tech != null ? tech.rating.toStringAsFixed(1) : '--', label: l.overallRating, sub: '',             compact: false, compactSub: false),
        (icon: Icons.savings_rounded,              value: tech != null ? FormatUtil.money(tech.balance) : '--', label: l.weeklyIncome,  sub: '',             compact: true,  compactSub: false),
        (icon: Icons.emoji_events_rounded,         value: '--',                                                  label: l.techRanking,   sub: l.storeRanking, compact: false, compactSub: true),
      ];
      return Container(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              context.primaryDk.withValues(alpha: .90),
              context.primary,
              context.primaryDk,
            ],
            stops: const [0.0, 0.55, 1.0],
          ),
          boxShadow: [
            BoxShadow(
                color: context.primaryDk.withValues(alpha: .45),
                blurRadius: 28, offset: const Offset(0, 10)),
          ],
        ),
        child: Stack(children: [
          Positioned(
            top: -20, right: -10,
            child: Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: .06),
              ),
            ),
          ),
          Positioned(
            bottom: -16, right: 50,
            child: Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: .05),
              ),
            ),
          ),
          Row(
            children: perfs.expand((e) sync* {
              if (e != perfs.first) yield _PerfDivider();
              yield _PerfStat(icon: e.icon, value: e.value, label: e.label,
                  sub: e.sub, compact: e.compact, compactSub: e.compactSub);
            }).toList(),
          ),
        ]),
      );
    });
  }
}

class _PerfStat extends StatelessWidget {
  final IconData icon;
  final String value, label, sub;
  final bool compact, compactSub;
  const _PerfStat({
    required this.icon, required this.value,
    required this.label, required this.sub,
    this.compact = false, this.compactSub = false,
  });

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: .30),
                  Colors.white.withValues(alpha: .12),
                ],
              ),
              shape: BoxShape.circle,
              border: Border.all(
                  color: Colors.white.withValues(alpha: .55), width: 1.2),
              boxShadow: [
                BoxShadow(
                    color: Colors.white.withValues(alpha: .15),
                    blurRadius: 6, offset: const Offset(0, 2)),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 17),
          ),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: compact ? 14 : 18,
                  fontWeight: FontWeight.w800, height: 1.1),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center),
          const SizedBox(height: 3),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: .65),
                  fontSize: 10.5, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center),
          const SizedBox(height: 3),
          Text(sub,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: .45),
                  fontSize: compactSub ? 9 : 10.5,
                  fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis),
        ]),
      );
}

class _PerfDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: .6, height: 56,
        color: Colors.white.withValues(alpha: .16),
      );
}
