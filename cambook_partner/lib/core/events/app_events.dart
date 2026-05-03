import '../models/models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// 全局事件定义 —— 所有模块通过 EventBusUtil 发布/订阅
// 遵循开闭原则：新增事件只需在此处添加，无需修改现有代码
// ─────────────────────────────────────────────────────────────────────────────

/// 新订单到达（抢单/推单）
class NewOrderEvent {
  final OrderModel order;
  final bool isGrabMode;          // true = 倒计时抢单模式
  final int  grabCountdownSecs;   // 抢单倒计时秒数，默认 30
  const NewOrderEvent(this.order, {this.isGrabMode = false, this.grabCountdownSecs = 30});
}

/// 订单状态变更
class OrderStatusChangedEvent {
  final int         orderId;
  final OrderStatus oldStatus;
  final OrderStatus newStatus;
  const OrderStatusChangedEvent(this.orderId, this.oldStatus, this.newStatus);
}

/// 技师在线状态变更
class TechStatusChangedEvent {
  final TechStatus oldStatus;
  final TechStatus newStatus;
  const TechStatusChangedEvent(this.oldStatus, this.newStatus);
}

/// 新消息到达
class NewMessageEvent {
  final String conversationId;
  final String senderName;
  final String content;
  final ConversationType type;
  const NewMessageEvent(this.conversationId, this.senderName, this.content, this.type);
}

/// 服务计时器事件（每秒触发）
class ServiceTimerTickEvent {
  final int elapsedSecs;
  final int orderId;
  const ServiceTimerTickEvent(this.orderId, this.elapsedSecs);
}

/// 服务完成事件
class ServiceCompletedEvent {
  final int    orderId;
  final double earnedAmount;
  const ServiceCompletedEvent(this.orderId, this.earnedAmount);
}

/// 余额变动事件（完成订单 / 提现）
class BalanceChangedEvent {
  final double oldBalance;
  final double newBalance;
  final String reason;
  const BalanceChangedEvent(this.oldBalance, this.newBalance, this.reason);
}

/// 系统通知事件
class SystemNoticeEvent {
  final String title;
  final String body;
  final NoticeLevel level;
  const SystemNoticeEvent(this.title, this.body, {this.level = NoticeLevel.info});
}

enum NoticeLevel { info, success, warning, error }

/// 抢单倒计时 Tick（每秒触发，用于抢单弹窗倒计时）
class GrabCountdownTickEvent {
  final int orderId;
  final int remaining;   // 剩余秒数
  const GrabCountdownTickEvent(this.orderId, this.remaining);
}

/// 抢单超时（无人接单，订单失效）
class GrabExpiredEvent {
  final int orderId;
  const GrabExpiredEvent(this.orderId);
}

/// 触发首页统计数据 HTTP 刷新（WS 新订单到达 / 服务完成 / 其他状态变更时触发）
///
/// HomeLogic 订阅此事件并调用 HTTP 接口拉取最新 stats + schedule + pendingCount，
/// 避免依赖 WS HOME_DATA 的推送周期延迟。
class HomeStatsRefreshEvent {
  const HomeStatsRefreshEvent();
}
