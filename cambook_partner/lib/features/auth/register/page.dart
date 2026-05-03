import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/i18n/l10n_ext.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/widgets/common_widgets.dart';
import '../auth_shared.dart';
import '../auth_theme_controller.dart';
import '../login/logic.dart';
import 'logic.dart';

const _kCountries = [
  ('+855','🇰🇭','Cambodia'),  ('+86','🇨🇳','China'),       ('+1','🇺🇸','USA'),
  ('+84','🇻🇳','Vietnam'),    ('+63','🇵🇭','Philippines'),  ('+66','🇹🇭','Thailand'),
  ('+65','🇸🇬','Singapore'),  ('+60','🇲🇾','Malaysia'),    ('+82','🇰🇷','Korea'),
  ('+81','🇯🇵','Japan'),      ('+62','🇮🇩','Indonesia'),   ('+91','🇮🇳','India'),
  ('+44','🇬🇧','UK'),         ('+61','🇦🇺','Australia'),
];

// ─────────────────────────────────────────────────────────────────────────────
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late final _logic  = Get.find<RegisterLogic>();
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
          Positioned.fill(child: LuxuryBackground(theme: t)),
          Scaffold(
          key: _scaffoldKey,
          backgroundColor: Colors.transparent,
          resizeToAvoidBottomInset: true,
          endDrawer: AuthMoreDrawer(
            theme: t,
            onLangChanged: (c) => Get.find<LoginLogic>().changeLocale(c),
          ),
          body: Column(children: [
              SizedBox(height: mq.padding.top),

              // ── Brand bar ────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Row(children: [
                  // Back arrow
                  BounceTap(
                    pressScale: 0.78,
                    onTap: () => Get.back(),
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(Icons.arrow_back_ios_new_rounded,
                          size: 19,
                          color: Colors.black87),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.spa_rounded, color: Colors.black87, size: 18),
                  const SizedBox(width: 5),
                  Text(l.brandTitle,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700,
                          color: Colors.black87, letterSpacing: 1.3)),
                  const Spacer(),
                  // Language button
                  BounceTap(
                    pressScale: 0.80,
                    onTap: () => Get.toNamed(AppRoutes.language),
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(Icons.language_rounded,
                          size: 22,
                          color: Colors.black87),
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
                          size: 30,
                          color: Colors.black87),
                    ),
                  ),
                ]),
              ),

              // ── Hero ────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.registerTitle,
                        style: TextStyle(
                            fontSize: 34, fontWeight: FontWeight.w800,
                            color: t.ink, height: 1.1,
                            shadows: const [
                              Shadow(color: Colors.white60, blurRadius: 12)
                            ])),
                    const SizedBox(height: 6),
                    RichText(
                      text: TextSpan(children: [
                        TextSpan(
                            text: l.registerJoinPrefix,
                            style: TextStyle(
                                fontSize: 14, color: t.inkMid,
                                fontWeight: FontWeight.w500, height: 1.5)),
                        TextSpan(
                            text: 'SPA 水汇',
                            style: TextStyle(
                                fontSize: 14, color: t.accent,
                                fontWeight: FontWeight.w700, height: 1.5)),
                        TextSpan(
                            text: l.registerJoinSuffix,
                            style: TextStyle(
                                fontSize: 14, color: t.inkMid,
                                fontWeight: FontWeight.w500, height: 1.5)),
                      ]),
                    ),
                    const SizedBox(height: 8),
                    SpaVerifiedBadge(theme: t),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // ── White form card ─────────────────────────────────────
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .97),
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(28)),
                    boxShadow: [
                      BoxShadow(
                        color: t.accent.withValues(alpha: .12),
                        blurRadius: 20, offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(20, 22, 20, bot + 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [

                        // ── 昵称 ────────────────────────────────────
                        TextField(
                          controller: _logic.nicknameCtrl,
                          style: TextStyle(color: t.ink, fontSize: 16),
                          decoration: t.field(
                            hint: l.nicknameHint,
                            prefix: fieldPrefixIcon(
                                Icons.person_outline_rounded, t),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // ── 手机号: 区号 + 号码 ─────────────────────
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Obx(() => BounceTap(
                              pressScale: 0.92,
                              onTap: () => _pickCountry(context, t),
                              child: Container(
                                height: 56,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10),
                                decoration: BoxDecoration(
                                  color: t.fieldBg,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: t.fieldBorder, width: .8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(_logic.state.countryFlag.value,
                                        style: const TextStyle(
                                            fontSize: 21)),
                                    const SizedBox(width: 4),
                                    Text(_logic.state.countryCode.value,
                                        style: TextStyle(
                                            fontSize: 14, color: t.ink,
                                            fontWeight: FontWeight.w700)),
                                    Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        size: 16,
                                        color: t.inkFaint),
                                  ],
                                ),
                              ),
                            )),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _logic.phoneCtrl,
                                keyboardType: TextInputType.phone,
                                style: TextStyle(color: t.ink, fontSize: 16),
                                decoration: t.field(hint: l.phone),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // ── 密码 ────────────────────────────────────
                        Obx(() => SpaPasswordField(
                          controller: _logic.passCtrl,
                          hint: l.passwordHint,
                          obscure: _logic.state.obscurePass.value,
                          onToggle: _logic.togglePass, theme: t,
                        )),
                        const SizedBox(height: 14),

                        // ── 确认密码 ─────────────────────────────────
                        Obx(() => SpaPasswordField(
                          controller: _logic.confirmCtrl,
                          hint: l.confirmPasswordHint,
                          obscure: _logic.state.obscureConfirm.value,
                          onToggle: _logic.toggleConfirm, theme: t,
                        )),
                        const SizedBox(height: 14),

                        // ── 商户邀请码 ───────────────────────────────
                        TextField(
                          controller: _logic.merchantCodeCtrl,
                          style: TextStyle(color: t.ink, fontSize: 16),
                          decoration: t.field(
                            hint: l.merchantCodeHint,
                            prefix: fieldPrefixIcon(
                                Icons.lock_outline_rounded, t),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ── 分隔线 ───────────────────────────────────
                        Row(children: [
                          Expanded(child: Divider(
                              color: t.divider, height: 1,
                              thickness: .6)),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12),
                            child: Text(l.orRegisterVia,
                                style: TextStyle(
                                    fontSize: 13, color: t.inkFaint,
                                    letterSpacing: .4)),
                          ),
                          Expanded(child: Divider(
                              color: t.divider, height: 1,
                              thickness: .6)),
                        ]),
                        const SizedBox(height: 14),

                        // ── Telegram（选填）──────────────────────────
                        TextField(
                          controller: _logic.telegramCtrl,
                          style: TextStyle(color: t.inkMid, fontSize: 16),
                          decoration: t.field(
                            hint: l.telegramOptional,
                            prefix: Padding(
                              padding: const EdgeInsets.only(
                                  left: 2, right: 8),
                              child: Icon(Icons.send_rounded, size: 18,
                                  color: t.accent.withValues(alpha: .55)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 26),

                        // ── 加入技师团队 ─────────────────────────────
                        Obx(() => SpaButton(
                          loading: _logic.state.loading.value,
                          label: l.registerBtn, theme: t,
                          onTap: _logic.register,
                        )),
                        const SizedBox(height: 16),

                        // ── 已有账号？去登录 ──────────────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(l.haveAccount,
                                style: TextStyle(
                                    color: t.inkFaint, fontSize: 14.5)),
                            BounceTap(
                              pressScale: 0.88,
                              onTap: () => Get.back(),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 4),
                                child: Text(l.goLogin,
                                    style: TextStyle(
                                        color: t.accent, fontSize: 14.5,
                                        fontWeight: FontWeight.w800)),
                              ),
                            ),
                          ],
                        ),

                        // ── 隐私保护 · 数据安全 · 专业平台  (+20px) ───
                        const SizedBox(height: 36),
                        SpaSafetyBar(theme: t),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),  // closes body Column
        ),    // closes Scaffold
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
}
