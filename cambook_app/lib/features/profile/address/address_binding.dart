import 'package:get/get.dart';
import 'address_logic.dart';

class AddressBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AddressLogic>(() => AddressLogic());
  }
}
