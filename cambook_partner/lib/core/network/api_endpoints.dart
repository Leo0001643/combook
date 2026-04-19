/// API 端点常量 —— 后期只需修改此文件即可切换后端地址
abstract class ApiEndpoints {
  static const String _base = '/api';

  // ── Auth ──────────────────────────────────────────────────────────
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
