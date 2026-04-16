import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';

/// 支付结果页 — 成功/失败状态，全部 i18n
class PaymentResultPage extends StatefulWidget {
  final bool success;
  final String orderNo;
  const PaymentResultPage({super.key, required this.success, required this.orderNo});

  @override
  State<PaymentResultPage> createState() => _PaymentResultPageState();
}

class _PaymentResultPageState extends State<PaymentResultPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _scale = Tween<double>(begin: 0.5, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.5)));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 动画图标
              AnimatedBuilder(
                animation: _ctrl,
                builder: (_, __) => Opacity(
                  opacity: _opacity.value,
                  child: Transform.scale(
                    scale: _scale.value,
                    child: Container(
                      width: 100, height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.success ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                      ),
                      child: Icon(
                        widget.success ? Icons.check_circle : Icons.cancel,
                        size: 64,
                        color: widget.success ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                widget.success ? l.paySuccess : l.payFailed,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: widget.success ? Colors.green : Colors.red),
              ),
              const SizedBox(height: 12),
              if (widget.success) ...[
                Text(l.orderNo, style: const TextStyle(fontSize: 14, color: AppTheme.gray500)),
                const SizedBox(height: 4),
                Text(widget.orderNo, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.gray900, fontFamily: 'monospace')),
              ],
              if (!widget.success)
                Text(l.operationFailed, style: const TextStyle(fontSize: 14, color: AppTheme.gray500, height: 1.5), textAlign: TextAlign.center),
              const SizedBox(height: 48),
              if (widget.success) ...[
                ElevatedButton(
                  onPressed: () => Get.toNamed('/member/orders/${widget.orderNo}'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: Text(l.orderDetail, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => Get.toNamed('/member/home'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    side: const BorderSide(color: AppTheme.primaryColor),
                  ),
                  child: Text(l.navHome, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ] else ...[
                ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: Text(l.retry, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Get.toNamed('/member/home'),
                  child: Text(l.navHome, style: const TextStyle(color: AppTheme.gray500)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
