part of '../page.dart';

// ════════════════════════════════════════════════════════════════════════════
// QUICK ACTIONS — 4 shortcut icons
// ════════════════════════════════════════════════════════════════════════════
abstract class _QuickActionsSection {
  static Widget headerRow(BuildContext context) {
    final l = context.l10n;
    return _SectionHeader(
      title: l.quickActions,
      trailing: _PrimaryChevron(
          label: l.allFeatures,
          onTap: () => AppToast.info(l.comingSoon)),
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid();

  @override
  Widget build(BuildContext context) {
    final l     = context.l10n;
    final items = <_QItem>[
      (icon: Icons.event_note_rounded, color: const Color(0xFF2D87E8), label: l.appointments, onTap: () => Get.toNamed(AppRoutes.schedule), badge: null),
      (icon: Icons.schedule_rounded,   color: const Color(0xFF7B5CF0), label: l.viewSchedule, onTap: () => Get.toNamed(AppRoutes.schedule), badge: null),
      (icon: Icons.list_alt_rounded,   color: const Color(0xFF42B3A0), label: l.serviceItems, onTap: () => AppToast.info(l.comingSoon),     badge: null),
      (icon: Icons.apps_rounded,       color: const Color(0xFF8B5CF6), label: l.allFeatures,  onTap: () => AppToast.info(l.comingSoon),     badge: null),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: items
            .map((e) => _QAction(
                icon: e.icon, color: e.color,
                label: e.label, onTap: e.onTap, badge: e.badge))
            .toList(),
      ),
    );
  }
}

class _QAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final int? badge;
  final VoidCallback onTap;
  const _QAction({
    required this.icon, required this.color,
    required this.label, required this.onTap, this.badge,
  });

  @override
  Widget build(BuildContext context) => Expanded(
        child: BounceTap(
          pressScale: 0.82,
          onTap: onTap,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Stack(clipBehavior: Clip.none, children: [
              GlassOrb(size: 52, tintColor: color,
                  child: Icon(icon, color: color, size: 24)),
              if (badge != null && badge! > 0)
                Positioned(
                  right: -2, top: -2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Text(badge! > 99 ? '99+' : '$badge',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 10,
                            fontWeight: FontWeight.w800)),
                  ),
                ),
            ]),
            const SizedBox(height: 7),
            Text(label,
                style: TextStyle(
                    fontSize: 11.5,
                    color: color.withValues(alpha: .85),
                    fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ]),
        ),
      );
}
