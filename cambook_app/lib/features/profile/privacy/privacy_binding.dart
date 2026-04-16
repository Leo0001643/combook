import 'package:get/get.dart';
import 'privacy_logic.dart';

class PrivacyBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PrivacyLogic>(() => PrivacyLogic());
  }
}
