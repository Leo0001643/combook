import 'package:get/get.dart';
import 'order_track_logic.dart';

class OrderTrackBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<OrderTrackLogic>(() => OrderTrackLogic());
  }
}
