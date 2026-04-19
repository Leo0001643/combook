import 'package:get/get.dart';
import '../../../core/mock/mock_data.dart';
import '../../../core/models/models.dart';
import '../../../core/utils/toast_util.dart';
import 'state.dart';
import '../../core/i18n/l10n_ext.dart';

class ScheduleLogic extends GetxController {
  final ScheduleState state = ScheduleState();

  List<AppointmentModel> get appointments => MockData.appointments;

  String dayName(int d) {
    final names = [
      '', gL10n.weekdayMon, gL10n.weekdayTue, gL10n.weekdayWed,
      gL10n.weekdayThu, gL10n.weekdayFri, gL10n.weekdaySat, gL10n.weekdaySun,
    ];
    return names[d];
  }
  bool isWorkDay(int d) => state.workDays.contains(d);

  void toggleWorkDay(int d) {
    if (state.workDays.contains(d)) {
      if (state.workDays.length <= 1) { ToastUtil.warning(gL10n.scheduleTitle); return; }
      state.workDays.remove(d);
    } else {
      state.workDays.add(d);
    }
    ToastUtil.success(gL10n.success);
  }

  void setWorkTime(String start, String end) {
    state.workStart.value = start;
    state.workEnd.value   = end;
    ToastUtil.success('${gL10n.workHours}: $start ~ $end');
  }
}
