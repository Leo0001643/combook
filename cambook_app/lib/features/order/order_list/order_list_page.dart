import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';

/// 订单列表页 — 全部 i18n，按状态 Tab 切换
class OrderListPage extends StatefulWidget {
  const OrderListPage({super.key});

  @override
  State<OrderListPage> createState() => _OrderListPageState();
}

class _OrderListPageState extends State<OrderListPage> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  final _mockOrders = [
    {'id': '1', 'no': 'CB20260412001', 'tech': '陈秀玲', 'service': '全身推拿 60分钟', 'status': 4, 'amount': '\$45.00', 'time': '2026-04-12 14:00', 'reviewed': false},
    {'id': '2', 'no': 'CB20260412002', 'tech': '蔡庆', 'service': '精油SPA 90分钟', 'status': 3, 'amount': '\$88.00', 'time': '2026-04-12 16:00', 'reviewed': false},
    {'id': '3', 'no': 'CB20260411001', 'tech': '任菁', 'service': '足疗足浴 45分钟', 'status': 4, 'amount': '\$30.00', 'time': '2026-04-11 10:00', 'reviewed': true},
    {'id': '4', 'no': 'CB20260410001', 'tech': '李洋', 'service': '头颈肩理疗 60分钟', 'status': 5, 'amount': '\$50.00', 'time': '2026-04-10 09:00', 'reviewed': false},
    {'id': '5', 'no': 'CB20260409001', 'tech': '阿丽达', 'service': '中式推拿 90分钟', 'status': 0, 'amount': '\$65.00', 'time': '2026-04-15 14:00', 'reviewed': false},
  ];

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final tabs = [l.all, l.orderPendingPay, l.orderInService, l.orderCompleted, l.orderCancelled];
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        title: Text(l.myOrders, style: const TextStyle(color: AppTheme.gray900, fontWeight: FontWeight.w700)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.gray500,
          indicatorColor: AppTheme.primaryColor,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 13),
          tabs: tabs.map((t) => Tab(text: t)).toList(),
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          dividerHeight: 0,
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildOrderList(l, _mockOrders),
          _buildOrderList(l, _mockOrders.where((o) => o['status'] == 0).toList()),
          _buildOrderList(l, _mockOrders.where((o) => o['status'] == 3).toList()),
          _buildOrderList(l, _mockOrders.where((o) => o['status'] == 4).toList()),
          _buildOrderList(l, _mockOrders.where((o) => o['status'] == 5).toList()),
        ],
      ),
    );
  }

  Widget _buildOrderList(AppLocalizations l, List<Map<String, dynamic>> orders) {
    if (orders.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.receipt_long_outlined, size: 60, color: AppTheme.gray200),
        const SizedBox(height: 12),
        Text(l.noData, style: const TextStyle(color: AppTheme.gray400, fontSize: 15)),
      ]));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: orders.length,
      itemBuilder: (_, i) => _buildOrderCard(l, orders[i]),
    );
  }

  Widget _buildOrderCard(AppLocalizations l, Map<String, dynamic> order) {
    final status = order['status'] as int;
    final statusMap = {
      0: (l.orderPendingPay, Colors.orange),
      1: (l.orderPaid, Colors.blue),
      2: (l.orderAccepted, Colors.cyan),
      3: (l.orderInService, const Color(0xFFFF8C00)),
      4: (l.orderCompleted, Colors.green),
      5: (l.orderCancelled, AppTheme.gray400),
      6: (l.orderRefunding, Colors.purple),
      7: (l.orderRefunded, AppTheme.gray400),
    };
    final (statusText, statusColor) = statusMap[status] ?? (l.all, AppTheme.gray400);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
      child: Column(
        children: [
          // 头部
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  const Icon(Icons.person, size: 16, color: AppTheme.gray400),
                  const SizedBox(width: 6),
                  Text(order['tech'] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                ]),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: Text(statusText, style: TextStyle(fontSize: 12, color: statusColor, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // 服务信息
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.spa, color: AppTheme.primaryColor, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(order['service'] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(order['time'] as String, style: const TextStyle(fontSize: 12, color: AppTheme.gray400)),
                  ],
                )),
                Text(order['amount'] as String, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.gray900)),
              ],
            ),
          ),
          // 底部操作栏
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(order['no'] as String, style: const TextStyle(fontSize: 11, color: AppTheme.gray400, fontFamily: 'monospace')),
                Row(
                  children: _buildActions(l, order),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildActions(AppLocalizations l, Map<String, dynamic> order) {
    final status = order['status'] as int;
    final reviewed = order['reviewed'] as bool;
    final actions = <Widget>[];

    if (status == 0) {
      actions.add(_ActionBtn(label: l.payConfirm, isPrimary: true, onTap: () => Get.toNamed('/payment?orderId=${order['id']}')));
      actions.add(const SizedBox(width: 8));
      actions.add(_ActionBtn(label: l.cancelOrder, isPrimary: false, onTap: () {}));
    } else if (status == 3) {
      actions.add(_ActionBtn(label: l.contactTech, isPrimary: false, onTap: () => Get.toNamed('/im/chat/${order['id']}')));
      actions.add(const SizedBox(width: 8));
      actions.add(_ActionBtn(label: l.trackLocation, isPrimary: true, onTap: () {}));
    } else if (status == 4 && !reviewed) {
      actions.add(_ActionBtn(label: l.reviewOrder, isPrimary: true, onTap: () {}));
    } else if (status == 4 && reviewed) {
      actions.add(_ActionBtn(label: l.orderDetail, isPrimary: false, onTap: () => Get.toNamed('/member/orders/${order['id']}')));
    }

    if (actions.isEmpty) {
      actions.add(_ActionBtn(label: l.orderDetail, isPrimary: false, onTap: () => Get.toNamed('/member/orders/${order['id']}')));
    }
    return actions;
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final bool isPrimary;
  final VoidCallback onTap;
  const _ActionBtn({required this.label, required this.isPrimary, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isPrimary ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isPrimary ? AppTheme.primaryColor : AppTheme.gray300),
        ),
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isPrimary ? Colors.white : AppTheme.gray700)),
      ),
    );
  }
}
