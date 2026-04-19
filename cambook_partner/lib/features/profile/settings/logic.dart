import 'dart:ui';
import 'package:get/get.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/user_service.dart';
import '../../../core/utils/toast_util.dart';
import 'state.dart';
import '../../../core/i18n/l10n_ext.dart';

class SettingsLogic extends GetxController {
  final SettingsState state = SettingsState();

  @override
  void onInit() {
    super.onInit();
    final storage = Get.find<StorageService>();
    final tech    = Get.find<UserService>().technician.value;
    state.locale.value        = storage.locale;
    state.notifyOrder.value   = storage.getNotify('order');
    state.notifyMessage.value = storage.getNotify('message');
    state.notifySystem.value  = storage.getNotify('system');
    state.nickname.value      = tech?.nickname ?? '';
    state.phone.value         = tech?.phone ?? '';
  }

  void toggleNotify(String key, bool val) {
    Get.find<StorageService>().saveNotify(key, val);
    switch (key) {
      case 'order':   state.notifyOrder.value   = val; break;
      case 'message': state.notifyMessage.value = val; break;
      case 'system':  state.notifySystem.value  = val; break;
    }
  }

  void changeLocale(String code) {
    Get.find<StorageService>().saveLocale(code);
    state.locale.value = code;
    Get.updateLocale(Locale(code));
    ToastUtil.success(gL10n.success);
  }

  void changePassword(String newPass) {
    if (newPass.length < 6) { ToastUtil.error(gL10n.passwordTooShort); return; }
    // 正式版：调用 HttpUtil.post(ApiEndpoints.changePassword, data:{newPass})
    ToastUtil.success(gL10n.success);
  }

  void saveProfile(String nickname, String phone) {
    if (nickname.isEmpty) { ToastUtil.error(gL10n.fullNameRequired); return; }
    state.nickname.value = nickname;
    state.phone.value    = phone;
    // 正式版：调用 HttpUtil.put(ApiEndpoints.profile, data:{nickname, phone})
    ToastUtil.success(gL10n.success);
  }
}
