import 'package:get/get.dart';
import '../../../core/events/app_events.dart';
import '../../../core/mock/mock_data.dart';
import '../../../core/models/models.dart';
import '../../../core/services/user_service.dart';
import '../../../core/utils/event_bus_util.dart';
import 'state.dart';

class IncomeLogic extends GetxController {
  final IncomeState state = IncomeState();

  final List<dynamic> _subs = [];

  List<IncomeRecordModel> get records => MockData.incomeRecords;
  List<IncomeTrendModel>  get trend   =>
      state.period.value == 0 ? MockData.trend7 : MockData.trend30;

  @override
  void onInit() {
    super.onInit();
    _computeStats();
    // 订单完成 / 余额变化时刷新收入统计
    _subs.add(EventBusUtil.listen<ServiceCompletedEvent>((_) => _computeStats()));
    _subs.add(EventBusUtil.listen<BalanceChangedEvent>((_) => _computeStats()));
    ever(Get.find<UserService>().technician, (_) => _computeStats());
  }

  @override
  void onClose() {
    for (final s in _subs) { s.cancel(); }
    _subs.clear();
    super.onClose();
  }

  void _computeStats() {
    final rs = records;
    state.todayIncome.value = rs.where(_isToday).fold(0.0, (s, r) => s + r.amount);
    state.weekIncome.value  = rs.where((r) => _within(r.date, 7)).fold(0.0, (s, r) => s + r.amount);
    state.monthIncome.value = rs.where((r) => _within(r.date, 30)).fold(0.0, (s, r) => s + r.amount);
    state.balance.value     = Get.find<UserService>().technician.value?.balance ?? 0;
  }

  void setPeriod(int p) => state.period.value = p;

  bool _isToday(IncomeRecordModel r) {
    final n = DateTime.now();
    return r.date.year == n.year && r.date.month == n.month && r.date.day == n.day;
  }
  bool _within(DateTime d, int days) => DateTime.now().difference(d).inDays < days;
}
