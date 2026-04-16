import 'package:get/get.dart';
import 'create_order_logic.dart';

class CreateOrderBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CreateOrderLogic>(() => CreateOrderLogic());
  }
}
