import 'package:get/get.dart';
import 'logic.dart';

class IncomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<IncomeLogic>(() => IncomeLogic());
  }
}
