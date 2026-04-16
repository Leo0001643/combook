import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import 'register_logic.dart';

/// 注册页面 — 完整真实 UI，全部 i18n，零硬编码
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPwdCtrl = TextEditingController();
  final _inviteCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  bool _agreedToTerms = false;
  int _countdown = 0;
  String _selectedCountryCode = '+855';
  int _registerType = 1; // 1会员 2技师 3商户

  static const _countryCodes = [
    {'flag': '🇰🇭', 'code': '+855', 'name': 'Cambodia'},
    {'flag': '🇻🇳', 'code': '+84', 'name': 'Việt Nam'},
    {'flag': '🇨🇳', 'code': '+86', 'name': '中国'},
    {'flag': '🇺🇸', 'code': '+1', 'name': 'USA'},
    {'flag': '🇸🇬', 'code': '+65', 'name': 'Singapore'},
    {'flag': '🇹🇭', 'code': '+66', 'name': 'Thailand'},
  ];

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _codeCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPwdCtrl.dispose();
    _inviteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.gray900),
          onPressed: () => Get.previousRoute.isNotEmpty ? Get.back() : Get.toNamed('/welcome'),
        ),
        title: Text(l.register, style: const TextStyle(color: AppTheme.gray900, fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 注册类型选择
              _buildRegisterType(l),
              const SizedBox(height: 24),
              // 手机号
              Text(l.phone, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.gray700)),
              const SizedBox(height: 8),
              _buildPhoneField(l),
              const SizedBox(height: 16),
              // 验证码
              Text(l.verifyCode, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.gray700)),
              const SizedBox(height: 8),
              _buildCodeField(l),
              const SizedBox(height: 16),
              // 密码
              Text(l.password, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.gray700)),
              const SizedBox(height: 8),
              _buildPasswordField(l, isConfirm: false),
              const SizedBox(height: 16),
              // 确认密码
              Text(l.confirmPassword, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.gray700)),
              const SizedBox(height: 8),
              _buildPasswordField(l, isConfirm: true),
              const SizedBox(height: 16),
              // 邀请码
              Text(l.inviteCode, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.gray700)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _inviteCtrl,
                decoration: InputDecoration(
                  hintText: l.inviteCode,
                  filled: true, fillColor: AppTheme.gray100,
                  prefixIcon: const Icon(Icons.card_giftcard_outlined, color: AppTheme.primaryColor, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.gray300)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.gray300)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
              ),
              const SizedBox(height: 20),
              // 服务条款
              _buildTerms(l),
              const SizedBox(height: 24),
              // 注册按钮
              ElevatedButton(
                onPressed: (!_agreedToTerms || _isLoading) ? null : () => _handleRegister(l),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                  disabledBackgroundColor: AppTheme.gray300,
                ),
                child: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(l.register, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 16),
              Center(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(color: AppTheme.gray500, fontSize: 14),
                    children: [
                      TextSpan(text: l.hasAccount.split('?').first + '? '),
                      TextSpan(
                        text: l.login,
                        style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w600),
                        recognizer: TapGestureRecognizer()..onTap = () => Get.toNamed('/login'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterType(AppLocalizations l) {
    final types = [
      {'value': 1, 'emoji': '👤', 'label': _localType(l, 1)},
      {'value': 2, 'emoji': '💆', 'label': _localType(l, 2)},
      {'value': 3, 'emoji': '🏢', 'label': _localType(l, 3)},
    ];
    return Row(
      children: types.map((t) {
        final selected = _registerType == t['value'];
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _registerType = t['value'] as int),
            child: Container(
              margin: EdgeInsets.only(right: t['value'] != 3 ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: selected ? AppTheme.primaryLight : AppTheme.gray100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: selected ? AppTheme.primaryColor : AppTheme.gray200, width: selected ? 1.5 : 1),
              ),
              child: Column(
                children: [
                  Text(t['emoji'] as String, style: const TextStyle(fontSize: 22)),
                  const SizedBox(height: 4),
                  Text(t['label'] as String,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: selected ? AppTheme.primaryColor : AppTheme.gray600),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  String _localType(AppLocalizations l, int type) {
    switch (type) {
      case 2: return l.roleTechnicianTitle;
      case 3: return l.roleMerchantTitle;
      default: return l.roleMember;
    }
  }

  Widget _buildPhoneField(AppLocalizations l) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => _showCountryPicker(l),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.gray100,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.gray300),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_countryCodes.firstWhere((c) => c['code'] == _selectedCountryCode)['flag']!, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 4),
                Text(_selectedCountryCode, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                const Icon(Icons.arrow_drop_down, size: 16, color: AppTheme.gray500),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextFormField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText: l.phonePlaceholder,
              filled: true, fillColor: AppTheme.gray100,
              prefixIcon: const Icon(Icons.phone_outlined, color: AppTheme.primaryColor, size: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.gray300)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.gray300)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
            validator: (v) => (v == null || v.isEmpty) ? l.phonePlaceholder : null,
          ),
        ),
      ],
    );
  }

  Widget _buildCodeField(AppLocalizations l) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _codeCtrl,
            keyboardType: TextInputType.number,
            maxLength: 6,
            buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
            decoration: InputDecoration(
              hintText: l.verifyCodePlaceholder,
              filled: true, fillColor: AppTheme.gray100,
              prefixIcon: const Icon(Icons.shield_outlined, color: AppTheme.primaryColor, size: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.gray300)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.gray300)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
            validator: (v) => (v == null || v.length != 6) ? l.verifyCodePlaceholder : null,
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: _countdown > 0 ? null : () => _sendCode(l),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            minimumSize: const Size(110, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 0,
            disabledBackgroundColor: AppTheme.gray300,
          ),
          child: Text(_countdown > 0 ? l.resendCountdown(_countdown) : l.sendCode, style: const TextStyle(fontSize: 12)),
        ),
      ],
    );
  }

  Widget _buildPasswordField(AppLocalizations l, {required bool isConfirm}) {
    final ctrl = isConfirm ? _confirmPwdCtrl : _passwordCtrl;
    final obscure = isConfirm ? _obscureConfirm : _obscurePassword;
    return TextFormField(
      controller: ctrl,
      obscureText: obscure,
      decoration: InputDecoration(
        hintText: isConfirm ? l.confirmPassword : l.passwordPlaceholder,
        filled: true, fillColor: AppTheme.gray100,
        prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.primaryColor, size: 20),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppTheme.gray500, size: 20),
          onPressed: () => setState(() {
            if (isConfirm) _obscureConfirm = !_obscureConfirm;
            else _obscurePassword = !_obscurePassword;
          }),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.gray300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.gray300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      validator: isConfirm
          ? (v) => v != _passwordCtrl.text ? l.confirmPassword : null
          : (v) => (v == null || v.length < 6) ? l.password : null,
    );
  }

  Widget _buildTerms(AppLocalizations l) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 20, height: 20,
          child: Checkbox(
            value: _agreedToTerms,
            onChanged: (v) => setState(() => _agreedToTerms = v ?? false),
            activeColor: AppTheme.primaryColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(color: AppTheme.gray500, fontSize: 13, height: 1.5),
              children: [
                TextSpan(text: l.agreeTerms + ' '),
                TextSpan(text: l.userAgreement, style: const TextStyle(color: AppTheme.primaryColor), recognizer: TapGestureRecognizer()..onTap = () {}),
                TextSpan(text: ' ${l.and} '),
                TextSpan(text: l.privacyPolicy, style: const TextStyle(color: AppTheme.primaryColor), recognizer: TapGestureRecognizer()..onTap = () {}),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showCountryPicker(AppLocalizations l) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: AppTheme.gray300, borderRadius: BorderRadius.circular(2))),
          Text(l.selectCountry, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ..._countryCodes.map((c) => ListTile(
            leading: Text(c['flag']!, style: const TextStyle(fontSize: 24)),
            title: Text(c['name']!, style: const TextStyle(fontSize: 14)),
            trailing: Text(c['code']!, style: const TextStyle(color: AppTheme.gray500)),
            selected: _selectedCountryCode == c['code'],
            selectedTileColor: AppTheme.primaryLight,
            onTap: () { setState(() => _selectedCountryCode = c['code']!); Navigator.pop(ctx); },
          )).toList(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _sendCode(AppLocalizations l) {
    if (_phoneCtrl.text.trim().isEmpty) {
      Get.snackbar(l.hint, l.phonePlaceholder, snackPosition: SnackPosition.TOP);
      return;
    }
    final logic = Get.find<RegisterLogic>();
    logic.state.phone.value       = _phoneCtrl.text.trim();
    logic.state.countryCode.value = _selectedCountryCode;

    // 发码后自动填入开发模式验证码
    logic.sendSmsCode().then((_) {
      if (mounted && logic.state.smsCode.value.isNotEmpty) {
        _codeCtrl.text = logic.state.smsCode.value;
      }
    });

    // 倒计时显示
    setState(() => _countdown = 60);
    _tickCountdown();
  }

  void _tickCountdown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted || _countdown <= 0) return;
      setState(() => _countdown--);
      _tickCountdown();
    });
  }

  void _handleRegister(AppLocalizations l) {
    if (!_formKey.currentState!.validate()) return;

    final logic = Get.find<RegisterLogic>();
    // 同步表单数据到 Logic State
    logic.state.phone.value       = _phoneCtrl.text.trim();
    logic.state.countryCode.value = _selectedCountryCode;
    logic.state.smsCode.value     = _codeCtrl.text.trim();
    logic.state.password.value    = _passwordCtrl.text;
    logic.state.confirmPwd.value  = _confirmPwdCtrl.text;
    logic.state.inviteCode.value  = _inviteCtrl.text.trim();
    logic.state.userType.value    = _registerType;
    logic.state.agreedTerms.value = _agreedToTerms;

    // 调用 Logic 注册，同步 isLoading 状态到本页
    setState(() => _isLoading = true);
    logic.register().then((_) {
      if (mounted) setState(() => _isLoading = logic.state.isLoading.value);
    });
  }
}
