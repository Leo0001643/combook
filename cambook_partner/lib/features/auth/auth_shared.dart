/// SPA Auth Design System — Three-Theme Edition
/// Pink / Lavender / Forest Green
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/config/app_config.dart';
import '../../core/constants/app_assets.dart';
import '../../core/i18n/l10n_ext.dart';
import '../../core/widgets/app_dialog.dart';
import '../../core/widgets/common_widgets.dart';
import 'auth_theme_controller.dart';

// ══════════════════════════════════════════════════════════════════════════════
// COLOUR SYSTEM  —  3 variants, open for extension
// ══════════════════════════════════════════════════════════════════════════════
enum SpaThemeVariant { pink, purple, green }

class SpaAuthTheme {
  final SpaThemeVariant variant;
  const SpaAuthTheme(this.variant);

  bool get isPink   => variant == SpaThemeVariant.pink;
  bool get isPurple => variant == SpaThemeVariant.purple;
  bool get isGreen  => variant == SpaThemeVariant.green;

  // ── Background image asset ─────────────────────────────────────────────────
  String get bgAsset => switch (variant) {
    SpaThemeVariant.pink   => AppAssets.bgHomePink,
    SpaThemeVariant.purple => AppAssets.bgHomePurple,
    SpaThemeVariant.green  => AppAssets.bgHomeGreen,
  };

  String get bgAuthAsset => switch (variant) {
    SpaThemeVariant.pink   => AppAssets.bgAuthPink,
    SpaThemeVariant.purple => AppAssets.bgAuthPurple,
    SpaThemeVariant.green  => AppAssets.bgAuthGreen,
  };

  // ── Accent / Brand ─────────────────────────────────────────────────────────
  Color get accent => switch (variant) {
    SpaThemeVariant.pink   => const Color(0xFFE8608A),
    SpaThemeVariant.purple => const Color(0xFF9874C8),
    SpaThemeVariant.green  => const Color(0xFF4B9B6F),
  };
  Color get accentDeep => switch (variant) {
    SpaThemeVariant.pink   => const Color(0xFFD04070),
    SpaThemeVariant.purple => const Color(0xFF7A5DB8),
    SpaThemeVariant.green  => const Color(0xFF357A52),
  };
  Color get accentLight => switch (variant) {
    SpaThemeVariant.pink   => const Color(0xFFFFE4EE),
    SpaThemeVariant.purple => const Color(0xFFEDE4F8),
    SpaThemeVariant.green  => const Color(0xFFDDF0E6),
  };

  // ── Gradient for CTA button ────────────────────────────────────────────────
  List<Color> get btnGrad => switch (variant) {
    SpaThemeVariant.pink   => [const Color(0xFFFF6E9C), const Color(0xFFD04070)],
    SpaThemeVariant.purple => [const Color(0xFFB088E0), const Color(0xFF7A5DB8)],
    SpaThemeVariant.green  => [const Color(0xFF6BBF8A), const Color(0xFF357A52)],
  };

  // ── Text ──────────────────────────────────────────────────────────────────
  Color get ink      => const Color(0xFF2B2828);
  Color get inkMid   => const Color(0xFF7A7070);
  Color get inkFaint => const Color(0xFFBBB0B0);

  // ── Card / Inputs ─────────────────────────────────────────────────────────
  Color get fieldBg     => switch (variant) {
    SpaThemeVariant.pink   => const Color(0xFFFFF5F9),
    SpaThemeVariant.purple => const Color(0xFFF9F5FF),
    SpaThemeVariant.green  => const Color(0xFFF4FAF6),
  };
  Color get fieldBorder => switch (variant) {
    SpaThemeVariant.pink   => const Color(0xFFFFCCDD),
    SpaThemeVariant.purple => const Color(0xFFD8C8F0),
    SpaThemeVariant.green  => const Color(0xFFB8DEC8),
  };
  Color get divider     => switch (variant) {
    SpaThemeVariant.pink   => const Color(0xFFFFDDE8),
    SpaThemeVariant.purple => const Color(0xFFE8DAFC),
    SpaThemeVariant.green  => const Color(0xFFC8E8D4),
  };

  // Legacy aliases for drawer header gradient
  Color get bgTop    => accentLight;
  Color get bgBottom => accentLight.withValues(alpha: .6);

  // ── Input decoration ──────────────────────────────────────────────────────
  InputDecoration field({required String hint, Widget? prefix, Widget? suffix}) =>
      InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: inkFaint, fontSize: 15.5),
        prefixIcon: prefix,
        suffixIcon: suffix,
        filled: true,
        fillColor: fieldBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: fieldBorder, width: 0.8),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: fieldBorder, width: 0.8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accent, width: 1.5),
        ),
      );
}

// ══════════════════════════════════════════════════════════════════════════════
// FULL-SCREEN BACKGROUND  —  real JPEG + subtle overlay for readability
// ══════════════════════════════════════════════════════════════════════════════
class LuxuryBackground extends StatelessWidget {
  final SpaAuthTheme theme;
  const LuxuryBackground({super.key, required this.theme});

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
        duration: const Duration(milliseconds: 600),
        child: SizedBox.expand(
          key: ValueKey(theme.variant),
          child: Image.asset(
            theme.bgAuthAsset,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
        ),
      );
}

// ══════════════════════════════════════════════════════════════════════════════
// THEME SWATCH PICKER  —  3 colour dots
// ══════════════════════════════════════════════════════════════════════════════
class ThemeSwatchPicker extends StatelessWidget {
  final SpaThemeVariant current;
  final ValueChanged<SpaThemeVariant> onSelect;
  const ThemeSwatchPicker({super.key, required this.current, required this.onSelect});

  static const _opts = [
    (SpaThemeVariant.pink,   Color(0xFFE8608A)),
    (SpaThemeVariant.purple, Color(0xFF9874C8)),
    (SpaThemeVariant.green,  Color(0xFF4B9B6F)),
  ];

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final labels = [l.themeRosePink, l.themeChampagneGold, l.themeForestGreen];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(_opts.length, (i) {
        final o      = _opts[i];
        final active = current == o.$1;
        return BounceTap(
          pressScale: 0.80,
          onTap: () => onSelect(o.$1),
          child: Tooltip(
            message: labels[i],
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width:  active ? 26 : 18,
              height: active ? 26 : 18,
              margin: const EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: o.$2,
                border: Border.all(
                  color: active ? Colors.white : Colors.transparent,
                  width: 2.5,
                ),
                boxShadow: active
                    ? [BoxShadow(color: o.$2.withValues(alpha: .45),
                        blurRadius: 10, offset: const Offset(0, 3))]
                    : [],
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ICON HELPER for inputs
// ══════════════════════════════════════════════════════════════════════════════
Widget _fieldIcon(IconData icon, SpaAuthTheme t) =>
    Icon(icon, size: 18, color: t.accent.withValues(alpha: .70));

// ══════════════════════════════════════════════════════════════════════════════
// GRADIENT PILL BUTTON
// ══════════════════════════════════════════════════════════════════════════════
class SpaButton extends StatelessWidget {
  final bool loading;
  final String label;
  final VoidCallback onTap;
  final SpaAuthTheme theme;
  const SpaButton({super.key, required this.loading, required this.label,
      required this.onTap, required this.theme});

  @override
  Widget build(BuildContext context) => BounceTap(
        pressScale: 0.96,
        onTap: loading ? null : onTap,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 120),
          opacity: loading ? .72 : 1.0,
          child: Container(
            height: 54,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: theme.btnGrad,
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(27),
              boxShadow: [
                BoxShadow(
                  color: theme.btnGrad.first.withValues(alpha: .40),
                  blurRadius: 18, offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: loading
                  ? const SizedBox(width: 22, height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.0))
                  : Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(label,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 17,
                              fontWeight: FontWeight.w800, letterSpacing: .8)),
                      const SizedBox(width: 10),
                      const Icon(Icons.arrow_forward_rounded,
                          color: Colors.white, size: 18),
                    ]),
            ),
          ),
        ),
      );
}

// ══════════════════════════════════════════════════════════════════════════════
// OUTLINED PILL BUTTON
// ══════════════════════════════════════════════════════════════════════════════
class SpaOutlinedButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final SpaAuthTheme theme;
  const SpaOutlinedButton({super.key, required this.label,
      required this.onTap, required this.theme});

  @override
  Widget build(BuildContext context) => BounceTap(
        pressScale: 0.94,
        onTap: onTap,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: theme.accent, width: 1.4),
            color: theme.accentLight.withValues(alpha: .15),
          ),
          child: Center(
            child: Text(label,
                style: TextStyle(
                    color: theme.accent, fontSize: 16,
                    fontWeight: FontWeight.w700, letterSpacing: .5)),
          ),
        ),
      );
}

// ══════════════════════════════════════════════════════════════════════════════
// PASSWORD FIELD
// ══════════════════════════════════════════════════════════════════════════════
class SpaPasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final VoidCallback onToggle;
  final SpaAuthTheme theme;
  const SpaPasswordField({super.key, required this.controller,
      required this.hint, required this.obscure,
      required this.onToggle, required this.theme});

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        obscureText: obscure,
        style: TextStyle(color: theme.ink, fontSize: 16),
        decoration: theme.field(
          hint: hint,
          prefix: _fieldIcon(Icons.lock_outline_rounded, theme),
          suffix: IconButton(
            icon: Icon(
              obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              size: 18, color: theme.inkFaint,
            ),
            onPressed: onToggle,
          ),
        ),
      );
}

// ══════════════════════════════════════════════════════════════════════════════
// VERIFIED BADGE
// ══════════════════════════════════════════════════════════════════════════════
class SpaVerifiedBadge extends StatelessWidget {
  final SpaAuthTheme theme;
  const SpaVerifiedBadge({super.key, required this.theme});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_rounded, color: theme.accent, size: 15),
          const SizedBox(width: 5),
          Text('Verified',
              style: TextStyle(
                  color: theme.accent, fontSize: 12.5,
                  fontWeight: FontWeight.w600, letterSpacing: .3)),
        ],
      );
}

// ══════════════════════════════════════════════════════════════════════════════
// SAFETY TRUST BAR  —  隐私保护 · 数据安全 · 专业平台
// ══════════════════════════════════════════════════════════════════════════════
class SpaSafetyBar extends StatelessWidget {
  final SpaAuthTheme theme;
  const SpaSafetyBar({super.key, required this.theme});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final items = [
      (Icons.lock_outline_rounded,     l.privacySafe),
      (Icons.security_rounded,         l.dataSafe),
      (Icons.verified_user_outlined,   l.provenPlatform),
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: items.map((item) => _SafetyItem(
        icon: item.$1, label: item.$2, theme: theme,
      )).toList(),
    );
  }
}

class _SafetyItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final SpaAuthTheme theme;
  const _SafetyItem({required this.icon, required this.label, required this.theme});

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: theme.accentLight,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 17, color: theme.accent),
          ),
          const SizedBox(height: 5),
          Text(label,
              style: TextStyle(
                  fontSize: 12.5, color: theme.inkMid,
                  fontWeight: FontWeight.w600, letterSpacing: .3)),
        ],
      );
}

// ══════════════════════════════════════════════════════════════════════════════
// MORE DRAWER
// ══════════════════════════════════════════════════════════════════════════════
class AuthMoreDrawer extends StatelessWidget {
  final SpaAuthTheme theme;
  final void Function(String) onLangChanged;
  const AuthMoreDrawer({super.key, required this.theme, required this.onLangChanged});

  @override
  Widget build(BuildContext context) {
    final l  = context.l10n;
    final mq = MediaQuery.of(context);
    return SizedBox(
      width: MediaQuery.sizeOf(context).width * .78,
      child: Drawer(
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(left: Radius.circular(24)),
        ),
        child: Column(children: [
          // ── Header with background image ────────────────────────────
          Container(
            height: mq.padding.top + 120,
            clipBehavior: Clip.hardEdge,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.only(topLeft: Radius.circular(24)),
            ),
            child: Stack(fit: StackFit.expand, children: [
              Image.asset(theme.bgAsset, fit: BoxFit.cover),
              Container(
                color: theme.accentDeep.withValues(alpha: .35),
              ),
              Positioned(
                left: 24, bottom: 22,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  const Icon(Icons.spa_rounded, color: Colors.white, size: 26),
                  const SizedBox(height: 8),
                  const Text(AppConfig.merchantName,
                      style: TextStyle(color: Colors.white,
                          fontWeight: FontWeight.w700, fontSize: 17)),
                  const SizedBox(height: 2),
                  Text(AppConfig.appName,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: .80),
                          fontSize: 12, letterSpacing: 1.6,
                          fontWeight: FontWeight.w500)),
                ]),
              ),
            ]),
          ),
          // ── Menu items ──────────────────────────────────────────────
          Expanded(child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 10),
            children: [
              _DItem(icon: Icons.campaign_outlined, theme: theme,
                  label: l.announcements,
                  onTap: () { Navigator.pop(context); AppToast.info(l.comingSoon); }),
              _LangItem(theme: theme, label: l.langTitle, onChanged: (c) {
                Navigator.pop(context); onLangChanged(c);
              }),
              // ── Theme colour picker ───────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 10, 22, 6),
                child: Row(children: [
                  Icon(Icons.palette_outlined, size: 16, color: theme.accent),
                  const SizedBox(width: 10),
                  Expanded(child: Text(l.themeColor,
                      style: TextStyle(fontSize: 15,
                          fontWeight: FontWeight.w600, color: theme.ink))),
                  Obx(() => ThemeSwatchPicker(
                    current: AuthThemeController.to.variant.value,
                    onSelect: AuthThemeController.to.select,
                  )),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Divider(color: theme.divider, height: 1, thickness: .6),
              ),
              _DItem(icon: Icons.shield_outlined, theme: theme,
                  label: l.privacyPolicy,
                  onTap: () { Navigator.pop(context); AppToast.info(l.comingSoon); }),
              _DItem(icon: Icons.description_outlined, theme: theme,
                  label: l.terms,
                  onTap: () { Navigator.pop(context); AppToast.info(l.comingSoon); }),
              _DItem(icon: Icons.help_outline_rounded, theme: theme,
                  label: l.helpAndSupport,
                  onTap: () { Navigator.pop(context); AppToast.info(l.comingSoon); }),
            ],
          )),
        ]),
      ),
    );
  }
}

class _DItem extends StatelessWidget {
  final IconData icon; final SpaAuthTheme theme;
  final String label; final VoidCallback onTap;
  const _DItem({required this.icon, required this.theme,
      required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 22),
        leading: Icon(icon, size: 18, color: theme.accent),
        title: Text(label, style: TextStyle(fontSize: 15,
            fontWeight: FontWeight.w600, color: theme.ink)),
        trailing: Icon(Icons.chevron_right_rounded, size: 16, color: theme.inkFaint),
        onTap: onTap,
      );
}

class _LangItem extends StatelessWidget {
  final SpaAuthTheme theme; final String label;
  final void Function(String) onChanged;
  const _LangItem({required this.theme, required this.label, required this.onChanged});

  static const _langs = [
    ('zh','🇨🇳','中文'), ('en','🇺🇸','English'), ('vi','🇻🇳','Tiếng Việt'),
    ('km','🇰🇭','ភាសាខ្មែរ'), ('ko','🇰🇷','한국어'), ('ja','🇯🇵','日本語'),
  ];

  @override
  Widget build(BuildContext context) {
    final cur = Localizations.localeOf(context).languageCode;
    return PopupMenuButton<String>(
      onSelected: onChanged,
      offset: const Offset(0, 40),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      itemBuilder: (_) => _langs.map((l) {
        final act = cur == l.$1;
        return PopupMenuItem<String>(
          value: l.$1,
          child: Row(children: [
            Text(l.$2, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Text(l.$3,
                style: TextStyle(fontSize: 15,
                    fontWeight: act ? FontWeight.w700 : FontWeight.w400,
                    color: act ? theme.accent : theme.ink)),
            if (act) ...[const Spacer(),
              Icon(Icons.check_rounded, size: 14, color: theme.accent)],
          ]),
        );
      }).toList(),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 22),
        leading: Icon(Icons.language_rounded, size: 20, color: theme.accent),
        title: Text(label, style: TextStyle(fontSize: 15,
            fontWeight: FontWeight.w600, color: theme.ink)),
        trailing: Icon(Icons.chevron_right_rounded, size: 16, color: theme.inkFaint),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// COUNTRY SELECTOR SHEET
// ══════════════════════════════════════════════════════════════════════════════
class AuthCountrySheet extends StatelessWidget {
  final List<(String, String, String)> countries;
  final String title;
  final void Function(String, String) onSelect;
  final SpaAuthTheme theme;
  const AuthCountrySheet({super.key, required this.countries,
      required this.title, required this.onSelect, required this.theme});

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final maxHeight = mq.size.height * 0.65;

    return Container(
        constraints: BoxConstraints(maxHeight: maxHeight),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: SafeArea(
          top: false,
          child: Column(children: [
            Container(
              margin: const EdgeInsets.only(top: 14, bottom: 6),
              width: 32, height: 3,
              decoration: BoxDecoration(
                  color: theme.divider, borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 6, 22, 14),
              child: Row(children: [
                Text(title, style: TextStyle(fontSize: 16,
                    fontWeight: FontWeight.w700, color: theme.ink)),
                const Spacer(),
                BounceTap(
                  pressScale: 0.78,
                  onTap: () => Get.back(),
                  child: Icon(Icons.close_rounded, size: 19, color: theme.inkFaint),
                ),
              ]),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: countries.length,
                padding: const EdgeInsets.only(bottom: 20),
                  itemBuilder: (_, i) {
                  final c = countries[i];
                  return BounceTap(
                    pressScale: 0.96,
                    onTap: () { onSelect(c.$1, c.$2); Get.back(); },
                    child: ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 22, vertical: 1),
                      leading: Text(c.$2,
                          style: const TextStyle(fontSize: 22)),
                      title: Text(c.$3, style: TextStyle(fontSize: 15,
                          fontWeight: FontWeight.w600, color: theme.ink)),
                      trailing: Text(c.$1, style: TextStyle(fontSize: 13,
                          fontWeight: FontWeight.w700, color: theme.accent)),
                    ),
                  );
                },
              ),
            ),
          ]),
        ));
  }
}

// Helper export so pages can use it directly
Widget fieldPrefixIcon(IconData icon, SpaAuthTheme t) => _fieldIcon(icon, t);
