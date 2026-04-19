import 'package:get/get.dart';
import 'logic.dart';

class OrderListBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<OrderListLogic>(() => OrderListLogic());
  }
}
