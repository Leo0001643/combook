import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:get/get.dart';
import '../../../l10n/app_localizations.dart';
import 'login_logic.dart';

const _mint = Color(0xFF4DC8AB);

/// 登录页 — 薄荷渐变背景 + "Hello!" 大标题
/// 用户类型选择（会员 / 技师 / 商户）
/// 手机号 + 验证码 / 密码 两种登录方式
class LoginPage extends GetView<LoginLogic> {
  const LoginPage({super.key});

  static const _mintLight = Color(0xFFB2E8D9);

  static const _countryCodes = [
    {'flag': '🇰🇭', 'code': '+855', 'name': 'Cambodia'},
    {'flag': '🇻🇳', 'code': '+84',  'name': 'Việt Nam'},
    {'flag': '🇨🇳', 'code': '+86',  'name': '中国'},
    {'flag': '🇺🇸', 'code': '+1',   'name': 'United States'},
    {'flag': '🇸🇬', 'code': '+65',  'name': 'Singapore'},
    {'flag': '🇹🇭', 'code': '+66',  'name': 'Thailand'},
    {'flag': '🇲🇾', 'code': '+60',  'name': 'Malaysia'},
    {'flag': '🇯🇵', 'code': '+81',  'name': 'Japan'},
  ];

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 背景渐变
          Positioned(
            top: 0, left: 0, right: 0,
            height: MediaQuery.of(context).size.height * 0.45,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFCEF0E8), Color(0xFFF7FEFA), Colors.white],
                  stops: [0.0, 0.65, 1.0],
                ),
              ),
            ),
          ),
          // 装饰圆环（右上角）
          Positioned(
            top: -20, right: -40,
            child: Container(
              width: 220, height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _mintLight.withValues(alpha: 0.35),
              ),
            ),
          ),
          Positioned(
            top: 20, right: 0,
            child: Container(
              width: 160, height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _mintLight.withValues(alpha: 0.5),
              ),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('💆‍♀️', style: TextStyle(fontSize: 48)),
                    Text('CamBook', style: TextStyle(fontSize: 10, color: Color(0xFF4DC8AB), fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                  ],
                ),
              ),
            ),
          ),
          // 主内容
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 8, top: 4),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_rounded, color: Color(0xFF555555), size: 20),
                      onPressed: controller.goBack,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(28, 0, 28, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Hello!', style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Color(0xFF222222), height: 1.1)),
                        const SizedBox(height: 4),
                        Text(l.welcomeToCamBook, style: const TextStyle(fontSize: 15, color: Color(0xFF888888), fontWeight: FontWeight.w400)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _UserTypeTabs(logic: controller, l: l),
                        const SizedBox(height: 24),
                        _LoginModeTabs(logic: controller, l: l),
                        const SizedBox(height: 20),
                        _LoginForms(logic: controller, l: l),
                        const SizedBox(height: 16),
                        _LoginBtn(logic: controller, l: l),
                        const SizedBox(height: 16),
                        _TermsRow(logic: controller, l: l),
                        const SizedBox(height: 12),
                        _RegisterLink(logic: controller, l: l),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 用户类型选择 ───────────────────────────────────────────────────────────────
class _UserTypeTabs extends StatelessWidget {
  final LoginLogic logic;
  final AppLocalizations l;
  const _UserTypeTabs({required this.logic, required this.l});

  List<Map<String, dynamic>> _types() => [
    {'value': 1, 'label': l.memberLogin},
    {'value': 2, 'label': l.technicianLogin},
    {'value': 3, 'label': l.merchantLogin},
  ];

  @override
  Widget build(BuildContext context) {
    return Obx(() => Row(
      children: _types().map((t) {
        final val      = t['value'] as int;
        final selected = logic.state.userType.value == val;
        return Expanded(
          child: GestureDetector(
            onTap: () => logic.state.userType.value = val,
            behavior: HitTestBehavior.opaque,
            child: Column(
              children: [
                Text(
                  t['label'] as String,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                    color: selected ? const Color(0xFF222222) : const Color(0xFFAAAAAA),
                  ),
                ),
                const SizedBox(height: 6),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 2.5,
                  width: selected ? 40 : 0,
                  decoration: BoxDecoration(color: _mint, borderRadius: BorderRadius.circular(2)),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    ));
  }
}

// ── 登录方式 Tab (验证码 / 密码) ───────────────────────────────────────────────
class _LoginModeTabs extends StatelessWidget {
  final LoginLogic logic;
  final AppLocalizations l;
  const _LoginModeTabs({required this.logic, required this.l});

  @override
  Widget build(BuildContext context) {
    return Obx(() => Row(
      children: [
        _tab(l.loginBySms,      true,  logic),
        const SizedBox(width: 24),
        _tab(l.loginByPassword, false, logic),
      ],
    ));
  }

  Widget _tab(String label, bool isSms, LoginLogic logic) {
    final selected = logic.state.isSmsMode.value == isSms;
    return GestureDetector(
      onTap: () => logic.state.isSmsMode.value = isSms,
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected ? _mint : const Color(0xFFBBBBBB),
            ),
          ),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 2,
            width: selected ? 48 : 0,
            color: _mint,
          ),
        ],
      ),
    );
  }
}

// ── 登录表单 ───────────────────────────────────────────────────────────────────
class _LoginForms extends StatefulWidget {
  final LoginLogic logic;
  final AppLocalizations l;
  const _LoginForms({required this.logic, required this.l});

  @override
  State<_LoginForms> createState() => _LoginFormsState();
}

class _LoginFormsState extends State<_LoginForms> {
  final _phoneCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _codeCtrl     = TextEditingController();

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  static const _countryCodes = LoginPage._countryCodes;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final logic = widget.logic;
      return Column(
        children: [
          _phoneInput(logic),
          const SizedBox(height: 14),
          if (logic.state.isSmsMode.value)
            _codeInput(logic)
          else ...[
            _passwordInput(logic),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: logic.goToForgotPassword,
                style: TextButton.styleFrom(
                  foregroundColor: _mint,
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(widget.l.forgotPassword, style: const TextStyle(fontSize: 13)),
              ),
            ),
          ],
        ],
      );
    });
  }

  Widget _phoneInput(LoginLogic logic) {
    return Container(
      height: 52,
      decoration: BoxDecoration(color: const Color(0xFFF5F6F8), borderRadius: BorderRadius.circular(26)),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _showCountryPicker(logic),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _countryCodes.firstWhere((c) => c['code'] == logic.state.countryCode.value)['flag']!,
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 4),
                  Obx(() => Text(logic.state.countryCode.value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF444444)))),
                  const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFFAAAAAA)),
                ],
              ),
            ),
          ),
          Container(width: 1, height: 22, color: const Color(0xFFDDDDDD)),
          Expanded(
            child: TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              onChanged: (v) => logic.state.phone.value = v,
              style: const TextStyle(fontSize: 15, color: Color(0xFF222222)),
              decoration: InputDecoration(
                hintText: widget.l.phonePlaceholder,
                hintStyle: const TextStyle(fontSize: 14, color: Color(0xFFCCCCCC)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _codeInput(LoginLogic logic) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 52,
            decoration: BoxDecoration(color: const Color(0xFFF5F6F8), borderRadius: BorderRadius.circular(26)),
            child: TextField(
              controller: _codeCtrl,
              keyboardType: TextInputType.number,
              onChanged: (v) => logic.state.smsCode.value = v,
              style: const TextStyle(fontSize: 15, color: Color(0xFF222222)),
              decoration: InputDecoration(
                hintText: widget.l.verifyCodePlaceholder,
                hintStyle: const TextStyle(fontSize: 14, color: Color(0xFFCCCCCC)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Obx(() => GestureDetector(
          onTap: logic.state.countdown.value > 0 ? null : logic.sendSmsCode,
          child: Text(
            logic.state.countdown.value > 0
                ? widget.l.resendCountdown(logic.state.countdown.value)
                : widget.l.sendCode,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: logic.state.countdown.value > 0 ? const Color(0xFFCCCCCC) : _mint,
            ),
          ),
        )),
      ],
    );
  }

  Widget _passwordInput(LoginLogic logic) {
    return Container(
      height: 52,
      decoration: BoxDecoration(color: const Color(0xFFF5F6F8), borderRadius: BorderRadius.circular(26)),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _passwordCtrl,
              onChanged: (v) => logic.state.password.value = v,
              obscureText: logic.state.obscurePassword.value,
              style: const TextStyle(fontSize: 15, color: Color(0xFF222222)),
              decoration: InputDecoration(
                hintText: widget.l.passwordPlaceholder,
                hintStyle: const TextStyle(fontSize: 14, color: Color(0xFFCCCCCC)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
            ),
          ),
          Obx(() => IconButton(
            onPressed: () => logic.state.obscurePassword.value = !logic.state.obscurePassword.value,
            icon: Icon(
              logic.state.obscurePassword.value ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              size: 20, color: const Color(0xFFBBBBBB),
            ),
          )),
        ],
      ),
    );
  }

  void _showCountryPicker(LoginLogic logic) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: const Color(0xFFDDDDDD), borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Text(widget.l.selectCountry, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
          const Divider(),
          ..._countryCodes.map((country) => ListTile(
            leading: Text(country['flag']!, style: const TextStyle(fontSize: 24)),
            title: Text(country['name']!, style: const TextStyle(fontSize: 14)),
            trailing: Text(country['code']!, style: const TextStyle(color: Color(0xFF888888), fontSize: 14)),
            selected: logic.state.countryCode.value == country['code'],
            selectedTileColor: const Color(0xFFF0FBF8),
            selectedColor: _mint,
            onTap: () {
              logic.state.countryCode.value = country['code']!;
              Navigator.pop(ctx);
            },
          )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ── 登录按钮 ───────────────────────────────────────────────────────────────────
class _LoginBtn extends StatelessWidget {
  final LoginLogic logic;
  final AppLocalizations l;
  const _LoginBtn({required this.logic, required this.l});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final hasInput  = logic.state.phone.value.isNotEmpty;
      final isLoading = logic.state.isLoading.value;
      return GestureDetector(
        onTap: isLoading ? null : () {
          if (logic.state.isSmsMode.value) {
            logic.loginBySms();
          } else {
            logic.loginByPassword();
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 52,
          decoration: BoxDecoration(
            gradient: hasInput
                ? const LinearGradient(colors: [Color(0xFF4DC8AB), Color(0xFF2AAF8E)])
                : null,
            color: hasInput ? null : const Color(0xFFE8E8E8),
            borderRadius: BorderRadius.circular(26),
          ),
          child: Center(
            child: isLoading
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : Text(
                    l.login,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: hasInput ? Colors.white : const Color(0xFFAAAAAA),
                    ),
                  ),
          ),
        ),
      );
    });
  }
}

// ── 协议复选框 ─────────────────────────────────────────────────────────────────
class _TermsRow extends StatelessWidget {
  final LoginLogic logic;
  final AppLocalizations l;
  const _TermsRow({required this.logic, required this.l});

  @override
  Widget build(BuildContext context) {
    return Obx(() => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => logic.state.agreedTerms.value = !logic.state.agreedTerms.value,
          child: Container(
            width: 18, height: 18,
            margin: const EdgeInsets.only(top: 1),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: logic.state.agreedTerms.value ? _mint : const Color(0xFFCCCCCC),
                width: 1.5,
              ),
              color: logic.state.agreedTerms.value ? _mint : Colors.transparent,
            ),
            child: logic.state.agreedTerms.value
                ? const Icon(Icons.check, size: 11, color: Colors.white)
                : null,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 12, color: Color(0xFF999999), height: 1.5),
              children: [
                TextSpan(text: l.agreeTerms),
                TextSpan(
                  text: l.userAgreement,
                  style: const TextStyle(color: _mint),
                  recognizer: TapGestureRecognizer()..onTap = logic.goToTerms,
                ),
                TextSpan(
                  text: l.privacyPolicy,
                  style: const TextStyle(color: _mint),
                  recognizer: TapGestureRecognizer()..onTap = logic.goToPrivacy,
                ),
                TextSpan(text: l.autoRegisterHint),
              ],
            ),
          ),
        ),
      ],
    ));
  }
}

// ── 注册链接 ───────────────────────────────────────────────────────────────────
class _RegisterLink extends StatelessWidget {
  final LoginLogic logic;
  final AppLocalizations l;
  const _RegisterLink({required this.logic, required this.l});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 14, color: Color(0xFFAAAAAA)),
          children: [
            TextSpan(text: l.noAccount),
            TextSpan(
              text: l.registerNow,
              style: const TextStyle(color: _mint, fontWeight: FontWeight.w600),
              recognizer: TapGestureRecognizer()..onTap = logic.goToRegister,
            ),
          ],
        ),
      ),
    );
  }
}
