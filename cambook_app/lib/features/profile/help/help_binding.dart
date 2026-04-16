import 'package:get/get.dart';
import 'help_logic.dart';

class HelpBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HelpLogic>(() => HelpLogic());
  }
}
