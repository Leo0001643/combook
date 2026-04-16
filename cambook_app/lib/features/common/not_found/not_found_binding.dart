import 'package:get/get.dart';
import 'not_found_logic.dart';

class NotFoundBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<NotFoundLogic>(() => NotFoundLogic());
  }
}
