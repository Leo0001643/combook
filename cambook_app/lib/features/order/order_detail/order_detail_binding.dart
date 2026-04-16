import 'package:get/get.dart';
import 'order_detail_logic.dart';

class OrderDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<OrderDetailLogic>(() => OrderDetailLogic());
  }
}
