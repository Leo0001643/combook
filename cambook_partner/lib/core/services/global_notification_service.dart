import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../events/app_events.dart';
import '../i18n/l10n_ext.dart';
import '../utils/event_bus_util.dart';
import '../utils/toast_util.dart';
import '../utils/audio_util.dart';
import '../utils/log_util.dart';
import '../constants/app_colors.dart';
import '../models/models.dart';
import '../routes/app_routes.dart';
import '../widgets/app_dialog.dart';
import 'order_service.dart';
import 'tech_ws_service.dart';

import '../../features/shell/shell_controller.dart';


/// 全局通知监听器 —— 在 main.dart 通过 initServices 启动
class GlobalNotificationService extends GetxService with EventBusMixin {
  StreamSubscription<Map<String, dynamic>>? _wsNewOrderSub;
  bool _grabDialogOpen = false; // 精确追踪抢单弹窗，避免误关其他对话框

  /// 记录已由 WS 路径立即播放过音效的订单 ID，防止 _onNewOrder 重复播放
  final _wsPlayedOrderIds = <int>{};

  Future<GlobalNotificationService> init() async {
    _subscribeAll();
    return this;
  }

  void _subscribeAll() {
    subscribe<NewOrderEvent>(_onNewOrder);
    subscribe<OrderStatusChangedEvent>(_onOrderStatusChanged);
    subscribe<TechStatusChangedEvent>(_onTechStatusChanged);
    subscribe<NewMessageEvent>(_onNewMessage);
    subscribe<ServiceCompletedEvent>(_onServiceCompleted);
    subscribe<BalanceChangedEvent>(_onBalanceChanged);
    subscribe<SystemNoticeEvent>(_onSystemNotice);
    subscribe<GrabExpiredEvent>(_onGrabExpired);
    // WS 新订单实时推送：刷新订单列表并触发 NewOrderEvent（音频+横幅+弹窗）
    _wsNewOrderSub = Get.find<TechWsService>()
        .newOrderStream
        .listen(_onWsNewOrder);
    LogUtil.i('[GlobalNotification] 已订阅所有事件');
  }

  void _onNewOrder(NewOrderEvent e) {
    final orderId = e.order.id;

    // 若已由 WS 路径立即播放过音效，跳过重复播放；否则（App 直接触发场景）正常播放
    if (_wsPlayedOrderIds.remove(orderId)) {
      LogUtil.d('[GlobalNotification] skip dup audio for WS order #$orderId');
    } else {
      unawaited(AudioUtil.playNewOrder());
    }

    // 后台 / 息屏时推送系统通知
    final customerName = e.order.customer.nickname.isNotEmpty
        ? e.order.customer.nickname : gL10n.unknownCustomer;
    final svcName = e.order.services.isNotEmpty
        ? e.order.services.first.name : '—';
    unawaited(AudioUtil.notifyNewOrder(
      title: gL10n.newOrder,
      body:  '$customerName · $svcName',
    ));
    if (e.isGrabMode) {
      _showGrabOrderDialog(e);
    } else {
      _showNewOrderBanner(e.order);
    }
  }

  /// WS 推送新订单：
  /// 1. 立即播放提示音+震动（无需等待网络）
  /// 2. 从服务端拉取订单详情，触发横幅 / 抢单弹窗
  /// 3. 将 orderId 记入 _wsPlayedOrderIds，让后续 _onNewOrder 跳过重复播音
  /// 4. 立即更新角标（不等待 HOME_DATA），并触发首页统计数据刷新
  Future<void> _onWsNewOrder(Map<String, dynamic> data) async {
    final orderId = (data['orderId'] as num?)?.toInt();
    if (orderId == null) {
      LogUtil.w('[GlobalNotification] WS NEW_ORDER missing orderId: $data');
      return;
    }

    LogUtil.i('[GlobalNotification] WS 新订单 #$orderId，立即播音+震动');

    // 立即触发音效+震动，不等待任何网络请求
    unawaited(AudioUtil.playNewOrder());
    // 标记：通知 _onNewOrder 跳过重复播音
    _wsPlayedOrderIds.add(orderId);

    final orderService = Get.find<OrderService>();
    try {
      await orderService.fetchFromApi();
    } catch (e) {
      LogUtil.w('[GlobalNotification] fetchFromApi failed: $e');
    }

    // ── 立即更新订单角标（不等待 HOME_DATA 推送）────────────────────────────
    _syncOrderBadge(orderService);

    final order = orderService.getById(orderId);
    if (order == null) {
      LogUtil.w('[GlobalNotification] order #$orderId not found after fetch; audio already played');
      _wsPlayedOrderIds.remove(orderId);
      return;
    }

    // 门店散客订单(orderType=2)：横幅；在线订单：抢单倒计时弹窗
    final grabMode = order.orderType != 2;
    orderService.pushNewOrder(order, grabMode: grabMode);
    // _onNewOrder 被触发后会移除 _wsPlayedOrderIds[orderId] 并跳过重复播音

    // ── 触发首页统计数据 HTTP 刷新（新订单到达后数据需立即更新）──────────────
    _triggerHomeStatsRefresh();
  }

  /// 根据本地已拉取的订单数据更新角标，无需等待服务端 HOME_DATA 推送。
  void _syncOrderBadge(OrderService orderService) {
    try {
      final pendingCount = orderService.orders
          .where((o) => o.status == OrderStatus.pending)
          .length;
      if (Get.isRegistered<ShellController>()) {
        Get.find<ShellController>().updateOrderBadge(pendingCount);
        LogUtil.d('[GlobalNotification] 角标同步: pending=$pendingCount');
      }
    } catch (e) {
      LogUtil.w('[GlobalNotification] _syncOrderBadge error: $e');
    }
  }

  /// 触发首页统计数据刷新。HomeLogic 为懒加载 Controller，可能未注册，安全绕过。
  void _triggerHomeStatsRefresh() {
    try {
      // 通过 EventBus 解耦，避免直接依赖 HomeLogic
      EventBusUtil.fire(const HomeStatsRefreshEvent());
    } catch (e) {
      LogUtil.w('[GlobalNotification] _triggerHomeStatsRefresh error: $e');
    }
  }

  void _onOrderStatusChanged(OrderStatusChangedEvent e) {
    LogUtil.d('[EventBus] order ${e.orderId}: ${e.oldStatus.name} → ${e.newStatus.name}');
    // 接单/拒单/状态变更后立即同步角标，无需等待下一次 HOME_DATA 推送
    _syncOrderBadge(Get.find<OrderService>());
  }

  void _onTechStatusChanged(TechStatusChangedEvent e) {
    // AppStatusToast is already shown by HomeLogic.changeStatus — no second toast needed
    LogUtil.d('[EventBus] status: ${e.oldStatus.name} → ${e.newStatus.name}');
  }

  void _onNewMessage(NewMessageEvent e) {
    if (Get.currentRoute == AppRoutes.chat) return;
    final title = e.type == ConversationType.customer
        ? gL10n.customerMessage : gL10n.systemMessage;
    AppBanner.show(
      title: title,
      subtitle: '${e.senderName}：${e.content}',
      actionLabel: gL10n.btnDetail,
      onAction: () => Get.toNamed(AppRoutes.chat,
          arguments: {'id': e.conversationId, 'name': e.senderName}),
    );
  }

  void _onServiceCompleted(ServiceCompletedEvent e) {
    ToastUtil.success('${gL10n.serviceCompleted} +\$${e.earnedAmount.toStringAsFixed(2)}');
  }

  void _onBalanceChanged(BalanceChangedEvent e) {
    LogUtil.i('[Balance] ${e.oldBalance} → ${e.newBalance}（${e.reason}）');
  }

  void _onSystemNotice(SystemNoticeEvent e) {
    switch (e.level) {
      case NoticeLevel.success: ToastUtil.success(e.body); break;
      case NoticeLevel.warning: ToastUtil.warning(e.body); break;
      case NoticeLevel.error:   ToastUtil.error(e.body);   break;
      case NoticeLevel.info:    ToastUtil.info(e.body);    break;
    }
  }

  void _onGrabExpired(GrabExpiredEvent e) {
    if (_grabDialogOpen) {
      _grabDialogOpen = false;
      Get.back();
    }
    ToastUtil.warning(gL10n.grabExpired);
  }

  // ── 新订单横幅 ────────────────────────────────────────────────────────────
  void _showNewOrderBanner(OrderModel order) {
    final name     = order.customer.nickname.isNotEmpty
        ? order.customer.nickname : gL10n.unknownCustomer;
    final svcPart  = order.services.isNotEmpty
        ? ' · ${order.services.first.name}' : '';
    final amtPart  = order.totalAmount > 0
        ? ' · \$${order.totalAmount.toStringAsFixed(0)}' : '';
    AppBanner.show(
      title: '🔔 ${gL10n.newOrder}',
      subtitle: '$name$amtPart$svcPart',
      actionLabel: gL10n.btnDetail,
      onAction: () => Get.toNamed(AppRoutes.orderDetail, arguments: {'id': order.id}),
      duration: const Duration(seconds: 5),
    );
  }

  // ── 抢单弹窗 ─────────────────────────────────────────────────────────────
  void _showGrabOrderDialog(NewOrderEvent e) {
    final order     = e.order;
    final total     = e.grabCountdownSecs;
    final remaining = total.obs;

    final sub = EventBusUtil.on<GrabCountdownTickEvent>()
        .where((t) => t.orderId == order.id)
        .listen((t) => remaining.value = t.remaining);

    _grabDialogOpen = true;
    Get.dialog(
      _GrabOrderDialog(order: order, remaining: remaining, total: total),
      barrierDismissible: false,
    ).then((_) {
      _grabDialogOpen = false;
      sub.cancel();
    });
  }

  @override
  void onClose() {
    _wsNewOrderSub?.cancel();
    cancelAllSubscriptions();
    super.onClose();
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// 抢单弹窗 —— 精品重设计
// ══════════════════════════════════════════════════════════════════════════════

class _GrabOrderDialog extends StatelessWidget {
  final OrderModel order;
  final RxInt      remaining;
  final int        total;

  const _GrabOrderDialog({
    required this.order,
    required this.remaining,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final l        = context.l10n;
    final customer = order.customer.nickname.isNotEmpty
        ? order.customer.nickname : l.unknownCustomer;
    final svcName  = order.services.isNotEmpty
        ? order.services.map((s) => s.name).join(' · ') : '—';

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.22),
              blurRadius: 60, spreadRadius: 0, offset: const Offset(0, 20),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20, offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: Column(mainAxisSize: MainAxisSize.min, children: [

            // ── 头部：渐变背景 + 倒计时 + 金额 ──────────────────────────
            _DialogHeader(remaining: remaining, total: total,
                amount: order.totalAmount, label: l.newOrderGrab),

            // ── 客户 & 服务信息 ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 4),
              child: Column(children: [
                _DetailTile(
                  icon: Icons.person_rounded,
                  color: const Color(0xFF6C63FF),
                  label: l.customerInfo,
                  value: customer,
                ),
                _DetailTile(
                  icon: Icons.spa_rounded,
                  color: const Color(0xFF00BFA5),
                  label: l.serviceType,
                  value: svcName,
                ),
                _DetailTile(
                  icon: Icons.schedule_rounded,
                  color: const Color(0xFFFF9800),
                  label: l.appointTime,
                  value: _fmt(order.appointTime),
                ),
                if (order.distance != null)
                  _DetailTile(
                    icon: Icons.near_me_rounded,
                    color: const Color(0xFF2196F3),
                    label: l.distanceFrom,
                    value: '${order.distance!.toStringAsFixed(1)} km',
                  ),
                _DetailTile(
                  icon: order.serviceMode == ServiceMode.home
                      ? Icons.home_rounded : Icons.storefront_rounded,
                  color: const Color(0xFFE91E63),
                  label: l.serviceType,
                  value: order.serviceMode == ServiceMode.home
                      ? l.homeService : l.storeService,
                ),
              ]),
            ),

            // ── 分隔线 ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
              child: Divider(
                  color: AppColors.border.withValues(alpha: 0.6), height: 1),
            ),

            // ── 操作按钮 ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Row(children: [
                // 忽略按钮
                _OutlineBtn(
                  label: l.ignore,
                  onTap: () => Get.back(),
                ),
                const SizedBox(width: 12),
                // 立即接单
                Expanded(child: _GradientBtn(
                  label: l.grabOrder,
                  onTap: () async {
                    Get.back();
                    final ok = await Get.find<OrderService>().accept(order.id);
                    if (ok) {
                      Get.toNamed(AppRoutes.orderDetail,
                          arguments: {'id': order.id});
                    } else {
                      AppToast.error(gL10n.failed);
                    }
                  },
                )),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  String _fmt(DateTime d) =>
      '${d.month.toString().padLeft(2,'0')}/${d.day.toString().padLeft(2,'0')} '
      '${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';
}

// ── 头部：渐变 + 倒计时环 + 金额 ─────────────────────────────────────────────
class _DialogHeader extends StatelessWidget {
  final RxInt  remaining;
  final int    total;
  final double amount;
  final String label;
  const _DialogHeader({
    required this.remaining, required this.total,
    required this.amount,    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      decoration: const BoxDecoration(
        gradient: AppColors.gradientPrimary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(children: [
        // 标题行
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.campaign_rounded,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(
              color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700,
              letterSpacing: 0.5)),
        ]),
        const SizedBox(height: 20),

        // 倒计时 + 金额横排
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          // 倒计时圆环
          Obx(() {
            final sec    = remaining.value;
            final urgent = sec <= 10;
            final ratio  = total > 0 ? sec / total : 0.0;
            return Stack(alignment: Alignment.center, children: [
              // 外圈光晕
              Container(
                width: 90, height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
              // 进度环
              SizedBox(
                width: 80, height: 80,
                child: CircularProgressIndicator(
                  value: ratio,
                  strokeWidth: 7,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation(
                      urgent ? Colors.amber : Colors.white),
                  strokeCap: StrokeCap.round,
                ),
              ),
              // 秒数
              Column(mainAxisSize: MainAxisSize.min, children: [
                Text('$sec', style: TextStyle(
                  color: urgent ? Colors.amber : Colors.white,
                  fontSize: 26, fontWeight: FontWeight.w900,
                  height: 1.1,
                )),
                Text('s', style: TextStyle(
                  color: (urgent ? Colors.amber : Colors.white)
                      .withValues(alpha: 0.7),
                  fontSize: 11, fontWeight: FontWeight.w500,
                )),
              ]),
            ]);
          }),

          // 竖分隔
          Container(width: 1, height: 60,
              color: Colors.white.withValues(alpha: 0.25)),

          // 金额
          Column(children: [
            Text(context.l10n.estimatedEarnings, style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 12, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('\$', style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(width: 2),
              Text(amount.toStringAsFixed(0), style: const TextStyle(
                  color: Colors.white,
                  fontSize: 40, fontWeight: FontWeight.w900,
                  height: 1.0)),
            ]),
          ]),
        ]),
      ]),
    );
  }
}

// ── 信息行 ────────────────────────────────────────────────────────────────────
class _DetailTile extends StatelessWidget {
  final IconData icon;
  final Color    color;
  final String   label;
  final String   value;
  const _DetailTile({
    required this.icon, required this.color,
    required this.label, required this.value,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(children: [
      Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(
              color: AppColors.textSecond, fontSize: 11,
              fontWeight: FontWeight.w500)),
          const SizedBox(height: 1),
          Text(value, style: const TextStyle(
              color: AppColors.textPrimary, fontSize: 14,
              fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis, maxLines: 1,
          ),
        ],
      )),
    ]),
  );
}

// ── 描边按钮 ──────────────────────────────────────────────────────────────────
class _OutlineBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _OutlineBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 88,
    height: 50,
    child: OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textSecond,
        side: BorderSide(color: AppColors.border.withValues(alpha: 0.8)),
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Text(label, style: const TextStyle(
          fontSize: 14, fontWeight: FontWeight.w600)),
    ),
  );
}

// ── 渐变按钮 ──────────────────────────────────────────────────────────────────
class _GradientBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _GradientBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => Container(
    height: 50,
    decoration: BoxDecoration(
      gradient: AppColors.gradientPrimary,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.38),
          blurRadius: 16, offset: const Offset(0, 6),
        ),
      ],
    ),
    child: ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent, elevation: 0,
        shadowColor: Colors.transparent, padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.flash_on_rounded, color: Colors.white, size: 18),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(
            fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white,
            letterSpacing: 0.5)),
      ]),
    ),
  );
}
