import 'package:get/get.dart';
import 'terms_logic.dart';

class TermsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TermsLogic>(() => TermsLogic());
  }
}
