import 'package:get/get.dart';
import '../../../core/models/models.dart';

class ServiceActiveState {
  final Rx<OrderModel?> order  = Rx(null);
  final RxInt           nowSec = 0.obs;   // 每秒由 Timer 更新为当前 Unix 秒
  final RxBool          paused = false.obs;

  /// 服务开始的 Unix 秒（来自后端 startTime 字段）
  int? get startTimeSec {
    final st = order.value?.startTime;
    if (st == null) return null;
    return st.millisecondsSinceEpoch ~/ 1000;
  }

  /// 已服务秒数 = 当前时间 - 服务开始时间
  /// 每次访问都实时计算，不受重进页面影响
  int get elapsedSec {
    final st = startTimeSec;
    if (st == null) return nowSec.value > 0 ? 0 : 0;
    return (nowSec.value - st).clamp(0, 86400);
  }
}
