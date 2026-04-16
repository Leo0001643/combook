import 'package:get/get.dart';

import 'app_routes.dart';

// ── Auth ──────────────────────────────────────────────────────────────────────
import '../../features/auth/splash/splash_page.dart';
import '../../features/auth/splash/splash_binding.dart';
import '../../features/auth/welcome/welcome_page.dart';
import '../../features/auth/onboarding/onboarding_page.dart';
import '../../features/auth/login/login_page.dart';
import '../../features/auth/login/login_binding.dart';
import '../../features/auth/register/register_page.dart';
import '../../features/auth/register/register_binding.dart';
import '../../features/auth/verify_code/verify_code_page.dart';
import '../../features/auth/verify_code/verify_code_binding.dart';
import '../../features/auth/forgot_password/forgot_password_page.dart';
import '../../features/auth/forgot_password/forgot_password_binding.dart';

// ── Home ──────────────────────────────────────────────────────────────────────
import '../../features/home/member_home/member_home_page.dart';
import '../../features/home/member_home/member_home_binding.dart';
import '../../features/home/tech_home/tech_home_page.dart';
import '../../features/home/tech_home/tech_home_binding.dart';
import '../../features/home/merchant_home/merchant_home_page.dart';
import '../../features/home/merchant_home/merchant_home_binding.dart';

// ── Technician ────────────────────────────────────────────────────────────────
import '../../features/technician/technician_list/technician_list_page.dart';
import '../../features/technician/technician_detail/technician_detail_page.dart';

// ── Discover ──────────────────────────────────────────────────────────────────
import '../../features/discover/discover/discover_page.dart';
import '../../features/discover/post_detail/post_detail_page.dart';

// ── Order ─────────────────────────────────────────────────────────────────────
import '../../features/order/order_list/order_list_page.dart';
import '../../features/order/order_detail/order_detail_page.dart';
import '../../features/order/create_order/create_order_page.dart';
import '../../features/order/order_track/order_track_page.dart';
import '../../features/order/review/review_page.dart';
import '../../features/order/refund/refund_page.dart';

// ── Payment ───────────────────────────────────────────────────────────────────
import '../../features/payment/payment/payment_page.dart';
import '../../features/payment/usdt_payment/usdt_payment_page.dart';
import '../../features/payment/aba_payment/aba_payment_page.dart';
import '../../features/payment/payment_result/payment_result_page.dart';

// ── Profile ───────────────────────────────────────────────────────────────────
import '../../features/profile/edit_profile/edit_profile_page.dart';
import '../../features/profile/address/address_page.dart';
import '../../features/profile/settings/settings_page.dart';
import '../../features/profile/invite/invite_page.dart';
import '../../features/profile/coupon/coupon_page.dart';
import '../../features/profile/favorites/favorites_page.dart';
import '../../features/profile/help/help_page.dart';
import '../../features/profile/about/about_page.dart';
import '../../features/profile/terms/terms_page.dart';
import '../../features/profile/privacy/privacy_page.dart';

// ── Wallet ────────────────────────────────────────────────────────────────────
import '../../features/profile/wallet/wallet_page.dart';
import '../../features/profile/recharge/recharge_page.dart';
import '../../features/profile/withdraw/withdraw_page.dart';

// ── Search / Notification ────────────────────────────────────────────────────
import '../../features/search/search/search_page.dart';
import '../../features/notification/notification/notification_page.dart';

// ── IM ────────────────────────────────────────────────────────────────────────
import '../../features/im/im_list/im_list_page.dart';
import '../../features/im/im_chat/im_chat_page.dart';

// ── Common ────────────────────────────────────────────────────────────────────
import '../../features/common/not_found/not_found_page.dart';

/// GetX 路由表
/// 替代原 go_router 的 AppRouter（已删除）
/// 参数通过 Get.arguments 传递，无需 URL 编码
class AppPages {
  AppPages._();

  static const initial = AppRoutes.splash;

  static final routes = <GetPage>[
    // ── 启动 / 引导 ──────────────────────────────────────────────────
    GetPage(
      name:    AppRoutes.splash,
      page:    () => const SplashPage(),
      binding: SplashBinding(),
    ),
    GetPage(name: AppRoutes.welcome,    page: () => const WelcomePage()),
    GetPage(name: AppRoutes.onboarding, page: () => const OnboardingPage()),

    // ── 认证 ────────────────────────────────────────────────────────
    GetPage(
      name:    AppRoutes.login,
      page:    () => const LoginPage(),
      binding: LoginBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name:    AppRoutes.register,
      page:    () => const RegisterPage(),
      binding: RegisterBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name:    AppRoutes.verifyCode,
      page:    () => const VerifyCodePage(),
      binding: VerifyCodeBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name:    AppRoutes.forgotPassword,
      page:    () => const ForgotPasswordPage(),
      binding: ForgotPasswordBinding(),
      transition: Transition.rightToLeft,
    ),

    // ── 会员端主页（包含底部导航 + 五个 Tab） ──────────────────────
    GetPage(
      name:    AppRoutes.memberHome,
      page:    () => const MemberHomePage(),
      binding: MemberHomeBinding(),
    ),

    // ── 技师端 / 商户端 ──────────────────────────────────────────────
    GetPage(name: AppRoutes.techHome,     page: () => const TechHomePage(),     binding: TechHomeBinding()),
    GetPage(name: AppRoutes.merchantHome, page: () => const MerchantHomePage(), binding: MerchantHomeBinding()),

    // ── 技师 ────────────────────────────────────────────────────────
    GetPage(name: AppRoutes.technicianList,   page: () => const TechnicianListPage()),
    GetPage(
      name: AppRoutes.technicianDetail,
      page: () {
        final args = Get.arguments as Map<String, dynamic>?;
        return TechnicianDetailPage(id: args?['id'] as String? ?? '');
      },
    ),

    // ── 发现 ────────────────────────────────────────────────────────
    GetPage(name: AppRoutes.discover,   page: () => const DiscoverPage()),
    GetPage(
      name: AppRoutes.postDetail,
      page: () {
        final args = Get.arguments as Map<String, dynamic>?;
        return PostDetailPage(postId: args?['postId'] as String? ?? '');
      },
    ),

    // ── 订单 ────────────────────────────────────────────────────────
    GetPage(name: AppRoutes.orderList, page: () => const OrderListPage()),
    GetPage(
      name: AppRoutes.orderDetail,
      page: () {
        final args = Get.arguments as Map<String, dynamic>?;
        return OrderDetailPage(orderId: args?['orderId'] as String? ?? '');
      },
    ),
    GetPage(
      name: AppRoutes.createOrder,
      page: () {
        final args = Get.arguments as Map<String, dynamic>?;
        return CreateOrderPage(
          technicianId: args?['technicianId'] as String? ?? '',
          packageId:    args?['packageId']    as String? ?? '',
        );
      },
    ),
    GetPage(
      name: AppRoutes.orderTrack,
      page: () {
        final args = Get.arguments as Map<String, dynamic>?;
        return OrderTrackPage(orderId: args?['orderId'] as String? ?? '');
      },
    ),
    GetPage(
      name: AppRoutes.orderReview,
      page: () {
        final args = Get.arguments as Map<String, dynamic>?;
        return ReviewPage(
          orderId:       args?['orderId']   as String? ?? '',
          technicianName: args?['techName'] as String? ?? '技师',
        );
      },
    ),
    GetPage(
      name: AppRoutes.orderRefund,
      page: () {
        final args = Get.arguments as Map<String, dynamic>?;
        return RefundPage(orderId: args?['orderId'] as String? ?? '');
      },
    ),

    // ── 支付 ────────────────────────────────────────────────────────
    GetPage(
      name: AppRoutes.payment,
      page: () {
        final args = Get.arguments as Map<String, dynamic>?;
        return PaymentPage(orderId: args?['orderId'] as String? ?? '');
      },
    ),
    GetPage(
      name: AppRoutes.usdtPayment,
      page: () {
        final args = Get.arguments as Map<String, dynamic>?;
        return UsdtPaymentPage(orderId: args?['orderId'] as String? ?? '');
      },
    ),
    GetPage(
      name: AppRoutes.abaPayment,
      page: () {
        final args = Get.arguments as Map<String, dynamic>?;
        return AbaPaymentPage(orderId: args?['orderId'] as String? ?? '');
      },
    ),
    GetPage(
      name: AppRoutes.paymentResult,
      page: () {
        final args = Get.arguments as Map<String, dynamic>?;
        return PaymentResultPage(
          success: args?['success'] as bool? ?? false,
          orderNo: args?['orderNo'] as String? ?? '',
        );
      },
    ),

    // ── 个人中心 ─────────────────────────────────────────────────────
    GetPage(name: AppRoutes.editProfile, page: () => const EditProfilePage()),
    GetPage(name: AppRoutes.addresses,   page: () => const AddressPage()),
    GetPage(name: AppRoutes.settings,    page: () => const SettingsPage()),
    GetPage(name: AppRoutes.invite,      page: () => const InvitePage()),
    GetPage(name: AppRoutes.coupons,     page: () => const CouponPage()),
    GetPage(name: AppRoutes.favorites,   page: () => const FavoritesPage()),
    GetPage(name: AppRoutes.help,        page: () => const HelpPage()),
    GetPage(name: AppRoutes.about,       page: () => const AboutPage()),
    GetPage(
      name: AppRoutes.terms,
      page: () {
        final args = Get.arguments as Map<String, dynamic>?;
        return TermsPage(showAgreeButton: args?['showAgreeButton'] as bool? ?? false);
      },
    ),
    GetPage(
      name: AppRoutes.privacy,
      page: () {
        final args = Get.arguments as Map<String, dynamic>?;
        return PrivacyPage(showAgreeButton: args?['showAgreeButton'] as bool? ?? false);
      },
    ),

    // ── 钱包 ────────────────────────────────────────────────────────
    GetPage(name: AppRoutes.wallet,   page: () => const WalletPage()),
    GetPage(name: AppRoutes.recharge, page: () => const RechargePage()),
    GetPage(name: AppRoutes.withdraw, page: () => const WithdrawPage()),

    // ── IM ──────────────────────────────────────────────────────────
    GetPage(name: AppRoutes.imList, page: () => const ImListPage()),
    GetPage(
      name: AppRoutes.imChat,
      page: () {
        final args = Get.arguments as Map<String, dynamic>?;
        return ImChatPage(targetUserId: args?['userId'] as String? ?? '');
      },
    ),

    // ── 搜索 / 通知 ──────────────────────────────────────────────────
    GetPage(name: AppRoutes.search,       page: () => const SearchPage()),
    GetPage(name: AppRoutes.notification, page: () => const NotificationPage()),

    // ── 404 ─────────────────────────────────────────────────────────
    GetPage(name: '/not-found', page: () => const NotFoundPage()),
  ];
}
