import 'package:get/get.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';

/// 404 插画：简单几何「困惑小人」
class _ConfusedMascotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // 身体（圆角矩形）
    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy + 8), width: 72, height: 88),
      const Radius.circular(18),
    );
    final bodyPaint = Paint()..color = AppTheme.primaryLight;
    canvas.drawRRect(body, bodyPaint);

    // 头部（圆）
    final headPaint = Paint()..color = const Color(0xFFFFE0B2);
    canvas.drawCircle(Offset(cx, cy - 42), 36, headPaint);

    // 问号气泡
    final bubble = Path()
      ..addOval(Rect.fromCenter(center: Offset(cx + 38, cy - 58), width: 36, height: 28));
    canvas.drawPath(
      bubble,
      Paint()..color = Colors.white,
    );
    canvas.drawPath(
      bubble,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = AppTheme.gray300,
    );
    final tp = TextPainter(
      text: const TextSpan(
        text: '?',
        style: TextStyle(
          color: AppTheme.gray700,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx + 38 - tp.width / 2, cy - 58 - tp.height / 2));

    // 眼睛（小圆点）
    final eye = Paint()..color = AppTheme.gray900;
    canvas.drawCircle(Offset(cx - 12, cy - 48), 4, eye);
    canvas.drawCircle(Offset(cx + 12, cy - 48), 4, eye);

    // 困惑眉（折线）
    final brow = Paint()
      ..color = AppTheme.gray700
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(cx - 22, cy - 62), Offset(cx - 6, cy - 56), brow);
    canvas.drawLine(Offset(cx + 6, cy - 56), Offset(cx + 22, cy - 60), brow);

    // 嘴巴（小波浪）
    final mouth = Path()
      ..moveTo(cx - 10, cy - 32)
      ..quadraticBezierTo(cx, cy - 22, cx + 10, cy - 32);
    canvas.drawPath(mouth, brow);

    // 脚
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx - 16, cy + 58), width: 22, height: 12),
        const Radius.circular(6),
      ),
      Paint()..color = AppTheme.gray400,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx + 16, cy + 58), width: 22, height: 12),
        const Radius.circular(6),
      ),
      Paint()..color = AppTheme.gray400,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 404 页面 — 渐变标题 + 渐入动画
/// 说明：AnimatedOpacity 需随状态从 0→1 变化，故使用 [StatefulWidget] 承载动画状态。
class NotFoundPage extends StatefulWidget {
  const NotFoundPage({super.key});

  @override
  State<NotFoundPage> createState() => _NotFoundPageState();
}

class _NotFoundPageState extends State<NotFoundPage> {
  double _opacity = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _opacity = 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: SafeArea(
        child: AnimatedOpacity(
          opacity: _opacity,
          duration: const Duration(milliseconds: 520),
          curve: Curves.easeOutCubic,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) {
                    return LinearGradient(
                      colors: [AppTheme.primaryColor, AppTheme.accentColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds);
                  },
                  child: const Text(
                    '404',
                    style: TextStyle(
                      fontSize: 88,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 160,
                  child: CustomPaint(
                    painter: _ConfusedMascotPainter(),
                    size: const Size(200, 160),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l.pageNotFound,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.gray900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l.pageNotFoundDesc,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: AppTheme.gray600.withValues(alpha: 0.95),
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Get.toNamed('/member/home'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.gray900,
                          side: const BorderSide(color: AppTheme.gray300),
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(l.backHome, style: const TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Get.toNamed('/im'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(l.contactUs, style: const TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
