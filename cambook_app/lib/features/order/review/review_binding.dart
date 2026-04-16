import 'package:get/get.dart';
import 'review_logic.dart';

class ReviewBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ReviewLogic>(() => ReviewLogic());
  }
}
