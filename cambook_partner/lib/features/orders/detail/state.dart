import 'package:get/get.dart';
import '../../../core/models/models.dart';

class OrderDetailState {
  final Rx<OrderModel?> order   = Rx(null);
  final RxBool          loading = false.obs;
  final RxBool          arrived = false.obs;  // 到达标志（accepted → arrived → inService）
}
