import 'package:get/get.dart';
import 'logic.dart';

class RegisterBinding extends Bindings {
  @override
  void dependencies() {
    // AuthThemeController already permanent from LoginBinding
    Get.lazyPut<RegisterLogic>(() => RegisterLogic());
  }
}
