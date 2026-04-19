import 'package:get/get.dart';
import 'logic.dart';

class OrderDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<OrderDetailLogic>(() => OrderDetailLogic(), fenix: true);
  }
}
