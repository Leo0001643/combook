import 'package:get/get.dart';
import 'usdt_payment_logic.dart';

class UsdtPaymentBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<UsdtPaymentLogic>(() => UsdtPaymentLogic());
  }
}
