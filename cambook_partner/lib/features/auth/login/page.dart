import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/i18n/l10n_ext.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/common_widgets.dart';
import '../auth_shared.dart';
import '../auth_theme_controller.dart';
import 'logic.dart';

const _kCountries = [
  ('+855','🇰🇭','Cambodia'),  ('+86','🇨🇳','China'),       ('+1','🇺🇸','USA / Canada'),
  ('+84','🇻🇳','Vietnam'),    ('+63','🇵🇭','Philippines'),  ('+66','🇹🇭','Thailand'),
  ('+65','🇸🇬','Singapore'),  ('+60','🇲🇾','Malaysia'),    ('+82','🇰🇷','Korea'),
  ('+81','🇯🇵','Japan'),      ('+62','🇮🇩','Indonesia'),    ('+44','🇬🇧','UK'),
  ('+61','🇦🇺','Australia'),
];

// ─────────────────────────────────────────────────────────────────────────────
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late final _logic  = Get.find<LoginLogic>();
  late final _tc     = AuthThemeController.to;

  @override
  Widget build(BuildContext context) {
    final l   = context.l10n;
    final mq  = MediaQuery.of(context);
    final bot = mq.padding.bottom;

    return Obx(() {
      final t = _tc.theme;
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: Colors.white,
        ),
        child: Stack(children: [
          // Full-screen background — lives OUTSIDE the Scaffold so it always
          // covers the status bar regardless of Scaffold body positioning.
          Positioned.fill(child: LuxuryBackground(theme: t)),
          Scaffold(
          key: _scaffoldKey,
          backgroundColor: Colors.transparent,
          resizeToAvoidBottomInset: true,
          endDrawer: AuthMoreDrawer(
              theme: t, onLangChanged: _logic.changeLocale),
          body: Column(children: [
            SizedBox(height: mq.padding.top),

              // ── Brand bar ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 16, 0),
                child: Row(children: [
                  const Icon(Icons.spa_rounded, color: Colors.black87, size: 20),
                  const SizedBox(width: 7),
                  Text(l.brandTitle,
                      style: const TextStyle(
                          fontSize: 13.5, fontWeight: FontWeight.w700,
                          color: Colors.black87, letterSpacing: 1.4)),
                  const Spacer(),
                  // Language button
                  BounceTap(
                    pressScale: 0.80,
                    onTap: () => Get.toNamed(AppRoutes.language),
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(Icons.language_rounded,
                          size: 22, color: Colors.black87),
                    ),
                  ),
                  // More (drawer) button
                  BounceTap(
                    pressScale: 0.80,
                    onTap: () =>
                        _scaffoldKey.currentState?.openEndDrawer(),
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(Icons.more_horiz_rounded,
                          size: 30, color: Colors.black87),
                    ),
                  ),
                ]),
              ),

              // ── Hero text block ─────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.technicianLogin,
                        style: TextStyle(
                            fontSize: 13, letterSpacing: 4.0,
                            fontWeight: FontWeight.w700,
                            color: t.accent)),
                    const SizedBox(height: 5),
                    Text(l.workbenchTitle,
                        style: TextStyle(
                            fontSize: 38, fontWeight: FontWeight.w800,
                            color: t.ink, height: 1.05,
                            shadows: const [
                              Shadow(color: Colors.white60, blurRadius: 12)
                            ])),
                    const SizedBox(height: 5),
                    Text(l.sanctuaryAwaits,
                        style: TextStyle(
                            fontSize: 16, fontStyle: FontStyle.italic,
                            color: t.inkMid, letterSpacing: .5,
                            fontWeight: FontWeight.w400)),
                    const SizedBox(height: 7),
                    Text(l.zenTagline,
                        style: TextStyle(
                            fontSize: 13, color: t.inkMid,
                            letterSpacing: .8, height: 1.65,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── White form card ─────────────────────────────────────
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .97),
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(28)),
                    boxShadow: [
                      BoxShadow(
                        color: t.accent.withValues(alpha: .14),
                        blurRadius: 24, offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(24, 22, 24, bot + 16),
                    child: Column(children: [
                      // Tab switcher
                      Obx(() => _TabRow(
                        mode: _logic.state.mode.value,
                        labels: [l.loginTabPhone, l.loginTabTechId],
                        theme: t, onTap: _logic.setMode,
                      )),
                      const SizedBox(height: 22),

                      // Account field
                      Obx(() {
                        final isPhone = _logic.state.mode.value == 0;
                        return AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          transitionBuilder: (child, anim) =>
                              FadeTransition(opacity: anim, child: child),
                          child: isPhone
                              ? _PhoneInput(
                                  key: const ValueKey('phone'),
                                  logic: _logic, theme: t,
                                  onCountryTap: () =>
                                      _pickCountry(context, t))
                              : _PlainInput(
                                  key: const ValueKey('tech'),
                                  ctrl: _logic.accountCtrl,
                                  hint: l.techIdHint,
                                  icon: Icons.badge_outlined,
                                  theme: t),
                        );
                      }),
                      const SizedBox(height: 14),

                      // Password
                      Obx(() => SpaPasswordField(
                        controller: _logic.passCtrl,
                        hint: l.passwordHint,
                        obscure: _logic.state.obscure.value,
                        onToggle: _logic.toggleObscure, theme: t,
                      )),
                      const SizedBox(height: 16),

                      // Remember me + Forgot password
                      Obx(() => Row(children: [
                        BounceTap(
                          pressScale: 0.88,
                          onTap: _logic.toggleRemember,
                          child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 20, height: 20,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(
                                  color: _logic.state.rememberMe.value
                                      ? t.accent
                                      : t.fieldBorder,
                                  width: 1.6,
                                ),
                                color: _logic.state.rememberMe.value
                                    ? t.accent
                                    : Colors.transparent,
                              ),
                              child: _logic.state.rememberMe.value
                                  ? const Icon(Icons.check_rounded,
                                      size: 13, color: Colors.white)
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            Text(l.rememberMe,
                                style: TextStyle(
                                    fontSize: 14, color: t.inkMid,
                                    fontWeight: FontWeight.w500)),
                          ]),
                        ),
                        const Spacer(),
                        BounceTap(
                          pressScale: 0.88,
                          onTap: () => _forgotPassword(context, t),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 2),
                            child: Text(l.forgotPassword,
                                style: TextStyle(
                                    fontSize: 14, color: t.accent,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ])),
                      const SizedBox(height: 24),

                      // ── 进入工作台 ─────────────────────────────────────
                      Obx(() => SpaButton(
                        loading: _logic.state.loading.value,
                        label: l.loginBtn, theme: t,
                        onTap: _logic.login,
                      )),
                      const SizedBox(height: 16),

                      // "没有账号?" divider
                      Row(children: [
                        Expanded(child: Divider(
                            color: t.divider, height: 1, thickness: .6)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Text(l.noAccount,
                              style: TextStyle(
                                  fontSize: 14, color: t.inkFaint)),
                        ),
                        Expanded(child: Divider(
                            color: t.divider, height: 1, thickness: .6)),
                      ]),
                      const SizedBox(height: 14),

                      // ── 注册新账号 ────────────────────────────────────
                      SpaOutlinedButton(
                        label: l.goRegister,
                        onTap: () => Get.toNamed(AppRoutes.register),
                        theme: t,
                      ),
                      const SizedBox(height: 20),

                      // Social login label
                      Text(l.otherLoginMethods,
                          style: TextStyle(
                              fontSize: 13, color: t.inkFaint,
                              letterSpacing: .6)),
                      const SizedBox(height: 14),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                        _SocialBtn(
                          icon: Icons.send_rounded, theme: t,
                          onTap: () => AppToast.info(l.comingSoon),
                        ),
                        const SizedBox(width: 18),
                        _SocialBtn(
                          icon: Icons.facebook_rounded, theme: t,
                          onTap: () => AppToast.info(l.comingSoon),
                        ),
                      ]),

                      // ── 隐私保护 · 数据安全 · 专业平台  (+20px gap) ────
                      const SizedBox(height: 36),
                      SpaSafetyBar(theme: t),
                      const SizedBox(height: 8),
                    ]),
                  ),
                ),
              ),
            ]),
          ),
        ]), // outer Stack (bg + scaffold)
      );
    });
  }

  void _pickCountry(BuildContext context, SpaAuthTheme t) =>
      showModalBottomSheet(
        context: context, backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (_) => AuthCountrySheet(
          countries: _kCountries,
          title: context.l10n.selectCountry,
          onSelect: _logic.setCountry, theme: t,
        ),
      );

  void _forgotPassword(BuildContext context, SpaAuthTheme t) {
    final l    = context.l10n;
    final ctrl = TextEditingController();
    AppSheet.show(
      title: l.forgotPasswordTitle, isScrollControlled: true,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
            22, 8, 22, MediaQuery.of(context).viewInsets.bottom + 28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(l.forgotPasswordDesc,
              style: TextStyle(
                  fontSize: 14, color: t.inkMid, height: 1.7),
              textAlign: TextAlign.center),
          const SizedBox(height: 22),
          TextField(
            controller: ctrl, autofocus: true,
            keyboardType: TextInputType.phone,
            style: TextStyle(color: t.ink, fontSize: 16),
            decoration: t.field(
                hint: l.phoneHint,
                prefix: fieldPrefixIcon(Icons.phone_outlined, t)),
          ),
          const SizedBox(height: 26),
          SpaButton(
            loading: false, label: l.sendOtp, theme: t,
            onTap: () {
              if (ctrl.text.trim().isEmpty) return;
              final phone = ctrl.text.trim();
              ctrl.dispose();
              Get.back();
              Future.delayed(const Duration(milliseconds: 200),
                  () => AppToast.success(l.otpSent(phone)));
            },
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Underline tab switcher
// ─────────────────────────────────────────────────────────────────────────────
class _TabRow extends StatelessWidget {
  final int mode;
  final List<String> labels;
  final SpaAuthTheme theme;
  final ValueChanged<int> onTap;
  const _TabRow({required this.mode, required this.labels,
      required this.theme, required this.onTap});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(labels.length, (i) {
          final active = mode == i;
          return BounceTap(
            pressScale: 0.88,
            onTap: () => onTap(i),
            child: Padding(
              padding: EdgeInsets.only(right: i < labels.length - 1 ? 36 : 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                          active ? FontWeight.w800 : FontWeight.w500,
                      color: active ? theme.accent : theme.inkFaint,
                    ),
                    child: Text(labels[i]),
                  ),
                  const SizedBox(height: 7),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                    height: 3.0,
                    width: active ? 48.0 : 0.0,
                    decoration: BoxDecoration(
                      color: theme.accent,
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Plain text input
// ─────────────────────────────────────────────────────────────────────────────
class _PlainInput extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final IconData icon;
  final SpaAuthTheme theme;
  const _PlainInput({super.key, required this.ctrl, required this.hint,
      required this.icon, required this.theme});

  @override
  Widget build(BuildContext context) => TextField(
        controller: ctrl,
        style: TextStyle(color: theme.ink, fontSize: 16),
        decoration: theme.field(
          hint: hint,
          prefix: fieldPrefixIcon(icon, theme),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Phone input with country code prefix
// ─────────────────────────────────────────────────────────────────────────────
class _PhoneInput extends StatelessWidget {
  final LoginLogic logic;
  final SpaAuthTheme theme;
  final VoidCallback onCountryTap;
  const _PhoneInput({super.key, required this.logic,
      required this.theme, required this.onCountryTap});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Obx(() => TextField(
          controller: logic.accountCtrl,
          keyboardType: TextInputType.phone,
          style: TextStyle(color: theme.ink, fontSize: 16),
          decoration: theme.field(
            hint: l.phoneHint,
            prefix: BounceTap(
              pressScale: 0.88,
              onTap: onCountryTap,
              child: Padding(
                padding: const EdgeInsets.only(left: 2, right: 4),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(logic.state.countryFlag.value,
                      style: const TextStyle(fontSize: 19)),
                  const SizedBox(width: 3),
                  Text(logic.state.countryCode.value,
                      style: TextStyle(fontSize: 13, color: theme.inkMid,
                          fontWeight: FontWeight.w700)),
                  Icon(Icons.expand_more_rounded,
                      size: 16, color: theme.inkFaint),
                  const SizedBox(width: 4),
                  Container(width: .8, height: 16, color: theme.fieldBorder),
                  const SizedBox(width: 2),
                ]),
              ),
            ),
          ),
        ));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Circular social button — uses BounceTap
// ─────────────────────────────────────────────────────────────────────────────
class _SocialBtn extends StatelessWidget {
  final IconData icon;
  final SpaAuthTheme theme;
  final VoidCallback onTap;
  const _SocialBtn(
      {required this.icon, required this.theme, required this.onTap});

  @override
  Widget build(BuildContext context) => BounceTap(
        pressScale: 0.82,
        onTap: onTap,
        child: Container(
          width: 50, height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: theme.divider, width: 1.0),
            boxShadow: [
              BoxShadow(color: theme.accent.withValues(alpha: .12),
                  blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          child: Icon(icon, size: 22, color: theme.inkMid),
        ),
      );
}
