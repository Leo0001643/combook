import 'package:get/get.dart';
import 'logic.dart';

class ServiceActiveBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ServiceActiveLogic>(() => ServiceActiveLogic(), fenix: true);
  }
}
