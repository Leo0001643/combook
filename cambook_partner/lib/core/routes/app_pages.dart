import 'package:get/get.dart';
import 'app_routes.dart';
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

/// 路由表 —— 所有页面在此注册，符合开闭原则（新增页面只需添加此处）
abstract class AppPages {
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
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.orderDetail,
      page: () => const OrderDetailPage(),
      binding: OrderDetailBinding(),
    ),
    GetPage(
      name: AppRoutes.serviceActive,
      page: () => const ServiceActivePage(),
      binding: ServiceActiveBinding(),
      transition: Transition.downToUp,
    ),
    GetPage(
      name: AppRoutes.chat,
      page: () => const ChatPage(),
      binding: ChatBinding(),
    ),
    GetPage(
      name: AppRoutes.settings,
      page: () => const SettingsPage(),
      binding: SettingsBinding(),
    ),
    GetPage(
      name: AppRoutes.skills,
      page: () => const SkillsPage(),
      binding: SkillsBinding(),
    ),
    GetPage(
      name: AppRoutes.reviews,
      page: () => const ReviewsPage(),
      binding: ReviewsBinding(),
    ),
    GetPage(
      name: AppRoutes.schedule,
      page: () => const SchedulePage(),
      binding: ScheduleBinding(),
    ),
  ];
}
