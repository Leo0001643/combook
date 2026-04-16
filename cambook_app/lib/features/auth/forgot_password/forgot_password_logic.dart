import 'dart:async';
import 'package:get/get.dart';
import '../../../core/network/auth_api.dart';
import '../../../core/routes/app_routes.dart';
import 'forgot_password_state.dart';

/// 忘记密码页逻辑
/// 流程：发送验证码 → 验证码 + 新密码 → 调注册/重置接口
class ForgotPasswordLogic extends GetxController {
  final state = ForgotPasswordState();

  Future<void> sendSmsCode() async {
    if (state.phone.value.isEmpty) {
      Get.snackbar('提示', '请输入手机号', snackPosition: SnackPosition.TOP);
      return;
    }
    try {
      await AuthApi.sendSmsCode(
        countryCode: state.countryCode.value,
        phone:       state.phone.value,
      );
    } catch (_) {
      // 忽略网络错误，开发模式继续填码
    }
    state.smsCode.value = '888888'; // 开发模式固定验证码
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

  Future<void> resetPassword() async {
    if (!_validate()) return;
    state.isLoading.value = true;
    try {
      final result = await AuthApi.resetPassword(
        countryCode: state.countryCode.value,
        phone:       state.phone.value,
        captcha:     state.smsCode.value,
        newPassword: state.newPassword.value,
      );
      if (result.isSuccess) {
        Get.snackbar('成功', '密码已重置，请重新登录', snackPosition: SnackPosition.TOP);
        await Future.delayed(const Duration(seconds: 1));
        Get.offAllNamed(AppRoutes.login);
      } else {
        Get.snackbar('重置失败', result.message, snackPosition: SnackPosition.TOP);
      }
    } catch (e) {
      Get.snackbar('网络错误', '请检查网络连接', snackPosition: SnackPosition.TOP);
    } finally {
      state.isLoading.value = false;
    }
  }

  bool _validate() {
    if (state.phone.value.isEmpty) {
      Get.snackbar('提示', '请输入手机号', snackPosition: SnackPosition.TOP);
      return false;
    }
    if (state.smsCode.value.isEmpty) {
      Get.snackbar('提示', '请输入验证码', snackPosition: SnackPosition.TOP);
      return false;
    }
    if (state.newPassword.value.length < 6) {
      Get.snackbar('提示', '密码长度不能少于6位', snackPosition: SnackPosition.TOP);
      return false;
    }
    if (state.newPassword.value != state.confirmPwd.value) {
      Get.snackbar('提示', '两次输入的密码不一致', snackPosition: SnackPosition.TOP);
      return false;
    }
    return true;
  }

  void goBack() => Get.back();
}
