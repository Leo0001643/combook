import 'package:get/get.dart';
import 'edit_profile_logic.dart';

class EditProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EditProfileLogic>(() => EditProfileLogic());
  }
}
