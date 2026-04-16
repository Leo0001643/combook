import 'package:get/get.dart';
import 'technician_list_logic.dart';

class TechnicianListBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TechnicianListLogic>(() => TechnicianListLogic());
  }
}
