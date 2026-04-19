import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/config/app_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/i18n/l10n_ext.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/common_widgets.dart';
import '../auth_shared.dart';
import '../login/logic.dart';
import 'logic.dart';

const _kRegisterCountries = [
  ('+855', '🇰🇭', 'Cambodia'), ('+1',  '🇺🇸', 'USA'),
  ('+44',  '🇬🇧', 'UK'),       ('+86', '🇨🇳', 'China'),
  ('+84',  '🇻🇳', 'Vietnam'),  ('+82', '🇰🇷', 'Korea'),
  ('+81',  '🇯🇵', 'Japan'),    ('+66', '🇹🇭', 'Thailand'),
  ('+60',  '🇲🇾', 'Malaysia'), ('+65', '🇸🇬', 'Singapore'),
  ('+62',  '🇮🇩', 'Indonesia'), ('+63', '🇵🇭', 'Philippines'),
  ('+91',  '🇮🇳', 'India'),    ('+61', '🇦🇺', 'Australia'),
  ('+33',  '🇫🇷', 'France'),   ('+49', '🇩🇪', 'Germany'),
];

// ─────────────────────────────────────────────────────────────────────────────
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late final RegisterLogic _logic = Get.find<RegisterLogic>();

  @override
  Widget build(BuildContext context) {
    final l     = context.l10n;
    final state = _logic.state;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF4F5FA),
      endDrawer: AuthMoreDrawer(
        onLangChanged: (code) => Get.find<LoginLogic>().changeLocale(code),
      ),

      // ── AppBar ─────────────────────────────────────────────────────────────
      appBar: AppBar(
        centerTitle: false,
        titleSpacing: 0,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Color(0xFF4F46E5), Color(0xFF6D3BE8), Color(0xFF7C3AED)],
            ),
          ),
        ),
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: Colors.white, size: 20),
        ),
        title: const AuthAppBarBrand(),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined,
                color: Colors.white, size: 22),
            onPressed: () => AppToast.info(l.comingSoon),
          ),
          LangMenuButton(
            onChanged: (code) => Get.find<LoginLogic>().changeLocale(code),
          ),
          IconButton(
            icon: const Icon(Icons.more_horiz_rounded,
                color: Colors.white, size: 24),
            onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
          ),
          const SizedBox(width: 2),
        ],
      ),

      // ── Body ───────────────────────────────────────────────────────────────
      body: Column(children: [
        AuthHeroSection(
          title: l.registerTitle,
          subtitle: l.registerSubtitle(AppConfig.merchantName),
        ),
        Expanded(
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                    color: Color(0x0C000000),
                    blurRadius: 24, offset: Offset(0, -6)),
              ],
            ),
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── 商户徽章 ─────────────────────────────────────────────
                  const _MerchantBadge(name: AppConfig.merchantName),
                  const SizedBox(height: 24),

                  // ── 姓名 ─────────────────────────────────────────────────
                  AuthFieldLabel(l.fieldFullName),
                  const SizedBox(height: 8),
                  _RegField(controller: _logic.nameCtrl,
                      hint: l.fullNameHint, icon: Icons.person_rounded),
                  const SizedBox(height: 18),

                  // ── 手机号 ───────────────────────────────────────────────
                  AuthFieldLabel(l.phone),
                  const SizedBox(height: 8),
                  _RegisterPhoneRow(
                      logic: _logic, hint: l.phoneHint,
                      onTap: () => _showCountryPicker(context)),
                  const SizedBox(height: 18),

                  // ── 邮箱 ─────────────────────────────────────────────────
                  AuthFieldLabel(l.fieldEmail),
                  const SizedBox(height: 8),
                  _RegField(controller: _logic.emailCtrl,
                      hint: l.emailHint, icon: Icons.email_rounded,
                      type: TextInputType.emailAddress),
                  const SizedBox(height: 18),

                  // ── 密码 ─────────────────────────────────────────────────
                  AuthFieldLabel(l.password),
                  const SizedBox(height: 8),
                  Obx(() => AuthPasswordField(
                    controller: _logic.passCtrl,
                    hint: l.passwordHint,
                    obscure: state.obscurePass.value,
                    onToggle: _logic.togglePass,
                  )),
                  const SizedBox(height: 18),

                  // ── 确认密码 ─────────────────────────────────────────────
                  AuthFieldLabel(l.fieldConfirmPassword),
                  const SizedBox(height: 8),
                  Obx(() => AuthPasswordField(
                    controller: _logic.confirmCtrl,
                    hint: l.confirmPasswordHint,
                    obscure: state.obscureConfirm.value,
                    onToggle: _logic.toggleConfirm,
                  )),
                  const SizedBox(height: 18),

                  // ── 商户码 ───────────────────────────────────────────────
                  AuthFieldLabel(l.fieldMerchantCode),
                  const SizedBox(height: 8),
                  _RegField(controller: _logic.merchantCodeCtrl,
                      hint: l.merchantCodeHint, icon: Icons.store_rounded),
                  const SizedBox(height: 24),

                  // ── 可选社交账号分隔 ─────────────────────────────────────
                  Row(children: [
                    const Expanded(child: Divider(color: Color(0xFFF0F0F6))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Text(l.optionalField,
                          style: const TextStyle(
                              color: Color(0xFFADB5C8), fontSize: 12,
                              fontWeight: FontWeight.w500)),
                    ),
                    const Expanded(child: Divider(color: Color(0xFFF0F0F6))),
                  ]),
                  const SizedBox(height: 18),

                  // ── Telegram ─────────────────────────────────────────────
                  AuthFieldLabel(l.fieldTelegram),
                  const SizedBox(height: 8),
                  _RegField(controller: _logic.telegramCtrl,
                      hint: l.telegramHint, icon: Icons.send_rounded),
                  const SizedBox(height: 18),

                  // ── Facebook ─────────────────────────────────────────────
                  AuthFieldLabel(l.fieldFacebook),
                  const SizedBox(height: 8),
                  _RegField(controller: _logic.facebookCtrl,
                      hint: l.facebookHint, icon: Icons.facebook_rounded),
                  const SizedBox(height: 32),

                  // ── 注册按钮 ─────────────────────────────────────────────
                  Obx(() => AuthGradientButton(
                    loading: state.loading.value,
                    label: l.registerBtn,
                    onTap: _logic.register,
                  )),
                  const SizedBox(height: 18),

                  // ── 去登录 ───────────────────────────────────────────────
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(l.haveAccount,
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xFFADB5C8),
                            fontWeight: FontWeight.w500)),
                    TextButton(
                      onPressed: () => Get.back(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(l.goLogin,
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700, fontSize: 13)),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ),
      ]),
    );
  }

  void _showCountryPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => AuthCountrySheet(
        countries: _kRegisterCountries,
        title: context.l10n.selectCountry,
        onSelect: _logic.setCountry,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 商户徽章
// ─────────────────────────────────────────────────────────────────────────────
class _MerchantBadge extends StatelessWidget {
  final String name;
  const _MerchantBadge({required this.name});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
      ),
      borderRadius: BorderRadius.circular(16),
      boxShadow: const [
        BoxShadow(
            color: Color(0x354F46E5), blurRadius: 16, offset: Offset(0, 6)),
      ],
    ),
    child: Row(children: [
      Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.store_rounded, color: Colors.white, size: 22),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w800,
                  fontSize: 15, letterSpacing: 0.1)),
          const SizedBox(height: 2),
          Text(context.l10n.merchantVerified,
              style: const TextStyle(
                  color: Colors.white70, fontSize: 11,
                  fontWeight: FontWeight.w500)),
        ],
      )),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.verified_rounded, color: Colors.white, size: 12),
          SizedBox(width: 4),
          Text('Verified',
              style: TextStyle(
                  color: Colors.white, fontSize: 10,
                  fontWeight: FontWeight.w700)),
        ]),
      ),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// 通用文本输入框
// ─────────────────────────────────────────────────────────────────────────────
class _RegField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType type;
  const _RegField({
    required this.controller, required this.hint, required this.icon,
    this.type = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    keyboardType: type,
    decoration: InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 18, color: const Color(0xFFADB5C8)),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// 手机号行
// ─────────────────────────────────────────────────────────────────────────────
class _RegisterPhoneRow extends StatelessWidget {
  final RegisterLogic logic;
  final String hint;
  final VoidCallback onTap;
  const _RegisterPhoneRow(
      {required this.logic, required this.hint, required this.onTap});

  @override
  Widget build(BuildContext context) => Obx(() => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      GestureDetector(
        onTap: onTap,
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(logic.state.countryFlag.value,
                style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 4),
            Text(logic.state.countryCode.value,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 13,
                    color: Color(0xFF374151))),
            const SizedBox(width: 2),
            const Icon(Icons.arrow_drop_down_rounded,
                size: 18, color: Color(0xFFADB5C8)),
          ]),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(child: TextField(
        controller: logic.phoneCtrl,
        keyboardType: TextInputType.phone,
        decoration: InputDecoration(hintText: hint),
      )),
    ],
  ));
}
