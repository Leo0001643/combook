import 'package:get/get.dart';
import 'payment_logic.dart';

class PaymentBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PaymentLogic>(() => PaymentLogic());
  }
}
