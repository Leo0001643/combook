part of '../page.dart';

// ── "···" right-to-left slide drawer ─────────────────────────────────────
void _showMoreDrawer(BuildContext context) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'more',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (_, __, ___) => const _HomeMoreDrawer(),
    transitionBuilder: (_, anim, __, child) => SlideTransition(
      position: Tween(begin: const Offset(1, 0), end: Offset.zero)
          .chain(CurveTween(curve: Curves.easeOut))
          .animate(anim),
      child: child,
    ),
  );
}

// ════════════════════════════════════════════════════════════════════════════
// HOME MORE DRAWER — premium right-to-left slide panel
// ════════════════════════════════════════════════════════════════════════════
class _HomeMoreDrawer extends StatelessWidget {
  const _HomeMoreDrawer();

  @override
  Widget build(BuildContext context) {
    final mq  = MediaQuery.of(context);
    final bot = mq.padding.bottom;

    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: Colors.transparent,
        child: ClipRRect(
          borderRadius: const BorderRadius.horizontal(left: Radius.circular(28)),
          child: Container(
            width: mq.size.width * .80,
            height: double.infinity,
            color: const Color(0xFFF7F4FF),
            child: Column(children: [
              const _DrawerBanner(),

              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.zero,
                  child: Builder(builder: (context) {
                    final l = context.l10n;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),

                        // Theme colour picker
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                          child: Row(children: [
                            Obx(() => Icon(Icons.palette_outlined,
                                color: AppThemeController.to.primary, size: 18)),
                            const SizedBox(width: 10),
                            Text(l.themeColor,
                                style: const TextStyle(fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF3D3058))),
                            const Spacer(),
                            Obx(() => ThemeSwatchPicker(
                              current: AppThemeController.to.variant.spaVariant,
                              onSelect: (v) => AppThemeController.to.select(
                                switch (v) {
                                  SpaThemeVariant.pink   => AppThemeVariant.pink,
                                  SpaThemeVariant.purple => AppThemeVariant.purple,
                                  SpaThemeVariant.green  => AppThemeVariant.green,
                                },
                              ),
                            )),
                          ]),
                        ),

                        const Padding(
                          padding: EdgeInsets.fromLTRB(20, 14, 20, 0),
                          child: Divider(height: 1, color: Color(0xFFE8E2F8)),
                        ),
                        const SizedBox(height: 18),

                        _DrawerGroup(title: (l) => l.drawerWorkGroup, items: [
                          _GItem(Icons.calendar_month_rounded, const Color(0xFF8B5CF6), (l) => l.appointments,  AppRoutes.schedule, false),
                          _GItem(Icons.schedule_rounded,       const Color(0xFF7C3AED), (l) => l.viewSchedule,  AppRoutes.schedule, false),
                          _GItem(Icons.spa_rounded,            const Color(0xFF06B6D4), (l) => l.serviceItems,  null,               true),
                        ]),
                        _DrawerGroup(title: (l) => l.drawerDataGroup, items: [
                          _GItem(Icons.savings_rounded,       const Color(0xFFF59E0B), (l) => l.weeklyIncome,  null, true),
                          _GItem(Icons.insights_rounded,      const Color(0xFF10B981), (l) => l.performance,   null, true),
                          _GItem(Icons.military_tech_rounded, const Color(0xFFF4BC30), (l) => l.overallRating, null, true),
                        ]),
                        _DrawerGroup(title: (l) => l.drawerProfileGroup, items: [
                          _GItem(Icons.notifications_active_rounded, const Color(0xFFEC4899), (l) => l.notifications,  null,                false),
                          _GItem(Icons.account_circle_rounded,       const Color(0xFF6366F1), (l) => l.profileSettings, AppRoutes.settings, false),
                          _GItem(Icons.settings_rounded,             const Color(0xFF64748B), (l) => l.settingsMenu,    AppRoutes.settings, false),
                        ]),
                        _DrawerGroup(
                          title: (l) => l.drawerMoreGroup,
                          items: [_GItem(Icons.language_rounded, const Color(0xFF94A3B8), (l) => l.langTitle, AppRoutes.language, false)],
                          singleRow: true,
                        ),
                        const SizedBox(height: 16),
                      ],
                    );
                  }),
                ),
              ),

              // ── Logout button ──────────────────────────────────────
              Builder(builder: (context) {
                final l = context.l10n;
                return Padding(
                  padding: EdgeInsets.fromLTRB(20, 0, 20, bot + 22),
                  child: BounceTap(
                    pressScale: 0.95,
                    onTap: () { Get.back(); Get.find<UserService>().logout(); },
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFE5E5), Color(0xFFFFF0F0)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        border: Border.all(color: const Color(0xFFFFCDD2), width: 1),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.logout_rounded,
                              color: Color(0xFFE53E3E), size: 18),
                          const SizedBox(width: 8),
                          Text(l.logout,
                              style: const TextStyle(
                                  color: Color(0xFFE53E3E),
                                  fontSize: 15, fontWeight: FontWeight.w700,
                                  letterSpacing: .3)),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ]),
          ),
        ),
      ),
    );
  }
}

// ── Drawer banner ─────────────────────────────────────────────────────────
class _DrawerBanner extends StatelessWidget {
  const _DrawerBanner();

  @override
  Widget build(BuildContext context) => Obx(() {
    final l       = context.l10n;
    final top     = MediaQuery.of(context).padding.top;
    final theme   = AppThemeController.to.spaTheme;
    final primary = AppThemeController.to.primary;
    final dk      = AppThemeController.to.primaryDk;
    final logic   = Get.find<HomeLogic>();
    final tech    = logic.technician;
    final nick    = tech?.nickname ?? '';
    final initial = nick.isNotEmpty ? nick[0].toUpperCase() : 'T';

    return SizedBox(
      height: top + 168,
      child: Stack(fit: StackFit.expand, children: [
        OverflowBox(
          alignment: Alignment.topCenter,
          maxHeight: double.infinity,
          child: Image.asset(theme.bgAsset, width: double.infinity, fit: BoxFit.fitWidth),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight, end: Alignment.bottomLeft,
              colors: [dk.withValues(alpha: .60), primary.withValues(alpha: .90)],
            ),
          ),
        ),
        Positioned(
          top: -30, right: -30,
          child: Container(
            width: 130, height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: .07),
            ),
          ),
        ),
        Positioned(
          left: 20, right: 20, bottom: 22,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Container(
                width: 62, height: 62,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                  boxShadow: [BoxShadow(
                    color: Colors.black.withValues(alpha: .20),
                    blurRadius: 12, offset: const Offset(0, 4),
                  )],
                  color: Colors.white24,
                ),
                child: Center(
                  child: Text(initial,
                      style: const TextStyle(color: Colors.white,
                          fontSize: 24, fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(nick.isEmpty ? l.technicianWorkstation : nick,
                        style: const TextStyle(color: Colors.white,
                            fontSize: 19, fontWeight: FontWeight.w800,
                            shadows: [Shadow(color: Colors.black26, blurRadius: 6)]),
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 5),
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .18),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: .30), width: .8),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.badge_rounded, color: Colors.white70, size: 11),
                          const SizedBox(width: 4),
                          Text(tech?.techNo ?? '--',
                              style: const TextStyle(color: Colors.white,
                                  fontSize: 11.5, fontWeight: FontWeight.w700)),
                        ]),
                      ),
                      const SizedBox(width: 8),
                      Builder(builder: (_) {
                        final status = Get.find<UserService>().status.value;
                        final isOnline = status == TechStatus.online;
                        final statusColor = isOnline
                            ? const Color(0xFF22C55E)
                            : const Color(0xFFF59E0B);
                        final statusText = isOnline ? l.statusOnline : l.statusBusy;
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: .18),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: statusColor.withValues(alpha: .45), width: .8),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.circle, color: statusColor, size: 7),
                            const SizedBox(width: 4),
                            Text(statusText,
                                style: TextStyle(color: statusColor,
                                    fontSize: 11, fontWeight: FontWeight.w700)),
                          ]),
                        );
                      }),
                    ]),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 14),
            Row(children: [
              const Icon(Icons.spa_rounded, color: Colors.white54, size: 13),
              const SizedBox(width: 6),
              Text(l.drawerBrand,
                  style: TextStyle(color: Colors.white.withValues(alpha: .60),
                      fontSize: 12, letterSpacing: 1.0, fontWeight: FontWeight.w500)),
            ]),
          ]),
        ),
      ]),
    );
  });
}

// ── Drawer item types ─────────────────────────────────────────────────────
typedef _LabelFn = String Function(AppLocalizations);

class _GItem {
  final IconData icon;
  final Color color;
  final _LabelFn label;
  final String? route;
  final bool comingSoon;
  _GItem(this.icon, this.color, this.label, this.route, this.comingSoon);
}

class _DrawerGroup extends StatelessWidget {
  final _LabelFn title;
  final List<_GItem> items;
  final bool singleRow;
  const _DrawerGroup({required this.title, required this.items, this.singleRow = false});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Obx(() => Container(
            width: 6, height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppThemeController.to.primary,
            ),
          )),
          const SizedBox(width: 7),
          Text(title(l),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                  color: Color(0xFF8B7FBF), letterSpacing: .5)),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          ...items.map((e) => Expanded(child: _DrawerIconItem(item: e, l: l))),
          ...List.generate(3 - items.length, (_) => const Expanded(child: SizedBox())),
        ]),
      ]),
    );
  }
}

class _DrawerIconItem extends StatelessWidget {
  final _GItem item;
  final AppLocalizations l;
  const _DrawerIconItem({required this.item, required this.l});

  @override
  Widget build(BuildContext context) => BounceTap(
        pressScale: 0.82,
        onTap: () {
          Get.back();
          if (item.comingSoon) {
            AppToast.info(l.comingSoon);
          } else if (item.route != null) {
            Get.toNamed(item.route!);
          }
        },
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 54, height: 54,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [
                  item.color.withValues(alpha: .16),
                  item.color.withValues(alpha: .08),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(
                color: item.color.withValues(alpha: .18),
                blurRadius: 10, offset: const Offset(0, 3),
              )],
            ),
            child: Icon(item.icon, color: item.color, size: 26),
          ),
          const SizedBox(height: 8),
          Text(item.label(l),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                  color: Color(0xFF3D3058), height: 1.2),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
        ]),
      );
}
