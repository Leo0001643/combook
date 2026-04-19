import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/i18n/l10n_ext.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/common_widgets.dart';
import '../auth_shared.dart';
import 'logic.dart';

const _kLoginCountries = [
  ('+855', '🇰🇭', 'Cambodia'), ('+1',  '🇺🇸', 'USA / Canada'),
  ('+84',  '🇻🇳', 'Vietnam'),  ('+82', '🇰🇷', 'Korea'),
  ('+81',  '🇯🇵', 'Japan'),    ('+86', '🇨🇳', 'China'),
  ('+66',  '🇹🇭', 'Thailand'), ('+65', '🇸🇬', 'Singapore'),
  ('+60',  '🇲🇾', 'Malaysia'), ('+62', '🇮🇩', 'Indonesia'),
  ('+44',  '🇬🇧', 'UK'),       ('+61', '🇦🇺', 'Australia'),
];

// ─────────────────────────────────────────────────────────────────────────────
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late final LoginLogic _logic = Get.find<LoginLogic>();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF4F5FA),
      endDrawer: AuthMoreDrawer(onLangChanged: _logic.changeLocale),

      // ── AppBar ─────────────────────────────────────────────────────────────
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: false,
        titleSpacing: 12,
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
        title: const AuthAppBarBrand(),
        actions: [
          // 公告
          IconButton(
            icon: const Icon(Icons.notifications_outlined,
                color: Colors.white, size: 22),
            onPressed: () => AppToast.info(l.comingSoon),
          ),
          // 语言
          LangMenuButton(onChanged: _logic.changeLocale),
          // 更多（横向三点）
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
        // Hero 渐变区
        AuthHeroSection(title: l.loginTitle, subtitle: l.loginSubtitle),

        // 白色表单区（Expanded 填满剩余屏幕）
        Expanded(child: _FormArea(
          logic: _logic,
          onCountryTap: () => _showCountryPicker(context),
          onForgotPassword: () => _showForgotPassword(context),
        )),
      ]),
    );
  }

  void _showCountryPicker(BuildContext context) {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent,
      builder: (_) => AuthCountrySheet(
        countries: _kLoginCountries,
        title: context.l10n.selectCountry,
        onSelect: _logic.setCountry,
      ),
    );
  }

  void _showForgotPassword(BuildContext context) {
    final l    = context.l10n;
    final ctrl = TextEditingController();
    AppSheet.show(
      title: l.forgotPasswordTitle,
      isScrollControlled: true,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
            20, 8, 20, MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(l.forgotPasswordDesc,
              style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
              textAlign: TextAlign.center),
          const SizedBox(height: 20),
          TextField(
            controller: ctrl,
            keyboardType: TextInputType.phone,
            autofocus: true,
            decoration: InputDecoration(
              labelText: l.phone, hintText: l.phoneHint,
              prefixIcon: const Icon(Icons.phone_rounded, size: 18),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (ctrl.text.trim().isEmpty) return;
                final phone = ctrl.text.trim();
                ctrl.dispose();
                Get.back();
                Future.delayed(const Duration(milliseconds: 200),
                    () => AppToast.success(l.otpSent(phone)));
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(l.sendOtp),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 表单区（白色卡片 + 微阴影）
// ─────────────────────────────────────────────────────────────────────────────
class _FormArea extends StatelessWidget {
  final LoginLogic logic;
  final VoidCallback onCountryTap;
  final VoidCallback onForgotPassword;
  const _FormArea({
    required this.logic,
    required this.onCountryTap,
    required this.onForgotPassword,
  });

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Container(
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
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // ── 登录方式 Tabs ───────────────────────────────────────────────
          Obx(() => _GradientTabs(
            mode: logic.state.mode.value,
            labels: [l.loginTabPhone, l.loginTabTechId],
            onTap: logic.setMode,
          )),
          const SizedBox(height: 26),

          // ── 账号输入 ────────────────────────────────────────────────────
          Obx(() => AuthFieldLabel(
            logic.state.mode.value == 0 ? l.phone : l.fieldTechId,
          )),
          const SizedBox(height: 8),
          Obx(() => logic.state.mode.value == 0
              ? _PhoneRow(
                  logic: logic, hint: l.phoneHint, onTap: onCountryTap)
              : _InputBox(
                  controller: logic.accountCtrl,
                  hint: l.techIdHint,
                  icon: Icons.badge_rounded,
                )),
          const SizedBox(height: 20),

          // ── 密码 ────────────────────────────────────────────────────────
          AuthFieldLabel(l.password),
          const SizedBox(height: 8),
          Obx(() => AuthPasswordField(
            controller: logic.passCtrl,
            hint: l.passwordHint,
            obscure: logic.state.obscure.value,
            onToggle: logic.toggleObscure,
          )),

          // ── 忘记密码 ────────────────────────────────────────────────────
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onForgotPassword,
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(l.forgotPassword,
                  style: const TextStyle(
                      color: AppColors.primary, fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 20),

          // ── 登录按钮 ────────────────────────────────────────────────────
          Obx(() => AuthGradientButton(
            loading: logic.state.loading.value,
            label: l.loginBtn,
            onTap: logic.login,
          )),
          const SizedBox(height: 28),

          // ── 分隔 + 注册入口 ─────────────────────────────────────────────
          const _RegisterRow(),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 渐变活动态 Tabs
// ─────────────────────────────────────────────────────────────────────────────
class _GradientTabs extends StatelessWidget {
  final int mode;
  final List<String> labels;
  final ValueChanged<int> onTap;
  const _GradientTabs(
      {required this.mode, required this.labels, required this.onTap});

  @override
  Widget build(BuildContext context) => Container(
    height: 48,
    decoration: BoxDecoration(
      color: const Color(0xFFF0F1F7),
      borderRadius: BorderRadius.circular(14),
    ),
    padding: const EdgeInsets.all(4),
    child: Row(children: List.generate(labels.length, (i) {
      final active = mode == i;
      return Expanded(child: GestureDetector(
        onTap: () => onTap(i),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            gradient: active
                ? const LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [Color(0xFF5048E8), Color(0xFF7C3AED)])
                : null,
            borderRadius: BorderRadius.circular(11),
            boxShadow: active
                ? [const BoxShadow(
                    color: Color(0x404F46E5),
                    blurRadius: 10, offset: Offset(0, 3))]
                : null,
          ),
          child: Center(child: Text(labels[i],
              style: TextStyle(
                fontSize: 13,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: active ? Colors.white : const Color(0xFF9CA3AF),
              ))),
        ),
      ));
    })),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// 普通输入框
// ─────────────────────────────────────────────────────────────────────────────
class _InputBox extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  const _InputBox(
      {required this.controller, required this.hint, required this.icon});

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    decoration: InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 18, color: const Color(0xFFADB5C8)),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// 手机号行（国旗 + 号码输入）
// ─────────────────────────────────────────────────────────────────────────────
class _PhoneRow extends StatelessWidget {
  final LoginLogic logic;
  final String hint;
  final VoidCallback onTap;
  const _PhoneRow(
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
        controller: logic.accountCtrl,
        keyboardType: TextInputType.phone,
        decoration: InputDecoration(hintText: hint),
      )),
    ],
  ));
}

// ─────────────────────────────────────────────────────────────────────────────
// 注册入口行（分隔 + 按钮）
// ─────────────────────────────────────────────────────────────────────────────
class _RegisterRow extends StatelessWidget {
  const _RegisterRow();

  @override
  Widget build(BuildContext context) {
    final loc = context.l10n;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        const Expanded(child: Divider(color: Color(0xFFEEF0F6))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(loc.noAccount,
              style: const TextStyle(
                  color: Color(0xFFADB5C8), fontSize: 12,
                  fontWeight: FontWeight.w500)),
        ),
        const Expanded(child: Divider(color: Color(0xFFEEF0F6))),
      ]),
      const SizedBox(height: 14),
      OutlinedButton(
        onPressed: () => Get.toNamed(AppRoutes.register),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
        ),
        child: Text(loc.goRegister,
            style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700, fontSize: 15)),
      ),
    ]);
  }
}
