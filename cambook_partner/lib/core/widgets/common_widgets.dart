import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_sizes.dart';
import '../i18n/l10n_ext.dart';
import '../models/models.dart';
import '../routes/app_routes.dart';
import '../services/storage_service.dart';
import '../services/user_service.dart';
import 'app_dialog.dart';

// ─── 渐变头部容器 ──────────────────────────────────────────────────────────────
class GradientHeader extends StatelessWidget {
  final Widget child;
  final double paddingBottom;
  final LinearGradient gradient;

  const GradientHeader({
    super.key,
    required this.child,
    this.paddingBottom = 24,
    this.gradient = AppColors.gradientPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(gradient: gradient),
      padding: EdgeInsets.only(
        left: AppSizes.pagePadding, right: AppSizes.pagePadding,
        top: MediaQuery.of(context).padding.top + 8,
        bottom: paddingBottom,
      ),
      child: child,
    );
  }
}

// ─── 弹跳点击效果（全局封装，按下缩小松开弹回） ────────────────────────────
class BounceTap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  /// 按下后缩放到的目标比例，越小弹跳越明显
  final double pressScale;

  const BounceTap({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.pressScale = 0.88,
  });

  @override
  State<BounceTap> createState() => _BounceTapState();
}

class _BounceTapState extends State<BounceTap>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 60),
      reverseDuration: const Duration(milliseconds: 160),
    );
    _scale = Tween<double>(begin: 1.0, end: widget.pressScale).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: Curves.easeIn,
        reverseCurve: Curves.easeOut,   // 去掉 easeOutBack 过冲，弹回更干脆
      ),
    );
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _down(TapDownDetails _) {
    HapticFeedback.lightImpact();
    _ctrl.stop();
    _ctrl.value = 1.0;
  }
  // onTapUp 只负责弹回动画，不触发业务回调
  void _up(TapUpDetails _)  => _ctrl.reverse();
  void _cancel()            => _ctrl.reverse();

  @override
  Widget build(BuildContext context) => GestureDetector(
    // opaque：整个矩形区域（含透明空隙）均响应触摸，避免"点透"漏触
    behavior: HitTestBehavior.opaque,
    onTapDown:   _down,
    onTapUp:     _up,
    onTapCancel: _cancel,
    // onTap 由手势竞技场确认后才触发，比 onTapUp 更可靠
    onTap:       widget.onTap,
    onLongPress: widget.onLongPress,
    child: AnimatedBuilder(
      animation: _scale,
      builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
      child: widget.child,
    ),
  );
}

// ─── 卡片容器 ──────────────────────────────────────────────────────────────────
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? color;

  const AppCard({super.key, required this.child, this.padding, this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final box = Container(
      padding: padding ?? const EdgeInsets.all(AppSizes.cardPadding),
      decoration: BoxDecoration(
        color: color ?? AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        boxShadow: const [BoxShadow(color: Color(0x0C000000), blurRadius: 12, offset: Offset(0,2))],
      ),
      child: child,
    );
    return onTap != null
        ? BounceTap(onTap: onTap, child: box)
        : box;
  }
}

// ─── 空状态视图 ────────────────────────────────────────────────────────────────
class EmptyView extends StatelessWidget {
  final String? message;
  final IconData icon;
  /// 传入自定义图标 Widget（优先于 [icon]）
  final Widget? iconWidget;

  const EmptyView({super.key, this.message,
    this.icon = Icons.inbox_rounded, this.iconWidget});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        iconWidget ?? Icon(icon, size: 64, color: AppColors.textHint),
        const SizedBox(height: 12),
        Text(message ?? '暂无数据',
            style: AppTextStyles.body2.copyWith(color: AppColors.textSecond)),
      ],
    ),
  );
}

// ─── 订单状态徽章 ──────────────────────────────────────────────────────────────
class OrderStatusBadge extends StatelessWidget {
  final OrderStatus status;
  final String label;

  const OrderStatusBadge({super.key, required this.status, required this.label});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status) {
      OrderStatus.pending   => (const Color(0xFFFEF3C7), const Color(0xFF92400E)),
      OrderStatus.accepted  => (const Color(0xFFDBEAFE), const Color(0xFF1E40AF)),
      OrderStatus.inService => (const Color(0xFFEDE9FE), const Color(0xFF5B21B6)),
      OrderStatus.completed => (const Color(0xFFD1FAE5), const Color(0xFF065F46)),
      OrderStatus.cancelled => (const Color(0xFFFEE2E2), const Color(0xFF991B1B)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppSizes.radiusFull)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg)),
    );
  }
}

// ─── 服务模式标签 ──────────────────────────────────────────────────────────────
class ServiceModeTag extends StatelessWidget {
  final ServiceMode mode;
  final String label;

  const ServiceModeTag({super.key, required this.mode, required this.label});

  @override
  Widget build(BuildContext context) {
    final isHome = mode == ServiceMode.home;
    final color  = isHome ? AppColors.info : AppColors.success;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusXs),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isHome ? Icons.home_rounded : Icons.store_rounded, size: 10, color: color),
          const SizedBox(width: 3),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

// ─── 分节标题 ──────────────────────────────────────────────────────────────────
class SectionTitle extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const SectionTitle({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(title, style: AppTextStyles.label1),
      if (trailing != null) trailing!,
    ],
  );
}

// ─── 渐变按钮 ──────────────────────────────────────────────────────────────────
class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final LinearGradient gradient;
  final double height;
  final IconData? icon;

  const GradientButton({
    super.key,
    required this.label,
    required this.onTap,
    this.gradient = AppColors.gradientPrimary,
    this.height = AppSizes.btnHeightMd,
    this.icon,
  });

  @override
  Widget build(BuildContext context) => BounceTap(
    onTap: onTap,
    child: Container(
      height: height,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        boxShadow: [BoxShadow(
          color: gradient.colors.first.withValues(alpha: 0.35),
          blurRadius: 14, offset: const Offset(0, 5),
        )],
      ),
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 6),
          ],
          Text(label, style: AppTextStyles.whiteMd),
        ],
      ),
    ),
  );
}

// ─── 技师状态颜色工具 ─────────────────────────────────────────────────────────
Color statusColor(TechStatus s) => switch (s) {
  TechStatus.online => AppColors.online,
  TechStatus.busy   => AppColors.busy,
  TechStatus.rest   => AppColors.rest,
};

Color orderStatusColor(OrderStatus s) => switch (s) {
  OrderStatus.pending   => AppColors.orderPending,
  OrderStatus.accepted  => AppColors.orderAccepted,
  OrderStatus.inService => AppColors.orderInService,
  OrderStatus.completed => AppColors.orderCompleted,
  OrderStatus.cancelled => AppColors.orderCancelled,
};

// ─── 语言切换按钮（AppBar actions 使用）────────────────────────────────────────
/// 用法: AppBar(actions: [LangMenuButton(onChanged: (code) => logic.changeLocale(code))])
class LangMenuButton extends StatelessWidget {
  final void Function(String code) onChanged;
  final Color? color;

  static const _langs = [
    ('zh', '🇨🇳', '中文'),
    ('en', '🇺🇸', 'English'),
    ('vi', '🇻🇳', 'Tiếng Việt'),
    ('km', '🇰🇭', 'ភាសាខ្មែរ'),
    ('ko', '🇰🇷', '한국어'),
    ('ja', '🇯🇵', '日本語'),
  ];

  const LangMenuButton({super.key, required this.onChanged, this.color});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.language_rounded, color: color ?? Colors.white, size: 22),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 8,
      offset: const Offset(0, 48),
      onSelected: onChanged,
      itemBuilder: (_) => _langs.map((lang) {
        final active = Localizations.localeOf(context).languageCode == lang.$1;
        return PopupMenuItem<String>(
          value: lang.$1,
          child: Row(children: [
            Text(lang.$2, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Text(lang.$3, style: TextStyle(
              fontWeight: active ? FontWeight.w700 : FontWeight.w400,
              color: active ? AppColors.primary : null,
            )),
            if (active) ...[
              const Spacer(),
              const Icon(Icons.check_rounded, size: 16, color: AppColors.primary),
            ],
          ]),
        );
      }).toList(),
    );
  }
}

// ─── 全局语言切换工具函数 ──────────────────────────────────────────────────────
void changeAppLocale(String code) {
  Get.find<StorageService>().saveLocale(code);
  Get.updateLocale(Locale(code));
}

// ─── 右侧滑出更多抽屉（适用于所有页面，无需 Scaffold key）──────────────────
void showMainMoreDrawer(BuildContext context) {
  final w = MediaQuery.sizeOf(context).width * 0.82;
  showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: '',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (_, __, ___) => Align(
      alignment: Alignment.centerRight,
      child: Material(
        elevation: 16,
        child: SizedBox(
          width: w,
          height: double.infinity,
          child: const _MainMorePanel(),
        ),
      ),
    ),
    transitionBuilder: (_, anim, __, child) => SlideTransition(
      position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
          .animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
      child: child,
    ),
  );
}

class _MainMorePanel extends StatelessWidget {
  const _MainMorePanel();

  @override
  Widget build(BuildContext context) {
    final l    = context.l10n;
    final tech = Get.find<UserService>().technician.value;
    return Column(children: [
      // ── 顶部用户信息 ─────────────────────────────────────────────
      Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(
            20, MediaQuery.of(context).padding.top + 20, 12, 24),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF1E1B4B), Color(0xFF312E81), Color(0xFF6D28D9)],
          ),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: Colors.white24,
            child: Text(
              (tech?.nickname ?? 'T').substring(0, 1).toUpperCase(),
              style: const TextStyle(
                  color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 4),
            Text(tech?.nickname ?? '',
                style: const TextStyle(
                    color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.badge_rounded, color: Colors.white54, size: 12),
              const SizedBox(width: 4),
              Text(tech?.techNo ?? '',
                  style: const TextStyle(
                      color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w500)),
            ]),
          ])),
          BounceTap(
            pressScale: 0.80,
            onTap: () => Navigator.of(context).pop(),
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(Icons.close_rounded, color: Colors.white54, size: 20),
            ),
          ),
        ]),
      ),
      // ── 菜单列表 ─────────────────────────────────────────────────
      Expanded(child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 10),
        children: [
          _DrawerItem(
            icon: Icons.campaign_rounded, color: const Color(0xFF4F46E5),
            label: l.announcements,
            onTap: () { Navigator.of(context).pop(); AppToast.info(l.comingSoon); },
          ),
          _DrawerLangItem(label: l.langTitle, onDismiss: () => Navigator.of(context).pop()),
          _DrawerItem(
            icon: Icons.settings_rounded, color: const Color(0xFF0284C7),
            label: l.settingsMenu,
            onTap: () { Navigator.of(context).pop(); Get.toNamed(AppRoutes.settings); },
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            child: Divider(color: Color(0xFFF0F0F6)),
          ),
          _DrawerItem(
            icon: Icons.shield_outlined, color: const Color(0xFF059669),
            label: l.privacyPolicy,
            onTap: () { Navigator.of(context).pop(); AppToast.info(l.comingSoon); },
          ),
          _DrawerItem(
            icon: Icons.description_outlined, color: const Color(0xFF0284C7),
            label: l.terms,
            onTap: () { Navigator.of(context).pop(); AppToast.info(l.comingSoon); },
          ),
          _DrawerItem(
            icon: Icons.help_outline_rounded, color: const Color(0xFFD97706),
            label: l.helpAndSupport,
            onTap: () { Navigator.of(context).pop(); AppToast.info(l.comingSoon); },
          ),
          _DrawerItem(
            icon: Icons.star_outline_rounded, color: const Color(0xFFF59E0B),
            label: l.rateApp,
            onTap: () { Navigator.of(context).pop(); AppToast.info(l.comingSoon); },
          ),
        ],
      )),
      // ── 版本号 ───────────────────────────────────────────────────
      Padding(
        padding: EdgeInsets.fromLTRB(
            20, 8, 20, MediaQuery.of(context).padding.bottom + 16),
        child: const Row(children: [
          Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFFD1D5DB)),
          SizedBox(width: 6),
          Text('v1.0.0',
              style: TextStyle(
                  color: Color(0xFF9CA3AF), fontSize: 12, fontWeight: FontWeight.w500)),
        ]),
      ),
    ]);
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;
  const _DrawerItem({
    required this.icon, required this.color,
    required this.label, required this.onTap,
  });

  @override
  Widget build(BuildContext context) => BounceTap(
    onTap: onTap,
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      leading: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, size: 18, color: color),
      ),
      title: Text(label,
          style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1F2937))),
      trailing: const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFFD1D5DB)),
    ),
  );
}

class _DrawerLangItem extends StatelessWidget {
  final String label;
  final VoidCallback onDismiss;
  const _DrawerLangItem({required this.label, required this.onDismiss});

  static const _langs = [
    ('zh', '🇨🇳', '中文'),
    ('en', '🇺🇸', 'English'),
    ('vi', '🇻🇳', 'Tiếng Việt'),
    ('km', '🇰🇭', 'ភាសាខ្មែរ'),
    ('ko', '🇰🇷', '한국어'),
    ('ja', '🇯🇵', '日本語'),
  ];

  @override
  Widget build(BuildContext context) {
    final current = Localizations.localeOf(context).languageCode;
    return PopupMenuButton<String>(
      onSelected: (code) { onDismiss(); changeAppLocale(code); },
      itemBuilder: (_) => _langs.map((lang) {
        final active = current == lang.$1;
        return PopupMenuItem<String>(
          value: lang.$1,
          child: Row(children: [
            Text(lang.$2, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Text(lang.$3, style: TextStyle(
                fontSize: 14,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: active ? AppColors.primary : const Color(0xFF374151))),
            if (active) ...[
              const Spacer(),
              const Icon(Icons.check_rounded, size: 16, color: AppColors.primary),
            ],
          ]),
        );
      }).toList(),
      offset: const Offset(-10, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
        leading: Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.language_rounded, size: 18, color: AppColors.primary),
        ),
        title: Text(label,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1F2937))),
        trailing: const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFFD1D5DB)),
      ),
    );
  }
}

// ─── 登录后所有页面顶栏公共操作区（公告 + 语言(可选) + 更多） ───────────────
class MainAppBarActions extends StatelessWidget {
  /// 是否显示切换语言按钮（仅首页和登录/注册页需要）
  final bool showLang;
  const MainAppBarActions({super.key, this.showLang = false});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      _AppBarIcon(icon: Icons.notifications_rounded, onTap: () => AppToast.info(context.l10n.comingSoon)),
      if (showLang) const LangMenuButton(color: Colors.white, onChanged: changeAppLocale),
      _AppBarIcon(icon: Icons.more_horiz_rounded, onTap: () => showMainMoreDrawer(context)),
      const SizedBox(width: 4),
    ],
  );
}

// ─── 全局通用 AppBar（登录后所有页面使用）────────────────────────────────────
class MainAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBack;
  final List<Widget> extraActions;

  const MainAppBar({
    super.key,
    required this.title,
    this.showBack = false,
    this.extraActions = const [],
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) => AppBar(
    title: Text(title),
    leading: showBack
        ? _AppBarIcon(icon: Icons.arrow_back_ios_rounded, onTap: () => Get.back(), padding: const EdgeInsets.fromLTRB(12, 8, 8, 8))
        : null,
    automaticallyImplyLeading: showBack,
    actions: [...extraActions, const MainAppBarActions()],
  );
}

// ─── AppBar 图标按钮（统一 BounceTap 动效）────────────────────────────────────
class _AppBarIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final EdgeInsetsGeometry padding;

  const _AppBarIcon({
    required this.icon,
    required this.onTap,
    this.padding = const EdgeInsets.all(10),
  });

  @override
  Widget build(BuildContext context) => BounceTap(
    pressScale: 0.78,
    onTap: onTap,
    child: Padding(padding: padding, child: Icon(icon, color: Colors.white, size: 24)),
  );
}

// ─── 精品渐变头部背景（多层渐变 + 光晕 + 粒子）──────────────────────────────
class PremiumHeaderBg extends StatelessWidget {
  final List<Color> colors;
  final Widget child;

  const PremiumHeaderBg({super.key, required this.colors, required this.child});

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
        ),
      ),
      // 光晕 1 — 右上角
      const Positioned(top: -60, right: -40, child: _Blob(220, 0.09)),
      // 光晕 2 — 左下角
      const Positioned(bottom: -50, left: -30, child: _Blob(170, 0.07)),
      // 光晕 3 — 中右
      const Positioned(top: 30, right: 80, child: _Blob(80, 0.08)),
      // 粒子网格
      const Positioned.fill(child: CustomPaint(painter: _DotGridPainter())),
      child,
    ],
  );
}

class _Blob extends StatelessWidget {
  final double size;
  final double opacity;
  const _Blob(this.size, this.opacity);

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white.withValues(alpha: opacity),
    ),
  );
}

class _DotGridPainter extends CustomPainter {
  const _DotGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = Colors.white.withValues(alpha: 0.06);
    for (double x = 0; x <= size.width; x += 28) {
      for (double y = 0; y <= size.height; y += 28) {
        canvas.drawCircle(Offset(x, y), 1.5, p);
      }
    }
  }

  @override
  bool shouldRepaint(_DotGridPainter _) => false;
}

// ─── 微信风格双气泡图标 ────────────────────────────────────────────────────────
/// 与微信图标高度一致：左大右小两个圆角椭圆气泡，各带两个白色眼睛圆点。
/// [color]  气泡填充颜色（与其他 Icon 保持统一）
/// [size]   图标整体尺寸
class WeChatBubbleIcon extends StatelessWidget {
  final Color color;
  final double size;
  const WeChatBubbleIcon({super.key, required this.color, this.size = 24});

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size(size, size),
    painter: _WeChatBubblePainter(color: color),
  );
}

class _WeChatBubblePainter extends CustomPainter {
  final Color color;
  const _WeChatBubblePainter({required this.color});

  @override
  void paint(Canvas canvas, Size s) {
    final fill  = Paint()..color = color..style = PaintingStyle.fill;
    final white = Paint()..color = Colors.white..style = PaintingStyle.fill;
    final w = s.width;
    final h = s.height;

    // ── 左侧气泡（较大，在后层）─────────────────────────────────────────────
    final leftR = RRect.fromLTRBR(
      0,        0,
      w * 0.72, h * 0.64,
      Radius.circular(h * 0.24),
    );
    canvas.drawRRect(leftR, fill);

    // 左气泡 · 两个白色眼睛
    canvas.drawOval(Rect.fromCenter(
      center: Offset(w * 0.245, h * 0.30), width: w * 0.12, height: h * 0.105), white);
    canvas.drawOval(Rect.fromCenter(
      center: Offset(w * 0.455, h * 0.30), width: w * 0.12, height: h * 0.105), white);

    // ── 右侧气泡（较小，在前层，覆盖左气泡右下角）────────────────────────────
    // 先用背景色抹掉被右气泡遮住的左气泡边缘（制造"穿透"感）
    final rightR = RRect.fromLTRBR(
      w * 0.27, h * 0.36,
      w * 1.0,  h * 1.0,
      Radius.circular(h * 0.20),
    );
    canvas.drawRRect(rightR, fill);

    // 右气泡 · 两个白色眼睛
    canvas.drawOval(Rect.fromCenter(
      center: Offset(w * 0.515, h * 0.685), width: w * 0.10, height: h * 0.09), white);
    canvas.drawOval(Rect.fromCenter(
      center: Offset(w * 0.705, h * 0.685), width: w * 0.10, height: h * 0.09), white);
  }

  @override
  bool shouldRepaint(_WeChatBubblePainter old) => old.color != color;
}
