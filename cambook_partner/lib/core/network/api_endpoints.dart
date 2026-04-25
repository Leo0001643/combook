/// API 端点常量 —— 后期只需修改此文件即可切换后端地址
abstract class ApiEndpoints {
  static const String _base = '';

  // ── 技师端认证（对应后端 TechnicianAuthController /tech/auth） ─────
  static const String techLogin    = '/tech/auth/login';
  static const String techRegister = '/tech/auth/register';
  static const String techMe       = '/tech/auth/me';

  // ── 技师端首页（对应后端 TechHomeController /tech/home） ───────────
  static const String techHomeStats         = '/tech/home/stats';
  static const String techHomeSchedule      = '/tech/home/schedule';
  static const String techPendingOrderCount = '/tech/home/pending-count';

  // ── 技师端订单 ─────────────────────────────────────────────────────
  static const String techOrders = '/tech/home/orders';
  static String techOrderItems(int orderId)            => '/tech/order/$orderId/item';
  static String techRemoveOrderItem(int orderId, int itemId)
      => '/tech/order/$orderId/item/$itemId';

  // 在线预约订单 接单 / 拒单 / 开始 / 完成
  static String techAcceptOnline(int id)   => '/tech/order/$id/accept';
  static String techRejectOnline(int id)   => '/tech/order/$id/reject';
  static String techStartOnline(int id)    => '/tech/order/$id/start';
  static String techCompleteOnline(int id) => '/tech/order/$id/complete';

  // 门店散客订单 接单 / 拒单 / 开始 / 完成（传 sessionId）
  static String techAcceptWalkin(int sessionId)   => '/tech/order/walkin/$sessionId/accept';
  static String techRejectWalkin(int sessionId)   => '/tech/order/walkin/$sessionId/reject';
  static String techStartWalkin(int sessionId)    => '/tech/order/walkin/$sessionId/start';
  static String techCompleteWalkin(int sessionId) => '/tech/order/walkin/$sessionId/complete';

  // ── Auth (legacy / 管理端) ─────────────────────────────────────────
  static const String login  = '$_base/partner/auth/login';
  static const String logout = '$_base/partner/auth/logout';
  static const String profile= '$_base/partner/profile';

  // ── 订单 ──────────────────────────────────────────────────────────
  static const String orderList   = '$_base/partner/orders';
  static String orderDetail(int id) => '$_base/partner/orders/$id';
  static String orderAccept(int id) => '$_base/partner/orders/$id/accept';
  static String orderReject(int id) => '$_base/partner/orders/$id/reject';
  static String orderStart(int id)  => '$_base/partner/orders/$id/start';
  static String orderComplete(int id)=> '$_base/partner/orders/$id/complete';

  // ── 收入 ──────────────────────────────────────────────────────────
  static const String incomeOverview= '$_base/partner/income/overview';
  static const String incomeRecords = '$_base/partner/income/records';
  static const String incomeTrend   = '$_base/partner/income/trend';
  static const String withdraw      = '$_base/partner/income/withdraw';

  // ── 消息 ──────────────────────────────────────────────────────────
  static const String conversations = '$_base/partner/conversations';
  static String chatMessages(String id) => '$_base/partner/conversations/$id/messages';

  // ── 排班 ──────────────────────────────────────────────────────────
  static const String schedule     = '$_base/partner/schedule';
  static const String appointments = '$_base/partner/appointments';

  // ── 技能 / 评价 ───────────────────────────────────────────────────
  static const String skills  = '$_base/partner/skills';
  static const String reviews = '$_base/partner/reviews';
}
