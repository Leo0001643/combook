import 'dart:async';
import 'package:get/get.dart';
import '../../../core/auth/auth_controller.dart';
import '../../../core/network/auth_api.dart';
import 'register_state.dart';

/// 注册页逻辑
class RegisterLogic extends GetxController {
  final state = RegisterState();

  // ── 发送短信验证码 ─────────────────────────────────────────────────
  Future<void> sendSmsCode() async {
    if (state.phone.value.isEmpty) {
      Get.snackbar('提示', '请输入手机号', snackPosition: SnackPosition.TOP);
      return;
    }
    state.isLoading.value = true;
    try {
      final result = await AuthApi.sendSmsCode(
        countryCode: state.countryCode.value,
        phone:       state.phone.value,
      );
      if (result.isSuccess) {
        state.smsCode.value = '888888'; // 开发模式固定验证码
        Get.snackbar('提示', '验证码已发送（开发模式：888888）', snackPosition: SnackPosition.TOP);
      } else {
        Get.snackbar('错误', result.message, snackPosition: SnackPosition.TOP);
      }
    } catch (_) {
      state.smsCode.value = '888888'; // 开发模式固定验证码
      Get.snackbar('提示', '验证码已发送（开发模式：888888）', snackPosition: SnackPosition.TOP);
    } finally {
      state.isLoading.value = false;
    }
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

  // ── 注册 ──────────────────────────────────────────────────────────
  Future<void> register() async {
    if (!_validate()) return;
    state.isLoading.value = true;
    try {
      final result = await AuthApi.register(
        phone:       state.phone.value,
        countryCode: state.countryCode.value,
        password:    state.password.value,
        captcha:     state.smsCode.value,
        userType:    state.userType.value,
        inviteCode:  state.inviteCode.value.isEmpty ? null : state.inviteCode.value,
        language:    AuthController.to.languageCode,
      );
      if (result.isSuccess && result.data != null) {
        // 注册成功自动登录
        await AuthController.to.loginSuccess(result.data!);
      } else {
        Get.snackbar('注册失败', result.message, snackPosition: SnackPosition.TOP);
      }
    } catch (e) {
      Get.snackbar('网络错误', '请检查网络连接后重试', snackPosition: SnackPosition.TOP);
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
    if (state.password.value.length < 6) {
      Get.snackbar('提示', '密码长度不能少于6位', snackPosition: SnackPosition.TOP);
      return false;
    }
    if (state.password.value != state.confirmPwd.value) {
      Get.snackbar('提示', '两次输入的密码不一致', snackPosition: SnackPosition.TOP);
      return false;
    }
    if (!state.agreedTerms.value) {
      Get.snackbar('提示', '请阅读并同意用户协议', snackPosition: SnackPosition.TOP);
      return false;
    }
    return true;
  }

  void goBack() => Get.back();
}
