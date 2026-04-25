import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import '../routes/app_routes.dart';
import '../services/user_service.dart';

/// 路由级认证守卫
///
/// 作用于所有受保护路由（登录/注册页除外）。
/// 未登录时自动重定向到登录页；已登出弹窗优先（弹窗显示期间不重复跳转）。
class AuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final user = Get.find<UserService>();

    // 已登录：放行
    if (user.isLoggedIn) return null;

    // 已登出弹窗正在显示：放行（弹窗自行完成跳转，避免导航栈混乱）
    if (user.isSessionExpired.value && (Get.isDialogOpen ?? false)) return null;

    // 未登录：重定向到登录页
    return const RouteSettings(name: AppRoutes.login);
  }
}
