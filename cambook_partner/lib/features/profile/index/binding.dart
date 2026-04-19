import 'package:get/get.dart';
import 'logic.dart';

class ProfileIndexBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ProfileIndexLogic>(() => ProfileIndexLogic());
  }
}
