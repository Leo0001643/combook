import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/i18n/l10n_ext.dart';
import '../../../core/mock/mock_data.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/user_service.dart';
import '../../../core/utils/toast_util.dart';
import 'state.dart';

class LoginLogic extends GetxController {
  final LoginState state = LoginState();

  final accountCtrl = TextEditingController(); // phone OR techId
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
      await Future.delayed(const Duration(milliseconds: 800));
      // 正式版:
      // final res = await HttpUtil.instance.post(ApiEndpoints.login, data: {
      //   'account': state.mode.value == 0
      //       ? '${state.countryCode.value}$account' : account,
      //   'loginType': state.mode.value == 0 ? 'phone' : 'techId',
      //   'password': pass,
      //   'merchantId': AppConfig.merchantId,
      // });
      Get.find<UserService>().login(MockData.technician, 'mock_token_abc');
      ToastUtil.success(l.loginSuccess);
      Get.offAllNamed(AppRoutes.main);
    } catch (e) {
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
