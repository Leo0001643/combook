import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/extensions/theme_ext.dart';
import '../../../core/i18n/l10n_ext.dart';
import '../../../core/models/models.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme_controller.dart';
import '../../../core/utils/date_util.dart';
import '../../../core/utils/format_util.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/glass_orb.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../core/services/user_service.dart';
import '../auth/auth_shared.dart' show ThemeSwatchPicker, SpaThemeVariant;
import '../shell/shell_controller.dart';
import 'logic.dart';
import 'state.dart';

part 'widgets/shared.dart';
part 'widgets/header.dart';
part 'widgets/drawer.dart';
part 'widgets/today_overview.dart';
part 'widgets/quick_actions.dart';
part 'widgets/schedule.dart';
part 'widgets/performance.dart';

// ════════════════════════════════════════════════════════════════════════════
// HOME PAGE
// ════════════════════════════════════════════════════════════════════════════
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final logic = Get.find<HomeLogic>();
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        body: Stack(children: [
          // ── Theme-aware full-screen background + gradient ────────────
          Obx(() {
            final theme = AppThemeController.to.spaTheme;
            final c     = AppThemeController.to.primaryDk;
            return Positioned.fill(
              child: Stack(children: [
                ColoredBox(
                  color: theme.accent.withValues(alpha: .15),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 600),
                    child: SizedBox.expand(
                      key: ValueKey(theme.bgAsset),
                      child: OverflowBox(
                        alignment: Alignment.topCenter,
                        maxHeight: double.infinity,
                        child: Image.asset(
                          theme.bgAsset,
                          width: double.infinity,
                          fit: BoxFit.fitWidth,
                          alignment: Alignment.topCenter,
                        ),
                      ),
                    ),
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        c.withValues(alpha: .50),
                        c.withValues(alpha: .20),
                        c.withValues(alpha: .0),
                      ],
                      stops: const [0.0, 0.20, 0.42],
                    ),
                  ),
                  child: const SizedBox.expand(),
                ),
              ]),
            );
          }),

          // ── Header + scrollable content ──────────────────────────────
          Column(children: [
            _HomeHeaderWidget(logic: logic),
            Expanded(child: _HomeContent(logic: logic)),
          ]),
        ]),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// HOME CONTENT — scrollable sections + one sticky header overlay at top
// ════════════════════════════════════════════════════════════════════════════
class _HomeContent extends StatefulWidget {
  final HomeLogic logic;
  const _HomeContent({required this.logic});

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent> {
  final _sc    = ScrollController();
  final _hKeys = List.generate(4, (_) => GlobalKey());
  int _activeIdx = -1;

  static const _kStickyH = 46.0;
  static const _kBg      = Color(0xFFFFFFFF);

  @override
  void initState() {
    super.initState();
    _sc.addListener(_onScroll);
  }

  @override
  void dispose() {
    _sc.removeListener(_onScroll);
    _sc.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!mounted) return;
    final box = context.findRenderObject();
    if (box == null || box is! RenderBox) return;

    int newIdx = -1;
    for (int i = 0; i < _hKeys.length; i++) {
      final hCtx = _hKeys[i].currentContext;
      if (hCtx == null) continue;
      final hRO = hCtx.findRenderObject();
      if (hRO == null || hRO is! RenderBox) continue;
      final dy        = hRO.localToGlobal(Offset.zero, ancestor: box).dy;
      final threshold = i == 0 ? 0.0 : _kStickyH.toDouble();
      if (dy <= threshold) newIdx = i;
    }
    if (newIdx != _activeIdx) setState(() => _activeIdx = newIdx);
  }

  Widget _buildSectionTitle(int idx) {
    final logic = widget.logic;
    return switch (idx) {
      0 => _TodayOverview.headerRow(context, logic),
      1 => _QuickActionsSection.headerRow(context),
      2 => _TodayScheduleSection.headerRow(context, logic),
      3 => _PerformanceCard.headerRow(context, logic),
      _ => const SizedBox.shrink(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final logic = widget.logic;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Stack(children: [
          // ── Scrollable content ───────────────────────────────────────
          CustomScrollView(
            controller: _sc,
            physics: const BouncingScrollPhysics(),
            slivers: [
              const SliverPadding(padding: EdgeInsets.only(top: 22)),

              SliverToBoxAdapter(
                child: Padding(
                  key: _hKeys[0],
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  child: _TodayOverview.headerRow(context, logic),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 22),
                sliver: SliverToBoxAdapter(child: _TodayOverviewCards(logic: logic)),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  key: _hKeys[1],
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  child: _QuickActionsSection.headerRow(context),
                ),
              ),
              const SliverPadding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 22),
                sliver: SliverToBoxAdapter(child: _QuickActionsGrid()),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  key: _hKeys[2],
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  child: _TodayScheduleSection.headerRow(context, logic),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 22),
                sliver: SliverToBoxAdapter(child: _TodayScheduleContent(logic: logic)),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  key: _hKeys[3],
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  child: _PerformanceCard.headerRow(context, logic),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                sliver: SliverToBoxAdapter(child: _PerformanceContent(logic: logic)),
              ),

              SliverPadding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.viewPaddingOf(context).bottom + 76,
                ),
              ),
            ],
          ),

          // ── Sticky section header overlay ────────────────────────────
          if (_activeIdx >= 0)
            Positioned(
              top: 0, left: 0, right: 0,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 160),
                child: Container(
                  key: ValueKey(_activeIdx),
                  height: _kStickyH,
                  color: _kBg,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _buildSectionTitle(_activeIdx),
                  ),
                ),
              ),
            ),
        ]),
      ),
    );
  }
}
