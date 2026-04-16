import 'package:get/get.dart';
import 'tech_home_logic.dart';

class TechHomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TechHomeLogic>(() => TechHomeLogic());
  }
}
