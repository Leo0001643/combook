import 'package:get/get.dart';
import '../../../core/auth/auth_controller.dart';
import '../../../core/routes/app_routes.dart';
import 'splash_state.dart';

/// 启动页逻辑
/// 监听 AuthController.isLoading，加载完成后根据登录态跳转
class SplashLogic extends GetxController {
  final state = SplashState();

  @override
  void onReady() {
    super.onReady();
    _awaitAuthAndNavigate();
  }

  void _awaitAuthAndNavigate() {
    final auth = AuthController.to;
    // isLoading: true → false 时触发导航
    ever(auth.isLoading, (bool loading) {
      if (!loading) _navigate(auth);
    });
    // 若 isLoading 已经为 false（极快速恢复），立即导航
    if (!auth.isLoading.value) _navigate(auth);
  }

  void _navigate(AuthController auth) {
    if (auth.isLoggedIn.value) {
      switch (auth.userType.value) {
        case 2:
          Get.offAllNamed(AppRoutes.techHome);
          return;
        case 3:
          Get.offAllNamed(AppRoutes.merchantHome);
          return;
        default:
          Get.offAllNamed(AppRoutes.memberHome);
      }
    } else {
      // 未登录 → 进入 Welcome 引导页，由用户选择登录或注册
      Get.offAllNamed(AppRoutes.welcome);
    }
  }
}
