import 'package:get/get.dart';
import 'logic.dart';

class ScheduleBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ScheduleLogic>(() => ScheduleLogic(), fenix: true);
  }
}
