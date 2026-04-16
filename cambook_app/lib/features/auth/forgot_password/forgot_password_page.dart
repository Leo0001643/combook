import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/routes/app_routes.dart';
import '../../../l10n/app_localizations.dart';
import 'forgot_password_logic.dart';

/// 忘记密码：手机验证 → 设置新密码
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  static const _countryCodes = [
    {'flag': '🇰🇭', 'code': '+855', 'name': 'Cambodia'},
    {'flag': '🇨🇳', 'code': '+86', 'name': 'China'},
    {'flag': '🇻🇳', 'code': '+84', 'name': 'Vietnam'},
  ];

  final _phoneCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _newPwdCtrl = TextEditingController();
  final _confirmPwdCtrl = TextEditingController();

  int _step = 0;
  String _countryCode = '+855';
  bool _obscureNew    = true;
  bool _obscureConfirm = true;

  ForgotPasswordLogic get _logic => Get.find<ForgotPasswordLogic>();

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _codeCtrl.dispose();
    _newPwdCtrl.dispose();
    _confirmPwdCtrl.dispose();
    super.dispose();
  }

  void _sendCode(AppLocalizations l) {
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.phonePlaceholder)));
      return;
    }
    _logic.state.phone.value       = phone;
    _logic.state.countryCode.value = _countryCode;

    _logic.sendSmsCode().then((_) {
      if (mounted && _logic.state.smsCode.value.isNotEmpty) {
        _codeCtrl.text = _logic.state.smsCode.value;
      }
    });
  }

  void _goStep2(AppLocalizations l) {
    final phone = _phoneCtrl.text.trim();
    final code  = _codeCtrl.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.phonePlaceholder)));
      return;
    }
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.verifyCodePlaceholder)));
      return;
    }
    _logic.state.phone.value       = phone;
    _logic.state.countryCode.value = _countryCode;
    _logic.state.smsCode.value     = code;
    setState(() => _step = 1);
  }

  _PwdStrength _pwdStrength(String s) {
    if (s.length < 6) return _PwdStrength.weak;
    final hasLetter = RegExp(r'[A-Za-z]').hasMatch(s);
    final hasDigit = RegExp(r'\d').hasMatch(s);
    final hasSpecial = RegExp(r'[^A-Za-z0-9]').hasMatch(s);
    var score = 0;
    if (s.length >= 8) score++;
    if (s.length >= 10) score++;
    if (hasLetter && hasDigit) score++;
    if (hasSpecial) score++;
    if (score >= 4) return _PwdStrength.strong;
    if (score >= 2) return _PwdStrength.medium;
    return _PwdStrength.weak;
  }

  void _submitNewPassword(AppLocalizations l) {
    final p = _newPwdCtrl.text;
    final c = _confirmPwdCtrl.text;
    if (p.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.passwordPlaceholder)));
      return;
    }
    if (p != c) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.confirmPassword)));
      return;
    }
    _logic.state.newPassword.value = p;
    _logic.state.confirmPwd.value  = c;
    _logic.resetPassword();
  }

  void _showCountryPicker(AppLocalizations l) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.gray300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              l.selectCountry,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 8),
          ..._countryCodes.map((country) {
            final code = country['code']!;
            return ListTile(
              leading: Text(country['flag']!, style: const TextStyle(fontSize: 24)),
              title: Text(country['name']!, style: const TextStyle(fontSize: 14)),
              trailing: Text(code, style: const TextStyle(color: AppTheme.gray500, fontSize: 13)),
              selected: _countryCode == code,
              selectedTileColor: AppTheme.primaryLight,
              onTap: () {
                setState(() => _countryCode = code);
                Navigator.pop(ctx);
              },
            );
          }),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: Text(l.resetPasswordTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStepHeader(l),
            const SizedBox(height: 24),
            if (_step == 0) _buildStep1(l) else _buildStep2(l),
            const SizedBox(height: 28),
            TextButton(
              onPressed: () => Get.offAllNamed(AppRoutes.login),
              child: Text(l.backToLogin, style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepHeader(AppLocalizations l) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.stepIndicator(_step + 1, 2),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.primaryColor),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _stepDot(0, l.resetPasswordStepVerify),
            Expanded(child: Container(height: 2, color: _step >= 1 ? AppTheme.primaryColor : AppTheme.gray300)),
            _stepDot(1, l.resetPasswordStepNewPwd),
          ],
        ),
      ],
    );
  }

  Widget _stepDot(int index, String label) {
    final active = _step >= index;
    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? AppTheme.primaryColor : AppTheme.gray300,
          ),
          child: Text(
            '${index + 1}',
            style: TextStyle(
              color: active ? Colors.white : AppTheme.gray600,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 88,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: active ? AppTheme.gray900 : AppTheme.gray500),
          ),
        ),
      ],
    );
  }

  Widget _buildStep1(AppLocalizations l) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () => _showCountryPicker(l),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.gray300),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _countryCodes.firstWhere((c) => c['code'] == _countryCode)['flag']!,
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(width: 4),
                    Text(_countryCode, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    const Icon(Icons.arrow_drop_down, size: 18, color: AppTheme.gray500),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: l.phonePlaceholder,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppTheme.gray300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppTheme.gray300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _codeCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: l.verifyCodePlaceholder,
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.shield_outlined, color: AppTheme.primaryColor, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppTheme.gray300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppTheme.gray300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Obx(() {
              final cd = _logic.state.countdown.value;
              return SizedBox(
                width: 118,
                height: 52,
                child: ElevatedButton(
                  onPressed: cd > 0 ? null : () => _sendCode(l),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppTheme.gray300,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    cd > 0 ? l.resendCountdown(cd) : l.sendCode,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }),
          ],
        ),
        const SizedBox(height: 28),
        ElevatedButton(
          onPressed: () => _goStep2(l),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          child: Text(l.next, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _buildStep2(AppLocalizations l) {
    return AnimatedBuilder(
      animation: Listenable.merge([_newPwdCtrl, _confirmPwdCtrl]),
      builder: (context, _) {
        final s = _pwdStrength(_newPwdCtrl.text);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _newPwdCtrl,
              obscureText: _obscureNew,
              decoration: InputDecoration(
                labelText: l.newPassword,
                hintText: l.passwordPlaceholder,
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.primaryColor, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: AppTheme.gray500,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscureNew = !_obscureNew),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppTheme.gray300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppTheme.gray300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(l.passwordStrengthLabel, style: const TextStyle(fontSize: 12, color: AppTheme.gray600)),
                const SizedBox(width: 8),
                _strengthChip(_PwdStrength.weak, s == _PwdStrength.weak, l.passwordWeak),
                const SizedBox(width: 6),
                _strengthChip(_PwdStrength.medium, s == _PwdStrength.medium, l.passwordMedium),
                const SizedBox(width: 6),
                _strengthChip(_PwdStrength.strong, s == _PwdStrength.strong, l.passwordStrong),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmPwdCtrl,
              obscureText: _obscureConfirm,
              decoration: InputDecoration(
                labelText: l.confirmPassword,
                hintText: l.confirmPassword,
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.primaryColor, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: AppTheme.gray500,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppTheme.gray300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppTheme.gray300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: () => _submitNewPassword(l),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: Text(l.confirmResetPassword, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ],
        );
      },
    );
  }

  Widget _strengthChip(_PwdStrength value, bool selected, String text) {
    Color bg;
    Color fg;
    if (selected) {
      switch (value) {
        case _PwdStrength.weak:
          bg = AppTheme.errorColor.withValues(alpha: 0.12);
          fg = AppTheme.errorColor;
          break;
        case _PwdStrength.medium:
          bg = AppTheme.warningColor.withValues(alpha: 0.15);
          fg = AppTheme.warningColor;
          break;
        case _PwdStrength.strong:
          bg = AppTheme.successColor.withValues(alpha: 0.12);
          fg = AppTheme.successColor;
          break;
      }
    } else {
      bg = AppTheme.gray200;
      fg = AppTheme.gray500;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
    );
  }
}

enum _PwdStrength { weak, medium, strong }
