import 'package:get/get.dart';
import '../../../core/models/models.dart';

class ServiceActiveState {
  final Rx<OrderModel?> order   = Rx(null);
  final RxInt           elapsed = 0.obs;  // seconds
  final RxBool          paused  = false.obs;
}
