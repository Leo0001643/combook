import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/i18n/l10n_ext.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/common_widgets.dart';
import '../auth_shared.dart';
import 'logic.dart';

const _kLoginCountries = [
  ('+855', '🇰🇭', 'Cambodia'),   ('+63',  '🇵🇭', 'Philippines'),
  ('+1',   '🇺🇸', 'USA/Canada'), ('+84',  '🇻🇳', 'Vietnam'),
  ('+82',  '🇰🇷', 'Korea'),      ('+81',  '🇯🇵', 'Japan'),
  ('+86',  '🇨🇳', 'China'),      ('+66',  '🇹🇭', 'Thailand'),
  ('+65',  '🇸🇬', 'Singapore'),  ('+60',  '🇲🇾', 'Malaysia'),
  ('+62',  '🇮🇩', 'Indonesia'),  ('+44',  '🇬🇧', 'UK'),
  ('+61',  '🇦🇺', 'Australia'),
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
    final l   = context.l10n;
    final mq  = MediaQuery.of(context);
    final top = mq.padding.top;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFF3730A3),
      endDrawer: AuthMoreDrawer(onLangChanged: _logic.changeLocale),
      body: Stack(children: [

        // ── 渐变背景 ────────────────────────────────────────────────────────
        Positioned.fill(child: _Background()),

        // ── 主体 ────────────────────────────────────────────────────────────
        Column(children: [
          SizedBox(height: top + 8),

          // AppBar 行
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(children: [
              const Expanded(child: AuthAppBarBrand()),
              BounceTap(
                pressScale: 0.80,
                onTap: () => AppToast.info(l.comingSoon),
                child: const Padding(
                  padding: EdgeInsets.all(10),
                  child: Icon(Icons.notifications_outlined, color: Colors.white70, size: 22),
                ),
              ),
              LangMenuButton(onChanged: _logic.changeLocale),
              BounceTap(
                pressScale: 0.80,
                onTap: () => _scaffoldKey.currentState?.openEndDrawer(),
                child: const Padding(
                  padding: EdgeInsets.all(10),
                  child: Icon(Icons.more_horiz_rounded, color: Colors.white70, size: 24),
                ),
              ),
              const SizedBox(width: 4),
            ]),
          ),

          // 品牌区
          SizedBox(
            height: 152,
            child: _BrandSection(subtitle: l.loginSubtitle),
          ),

          // 表单卡片（撑满底部）
          Expanded(child: _FormCard(
            logic: _logic,
            onCountryTap: () => _showCountryPicker(context),
            onForgotPassword: () => _showForgotPassword(context),
          )),
        ]),
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
// 渐变背景 + 装饰圆
// ─────────────────────────────────────────────────────────────────────────────
class _Background extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height;
    return Stack(children: [
      // 主渐变
      Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF312E81), Color(0xFF4F46E5), Color(0xFF6D28D9)],
          ),
        ),
      ),
      // 右上大装饰圆
      Positioned(
        top: -60, right: -60,
        child: Container(
          width: 240, height: 240,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.06),
          ),
        ),
      ),
      // 左侧中装饰圆
      Positioned(
        top: h * 0.18, left: -40,
        child: Container(
          width: 130, height: 130,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.04),
          ),
        ),
      ),
      // 右侧小点缀圆
      Positioned(
        top: h * 0.12, right: 30,
        child: Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 品牌区（图标 + 副标题居中）
// ─────────────────────────────────────────────────────────────────────────────
class _BrandSection extends StatelessWidget {
  final String subtitle;
  const _BrandSection({required this.subtitle});

  @override
  Widget build(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      // 图标光晕容器
      Stack(alignment: Alignment.center, children: [
        Container(
          width: 88, height: 88,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
        Container(
          width: 66, height: 66,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Color(0xFF818CF8), Color(0xFF6D28D9)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4F46E5).withValues(alpha: 0.50),
                blurRadius: 20, offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(Icons.spa_rounded, color: Colors.white, size: 32),
        ),
      ]),
      const SizedBox(height: 12),
      // 副标题居中
      Text(
        subtitle,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white70, fontSize: 13,
          fontWeight: FontWeight.w400, height: 1.4,
        ),
      ),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// 表单卡片
// ─────────────────────────────────────────────────────────────────────────────
class _FormCard extends StatelessWidget {
  final LoginLogic logic;
  final VoidCallback onCountryTap;
  final VoidCallback onForgotPassword;
  const _FormCard({
    required this.logic,
    required this.onCountryTap,
    required this.onForgotPassword,
  });

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFFF7F8FF),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(color: Color(0x28000000), blurRadius: 30, offset: Offset(0, -6)),
        ],
      ),
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [

          // 标题
          Text(l.loginTitle,
              style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.w800,
                color: Color(0xFF1E1B4B), letterSpacing: -0.3,
              )),
          const SizedBox(height: 22),

          // ── 登录方式 Tabs ──────────────────────────────────────────────
          Obx(() => _SlidingTabs(
            mode: logic.state.mode.value,
            labels: [l.loginTabPhone, l.loginTabTechId],
            onTap: logic.setMode,
          )),
          const SizedBox(height: 22),

          // ── 账号输入（带切换动画）────────────────────────────────────
          Obx(() {
            final isTechId = logic.state.mode.value == 1;
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.05, 0), end: Offset.zero,
                  ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
                  child: child,
                ),
              ),
              child: isTechId
                  ? _PremiumInput(
                      key: const ValueKey('techId'),
                      controller: logic.accountCtrl,
                      label: l.fieldTechId,
                      hint: l.techIdHint,
                      icon: Icons.badge_rounded,
                    )
                  : _PhoneInput(
                      key: const ValueKey('phone'),
                      logic: logic,
                      label: l.phone,
                      hint: l.phoneHint,
                      onCountryTap: onCountryTap,
                    ),
            );
          }),
          const SizedBox(height: 16),

          // ── 密码 ─────────────────────────────────────────────────────
          _InputLabel(l.password),
          const SizedBox(height: 8),
          Obx(() => _PasswordInput(
            controller: logic.passCtrl,
            hint: l.passwordHint,
            obscure: logic.state.obscure.value,
            onToggle: logic.toggleObscure,
          )),

          // ── 忘记密码 ─────────────────────────────────────────────────
          Align(
            alignment: Alignment.centerRight,
            child: BounceTap(
              onTap: onForgotPassword,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
                child: Text(l.forgotPassword,
                    style: const TextStyle(
                        color: AppColors.primary, fontSize: 12.5,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ),
          const SizedBox(height: 6),

          // ── 登录按钮 ─────────────────────────────────────────────────
          Obx(() => AuthGradientButton(
            loading: logic.state.loading.value,
            label: l.loginBtn,
            onTap: logic.login,
          )),
          const SizedBox(height: 30),

          // ── 分隔 + 注册入口 ──────────────────────────────────────────
          const _RegisterRow(),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 滑动 Tabs
// ─────────────────────────────────────────────────────────────────────────────
class _SlidingTabs extends StatelessWidget {
  final int mode;
  final List<String> labels;
  final ValueChanged<int> onTap;
  const _SlidingTabs({required this.mode, required this.labels, required this.onTap});

  @override
  Widget build(BuildContext context) => Container(
    height: 46,
    decoration: BoxDecoration(
      color: const Color(0xFFEEEFF8),
      borderRadius: BorderRadius.circular(14),
    ),
    padding: const EdgeInsets.all(4),
    child: Stack(children: [
      AnimatedAlign(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        alignment: mode == 0 ? Alignment.centerLeft : Alignment.centerRight,
        child: FractionallySizedBox(
          widthFactor: 1 / labels.length,
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [Color(0xFF6366F1), Color(0xFF7C3AED)],
              ),
              borderRadius: BorderRadius.circular(11),
              boxShadow: const [BoxShadow(
                color: Color(0x506366F1), blurRadius: 8, offset: Offset(0, 3),
              )],
            ),
          ),
        ),
      ),
      Row(children: List.generate(labels.length, (i) {
        final active = mode == i;
        return Expanded(child: BounceTap(
          pressScale: 0.92,
          onTap: () => onTap(i),
          child: Center(child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontSize: 13,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              color: active ? Colors.white : const Color(0xFF9CA3AF),
            ),
            child: Text(labels[i]),
          )),
        ));
      })),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// 统一输入框标签
// ─────────────────────────────────────────────────────────────────────────────
class _InputLabel extends StatelessWidget {
  final String text;
  const _InputLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
        fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF374151),
      ));
}

// ─────────────────────────────────────────────────────────────────────────────
// 精品输入框（技师编号）
// ─────────────────────────────────────────────────────────────────────────────
class _PremiumInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  const _PremiumInput({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _InputLabel(label),
      const SizedBox(height: 8),
      TextField(
        controller: controller,
        keyboardType: TextInputType.text,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, size: 18, color: const Color(0xFFADB5C8)),
        ),
      ),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// 手机号输入框（区号内嵌在同一文本框内）
// ─────────────────────────────────────────────────────────────────────────────
class _PhoneInput extends StatelessWidget {
  final LoginLogic logic;
  final String label;
  final String hint;
  final VoidCallback onCountryTap;
  const _PhoneInput({
    super.key,
    required this.logic,
    required this.label,
    required this.hint,
    required this.onCountryTap,
  });

  @override
  Widget build(BuildContext context) => Obx(() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _InputLabel(label),
      const SizedBox(height: 8),
      TextField(
        controller: logic.accountCtrl,
        keyboardType: TextInputType.phone,
        decoration: InputDecoration(
          hintText: hint,
          contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 14),
          // 区号作为 prefix（点击弹出选择器）
          prefixIcon: BounceTap(
            pressScale: 0.88,
            onTap: onCountryTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(logic.state.countryFlag.value,
                    style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 5),
                Text(logic.state.countryCode.value,
                    style: const TextStyle(
                      fontSize: 13.5, fontWeight: FontWeight.w700,
                      color: Color(0xFF374151),
                    )),
                const SizedBox(width: 2),
                const Icon(Icons.arrow_drop_down_rounded,
                    size: 16, color: Color(0xFFADB5C8)),
                const SizedBox(width: 6),
                // 分隔线
                Container(width: 1, height: 18,
                    color: const Color(0xFFDDE1EE)),
              ]),
            ),
          ),
          // 让 prefix 的点击区域不被 TextField 的 onTap 遮盖
          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        ),
      ),
    ],
  ));
}

// ─────────────────────────────────────────────────────────────────────────────
// 密码框
// ─────────────────────────────────────────────────────────────────────────────
class _PasswordInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final VoidCallback onToggle;
  const _PasswordInput({
    required this.controller,
    required this.hint,
    required this.obscure,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    obscureText: obscure,
    decoration: InputDecoration(
      hintText: hint,
      prefixIcon: const Icon(Icons.lock_rounded, size: 18,
          color: Color(0xFFADB5C8)),
      suffixIcon: BounceTap(
        pressScale: 0.82,
        onTap: onToggle,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(
            obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
            size: 18, color: const Color(0xFFADB5C8),
          ),
        ),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// 注册入口行
// ─────────────────────────────────────────────────────────────────────────────
class _RegisterRow extends StatelessWidget {
  const _RegisterRow();

  @override
  Widget build(BuildContext context) {
    final loc = context.l10n;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        const Expanded(child: Divider(color: Color(0xFFE5E7EB))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(loc.noAccount,
              style: const TextStyle(
                  color: Color(0xFFADB5C8), fontSize: 12,
                  fontWeight: FontWeight.w500)),
        ),
        const Expanded(child: Divider(color: Color(0xFFE5E7EB))),
      ]),
      const SizedBox(height: 14),
      BounceTap(
        onTap: () => Get.toNamed(AppRoutes.register),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.55), width: 1.5),
            color: AppColors.primary.withValues(alpha: 0.04),
          ),
          child: Center(child: Text(loc.goRegister,
              style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700, fontSize: 15))),
        ),
      ),
    ]);
  }
}
