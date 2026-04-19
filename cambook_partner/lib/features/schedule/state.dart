import 'package:get/get.dart';

class ScheduleState {
  final RxInt       selectedDay  = DateTime.now().weekday.obs;
  final RxList<int> workDays     = <int>[1,2,3,4,5].obs;
  final RxBool      loading      = false.obs;
  final RxString    workStart    = '09:00'.obs;
  final RxString    workEnd      = '21:00'.obs;
}
