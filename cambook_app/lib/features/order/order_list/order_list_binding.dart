import 'package:get/get.dart';
import 'order_list_logic.dart';

class OrderListBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<OrderListLogic>(() => OrderListLogic());
  }
}
