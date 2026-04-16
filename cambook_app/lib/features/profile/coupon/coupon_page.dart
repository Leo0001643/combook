import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';

/// 我的优惠券页 — 领券中心 + 我的券包
class CouponPage extends StatefulWidget {
  const CouponPage({super.key});

  @override
  State<CouponPage> createState() => _CouponPageState();
}

class _CouponPageState extends State<CouponPage> with SingleTickerProviderStateMixin {
  late TabController _tab;

  final _availableCoupons = [
    {'id': '1', 'type': 'cash', 'value': 10.0, 'threshold': 50.0, 'name': '10元代金券', 'expiry': '2026-06-30', 'status': 'unused', 'stock': 50},
    {'id': '2', 'type': 'discount', 'value': 0.8, 'threshold': 80.0, 'name': '8折优惠券', 'expiry': '2026-05-31', 'status': 'unused', 'stock': 20},
    {'id': '3', 'type': 'cash', 'value': 5.0, 'threshold': 30.0, 'name': '5元代金券', 'expiry': '2026-07-15', 'status': 'unused', 'stock': 100},
    {'id': '4', 'type': 'transport', 'value': 0.0, 'threshold': 0.0, 'name': '免车费券', 'expiry': '2026-05-15', 'status': 'unused', 'stock': 8},
  ];

  final _myCoupons = [
    {'id': 'u1', 'type': 'cash', 'value': 10.0, 'threshold': 50.0, 'name': '新用户专享', 'expiry': '2026-05-30', 'status': 'unused'},
    {'id': 'u2', 'type': 'discount', 'value': 0.9, 'threshold': 60.0, 'name': '9折限时券', 'expiry': '2026-04-20', 'status': 'unused'},
    {'id': 'u3', 'type': 'cash', 'value': 20.0, 'threshold': 100.0, 'name': '满百减20', 'expiry': '2026-03-31', 'status': 'expired'},
    {'id': 'u4', 'type': 'cash', 'value': 5.0, 'threshold': 30.0, 'name': '5元小券', 'expiry': '2026-02-28', 'status': 'used'},
  ];

  final Set<String> _received = {};

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppTheme.gray900),
          onPressed: () => Get.back(),
        ),
        title: Text(l.myCoupons, style: const TextStyle(color: AppTheme.gray900, fontWeight: FontWeight.w700, fontSize: 17)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tab,
          indicatorColor: AppTheme.primaryColor,
          indicatorWeight: 3,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.gray400,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          tabs: [
            Tab(text: l.couponCenter),
            Tab(text: l.myCoupons),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _buildCouponCenter(l),
          _buildMyCoupons(l),
        ],
      ),
    );
  }

  Widget _buildCouponCenter(AppLocalizations l) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _availableCoupons.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final c = _availableCoupons[i];
        final isReceived = _received.contains(c['id'] as String);
        final stock = c['stock'] as int;
        return _CouponCard(
          coupon: c,
          action: stock == 0
              ? _CouponAction.outOfStock
              : isReceived
                  ? _CouponAction.received
                  : _CouponAction.getIt,
          onGet: () {
            setState(() => _received.add(c['id'] as String));
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(l.operationSuccess),
              backgroundColor: AppTheme.primaryColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              duration: const Duration(seconds: 2),
            ));
          },
        );
      },
    );
  }

  Widget _buildMyCoupons(AppLocalizations l) {
    final tabs = [l.unusedCoupon, l.usedCoupon, l.expiredCoupon];
    final statuses = ['unused', 'used', 'expired'];
    return DefaultTabController(
      length: 3,
      child: Column(children: [
        Container(
          color: Colors.white,
          child: TabBar(
            indicatorColor: AppTheme.primaryColor,
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: AppTheme.gray400,
            labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            tabs: tabs.map((t) => Tab(text: t)).toList(),
          ),
        ),
        Expanded(
          child: TabBarView(
            children: statuses.map((s) {
              final filtered = _myCoupons.where((c) => c['status'] == s).toList();
              if (filtered.isEmpty) {
                return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.local_activity_outlined, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Text(l.noData, style: TextStyle(color: Colors.grey.shade400, fontSize: 15)),
                ]));
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _CouponCard(
                  coupon: filtered[i],
                  action: s == 'unused' ? _CouponAction.use : _CouponAction.none,
                  onGet: () => Get.toNamed('/member/technicians'),
                ),
              );
            }).toList(),
          ),
        ),
      ]),
    );
  }
}

enum _CouponAction { getIt, received, outOfStock, use, none }

class _CouponCard extends StatelessWidget {
  final Map<String, dynamic> coupon;
  final _CouponAction action;
  final VoidCallback? onGet;

  const _CouponCard({required this.coupon, required this.action, this.onGet});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final type = coupon['type'] as String;
    final value = coupon['value'] as double;
    final threshold = coupon['threshold'] as double;
    final isExpired = coupon['status'] == 'expired';
    final isUsed = coupon['status'] == 'used';
    final dimmed = isExpired || isUsed;

    Color leftColor = type == 'cash'
        ? const Color(0xFFFF6B6B)
        : type == 'discount'
            ? const Color(0xFFFF9500)
            : const Color(0xFF4ECDC4);
    if (dimmed) leftColor = Colors.grey.shade400;

    return Opacity(
      opacity: dimmed ? 0.6 : 1.0,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Row(
            children: [
              // 左侧彩色区域
              Container(
                width: 90,
                color: leftColor,
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  if (type == 'cash')
                    Text('\$$value', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white))
                  else if (type == 'discount')
                    Text(l.discountFmt((value * 10).toStringAsFixed(0)), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white))
                  else
                    const Icon(Icons.directions_car_outlined, color: Colors.white, size: 32),
                  const SizedBox(height: 2),
                  if (type != 'transport')
                    Text(l.couponMinAmount('\$${threshold.toStringAsFixed(0)}'), style: const TextStyle(fontSize: 10, color: Colors.white70)),
                ]),
              ),
              // 锯齿分割线
              _jagged(leftColor),
              // 右侧内容
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(coupon['name'] as String, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: dimmed ? AppTheme.gray400 : AppTheme.gray900)),
                          _actionWidget(l),
                        ],
                      ),
                      Text(
                        type == 'cash' ? l.cashCoupon : type == 'discount' ? l.discountCoupon : l.freeTransportCoupon,
                        style: TextStyle(fontSize: 11, color: dimmed ? Colors.grey.shade400 : leftColor.withValues(alpha: 0.8)),
                      ),
                      Text(
                        l.couponExpiry(coupon['expiry'] as String),
                        style: const TextStyle(fontSize: 11, color: AppTheme.gray400),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _jagged(Color color) {
    return SizedBox(
      width: 16,
      child: CustomPaint(
        painter: _JaggedPainter(color),
      ),
    );
  }

  Widget _actionWidget(AppLocalizations l) {
    switch (action) {
      case _CouponAction.getIt:
        return GestureDetector(
          onTap: onGet,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(color: AppTheme.primaryColor, borderRadius: BorderRadius.circular(20)),
            child: Text(l.getCoupon, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
          ),
        );
      case _CouponAction.received:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(border: Border.all(color: AppTheme.gray300), borderRadius: BorderRadius.circular(20)),
          child: Text(l.unfavorite, style: const TextStyle(color: AppTheme.gray400, fontSize: 11)),
        );
      case _CouponAction.outOfStock:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(20)),
          child: Text(l.soldOut, style: const TextStyle(color: AppTheme.gray400, fontSize: 11)),
        );
      case _CouponAction.use:
        return GestureDetector(
          onTap: onGet,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(color: AppTheme.primaryColor, borderRadius: BorderRadius.circular(20)),
            child: Text(l.useNow, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
          ),
        );
      case _CouponAction.none:
        return const SizedBox.shrink();
    }
  }
}

class _JaggedPainter extends CustomPainter {
  final Color leftColor;
  _JaggedPainter(this.leftColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = leftColor;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, 0)
      ..lineTo(size.width / 2, 0);

    const r = 6.0;
    double y = 0;
    while (y < size.height) {
      path.arcToPoint(Offset(size.width / 2, y + r * 2), radius: const Radius.circular(r), clockwise: false);
      y += r * 2;
    }
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_JaggedPainter old) => false;
}
