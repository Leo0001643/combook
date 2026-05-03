import 'package:get/get.dart';
import '../auth_theme_controller.dart';
import 'logic.dart';

class LoginBinding extends Bindings {
  @override
  void dependencies() {
    // AuthThemeController bridges to AppThemeController (app-wide permanent).
    // Register permanent so it survives route transitions.
    if (!Get.isRegistered<AuthThemeController>()) {
      Get.put<AuthThemeController>(AuthThemeController(), permanent: true);
    }
    Get.lazyPut<LoginLogic>(() => LoginLogic());
  }
}
