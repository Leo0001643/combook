import 'package:get/get.dart';
import '../../core/theme/app_theme_controller.dart';
import 'auth_shared.dart';

/// Thin bridge — login/register pages use AuthThemeController;
/// actual state lives in the app-wide AppThemeController singleton.
class AuthThemeController extends GetxController {
  static AuthThemeController get to => Get.find<AuthThemeController>();

  AppThemeController get _app => AppThemeController.to;

  late final Rx<SpaThemeVariant> variant =
      _app.variantRx.value.spaVariant.obs;

  @override
  void onInit() {
    super.onInit();
    ever(_app.variantRx, (AppThemeVariant v) {
      variant.value = v.spaVariant;
    });
  }

  SpaAuthTheme get theme => _app.spaTheme;

  void select(SpaThemeVariant v) => _app.select(switch (v) {
    SpaThemeVariant.pink   => AppThemeVariant.pink,
    SpaThemeVariant.purple => AppThemeVariant.purple,
    SpaThemeVariant.green  => AppThemeVariant.green,
  });

  void toggle() => _app.toggle();
}
