import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/i18n/l10n_ext.dart';
import '../../../core/mock/mock_data.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/user_service.dart';
import '../../../core/utils/toast_util.dart';
import 'state.dart';

class RegisterLogic extends GetxController {
  final RegisterState state = RegisterState();

  // ── 表单控制器 ─────────────────────────────────────────────────
  final nameCtrl         = TextEditingController();
  final phoneCtrl        = TextEditingController();
  final emailCtrl        = TextEditingController();
  final passCtrl         = TextEditingController();
  final confirmCtrl      = TextEditingController();
  final telegramCtrl     = TextEditingController();
  final facebookCtrl     = TextEditingController();
  final merchantCodeCtrl = TextEditingController();

  @override
  void onClose() {
    nameCtrl.dispose();       phoneCtrl.dispose();
    emailCtrl.dispose();      passCtrl.dispose();
    confirmCtrl.dispose();    telegramCtrl.dispose();
    facebookCtrl.dispose();   merchantCodeCtrl.dispose();
    super.onClose();
  }

  void togglePass()    => state.obscurePass.value    = !state.obscurePass.value;
  void toggleConfirm() => state.obscureConfirm.value = !state.obscureConfirm.value;

  void setCountry(String code, String flag) {
    state.countryCode.value = code;
    state.countryFlag.value = flag;
  }

  // ── 验证 ────────────────────────────────────────────────────────
  bool _validate() {
    final l = gL10n;
    if (nameCtrl.text.trim().isEmpty) { ToastUtil.warning(l.fullNameRequired); return false; }
    if (phoneCtrl.text.trim().isEmpty) { ToastUtil.warning(l.phoneRequired); return false; }
    if (!_isValidPhone(phoneCtrl.text.trim())) { ToastUtil.warning(l.invalidPhone); return false; }
    if (!_isValidEmail(emailCtrl.text.trim())) { ToastUtil.warning(l.invalidEmail); return false; }
    if (passCtrl.text.length < 6) { ToastUtil.warning(l.passwordTooShort); return false; }
    if (passCtrl.text != confirmCtrl.text) { ToastUtil.warning(l.passwordMismatch); return false; }
    if (merchantCodeCtrl.text.trim().isEmpty) { ToastUtil.warning(l.merchantCodeRequired); return false; }
    return true;
  }

  bool _isValidPhone(String p) => RegExp(r'^\d{6,15}$').hasMatch(p.replaceAll(RegExp(r'[\s\-]'), ''));
  bool _isValidEmail(String e) => e.isEmpty || RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(e);

  // ── 注册 ────────────────────────────────────────────────────────
  Future<void> register() async {
    if (!_validate()) return;
    state.loading.value = true;
    try {
      await Future.delayed(const Duration(milliseconds: 900)); // 正式版 → HttpUtil.post
      // 正式版:
      // await HttpUtil.instance.post(ApiEndpoints.register, data: {
      //   'name': nameCtrl.text.trim(),
      //   'phone': '${state.countryCode.value}${phoneCtrl.text.trim()}',
      //   'email': emailCtrl.text.trim(),
      //   'password': passCtrl.text,
      //   'telegram': telegramCtrl.text.trim(),
      //   'facebook': facebookCtrl.text.trim(),
      //   'merchantCode': merchantCodeCtrl.text.trim(),
      //   'merchantId': AppConfig.merchantId,
      // });

      // Mock: 直接登录（注册+自动登录演示）
      Get.find<UserService>().login(MockData.technician, 'mock_token_register');
      ToastUtil.success(gL10n.registerSuccess);
      Get.offAllNamed(AppRoutes.main);
    } catch (e) {
      ToastUtil.error(gL10n.registerFailed);
    } finally {
      state.loading.value = false;
    }
  }
}
