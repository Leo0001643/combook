import 'package:get/get.dart';

class IncomeState {
  final RxInt    period      = 0.obs;
  final RxBool   loading     = false.obs;
  final RxDouble todayIncome = 0.0.obs;
  final RxDouble weekIncome  = 0.0.obs;
  final RxDouble monthIncome = 0.0.obs;
  final RxDouble balance     = 0.0.obs;
}
