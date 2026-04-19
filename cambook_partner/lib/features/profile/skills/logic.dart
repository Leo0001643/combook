import 'package:get/get.dart';
import '../../../core/i18n/l10n_ext.dart';
import '../../../core/services/user_service.dart';
import '../../../core/utils/toast_util.dart';
import 'state.dart';

class SkillsLogic extends GetxController {
  final SkillsState state = SkillsState();

  @override
  void onInit() {
    super.onInit();
    final skills = Get.find<UserService>().technician.value?.skills ?? [];
    state.skills.assignAll(skills);
  }

  void toggle(int id) {
    final i = state.skills.indexWhere((s) => s.id == id);
    if (i >= 0) {
      state.skills[i].enabled = !state.skills[i].enabled;
      state.skills.refresh();
      ToastUtil.success(gL10n.success);
    }
  }
}
