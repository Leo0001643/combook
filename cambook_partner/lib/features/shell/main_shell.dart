import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:badges/badges.dart' as bdg;
import '../../core/constants/app_colors.dart';
import '../../core/i18n/l10n_ext.dart';
import '../../core/services/message_service.dart';
import '../../core/theme/app_theme_controller.dart';
import '../../core/widgets/common_widgets.dart';
import '../home/page.dart';
import '../orders/list/page.dart';
import '../messages/list/page.dart';
import '../income/page.dart';
import '../profile/index/page.dart';
import 'shell_controller.dart';

// ── Design tokens ─────────────────────────────────────────────────────────────
const _kFabR    = 28.0;              // FAB radius → diameter 56
const _kNotchR  = 34.0;              // Notch radius (FAB + 6 px gap)
const _kNavH    = 62.0;              // Nav bar content height (excl. safe-area)
const _kIconSz  = 24.0;              // Tab icon size
const _kLblSz   = 10.5;              // Tab label font size
const _kGray    = Color(0xFFC2CBD4); // Inactive tab colour

// ── Tab descriptor (OCP: adding a tab = adding one entry here only) ───────────
@immutable
class _TabDesc {
  final int     idx;
  final IconData icon;
  final String Function(BuildContext) label;
  final bool    isMsgTab;
  const _TabDesc(this.idx, this.icon, this.label, {this.isMsgTab = false});
}

// ═════════════════════════════════════════════════════════════════════════════
// MainShell — pure composition, zero logic
// ═════════════════════════════════════════════════════════════════════════════
class MainShell extends StatelessWidget {
  const MainShell({super.key});

  static const _pages = [
    HomePage(), MessageListPage(), OrderListPage(), IncomePage(), ProfileIndexPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<ShellController>();
    return Scaffold(
      // Transparent lets each page own its background; extendBody lets the
      // glass nav bar blur what's beneath it.
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: Obx(() => IndexedStack(
        index: ctrl.currentIdx.value,
        children: _pages,
      )),
      bottomNavigationBar: const _BottomNav(),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// _BottomNav — owns animations; composes painter + tabs + FAB via Stack
// ═════════════════════════════════════════════════════════════════════════════
class _BottomNav extends StatefulWidget {
  const _BottomNav();
  @override State<_BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<_BottomNav> with TickerProviderStateMixin {

  // Extend the nav by adding an entry here — nothing else needs to change.
  static final _tabs = <_TabDesc>[
    _TabDesc(0, Icons.home_rounded,                   (c) => c.l10n.navHome),
    _TabDesc(1, Icons.chat_bubble_rounded,            (c) => c.l10n.navMessages,
        isMsgTab: true),
    _TabDesc(3, Icons.account_balance_wallet_rounded, (c) => c.l10n.navIncome),
    _TabDesc(4, Icons.person_rounded,                 (c) => c.l10n.navProfile),
  ];

  late final Map<int, AnimationController> _anims;
  late final Worker _worker;

  @override
  void initState() {
    super.initState();
    final shell = Get.find<ShellController>();
    _anims = {
      for (final t in _tabs)
        t.idx: AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 230),
          value: shell.currentIdx.value == t.idx ? 1.0 : 0.0,
        ),
    };
    _worker = ever(shell.currentIdx, (int idx) =>
        _anims.forEach((i, c) => idx == i ? c.forward() : c.reverse()));
  }

  @override
  void dispose() {
    _worker.dispose();
    for (final c in _anims.values) { c.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pad   = MediaQuery.paddingOf(context).bottom;
    final shell = Get.find<ShellController>();

    return Obx(() {
      final curIdx = shell.currentIdx.value;
      return Material(
        color: Colors.white,
        elevation: 4,
        shadowColor: Colors.black26,
        child: SizedBox(
        height: _kNavH + pad,
        child: Stack(
          clipBehavior: Clip.none,   // FAB overflows upward
          children: [

            // Thin top separator
            const Positioned(
              top: 0, left: 0, right: 0,
              child: Divider(height: 0.5, thickness: 0.5, color: Color(0x18000000)),
            ),

            // ② Four regular tab items
            Positioned.fill(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final t in _tabs.take(2))
                    _NavTab(
                      desc:   t,
                      ctrl:   _anims[t.idx]!,
                      onTap:  () => shell.switchTab(t.idx),
                      safePad: pad,
                    ),
                  // Center slot — only the "订单" label; FAB floats above
                  _CenterLabel(
                    isActive: curIdx == ShellController.tabOrders,
                    label:    context.l10n.navOrders,
                    onTap:    () => shell.switchTab(ShellController.tabOrders),
                    safePad:  pad,
                  ),
                  for (final t in _tabs.skip(2))
                    _NavTab(
                      desc:   t,
                      ctrl:   _anims[t.idx]!,
                      onTap:  () => shell.switchTab(t.idx),
                      safePad: pad,
                    ),
                ],
              ),
            ),

            // ③ Floating order button — floats above the nav bar (no notch)
            Positioned(
              top:   -(_kFabR + 10),  // FAB lifts 10 px above the nav-bar top edge
              left:  0,
              right: 0,
              child: Center(
                child: Obx(() => _OrderFab(
                  isActive:   curIdx == ShellController.tabOrders,
                  badgeCount: shell.orderBadgeCount.value,
                  onTap:      () => shell.switchTab(ShellController.tabOrders),
                )),
              ),
            ),
          ],
        ),      // Stack
        ),      // SizedBox
      );        // Material
    });
  }
}


// ═════════════════════════════════════════════════════════════════════════════
// _NavTab — single regular tab item
// ═════════════════════════════════════════════════════════════════════════════
class _NavTab extends StatelessWidget {
  final _TabDesc          desc;
  final AnimationController ctrl;
  final VoidCallback       onTap;
  final double             safePad;

  const _NavTab({
    required this.desc,
    required this.ctrl,
    required this.onTap,
    required this.safePad,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: BounceTap(
        pressScale: 0.78,
        onTap: onTap,
        child: AnimatedBuilder(
          animation: ctrl,
          builder: (_, __) {
            final t     = Curves.easeOut.transform(ctrl.value);
            final color = Color.lerp(_kGray, AppThemeController.to.primary, t)!;
            return Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Transform.scale(
                  scale: 1.0 + t * 0.12,
                  child: _buildIcon(color),
                ),
                const SizedBox(height: 3),
                Text(desc.label(context),
                  style: TextStyle(
                    color:      color,
                    fontSize:   _kLblSz,
                    height:     1.0,
                    fontWeight: t > 0.5 ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                // safePad keeps the content visually centred in the white area
                // on both regular and edge-to-edge devices.
                SizedBox(height: 8 + safePad),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildIcon(Color color) {
    Widget icon = desc.isMsgTab
        ? WeChatBubbleIcon(color: color, size: _kIconSz)
        : Icon(desc.icon, color: color, size: _kIconSz);
    if (!desc.isMsgTab) {
      // Glow-behind-icon 3-D effect: radial gradient halo, no visible circle
      return Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: _kIconSz + 16,
            height: _kIconSz + 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  color.withValues(alpha: .22),
                  color.withValues(alpha: .0),
                ],
              ),
            ),
          ),
          Icon(desc.icon, color: color, size: _kIconSz),
        ],
      );
    }

    return Obx(() {
      final n = Get.find<MessageService>().totalUnread;
      if (n == 0) return icon;
      return bdg.Badge(
        showBadge: true,
        badgeContent: Text(
          n > 9 ? '9+' : '$n',
          style: const TextStyle(
              color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold),
        ),
        badgeStyle: const bdg.BadgeStyle(
            badgeColor: AppColors.danger, padding: EdgeInsets.all(3)),
        child: icon,
      );
    });
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// _CenterLabel — "订单" label that sits below the notch
// ═════════════════════════════════════════════════════════════════════════════
class _CenterLabel extends StatelessWidget {
  final bool        isActive;
  final String      label;
  final VoidCallback onTap;
  final double      safePad;

  const _CenterLabel({
    required this.isActive,
    required this.label,
    required this.onTap,
    required this.safePad,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: (_kNotchR + 10) * 2,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.translucent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 220),
              style: TextStyle(
                color:      isActive ? AppThemeController.to.primary : _kGray,
                fontSize:   _kLblSz,
                height:     1.0,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
              child: Text(label),
            ),
            SizedBox(height: 8 + safePad),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// _OrderFab — Siri-style rotating rainbow ring + gradient sphere
// ═════════════════════════════════════════════════════════════════════════════
class _OrderFab extends StatefulWidget {
  final bool        isActive;
  final int         badgeCount;
  final VoidCallback onTap;
  const _OrderFab({required this.isActive, required this.badgeCount, required this.onTap});
  @override State<_OrderFab> createState() => _OrderFabState();
}

class _OrderFabState extends State<_OrderFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotate;

  @override
  void initState() {
    super.initState();
    _rotate = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3000))
      ..repeat();
  }

  @override
  void dispose() {
    _rotate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const d = _kFabR * 2;            // 56 px inner button
    const outer = d + 12.0;          // 68 px outer ring area
    const ringW = 4.0;               // ring stroke width

    return SizedBox(
      width:  outer + 20,
      height: outer + 20,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ── Siri rainbow rotating ring ──────────────────────────────────
          AnimatedBuilder(
            animation: _rotate,
            builder: (_, __) => Transform.rotate(
              angle: _rotate.value * 6.2832,   // full 360°
              child: CustomPaint(
                size: const Size(outer, outer),
                painter: _SiriRingPainter(
                  active: widget.isActive,
                  strokeWidth: ringW,
                ),
              ),
            ),
          ),
          // ── Main button ─────────────────────────────────────────────────
          BounceTap(
            pressScale: 0.88,
            onTap: widget.onTap,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: d, height: d,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end:   Alignment.bottomRight,
                      colors: widget.isActive
                          ? [AppThemeController.to.primaryLt, AppThemeController.to.primaryDk]
                          : [AppThemeController.to.primary, AppThemeController.to.primaryDk],
                    ),
                    border: Border.all(color: Colors.white, width: 3.5),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4F46E5)
                            .withValues(alpha: widget.isActive ? 0.55 : 0.28),
                        blurRadius: 20,
                        spreadRadius: 2,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.spa_rounded, color: Colors.white, size: 26),
                ),
                // 角标
                if (widget.badgeCount > 0)
                  Positioned(
                    top: -2, right: -2,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 19, minHeight: 19),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: AppColors.danger,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [BoxShadow(
                          color: AppColors.danger.withValues(alpha: 0.5),
                          blurRadius: 6, offset: const Offset(0, 2))],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        widget.badgeCount > 99 ? '99+' : '${widget.badgeCount}',
                        style: const TextStyle(
                          color: Colors.white, fontSize: 9,
                          fontWeight: FontWeight.w800, height: 1.0),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Paints the Siri-style rotating rainbow gradient ring.
class _SiriRingPainter extends CustomPainter {
  final bool  active;
  final double strokeWidth;
  const _SiriRingPainter({required this.active, required this.strokeWidth});

  static const _colors = [
    Color(0xFF6366F1),  // indigo
    Color(0xFF8B5CF6),  // violet
    Color(0xFFEC4899),  // pink
    Color(0xFFF97316),  // orange
    Color(0xFFFACC15),  // yellow
    Color(0xFF34D399),  // emerald
    Color(0xFF38BDF8),  // sky
    Color(0xFF6366F1),  // indigo (loop)
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final r    = size.width / 2;
    final rect = Rect.fromCircle(center: Offset(r, r), radius: r - strokeWidth / 2);
    final opacity = active ? 1.0 : 0.55;

    final paint = Paint()
      ..style      = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap  = StrokeCap.round
      ..shader     = SweepGradient(
          colors: _colors.map((c) => c.withValues(alpha: opacity)).toList(),
        ).createShader(rect);

    canvas.drawArc(rect, -1.5708, 6.2832, false, paint);   // full circle from top
  }

  @override
  bool shouldRepaint(_SiriRingPainter old) =>
      old.active != active || old.strokeWidth != strokeWidth;
}
