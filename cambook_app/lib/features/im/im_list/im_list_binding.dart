import 'package:get/get.dart';
import 'im_list_logic.dart';

class ImListBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ImListLogic>(() => ImListLogic());
  }
}
