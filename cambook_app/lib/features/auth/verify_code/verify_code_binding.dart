import 'package:get/get.dart';
import 'verify_code_logic.dart';

class VerifyCodeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<VerifyCodeLogic>(() => VerifyCodeLogic());
  }
}
