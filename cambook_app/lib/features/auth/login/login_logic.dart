import 'dart:async';
import 'package:get/get.dart';
import '../../../core/auth/auth_controller.dart';
import '../../../core/network/auth_api.dart';
import '../../../core/routes/app_routes.dart';
import 'login_state.dart';

/// 登录页逻辑
class LoginLogic extends GetxController {
  final state = LoginState();

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
        _startCountdown();
      } else {
        Get.snackbar('错误', result.message, snackPosition: SnackPosition.TOP);
      }
    } catch (e) {
      state.smsCode.value = '888888'; // 开发模式固定验证码
      Get.snackbar('提示', '验证码已发送（开发模式：888888）', snackPosition: SnackPosition.TOP);
      _startCountdown();
    } finally {
      state.isLoading.value = false;
    }
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

  // ── 验证码登录 ────────────────────────────────────────────────────
  Future<void> loginBySms() async {
    if (state.phone.value.isEmpty) {
      Get.snackbar('提示', '请输入手机号', snackPosition: SnackPosition.TOP);
      return;
    }
    if (state.smsCode.value.isEmpty) {
      Get.snackbar('提示', '请输入验证码', snackPosition: SnackPosition.TOP);
      return;
    }
    if (!state.agreedTerms.value) {
      Get.snackbar('提示', '请阅读并同意用户协议', snackPosition: SnackPosition.TOP);
      return;
    }
    await _doLogin(() => AuthApi.loginBySms(
      phone:       state.phone.value,
      countryCode: state.countryCode.value,
      captcha:     state.smsCode.value,
      language:    AuthController.to.languageCode,
    ));
  }

  // ── 密码登录 ──────────────────────────────────────────────────────
  Future<void> loginByPassword() async {
    if (state.phone.value.isEmpty) {
      Get.snackbar('提示', '请输入手机号', snackPosition: SnackPosition.TOP);
      return;
    }
    if (state.password.value.isEmpty) {
      Get.snackbar('提示', '请输入密码', snackPosition: SnackPosition.TOP);
      return;
    }
    if (!state.agreedTerms.value) {
      Get.snackbar('提示', '请阅读并同意用户协议', snackPosition: SnackPosition.TOP);
      return;
    }
    await _doLogin(() => AuthApi.loginByPassword(
      phone:       state.phone.value,
      countryCode: state.countryCode.value,
      password:    state.password.value,
      language:    AuthController.to.languageCode,
    ));
  }

  // ── 通用登录执行 ──────────────────────────────────────────────────
  Future<void> _doLogin(Future<dynamic> Function() apiCall) async {
    state.isLoading.value = true;
    try {
      final result = await apiCall();
      if (result.isSuccess && result.data != null) {
        await AuthController.to.loginSuccess(result.data!);
        // loginSuccess 内部调用 _navigateToHome，无需在此跳转
      } else {
        Get.snackbar('登录失败', result.message, snackPosition: SnackPosition.TOP);
      }
    } catch (e) {
      Get.snackbar('网络错误', '请检查网络连接后重试', snackPosition: SnackPosition.TOP);
    } finally {
      state.isLoading.value = false;
    }
  }

  // ── 开发模式辅助 ──────────────────────────────────────────────────
  /// 开发模式：后端 application.yml 中 dev-code = "888888"
  String _devCode() => '888888';

  // ── 导航 ──────────────────────────────────────────────────────────
  void goToRegister()       => Get.toNamed(AppRoutes.register);
  void goToForgotPassword() => Get.toNamed(AppRoutes.forgotPassword);
  void goToTerms()          => Get.toNamed(AppRoutes.terms);
  void goToPrivacy()        => Get.toNamed(AppRoutes.privacy);
  void goBack()             => Get.back();
}
