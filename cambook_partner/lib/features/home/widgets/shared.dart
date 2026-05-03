part of '../page.dart';

// ── Shared card decoration ────────────────────────────────────────────────
const _kCardDeco = BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.all(Radius.circular(20)),
  boxShadow: [BoxShadow(color: Color(0x0C000000), blurRadius: 16, offset: Offset(0, 4))],
);

// ── Record types ──────────────────────────────────────────────────────────
typedef _QItem    = ({IconData icon, Color color, String label, VoidCallback onTap, int? badge});
typedef _StatItem = ({IconData icon, Color color, String value, String label, bool compact});
typedef _ChipItem = ({TechStatus target, IconData icon, Color color, String label, String sublabel});
typedef _PerfItem = ({IconData icon, String value, String label, String sub, bool compact, bool compactSub});

// ── "label ›" trailing widget for section headers ─────────────────────────
class _PrimaryChevron extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PrimaryChevron({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => BounceTap(
        pressScale: 0.88,
        onTap: onTap,
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: context.primary)),
          Icon(Icons.chevron_right_rounded, color: context.primary, size: 18),
        ]),
      );
}

// ── Section header — accent bar + title + optional trailing ───────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const _SectionHeader({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Obx(() {
            final c = AppThemeController.to.primary;
            return Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [c, c.withValues(alpha: .55)],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
          const SizedBox(width: 8),
          Expanded(
            child: Text(title,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2B2040)),
                overflow: TextOverflow.ellipsis,
                maxLines: 1),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing!,
          ],
        ],
      );
}
