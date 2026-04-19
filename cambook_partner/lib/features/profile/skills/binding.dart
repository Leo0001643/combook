import 'package:get/get.dart';
import 'logic.dart';

class SkillsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SkillsLogic>(() => SkillsLogic(), fenix: true);
  }
}
