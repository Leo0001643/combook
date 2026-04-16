import 'package:get/get.dart';
import 'aba_payment_logic.dart';

class AbaPaymentBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AbaPaymentLogic>(() => AbaPaymentLogic());
  }
}
