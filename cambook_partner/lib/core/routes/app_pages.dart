import 'package:get/get.dart';
import 'app_routes.dart';
import '../../core/middleware/auth_middleware.dart';
import '../../features/auth/login/binding.dart';
import '../../features/auth/login/page.dart';
import '../../features/auth/register/binding.dart';
import '../../features/auth/register/page.dart';
import '../../features/shell/main_shell.dart';
import '../../features/shell/main_binding.dart';
import '../../features/orders/detail/binding.dart';
import '../../features/orders/detail/page.dart';
import '../../features/orders/service_active/binding.dart';
import '../../features/orders/service_active/page.dart';
import '../../features/messages/chat/binding.dart';
import '../../features/messages/chat/page.dart';
import '../../features/profile/settings/binding.dart';
import '../../features/profile/settings/page.dart';
import '../../features/profile/skills/binding.dart';
import '../../features/profile/skills/page.dart';
import '../../features/profile/reviews/binding.dart';
import '../../features/profile/reviews/page.dart';
import '../../features/schedule/binding.dart';
import '../../features/schedule/page.dart';
import '../../features/profile/language/page.dart';

/// 路由表 —— 所有页面在此注册，符合开闭原则（新增页面只需添加此处）
/// 除 login / register 外，所有页面均挂载 [AuthMiddleware] 路由守卫
abstract class AppPages {
  static final _auth = [AuthMiddleware()];

  static final pages = <GetPage>[
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginPage(),
      binding: LoginBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.register,
      page: () => const RegisterPage(),
      binding: RegisterBinding(),
    ),
    GetPage(
      name: AppRoutes.main,
      page: () => const MainShell(),
      binding: MainBinding(),
      middlewares: _auth,
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.orderDetail,
      page: () => const OrderDetailPage(),
      binding: OrderDetailBinding(),
      middlewares: _auth,
    ),
    GetPage(
      name: AppRoutes.serviceActive,
      page: () => const ServiceActivePage(),
      binding: ServiceActiveBinding(),
      middlewares: _auth,
      transition: Transition.downToUp,
    ),
    GetPage(
      name: AppRoutes.chat,
      page: () => const ChatPage(),
      binding: ChatBinding(),
      middlewares: _auth,
    ),
    GetPage(
      name: AppRoutes.settings,
      page: () => const SettingsPage(),
      binding: SettingsBinding(),
      middlewares: _auth,
    ),
    GetPage(
      name: AppRoutes.skills,
      page: () => const SkillsPage(),
      binding: SkillsBinding(),
      middlewares: _auth,
    ),
    GetPage(
      name: AppRoutes.reviews,
      page: () => const ReviewsPage(),
      binding: ReviewsBinding(),
      middlewares: _auth,
    ),
    GetPage(
      name: AppRoutes.schedule,
      page: () => const SchedulePage(),
      binding: ScheduleBinding(),
      middlewares: _auth,
    ),
    GetPage(
      name: AppRoutes.language,
      page: () => const LanguagePage(),
      transition: Transition.rightToLeft,
    ),
  ];
}
