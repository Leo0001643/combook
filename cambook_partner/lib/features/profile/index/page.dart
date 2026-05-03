import 'package:flutter/material.dart';
import '../../../core/widgets/app_dialog.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/extensions/theme_ext.dart';import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/i18n/l10n_ext.dart';
import '../../../core/models/models.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/utils/toast_util.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../l10n/gen/app_localizations.dart';
import 'logic.dart';

class ProfileIndexPage extends StatelessWidget {
  const ProfileIndexPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l      = context.l10n;
    final logic  = Get.find<ProfileIndexLogic>();
    final topPad = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(slivers: [
        SliverPersistentHeader(
          pinned: true,
          delegate: _ProfileHeaderDelegate(logic: logic, topPadding: topPad),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(AppSizes.pagePadding),
          sliver: SliverList(delegate: SliverChildListDelegate([
            // ── 统计卡片 ──────────────────────────────────────────────
            _StatsCard(logic: logic),
            const SizedBox(height: 10),
            // ── 功能菜单 ──────────────────────────────────────────────
            _MenuCard(items: [
              _MenuItem(Icons.star_rounded, l.reviewsMenu,
                  const LinearGradient(colors: [Color(0xFFD97706), Color(0xFFF59E0B)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  () => Get.toNamed(AppRoutes.reviews)),
              _MenuItem(Icons.build_circle_rounded, l.skillsMenu,
                  const LinearGradient(colors: [Color(0xFF6D28D9), Color(0xFF8B5CF6)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  () => Get.toNamed(AppRoutes.skills)),
              _MenuItem(Icons.calendar_month_rounded, l.scheduleMenu,
                  const LinearGradient(colors: [Color(0xFF1D4ED8), Color(0xFF60A5FA)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  () => Get.toNamed(AppRoutes.schedule)),
            ]),
            const SizedBox(height: 10),
            _MenuCard(items: [
              _MenuItem(Icons.settings_rounded, l.settingsMenu,
                  const LinearGradient(colors: [Color(0xFF374151), Color(0xFF6B7280)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  () => Get.toNamed(AppRoutes.settings)),
              _MenuItem(Icons.help_rounded, l.helpMenu,
                  const LinearGradient(colors: [Color(0xFFEA580C), Color(0xFFFB923C)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  () => AppToast.info(l.comingSoon)),
              _MenuItem(Icons.shield_rounded, l.privacyPolicy,
                  const LinearGradient(colors: [Color(0xFF065F46), Color(0xFF34D399)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  () => AppToast.info(l.comingSoon)),
              _MenuItem(Icons.info_rounded, l.aboutMenu,
                  const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFFA78BFA)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  () => AppToast.info(l.comingSoon)),
            ]),
            const SizedBox(height: 14),
            GradientButton(
              label: l.logout,
              gradient: AppColors.gradientWarm,
              onTap: () async {
                final ok = await ToastUtil.confirm(
                    l.logout, l.logoutConfirm, okText: l.logout);
                if (ok) logic.logout();
              },
            ),
            const SizedBox(height: 30),
          ])),
        ),
      ]),
    );
  }
}

// ── 固定头部 delegate（紧凑版，仅头像 + 名字 + 工号） ─────────────────────────
class _ProfileHeaderDelegate extends SliverPersistentHeaderDelegate {
  final ProfileIndexLogic logic;
  final double topPadding;
  const _ProfileHeaderDelegate({required this.logic, required this.topPadding});

  static const double _contentH = 158.0;

  @override double get minExtent => topPadding + _contentH;
  @override double get maxExtent => topPadding + _contentH;
  @override bool shouldRebuild(_ProfileHeaderDelegate old) =>
      old.topPadding != topPadding;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return PremiumHeaderBg(
      colors: const [Color(0xFF0C1445), Color(0xFF1E3A8A), Color(0xFF1D4ED8)],
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, topPadding + 8, 4, 16),
        child: Obx(() {
          final tech = logic.technician;
          final s    = logic.status;
          final l    = Get.context!.l10n;
          return Column(mainAxisSize: MainAxisSize.min, children: [
            // Top row: actions aligned right
            const Row(children: [
              Spacer(),
              MainAppBarActions(),
            ]),
            const SizedBox(height: 6),
            // Avatar + info row
            Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              Stack(alignment: Alignment.bottomRight, children: [
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: statusColor(s), width: 2.5),
                    color: Colors.white24,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    (tech?.nickname ?? 'T').substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  width: 18, height: 18,
                  decoration: BoxDecoration(
                    color: statusColor(s), shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ]),
              const SizedBox(width: 14),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tech?.nickname ?? '',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.badge_rounded, color: Colors.white60, size: 12),
                    const SizedBox(width: 4),
                    Text(tech?.techNo ?? '', style: AppTextStyles.whiteXs),
                  ]),
                  const SizedBox(height: 6),
                  Row(children: [
                    _LevelBadge(tech?.level ?? TechLevel.normal, l),
                    const SizedBox(width: 8),
                    ...List.generate(5, (i) => Icon(
                      i < (tech?.rating ?? 5).floor()
                          ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: Colors.amber, size: 13,
                    )),
                    const SizedBox(width: 4),
                    Text('${tech?.rating ?? 0}',
                        style: const TextStyle(
                            color: Colors.amber, fontSize: 12, fontWeight: FontWeight.w700)),
                  ]),
                ],
              )),
            ]),
          ]);
        }),
      ),
    );
  }
}

// ── 统计卡片（从 header 移出，放在内容区） ────────────────────────────────────
class _StatsCard extends StatelessWidget {
  final ProfileIndexLogic logic;
  const _StatsCard({required this.logic});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Obx(() {
      final tech = logic.technician;
      return AppCard(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _StatTile('${tech?.completedOrders ?? 0}', l.completedOrders,
              Icons.receipt_long_rounded, context.primary),
          Container(width: 1, height: 40, color: AppColors.divider),
          _StatTile('\$${tech?.balance.toStringAsFixed(0) ?? '0'}',
              l.availableBalance, Icons.account_balance_wallet_rounded, AppColors.success),
          Container(width: 1, height: 40, color: AppColors.divider),
          _StatTile('${tech?.rating ?? 0}', l.avgRating,
              Icons.star_rounded, AppColors.warning),
        ]),
      );
    });
  }
}

class _StatTile extends StatelessWidget {
  final String value, label;
  final IconData icon;
  final Color color;
  const _StatTile(this.value, this.label, this.icon, this.color);

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(children: [
      Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10), shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 17),
      ),
      const SizedBox(height: 6),
      Text(value, style: TextStyle(
          fontSize: 17, fontWeight: FontWeight.w800, color: color)),
      const SizedBox(height: 2),
      Text(label, style: AppTextStyles.caption, textAlign: TextAlign.center),
    ]),
  );
}

class _LevelBadge extends StatelessWidget {
  final TechLevel level;
  final AppLocalizations l;
  const _LevelBadge(this.level, this.l);

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (level) {
      TechLevel.normal => (l.levelNormal, AppColors.textSecond),
      TechLevel.senior => (l.levelSenior, AppColors.info),
      TechLevel.gold   => (l.levelGold, Colors.amber),
      TechLevel.top    => (l.levelTop, AppColors.secondary),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(label,
          style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
    );
  }
}

// ── 菜单列表卡片 ───────────────────────────────────────────────────────────────
class _MenuItem {
  final IconData icon;
  final String label;
  final LinearGradient gradient;
  final VoidCallback onTap;
  const _MenuItem(this.icon, this.label, this.gradient, this.onTap);
}

class _MenuCard extends StatelessWidget {
  final List<_MenuItem> items;
  const _MenuCard({required this.items});

  @override
  Widget build(BuildContext context) => AppCard(
    padding: EdgeInsets.zero,
    child: Column(children: items.asMap().entries.map((e) {
      final item = e.value;
      final isLast = e.key == items.length - 1;
      return Column(mainAxisSize: MainAxisSize.min, children: [
        BounceTap(
          onTap: item.onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  gradient: item.gradient,
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: [BoxShadow(
                    color: item.gradient.colors.first.withValues(alpha: 0.30),
                    blurRadius: 6, offset: const Offset(0, 2),
                  )],
                ),
                child: Icon(item.icon, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(child: Text(item.label,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937)))),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textHint, size: 20),
            ]),
          ),
        ),
        if (!isLast)
          const Divider(indent: 66, height: 1, endIndent: 0, color: AppColors.divider),
      ]);
    }).toList()),
  );
}
