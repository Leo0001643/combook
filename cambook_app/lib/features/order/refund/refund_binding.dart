import 'package:get/get.dart';
import 'refund_logic.dart';

class RefundBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RefundLogic>(() => RefundLogic());
  }
}
