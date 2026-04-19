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
    final order = Get.find<OrderService>().activeOrder;
    state.order.value = order;
    // 从订单 startTime 开始计时，防止重进页面时归零
    if (order?.startTime != null) {
      state.elapsed.value = DateTime.now().difference(order!.startTime!).inSeconds;
    }
    _startTimer();
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!state.paused.value) state.elapsed.value++;
    });
  }

  void togglePause() => state.paused.value = !state.paused.value;

  void callCustomer() {
    final phone = state.order.value?.customer.phone;
    if (phone == null) return;
    // 正式版：launchUrl(Uri(scheme: 'tel', path: phone.replaceAll(' ', '')))
    AppToast.info(phone);
  }

  Future<void> complete() async {
    final ok = await ToastUtil.confirm(gL10n.endService, gL10n.endServiceConfirm, okText: gL10n.confirm);
    if (!ok) return;
    final id = state.order.value?.id;
    if (id != null) {
      Get.find<OrderService>().complete(id);
      final still = Get.find<OrderService>().activeOrder;
      if (still == null) Get.find<UserService>().setStatus(TechStatus.online);
    }
    ToastUtil.success(gL10n.success);
    Get.offAllNamed(AppRoutes.main);
  }
}
