import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';

/// 订单实时追踪页 — 集成 Google Maps，展示技师位置
class OrderTrackPage extends StatefulWidget {
  final String orderId;
  const OrderTrackPage({super.key, required this.orderId});

  @override
  State<OrderTrackPage> createState() => _OrderTrackPageState();
}

class _OrderTrackPageState extends State<OrderTrackPage> with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  // 模拟追踪进度：0=前往中, 1=已到达, 2=服务中
  int _trackingStep = 0;
  double _estimatedMinutes = 8.0;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.6, end: 1.0).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _startSimulation();
  }

  void _startSimulation() async {
    // 模拟实时追踪状态变化
    await Future.delayed(const Duration(seconds: 4));
    if (mounted) setState(() { _trackingStep = 1; _estimatedMinutes = 0; });
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) setState(() => _trackingStep = 2);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 地图占位区域（实际项目接入 google_maps_flutter）
          _buildMapArea(l),
          // 顶部导航栏
          _buildTopBar(context, l),
          // 底部信息面板
          _buildBottomPanel(context, l),
        ],
      ),
    );
  }

  Widget _buildMapArea(AppLocalizations l) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E3A5F), Color(0xFF2D5016), Color(0xFF1A3A2A)],
        ),
      ),
      child: CustomPaint(painter: _MapGridPainter(), child: Container()),
    );
  }

  Widget _buildTopBar(BuildContext context, AppLocalizations l) {
    return Positioned(
      top: 0, left: 0, right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(children: [
            GestureDetector(
              onTap: () => Get.back(),
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9), shape: BoxShape.circle),
                child: const Icon(Icons.arrow_back_ios_new, size: 16, color: AppTheme.gray900),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(20)),
                child: Row(children: [
                  const Icon(Icons.my_location, size: 16, color: AppTheme.primaryColor),
                  const SizedBox(width: 8),
                  Text(l.trackLocation, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.gray900)),
                  const Spacer(),
                  Text('${l.orderNo}: ${widget.orderId.substring(0, 10)}...', style: const TextStyle(fontSize: 11, color: AppTheme.gray400)),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildBottomPanel(BuildContext context, AppLocalizations l) {
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          left: 20, right: 20,
          top: 16,
          bottom: MediaQuery.of(context).padding.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 抓手
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            // 技师卡片
            _buildTechCard(l),
            const SizedBox(height: 16),
            // 状态进度
            _buildStatusStepper(l),
            const SizedBox(height: 16),
            // 操作按钮
            _buildActionButtons(context, l),
          ],
        ),
      ),
    );
  }

  Widget _buildTechCard(AppLocalizations l) {
    return Row(children: [
      AnimatedBuilder(
        animation: _pulseAnim,
        builder: (_, child) => Transform.scale(scale: _trackingStep == 0 ? _pulseAnim.value : 1.0, child: child),
        child: Stack(children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [AppTheme.primaryColor.withValues(alpha: 0.8), AppTheme.primaryColor]),
            ),
            child: const Center(child: Icon(Icons.person, color: Colors.white, size: 30)),
          ),
          Positioned(
            bottom: 0, right: 0,
            child: Container(
              width: 16, height: 16,
              decoration: BoxDecoration(
                color: _trackingStep == 2 ? Colors.blue : Colors.green,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
        ]),
      ),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('陈秀玲', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.gray900)),
        const SizedBox(height: 3),
        Row(children: [
          const Icon(Icons.star, color: Colors.amber, size: 14),
          const Text(' 4.9  ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          Text(_statusText(l), style: TextStyle(fontSize: 12, color: _statusColor, fontWeight: FontWeight.w600)),
        ]),
        if (_trackingStep == 0) ...[
          const SizedBox(height: 4),
          Text(l.estimatedArrival(_estimatedMinutes.toInt()), style: const TextStyle(fontSize: 12, color: AppTheme.gray500)),
        ],
      ])),
      // 联系按钮
      Column(children: [
        _circleBtn(Icons.phone, Colors.green, () {}),
        const SizedBox(height: 8),
        _circleBtn(Icons.chat_bubble_outline, AppTheme.primaryColor, () => Get.toNamed('/im/chat/tech1')),
      ]),
    ]);
  }

  String _statusText(AppLocalizations l) {
    switch (_trackingStep) {
      case 0: return l.techEnRoute;
      case 1: return l.techArrived;
      default: return l.inService;
    }
  }

  Color get _statusColor {
    switch (_trackingStep) {
      case 0: return Colors.orange;
      case 1: return Colors.green;
      default: return Colors.blue;
    }
  }

  Widget _circleBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }

  Widget _buildStatusStepper(AppLocalizations l) {
    final steps = [
      {'label': l.techEnRouteLabel, 'icon': Icons.directions_walk},
      {'label': l.techArrived, 'icon': Icons.location_on},
      {'label': l.inService, 'icon': Icons.spa_outlined},
      {'label': l.orderCompleted, 'icon': Icons.check_circle},
    ];
    return Row(
      children: List.generate(steps.length, (i) {
        final active = i <= _trackingStep;
        final isLast = i == steps.length - 1;
        return Expanded(
          child: Row(children: [
            Column(children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: active ? AppTheme.primaryColor : Colors.grey.shade200,
                  shape: BoxShape.circle,
                ),
                child: Icon(steps[i]['icon'] as IconData, size: 16, color: active ? Colors.white : Colors.grey.shade400),
              ),
              const SizedBox(height: 4),
              Text(steps[i]['label'] as String, style: TextStyle(fontSize: 10, color: active ? AppTheme.primaryColor : AppTheme.gray400, fontWeight: active ? FontWeight.w600 : FontWeight.normal), textAlign: TextAlign.center),
            ]),
            if (!isLast)
              Expanded(child: Container(height: 2, color: i < _trackingStep ? AppTheme.primaryColor : Colors.grey.shade200, margin: const EdgeInsets.only(bottom: 20))),
          ]),
        );
      }),
    );
  }

  Widget _buildActionButtons(BuildContext context, AppLocalizations l) {
    if (_trackingStep == 2) {
      return SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          child: Text(l.confirmComplete, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
        ),
      );
    }
    return Row(children: [
      Expanded(
        child: OutlinedButton(
          onPressed: () {},
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.red),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: Text(l.cancelOrder, style: const TextStyle(color: Colors.red, fontSize: 14, fontWeight: FontWeight.w600)),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: ElevatedButton(
          onPressed: () => Get.toNamed('/im/chat/tech1'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.symmetric(vertical: 14),
            elevation: 0,
          ),
          child: Text(l.contactTech, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
        ),
      ),
    ]);
  }
}

/// 地图网格背景画布
class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 1;
    const spacing = 30.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // 模拟道路
    final roadPaint = Paint()..color = Colors.white.withValues(alpha: 0.08)..strokeWidth = 6;
    canvas.drawLine(Offset(size.width * 0.2, 0), Offset(size.width * 0.2, size.height), roadPaint);
    canvas.drawLine(Offset(size.width * 0.6, 0), Offset(size.width * 0.6, size.height), roadPaint);
    canvas.drawLine(Offset(0, size.height * 0.3), Offset(size.width, size.height * 0.3), roadPaint);
    canvas.drawLine(Offset(0, size.height * 0.65), Offset(size.width, size.height * 0.65), roadPaint);

    // 定位标记
    final markerPaint = Paint()..color = AppTheme.primaryColor;
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.45), 12, markerPaint);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.45), 8, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.45), 4, markerPaint);

    // 用户位置
    final userPaint = Paint()..color = Colors.blue;
    canvas.drawCircle(Offset(size.width * 0.3, size.height * 0.6), 10, userPaint);
    canvas.drawCircle(Offset(size.width * 0.3, size.height * 0.6), 6, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(size.width * 0.3, size.height * 0.6), 3, userPaint);

    // 路径
    final pathPaint = Paint()
      ..color = AppTheme.primaryColor.withValues(alpha: 0.6)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(size.width * 0.5, size.height * 0.45)
      ..lineTo(size.width * 0.5, size.height * 0.65)
      ..lineTo(size.width * 0.3, size.height * 0.65)
      ..lineTo(size.width * 0.3, size.height * 0.6);
    canvas.drawPath(path, pathPaint);
  }

  @override
  bool shouldRepaint(_MapGridPainter old) => false;
}
