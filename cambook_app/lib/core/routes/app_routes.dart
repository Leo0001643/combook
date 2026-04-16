/// GetX 路由名称常量
abstract class AppRoutes {
  // ── 启动 / 引导 ───────────────────────────────────────────────────
  static const splash      = '/splash';
  static const welcome     = '/welcome';
  static const onboarding  = '/onboarding';

  // ── 认证 ──────────────────────────────────────────────────────────
  static const login          = '/login';
  static const register       = '/register';
  static const verifyCode     = '/verify-code';
  static const forgotPassword = '/forgot-password';

  // ── 会员端 ────────────────────────────────────────────────────────
  static const memberHome = '/member/home';

  // ── 技师端 ────────────────────────────────────────────────────────
  static const techHome = '/tech/home';

  // ── 商户端 ────────────────────────────────────────────────────────
  static const merchantHome = '/merchant/home';

  // ── 技师相关 ──────────────────────────────────────────────────────
  static const technicianList   = '/member/technicians';
  static const technicianDetail = '/technician/detail';

  // ── 发现 ──────────────────────────────────────────────────────────
  static const discover    = '/member/discover';
  static const postDetail  = '/discover/post';

  // ── 订单 ──────────────────────────────────────────────────────────
  static const orderList   = '/member/orders';
  static const orderDetail = '/order/detail';
  static const createOrder = '/create-order';
  static const orderTrack  = '/order/track';
  static const orderReview = '/order/review';
  static const orderRefund = '/order/refund';

  // ── 支付 ──────────────────────────────────────────────────────────
  static const payment       = '/payment';
  static const usdtPayment   = '/payment/usdt';
  static const abaPayment    = '/payment/aba';
  static const paymentResult = '/payment/result';

  // ── 个人中心 ──────────────────────────────────────────────────────
  static const profile     = '/member/profile';
  static const editProfile = '/profile/edit';
  static const addresses   = '/profile/addresses';
  static const settings    = '/profile/settings';
  static const invite      = '/profile/invite';
  static const coupons     = '/profile/coupons';
  static const favorites   = '/profile/favorites';
  static const help        = '/profile/help';
  static const about       = '/profile/about';
  static const terms       = '/profile/terms';
  static const privacy     = '/profile/privacy';

  // ── 钱包 ──────────────────────────────────────────────────────────
  static const wallet   = '/wallet';
  static const recharge = '/wallet/recharge';
  static const withdraw = '/wallet/withdraw';

  // ── IM ────────────────────────────────────────────────────────────
  static const imList = '/im';
  static const imChat = '/im/chat';

  // ── 搜索 / 通知 ───────────────────────────────────────────────────
  static const search       = '/search';
  static const notification = '/notifications';
}
