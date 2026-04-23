import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/config/app_config.dart';
import '../../../core/i18n/l10n_ext.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/http_util.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/user_service.dart';
import '../../../core/utils/toast_util.dart';
import 'state.dart';

class LoginLogic extends GetxController {
  final LoginState state = LoginState();

  final accountCtrl = TextEditingController();
  final passCtrl    = TextEditingController();

  @override
  void onClose() {
    accountCtrl.dispose();
    passCtrl.dispose();
    super.onClose();
  }

  void setMode(int m) => state.mode.value = m;
  void toggleObscure() => state.obscure.value = !state.obscure.value;

  void setCountry(String code, String flag) {
    state.countryCode.value = code;
    state.countryFlag.value = flag;
  }

  Future<void> login() async {
    final account = accountCtrl.text.trim();
    final pass    = passCtrl.text;
    final l       = gL10n;

    if (account.isEmpty) {
      ToastUtil.warning(state.mode.value == 0 ? l.phoneRequired : l.techIdRequired);
      return;
    }
    if (pass.isEmpty) { ToastUtil.warning(l.passwordRequired); return; }

    state.loading.value = true;
    try {
      final isPhone = state.mode.value == 0;
      final fullAccount = isPhone
          ? '${state.countryCode.value}$account'
          : account;

      final data = await HttpUtil.post<Map<String, dynamic>>(
        ApiEndpoints.techLogin,
        data: {
          'loginType':  isPhone ? 'phone' : 'techId',
          'account':    fullAccount,
          'password':   pass,
          'merchantId': AppConfig.merchantId,
          'lang':       Get.locale?.languageCode ?? 'zh',
        },
      );

      final token     = data['token'] as String;
      final techInfo  = Map<String, dynamic>.from(data);

      Get.find<StorageService>().saveToken(token);
      Get.find<UserService>().loginFromApi(techInfo, token);

      ToastUtil.success(l.loginSuccess);
      Get.offAllNamed(AppRoutes.main);
    } on ApiException catch (e) {
      ToastUtil.error(e.message);
    } catch (_) {
      ToastUtil.error(l.loginFailed);
    } finally {
      state.loading.value = false;
    }
  }

  void changeLocale(String code) {
    Get.find<StorageService>().saveLocale(code);
    Get.updateLocale(Locale(code));
  }
}
