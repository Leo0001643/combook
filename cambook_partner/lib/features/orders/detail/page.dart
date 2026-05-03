import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/extensions/theme_ext.dart';import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/i18n/l10n_ext.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../core/models/models.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/utils/date_util.dart';
import '../../../core/utils/format_util.dart';
import '../../../core/widgets/common_widgets.dart';
import 'logic.dart';

class OrderDetailPage extends StatelessWidget {
  const OrderDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final logic = Get.find<OrderDetailLogic>();
    return Obx(() {
      if (logic.state.loading.value) {
        return Scaffold(body: Center(child: CircularProgressIndicator(color: context.primary)));
      }
      final order = logic.state.order.value;
      if (order == null) {
        final loc = context.l10n;
        return Scaffold(appBar: AppBar(title: Text(loc.orderDetailTitle)), body: EmptyView(message: loc.noData));
      }
      return Scaffold(
        backgroundColor: AppColors.background,
        body: CustomScrollView(slivers: [
          _buildAppBar(context, order),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
            sliver: SliverList(delegate: SliverChildListDelegate([
              _ProgressCard(order: order, arrived: logic.state.arrived.value),
              const SizedBox(height: 12),
              _CustomerCard(order: order, logic: logic),
              const SizedBox(height: 12),
              _OrderInfoCard(order: order),
              const SizedBox(height: 12),
              _ServicesCard(order: order),
              if (order.remark != null && order.remark!.isNotEmpty) ...[
                const SizedBox(height: 12),
                _RemarkCard(remark: order.remark!),
              ],
            ])),
          ),
        ]),
        bottomNavigationBar: _ActionBar(order: order, logic: logic),
      );
    });
  }

  Widget _buildAppBar(BuildContext context, OrderModel order) {
    final l = context.l10n;
    return SliverAppBar(
      expandedHeight: 130,
      pinned: true,
      backgroundColor: context.primary,
      leading: BounceTap(
        pressScale: 0.78,
        onTap: () => Get.back(),
        child: const Padding(
          padding: EdgeInsets.fromLTRB(12, 8, 8, 8),
          child: Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
        ),
      ),
      actions: const [MainAppBarActions()],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(gradient: context.primaryGrad),
          padding: const EdgeInsets.fromLTRB(20, 80, 20, 16),
          alignment: Alignment.bottomLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(l.orderDetailTitle, style: AppTextStyles.whiteH),
              const SizedBox(height: 4),
              Text('# ${order.orderNo}', style: AppTextStyles.whiteXs),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 流程进度条（在线5步 / 门店散客3步） ─────────────────────────────────────────
class _ProgressCard extends StatelessWidget {
  final OrderModel order;
  final bool arrived;
  const _ProgressCard({required this.order, required this.arrived});

  bool get _isWalkin => order.isWalkin;

  int get _current {
    if (order.status == OrderStatus.cancelled) return -1;
    if (_isWalkin) {
      // 门店散客简化进度：待接单(0) → 服务中(1) → 已完成(2)
      if (order.status == OrderStatus.pending)   return 0;
      if (order.status == OrderStatus.inService) return 1;
      return 2;
    }
    if (order.status == OrderStatus.pending)   return 0;
    if (order.status == OrderStatus.accepted)  return arrived ? 2 : 1;
    if (order.status == OrderStatus.inService) return 3;
    return 4;
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final steps = _isWalkin
        ? [l.stepPending, l.tabInService, l.stepCompleted]
        : [l.stepPending, l.stepAccepted, l.stepArrived, l.stepInService, l.stepCompleted];
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l.serviceProgress, style: AppTextStyles.label1),
              if (order.status == OrderStatus.cancelled)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: AppColors.danger.withValues(alpha:0.1), borderRadius: BorderRadius.circular(20)),
                  child: Text(l.tabCancelled, style: const TextStyle(color: AppColors.danger, fontSize: 11, fontWeight: FontWeight.w700)),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: List.generate(steps.length, (i) {
              final done   = _current >= 0 && i <= _current;
              final active = i == _current;
              return Expanded(child: Row(children: [
                Expanded(child: Column(children: [
                  Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: done ? context.primary : AppColors.border,
                      boxShadow: active ? [BoxShadow(color: context.primary.withValues(alpha:0.4), blurRadius: 8)] : null,
                    ),
                    alignment: Alignment.center,
                    child: done
                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 15)
                      : Text('${i+1}', style: const TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 5),
                  Text(steps[i], textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 9,
                        color: done ? context.primary : AppColors.textHint,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                      )),
                ])),
                if (i < steps.length - 1)
                  Expanded(child: Container(
                      height: 2,
                      margin: const EdgeInsets.only(bottom: 20),
                      color: (done && i < _current) ? context.primary : AppColors.border)),
              ]));
            }),
          ),
        ],
      ),
    );
  }
}

// ── 客户信息 ───────────────────────────────────────────────────────────────────
class _CustomerCard extends StatelessWidget {
  final OrderModel order;
  final OrderDetailLogic logic;
  const _CustomerCard({required this.order, required this.logic});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.customerInfo, style: AppTextStyles.label1),
          const SizedBox(height: 12),
          Row(children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: context.primary.withValues(alpha:0.1),
              child: Text((order.customer.nickname.isNotEmpty ? order.customer.nickname[0] : '?').toUpperCase(),
                  style: TextStyle(color: context.primary, fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order.customer.nickname, style: AppTextStyles.label1),
                const SizedBox(height: 2),
                Text(order.customer.phone, style: AppTextStyles.body3),
              ],
            )),
            _IconBtn(Icons.phone_rounded, AppColors.success, l.call, logic.callCustomer),
            const SizedBox(width: 8),
            _IconBtn(Icons.chat_bubble_rounded, context.primary, l.messagesTitle, () {
              final c = order.customer;
              Get.toNamed(AppRoutes.chat, arguments: {
                'id': 'cust_${c.id}',
                'name': c.nickname,
                'customerId': c.id.toString(),
              });
            }),
          ]),
          if (order.customer.address != null) ...[
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.location_on_rounded, color: AppColors.danger, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(order.customer.address!, style: AppTextStyles.body3)),
              const SizedBox(width: 8),
              _TextBtn(Icons.navigation_rounded, l.navigate, logic.navigateToCustomer),
            ]),
          ],
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon; final Color color; final String label; final VoidCallback onTap;
  const _IconBtn(this.icon, this.color, this.label, this.onTap);
  @override
  Widget build(BuildContext context) => BounceTap(
    onTap: onTap,
    child: Column(children: [
      Container(
        width: 36, height: 36,
        decoration: BoxDecoration(color: color.withValues(alpha:0.1), shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 18),
      ),
      const SizedBox(height: 3),
      Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w500)),
    ]),
  );
}

class _TextBtn extends StatelessWidget {
  final IconData icon; final String label; final VoidCallback onTap;
  const _TextBtn(this.icon, this.label, this.onTap);
  @override
  Widget build(BuildContext context) => BounceTap(
    onTap: onTap,
    child: TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 14),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
    ),
  );
}

// ── 订单信息 ───────────────────────────────────────────────────────────────────
class _OrderInfoCard extends StatelessWidget {
  final OrderModel order;
  const _OrderInfoCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l.orderInfo, style: AppTextStyles.label1),
        const SizedBox(height: 10),
        _infoRow(l, l.orderNo,  order.orderNo),
        _infoRow(l, l.serviceType, order.serviceMode == ServiceMode.home ? l.homeService : l.storeService),
        _infoRow(l, l.appointTime, DateUtil.format(order.appointTime)),
        _infoRow(l, l.orderTime, DateUtil.format(order.createTime)),
        _infoRow(l, l.totalAmount,  FormatUtil.moneyFull(order.totalAmount), highlight: true),
      ]),
    );
  }

  Widget _infoRow(AppLocalizations l, String k, String v, {bool highlight = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: [
      SizedBox(width: 78, child: Text(k, style: AppTextStyles.body3)),
      Expanded(child: Text(v, style: highlight ? AppTextStyles.amountSm : AppTextStyles.label2)),
    ]),
  );
}

// ── 服务项目 ───────────────────────────────────────────────────────────────────
class _ServicesCard extends StatelessWidget {
  final OrderModel order;
  const _ServicesCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l.serviceItems, style: AppTextStyles.label1),
        const SizedBox(height: 12),
        ...order.services.map((s) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: AppColors.secondary.withValues(alpha:0.1), borderRadius: BorderRadius.circular(AppSizes.radiusSm)),
              child: const Icon(Icons.spa_rounded, color: AppColors.secondary, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.name, style: AppTextStyles.label2),
              Text('${s.duration} ${l.unitMin}', style: AppTextStyles.caption),
            ])),
            Text(FormatUtil.money(s.price), style: AppTextStyles.amountSm),
          ]),
        )),
        const Divider(),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(l.amount, style: AppTextStyles.label1),
          Text(FormatUtil.moneyFull(order.totalAmount), style: AppTextStyles.amountMd),
        ]),
      ]),
    );
  }
}

// ── 备注 ───────────────────────────────────────────────────────────────────────
class _RemarkCard extends StatelessWidget {
  final String remark;
  const _RemarkCard({required this.remark});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l.customerNotes, style: AppTextStyles.label1),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFFFFF9C4), borderRadius: BorderRadius.circular(AppSizes.radiusSm)),
          child: Row(children: [
            const Icon(Icons.notes_rounded, color: Color(0xFF92400E), size: 16),
            const SizedBox(width: 8),
            Expanded(child: Text(remark, style: const TextStyle(fontSize: 14, color: Color(0xFF78350F)))),
          ]),
        ),
      ]),
    );
  }
}

// ── 底部操作栏（完整服务流程：接/拒 → 到达 → 开始服务 → 完成）────────────────
class _ActionBar extends StatelessWidget {
  final OrderModel order;
  final OrderDetailLogic logic;
  const _ActionBar({required this.order, required this.logic});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final content = _buildContent(context, l);
    if (content == null) return const SizedBox.shrink();
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Color(0x0F000000), blurRadius: 12, offset: Offset(0, -2))],
      ),
      child: content,
    );
  }

  Widget? _buildContent(BuildContext ctx, AppLocalizations l) {
    switch (order.status) {
      case OrderStatus.pending:
        return Row(children: [
          Expanded(child: BounceTap(child: OutlinedButton(
            onPressed: logic.reject,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.danger,
              side: const BorderSide(color: AppColors.danger),
              minimumSize: const Size(0, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(l.btnReject),
          ))),
          const SizedBox(width: 12),
          Expanded(flex: 2, child: BounceTap(child: ElevatedButton(
            onPressed: logic.accept,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(0, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(l.btnAccept, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ))),
        ]);

      case OrderStatus.accepted:
        return Obx(() => Row(children: [
          _SmallBtn(Icons.phone_rounded, l.btnContact, AppColors.info, logic.callCustomer),
          const SizedBox(width: 8),
          if (!logic.state.arrived.value)
            Expanded(child: OutlinedButton.icon(
              onPressed: logic.arrive,
              icon: const Icon(Icons.location_on_rounded, size: 16),
              label: Text(l.confirmArrival),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 48),
                foregroundColor: AppColors.secondary,
                side: const BorderSide(color: AppColors.secondary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ))
          else
            Expanded(child: ElevatedButton.icon(
              onPressed: logic.startService,
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(l.btnStartService, style: const TextStyle(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                minimumSize: const Size(0, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            )),
        ]));

      case OrderStatus.inService:
        return Row(children: [
          _SmallBtn(Icons.phone_rounded, l.btnContact, AppColors.info, logic.callCustomer),
          const SizedBox(width: 8),
          Expanded(child: ElevatedButton.icon(
            onPressed: () => Get.toNamed(AppRoutes.serviceActive),
            icon: const Icon(Icons.timelapse_rounded),
            label: Text(l.btnDetail, style: const TextStyle(fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              minimumSize: const Size(0, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          )),
          const SizedBox(width: 8),
          Expanded(child: ElevatedButton.icon(
            onPressed: logic.complete,
            icon: const Icon(Icons.check_circle_rounded),
            label: Text(l.btnComplete, style: const TextStyle(fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              minimumSize: const Size(0, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          )),
        ]);

      default: return null;
    }
  }
}

class _SmallBtn extends StatelessWidget {
  final IconData icon; final String label; final Color color; final VoidCallback onTap;
  const _SmallBtn(this.icon, this.label, this.color, this.onTap);
  @override
  Widget build(BuildContext context) => BounceTap(
    onTap: onTap,
    child: Container(
      width: 52, height: 48,
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha:0.3)),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: color, size: 18),
        Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
      ]),
    ),
  );
}
