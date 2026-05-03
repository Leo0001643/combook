import 'dart:async';
import '../../../core/widgets/app_dialog.dart';
import 'package:get/get.dart';
import '../../../core/models/models.dart';
import '../../../core/services/order_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/user_service.dart';
import '../../../core/utils/toast_util.dart';
import '../../../core/routes/app_routes.dart';
import 'state.dart';
import '../../../core/i18n/l10n_ext.dart';

class ServiceActiveLogic extends GetxController {
  final ServiceActiveState state = ServiceActiveState();
  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    // 1. 用内存缓存快速初始化，避免页面闪白
    _applyOrder(Get.find<OrderService>().activeOrder);
    // 2. 同步启动秒级计时器（更新 nowSec）
    _startTick();
    // 3. 后台从 API 刷新一次，确保 startTime 精准
    //    即使 app 杀死重开，也能从后端拿到正确的 service_start_time
    _syncFromApi();
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  /// 应用订单数据，并在 startTime 缺失时补全 fallback，确保计时器立即运行
  void _applyOrder(OrderModel? order) {
    state.order.value = order != null ? _withStartTime(order) : null;
    state.nowSec.value = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  }

  /// 每秒更新 nowSec；elapsed = nowSec - startTimeSec 由 state 自动计算
  void _startTick() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!state.paused.value) {
        state.nowSec.value = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      }
    });
  }

  /// 从后端拉取最新订单（包含 service_start_time），刷新 startTime
  Future<void> _syncFromApi() async {
    try {
      await Get.find<OrderService>().fetchFromApi();
      final fresh = Get.find<OrderService>().activeOrder;
      if (fresh != null) {
        state.order.value = _withStartTime(fresh);
        state.nowSec.value = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      }
    } catch (_) {
      // 静默失败：保留内存缓存值继续计时
    }
  }

  /// startTime 三级兜底：
  ///   1. 后端返回的真实 startTime（最优）
  ///   2. 本地持久化存储（跨重启/登出后恢复）
  ///   3. appointTime（预约时间，总是非空，保证计时器不归零）
  OrderModel _withStartTime(OrderModel order) {
    if (order.startTime != null) return order;
    final storage = Get.find<StorageService>();
    final storedMs = storage.getServiceStartMs(order.id);
    final fallback = storedMs != null
        ? DateTime.fromMillisecondsSinceEpoch(storedMs)
        : order.appointTime; // appointTime 始终非空（fromEpochSec fallback to now）
    storage.saveServiceStartMs(order.id, fallback);
    return order.copyWith(startTime: fallback);
  }

  void togglePause() => state.paused.value = !state.paused.value;

  Future<void> complete() async {
    final ok = await ToastUtil.confirm(gL10n.endService, gL10n.endServiceConfirm, okText: gL10n.confirm);
    if (!ok) return;
    final id = state.order.value?.id;
    if (id == null) return;
    try {
      await Get.find<OrderService>().complete(id);
    } catch (e) {
      AppToast.error(gL10n.failed);
      return;
    }
    final still = Get.find<OrderService>().activeOrder;
    if (still == null) Get.find<UserService>().setStatus(TechStatus.online);
    ToastUtil.success(gL10n.success);
    await Get.find<OrderService>().fetchFromApi();
    Get.offAllNamed(AppRoutes.main);
  }
}
