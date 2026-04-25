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
import '../constants/app_text_styles.dart';
import '../models/models.dart';
import '../routes/app_routes.dart';
import '../widgets/app_dialog.dart';
import 'order_service.dart';
import 'tech_ws_service.dart';

/// 全局通知监听器 —— 在 main.dart 通过 initServices 启动
class GlobalNotificationService extends GetxService with EventBusMixin {
  StreamSubscription<Map<String, dynamic>>? _wsNewOrderSub;

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
    // 前台：播放提示音
    AudioUtil.playNewOrder();
    // 后台 & 前台：同时发送本地通知（确保息屏 / 切后台时也有系统级提醒）
    AudioUtil.notifyNewOrder(
      title: gL10n.newOrder,
      body:  '${e.order.customer.nickname.isNotEmpty ? e.order.customer.nickname : "新客户"} '
             '预约了 ${e.order.services.isNotEmpty ? e.order.services.first.name : "服务"}，请及时接单！',
    );
    if (e.isGrabMode) {
      _showGrabOrderDialog(e);
    } else {
      _showNewOrderBanner(e.order);
    }
  }

  /// WS 推送新订单：刷新订单列表后通过 [OrderService.pushNewOrder] 触发标准流程
  Future<void> _onWsNewOrder(Map<String, dynamic> data) async {
    final orderId = (data['orderId'] as num?)?.toInt();
    if (orderId == null) return;

    final orderService = Get.find<OrderService>();
    // 拉取最新订单列表，确保新订单已进入本地缓存
    await orderService.fetchFromApi();

    final order = orderService.getById(orderId);
    if (order == null) {
      LogUtil.w('[GlobalNotification] WS new order #$orderId not found after fetchFromApi');
      return;
    }

    // 门店散客订单(orderType=2)：横幅提示；在线订单：抢单倒计时弹窗
    final grabMode = order.orderType != 2;
    orderService.pushNewOrder(order, grabMode: grabMode);
  }

  void _onOrderStatusChanged(OrderStatusChangedEvent e) {
    LogUtil.d('[EventBus] order ${e.orderId}: ${e.oldStatus.name} → ${e.newStatus.name}');
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
    if (Get.isDialogOpen == true) Get.back();
    ToastUtil.warning(gL10n.grabExpired);
  }

  // ── 新订单横幅 ────────────────────────────────────────────────────────────
  void _showNewOrderBanner(OrderModel order) {
    final name     = order.customer.nickname.isNotEmpty
        ? order.customer.nickname : '新客户';
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

    Get.dialog(
      _GrabOrderDialog(order: order, remaining: remaining, total: total),
      barrierDismissible: false,
    ).then((_) => sub.cancel());
  }

  @override
  void onClose() {
    _wsNewOrderSub?.cancel();
    cancelAllSubscriptions();
    super.onClose();
  }
}

// ── 抢单弹窗（重设计为精品风格）──────────────────────────────────────────────
class _GrabOrderDialog extends StatelessWidget {
  final OrderModel order;
  final RxInt remaining;
  final int   total;
  const _GrabOrderDialog({required this.order, required this.remaining, required this.total});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 28),
        constraints: const BoxConstraints(maxWidth: 380),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 40, offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // ── 渐变头部 + 倒计时 ─────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
              decoration: const BoxDecoration(
                gradient: AppColors.gradientPrimary,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.campaign_rounded, color: Colors.white, size: 22),
                  const SizedBox(width: 8),
                  Text(l.newOrderGrab, style: AppTextStyles.whiteH),
                ]),
                const SizedBox(height: 16),
                // 倒计时圆环
                Obx(() {
                  final sec = remaining.value;
                  final urgent = sec <= 10;
                  return Stack(alignment: Alignment.center, children: [
                    SizedBox(
                      width: 80, height: 80,
                      child: CircularProgressIndicator(
                        value: total > 0 ? sec / total : 0,
                        strokeWidth: 6,
                        backgroundColor: Colors.white24,
                        valueColor: AlwaysStoppedAnimation(
                            urgent ? Colors.amber : Colors.white),
                      ),
                    ),
                    Container(
                      width: 60, height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Center(child: Text('$sec', style: TextStyle(
                        color: urgent ? Colors.amber : Colors.white,
                        fontSize: 28, fontWeight: FontWeight.w900,
                      ))),
                    ),
                  ]);
                }),
              ]),
            ),

            // ── 订单详情 ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Column(children: [
                _InfoRow(Icons.person_rounded, order.customer.nickname),
                _InfoRow(Icons.spa_rounded,    order.services.map((s) => s.name).join(' · ')),
                _InfoRow(Icons.access_time_rounded, _fmt(order.appointTime)),
                if (order.distance != null)
                  _InfoRow(Icons.near_me_rounded,
                      '${l.distanceFrom} ${order.distance!.toStringAsFixed(1)} km'),
                _InfoRow(
                  order.serviceMode == ServiceMode.home
                      ? Icons.home_rounded : Icons.store_rounded,
                  order.serviceMode == ServiceMode.home
                      ? l.homeService : l.storeService,
                ),
              ]),
            ),

            // 金额
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Text('\$', style: TextStyle(
                    color: AppColors.primary, fontSize: 18, fontWeight: FontWeight.w700)),
                Text(order.totalAmount.toStringAsFixed(0), style: const TextStyle(
                    color: AppColors.primary, fontSize: 40, fontWeight: FontWeight.w900)),
              ]),
            ),

            // ── 操作按钮 ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              child: Row(children: [
                Expanded(child: OutlinedButton(
                  onPressed: () => Get.back(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecond,
                    side: const BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(l.ignore, style: const TextStyle(fontSize: 15)),
                )),
                const SizedBox(width: 12),
                Expanded(flex: 2, child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: AppColors.gradientPrimary,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 10, offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      Get.back();
                      Get.find<OrderService>().accept(order.id);
                      Get.toNamed(AppRoutes.orderDetail, arguments: {'id': order.id});
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent, elevation: 0,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(l.grabOrder,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800,
                            color: Colors.white)),
                  ),
                )),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  String _fmt(DateTime d) =>
      '${d.month}/${d.day} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

class _InfoRow extends StatelessWidget {
  final IconData icon; final String text;
  const _InfoRow(this.icon, this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(children: [
      Container(
        width: 28, height: 28,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 15, color: AppColors.primary),
      ),
      const SizedBox(width: 10),
      Expanded(child: Text(text,
          style: AppTextStyles.body2, overflow: TextOverflow.ellipsis)),
    ]),
  );
}
