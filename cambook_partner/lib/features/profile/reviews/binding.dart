import 'package:get/get.dart';
import 'logic.dart';

class ReviewsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ReviewsLogic>(() => ReviewsLogic(), fenix: true);
  }
}
