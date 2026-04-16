import 'package:get/get.dart';
import 'payment_result_logic.dart';

class PaymentResultBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PaymentResultLogic>(() => PaymentResultLogic());
  }
}
