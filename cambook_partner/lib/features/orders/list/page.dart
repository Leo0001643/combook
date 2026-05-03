import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/extensions/theme_ext.dart';import '../../../core/constants/app_sizes.dart';
import '../../../core/i18n/l10n_ext.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../core/models/models.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/utils/date_util.dart';
import '../../../core/utils/format_util.dart';
import '../../../core/utils/toast_util.dart';
import '../../../core/widgets/common_widgets.dart';
import 'logic.dart';

class OrderListPage extends StatefulWidget {
  const OrderListPage({super.key});

  @override
  State<OrderListPage> createState() => _OrderListPageState();
}

class _OrderListPageState extends State<OrderListPage>
    with TickerProviderStateMixin {
  static const _statuses = [
    OrderStatus.pending, OrderStatus.accepted,
    OrderStatus.inService, OrderStatus.completed, OrderStatus.cancelled,
  ];

  late final TabController _tabCtrl;
  late final OrderListLogic _logic;
  // 每个 tab 独立的弹跳动画控制器
  late final List<AnimationController> _bounceCtrl;
  late final List<Animation<double>> _bounceAnim;

  @override
  void initState() {
    super.initState();
    _logic   = Get.find<OrderListLogic>();
    _tabCtrl = TabController(length: _statuses.length, vsync: this);
    ever(_logic.state.tabIndex, (idx) {
      if (_tabCtrl.index != idx) _tabCtrl.animateTo(idx);
    });

    _bounceCtrl = List.generate(_statuses.length, (_) =>
        AnimationController(vsync: this, duration: const Duration(milliseconds: 260)));
    _bounceAnim = _bounceCtrl.map((c) =>
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.72), weight: 35),
          TweenSequenceItem(tween: Tween(begin: 0.72, end: 1.10), weight: 35),
          TweenSequenceItem(tween: Tween(begin: 1.10, end: 1.0),  weight: 30),
        ]).animate(CurvedAnimation(parent: c, curve: Curves.easeInOut))
    ).toList();

    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging) return;
      final i = _tabCtrl.index;
      _bounceCtrl[i].forward(from: 0);
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    for (final c in _bounceCtrl) { c.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final tabLabels = [l.tabPending, l.tabAccepted, l.tabInService, l.tabCompleted, l.tabCancelled];
    return Scaffold(
        backgroundColor: AppColors.background,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight + 48),
          child: AppBar(
            title: Text(l.ordersTitle),
            automaticallyImplyLeading: false,
            actions: const [MainAppBarActions()],
            bottom: TabBar(
              controller: _tabCtrl,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              unselectedLabelStyle:
                  const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              tabs: List.generate(_statuses.length, (i) {
                return Obx(() {
                  final cnt = _logic.countOf(_statuses[i]);
                  return Tab(
                    child: AnimatedBuilder(
                      animation: _bounceAnim[i],
                      builder: (_, child) => Transform.scale(
                        scale: _bounceAnim[i].value,
                        child: child,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(tabLabels[i]),
                          if (cnt > 0) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                  color: Colors.white30,
                                  borderRadius: BorderRadius.circular(10)),
                              child: Text('$cnt',
                                  style: const TextStyle(fontSize: 10)),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                });
              }),
            ),
          ),
        ),
        body: TabBarView(
          controller: _tabCtrl,
          children:
              _statuses.map((s) => _TabBody(status: s, logic: _logic)).toList(),
        ),
      );
  }
}

class _TabBody extends StatelessWidget {
  final OrderStatus status;
  final OrderListLogic logic;
  const _TabBody({required this.status, required this.logic});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Obx(() {
      if (logic.state.loading.value) {
        return Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            CircularProgressIndicator(color: context.primary, strokeWidth: 2.5),
            const SizedBox(height: 14),
            Text(l.loading, style: TextStyle(color: context.primary.withValues(alpha: .65),
                fontSize: 14, fontWeight: FontWeight.w500)),
          ]),
        );
      }
      final orders = logic.byStatus(status);
      if (orders.isEmpty) return EmptyView(message: l.noOrders);
      return RefreshIndicator(
        color: context.primary,
        onRefresh: logic.refresh,
        child: ListView.separated(
          padding: const EdgeInsets.all(AppSizes.pagePadding),
          itemCount: orders.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) => _OrderCard(order: orders[i], logic: logic),
        ),
      );
    });
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;
  final OrderListLogic logic;
  const _OrderCard({required this.order, required this.logic});

  @override
  Widget build(BuildContext context) {
    final l  = context.l10n;
    final sc = orderStatusColor(order.status);
    return BounceTap(
      onTap: () => Get.toNamed(AppRoutes.orderDetail, arguments: {'id': order.id}),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          boxShadow: const [
            BoxShadow(color: Color(0x0E000000), blurRadius: 14, offset: Offset(0, 3)),
          ],
          border: Border(left: BorderSide(color: sc, width: 4)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 客户 + 状态 ──────────────────────────────────────────
              Row(children: [
                Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                      colors: [sc, sc.withValues(alpha: 0.65)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(
                      color: sc.withValues(alpha: 0.30), blurRadius: 8, offset: const Offset(0, 3))],
                  ),
                  child: Center(child: Text(
                    (order.customer.nickname.isNotEmpty ? order.customer.nickname[0] : '?').toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                  )),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(order.customer.nickname.isNotEmpty ? order.customer.nickname : '--',
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    if (order.distance != null) ...[
                      const SizedBox(height: 2),
                      Row(children: [
                        const Icon(Icons.near_me_rounded, size: 13, color: AppColors.textSecond),
                        const SizedBox(width: 3),
                        Text(FormatUtil.km(order.distance!),
                            style: const TextStyle(fontSize: 13, color: AppColors.textSecond)),
                      ]),
                    ],
                  ],
                )),
                OrderStatusBadge(
                  status: order.status,
                  label: _statusLabel(order.status, l),
                ),
              ]),
              const SizedBox(height: 10),

              // ── 服务标签 ─────────────────────────────────────────────
              Wrap(
                spacing: 6, runSpacing: 5,
                children: order.services.map((s) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: sc.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: sc.withValues(alpha: 0.22)),
                  ),
                  child: Text('${s.name} · ${s.duration}${l.unitMin}',
                      style: TextStyle(
                          fontSize: 13, color: sc, fontWeight: FontWeight.w600)),
                )).toList(),
              ),
              const SizedBox(height: 10),

              // ── 时间 + 金额 ──────────────────────────────────────────
              Row(children: [
                const Icon(Icons.access_time_rounded, size: 14, color: AppColors.textSecond),
                const SizedBox(width: 4),
                Text(DateUtil.format(order.appointTime),
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecond,
                        fontWeight: FontWeight.w500)),
                const SizedBox(width: 8),
                ServiceModeTag(
                  mode: order.serviceMode,
                  label: order.serviceMode == ServiceMode.home ? l.homeService : l.storeService,
                ),
                const Spacer(),
                Text(FormatUtil.money(order.totalAmount),
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800, color: sc)),
              ]),

              if (_hasActions(order.status)) ...[
                const SizedBox(height: 12),
                Divider(height: 1, color: AppColors.divider.withValues(alpha: 0.6)),
                const SizedBox(height: 12),
                _buildActions(context, l),
              ],
            ],
          ),
        ),
      ),
    );
  }

  bool _hasActions(OrderStatus s) =>
      s == OrderStatus.pending || s == OrderStatus.accepted || s == OrderStatus.inService;

  Widget _buildActions(BuildContext context, AppLocalizations l) {
    final sc = orderStatusColor(order.status);
    switch (order.status) {
      case OrderStatus.pending:
        return Row(children: [
          Expanded(child: OutlinedButton(
            onPressed: () async {
              final ok = await ToastUtil.confirm(l.confirm, l.rejectConfirm);
              if (ok) logic.reject(order.id);
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.danger,
              side: const BorderSide(color: AppColors.danger),
              padding: const EdgeInsets.symmetric(vertical: 12),
              textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusSm)),
            ),
            child: Text(l.btnReject),
          )),
          const SizedBox(width: 10),
          Expanded(flex: 2, child: ElevatedButton(
            onPressed: () async {
              final ok = await ToastUtil.confirm(l.confirm, l.acceptConfirm);
              if (ok) logic.accept(order.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: sc,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              elevation: 2,
              shadowColor: sc.withValues(alpha: 0.35),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusSm)),
            ),
            child: Text(l.btnAccept),
          )),
        ]);
      case OrderStatus.accepted:
        return Row(children: [
          Expanded(child: OutlinedButton.icon(
            onPressed: () => Get.toNamed(AppRoutes.orderDetail, arguments: {'id': order.id}),
            icon: const Icon(Icons.info_outline_rounded, size: 17),
            label: Text(l.btnDetail),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusSm)),
            ),
          )),
          const SizedBox(width: 10),
          Expanded(flex: 2, child: ElevatedButton(
            onPressed: () async => logic.start(order.id),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              elevation: 2,
              shadowColor: AppColors.secondary.withValues(alpha: 0.35),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusSm)),
            ),
            child: Text(l.btnStartService),
          )),
        ]);
      case OrderStatus.inService:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => Get.toNamed(AppRoutes.serviceActive),
            icon: const Icon(Icons.timelapse_rounded, size: 20),
            label: Text('${l.tabInService} — ${l.btnDetail}'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              elevation: 3,
              shadowColor: AppColors.secondary.withValues(alpha: 0.35),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
            ),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  String _statusLabel(OrderStatus s, AppLocalizations l) => switch (s) {
    OrderStatus.pending   => l.tabPending,
    OrderStatus.accepted  => l.tabAccepted,
    OrderStatus.inService => l.tabInService,
    OrderStatus.completed => l.tabCompleted,
    OrderStatus.cancelled => l.tabCancelled,
  };
}
