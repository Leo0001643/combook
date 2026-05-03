import 'package:flutter/material.dart';
import '../theme/app_theme_controller.dart';

/// BuildContext extension — 动态主题色快捷访问
/// 用法：context.primary, context.primaryGrad 等
/// 所有颜色跟随商户配置，无需硬编码 AppColors.primary
extension ThemeX on BuildContext {
  Color get primary   => Theme.of(this).colorScheme.primary;
  Color get primaryDk => AppThemeController.to.primaryDk;
  Color get primaryLt => AppThemeController.to.primaryLt;

  LinearGradient get primaryGrad => LinearGradient(
      begin: Alignment.topLeft, end: Alignment.bottomRight,
      colors: [primaryDk, primary]);
}
