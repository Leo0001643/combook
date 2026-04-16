import 'package:get/get.dart';
import 'technician_detail_logic.dart';

class TechnicianDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TechnicianDetailLogic>(() => TechnicianDetailLogic());
  }
}
