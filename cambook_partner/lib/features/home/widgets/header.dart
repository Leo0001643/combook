part of '../page.dart';

// ════════════════════════════════════════════════════════════════════════════
// HEADER WIDGET — fixed, transparent overlay on background image
// ════════════════════════════════════════════════════════════════════════════
class _HomeHeaderWidget extends StatelessWidget {
  final HomeLogic logic;
  const _HomeHeaderWidget({required this.logic});

  @override
  Widget build(BuildContext context) {
    final l      = context.l10n;
    final topPad = MediaQuery.of(context).padding.top;
    return Padding(
      padding: EdgeInsets.fromLTRB(18, topPad + 8, 14, 16),
      child: Obx(() {
        final tech    = logic.technician;
        final status  = logic.techStatus;
        final nick    = tech?.nickname ?? '';
        final initial = nick.isNotEmpty ? nick[0].toUpperCase() : 'T';

        return Column(mainAxisSize: MainAxisSize.min, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // ── Avatar with status dot ───────────────────────────────
            Stack(clipBehavior: Clip.none, children: [
              Container(
                width: 58, height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                  boxShadow: [BoxShadow(
                    color: Colors.black.withValues(alpha: .25),
                    blurRadius: 12, offset: const Offset(0, 4),
                  )],
                ),
                child: CircleAvatar(
                  backgroundColor: Colors.white24,
                  child: Text(initial,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 22,
                          fontWeight: FontWeight.w800)),
                ),
              ),
              Positioned(
                right: 0, bottom: 0,
                child: Container(
                  width: 18, height: 18,
                  decoration: BoxDecoration(
                    color: statusColor(status),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 10),
                ),
              ),
            ]),
            const SizedBox(width: 12),

            // ── Greeting + badge + tagline ───────────────────────────
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Flexible(
                    child: Text(
                      '${_greeting(context, DateTime.now().hour)}, $nick',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 18,
                          fontWeight: FontWeight.w800,
                          shadows: [Shadow(color: Colors.black26, blurRadius: 8)]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Icon(Icons.auto_awesome_rounded,
                      color: Colors.amber.shade200, size: 14),
                ]),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: context.primary.withValues(alpha: .72),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: .35), width: .8),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.badge_rounded, color: Colors.white70, size: 11),
                    const SizedBox(width: 4),
                    Text(tech?.techNo ?? '',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ]),
                ),
                const SizedBox(height: 5),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(l.homeTagline,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: .78),
                          fontSize: 12, fontWeight: FontWeight.w400,
                          letterSpacing: .5)),
                ),
              ]),
            ),

            // ── Action icons: bell · scan · ··· ─────────────────────
            Row(mainAxisSize: MainAxisSize.min, children: [
              _HeaderIcon(icon: Icons.notifications_outlined,
                  onTap: () => AppToast.info(l.comingSoon)),
              const SizedBox(width: 6),
              _HeaderIcon(icon: Icons.crop_free_rounded,
                  onTap: () => AppToast.info(l.comingSoon)),
              const SizedBox(width: 6),
              _HeaderIcon(icon: Icons.more_horiz_rounded, size: 24,
                  onTap: () => _showMoreDrawer(context)),
            ]),
          ]),

          const SizedBox(height: 16),
          _GlassStatusBar(logic: logic),
        ]);
      }),
    );
  }
}

String _greeting(BuildContext context, int h) {
  final l = context.l10n;
  if (h < 12) return l.greetingMorning;
  if (h < 18) return l.greetingAfternoon;
  return l.greetingEvening;
}

// ── Compact icon button ───────────────────────────────────────────────────
class _HeaderIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  const _HeaderIcon({required this.icon, required this.onTap, this.size = 22});

  @override
  Widget build(BuildContext context) => BounceTap(
        pressScale: 0.78,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, color: Colors.white, size: size,
              shadows: const [Shadow(color: Colors.black38, blurRadius: 6)]),
        ),
      );
}

// ════════════════════════════════════════════════════════════════════════════
// GLASS STATUS BAR  ── 在线 / 忙碌中 / 休息
// ════════════════════════════════════════════════════════════════════════════
class _GlassStatusBar extends StatelessWidget {
  final HomeLogic logic;
  const _GlassStatusBar({required this.logic});

  static const _kDivider = SizedBox(
    width: .6, height: 38,
    child: ColoredBox(color: Color(0x47FFFFFF)),
  );

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final chips = <_ChipItem>[
      (target: TechStatus.online, icon: Icons.wifi_rounded,      color: AppColors.online, label: l.statusOnline, sublabel: l.statusOnlineDesc),
      (target: TechStatus.busy,   icon: Icons.timelapse_rounded, color: AppColors.busy,   label: l.statusBusy,   sublabel: l.statusBusyDesc),
      (target: TechStatus.rest,   icon: Icons.bedtime_rounded,   color: AppColors.rest,   label: l.statusRest,   sublabel: l.statusRestDesc),
    ];
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .18),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: .28), width: .8),
        ),
        child: Obx(() {
          final cur = logic.techStatus;
          return Row(
            children: chips.expand((e) sync* {
              if (e != chips.first) yield _kDivider;
              yield _StatusChip(cur: cur, target: e.target, icon: e.icon,
                  color: e.color, label: e.label, sublabel: e.sublabel, logic: logic);
            }).toList(),
          );
        }),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final TechStatus cur, target;
  final IconData icon;
  final Color color;
  final String label, sublabel;
  final HomeLogic logic;
  const _StatusChip({
    required this.cur, required this.target, required this.icon,
    required this.color, required this.label, required this.sublabel,
    required this.logic,
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
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? Colors.white.withValues(alpha: .95) : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(icon, size: 18, color: active ? color : Colors.white),
              const SizedBox(width: 5),
              Text(label,
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w800,
                      color: active ? color : Colors.white)),
            ]),
            const SizedBox(height: 2),
            Text(sublabel,
                style: TextStyle(
                    fontSize: 11.5, fontWeight: FontWeight.w600,
                    color: active
                        ? color.withValues(alpha: .7)
                        : Colors.white.withValues(alpha: .85))),
          ]),
        ),
      ),
    );
  }
}
