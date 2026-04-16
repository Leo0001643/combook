import 'dart:async';
import 'package:get/get.dart';
import '../../../core/auth/auth_controller.dart';
import '../../../core/network/auth_api.dart';
import '../../../core/routes/app_routes.dart';
import 'verify_code_state.dart';

/// 验证码页逻辑
/// 从 Get.arguments 读取 phone 和 countryCode
class VerifyCodeLogic extends GetxController {
  final state = VerifyCodeState();

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>?;
    if (args != null) {
      state.phone.value       = args['phone'] as String? ?? '';
      state.countryCode.value = args['countryCode'] as String? ?? '+855';
    }
    // 进入页面自动发送验证码
    sendSmsCode();
  }

  Future<void> sendSmsCode() async {
    if (state.phone.value.isEmpty) return;
    try {
      await AuthApi.sendSmsCode(
        countryCode: state.countryCode.value,
        phone:       state.phone.value,
      );
    } catch (_) {
      // 忽略网络错误，开发模式继续填码
    }
    state.code.value = '888888'; // 开发模式固定验证码
    Get.snackbar('提示', '验证码已发送（开发模式：888888）', snackPosition: SnackPosition.TOP);
    _startCountdown();
  }

  void _startCountdown() {
    state.countdown.value = 60;
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.countdown.value <= 0) {
        timer.cancel();
      } else {
        state.countdown.value--;
      }
    });
  }

  Future<void> verifyAndLogin() async {
    if (state.code.value.length < 4) {
      Get.snackbar('提示', '请输入验证码', snackPosition: SnackPosition.TOP);
      return;
    }
    state.isLoading.value = true;
    try {
      final result = await AuthApi.loginBySms(
        phone:       state.phone.value,
        countryCode: state.countryCode.value,
        captcha:     state.code.value,
        language:    AuthController.to.languageCode,
      );
      if (result.isSuccess && result.data != null) {
        await AuthController.to.loginSuccess(result.data!);
      } else {
        Get.snackbar('验证失败', result.message, snackPosition: SnackPosition.TOP);
      }
    } catch (e) {
      Get.snackbar('网络错误', '请检查网络连接', snackPosition: SnackPosition.TOP);
    } finally {
      state.isLoading.value = false;
    }
  }

  void goBack()    => Get.back();
  void goToLogin() => Get.offAllNamed(AppRoutes.login);
}
