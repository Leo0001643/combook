import 'dart:async';
import '../../../core/widgets/app_dialog.dart';
import 'package:get/get.dart';
import '../../../core/models/models.dart';
import '../../../core/services/order_service.dart';
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

  /// 应用订单数据并立即更新 nowSec
  void _applyOrder(OrderModel? order) {
    state.order.value = order;
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
        state.order.value = fresh;
        // 刷新后重新对齐 nowSec，消除拉取期间的细微偏差
        state.nowSec.value = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      }
    } catch (_) {
      // 静默失败：保留内存缓存值继续计时
    }
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
