import 'package:get/get.dart';
import 'coupon_logic.dart';

class CouponBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CouponLogic>(() => CouponLogic());
  }
}
