import 'package:get/get.dart';
import 'merchant_home_logic.dart';

class MerchantHomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MerchantHomeLogic>(() => MerchantHomeLogic());
  }
}
