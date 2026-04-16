import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';

/// 支付页面 — 选择支付方式（USDT/ABA/余额），全部 i18n
class PaymentPage extends StatefulWidget {
  final String orderId;
  const PaymentPage({super.key, required this.orderId});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  int _selectedMethod = 2; // 默认 ABA
  bool _isLoading = false;

  // 支付方式数据
  List<_PayMethod> _buildMethods(AppLocalizations l) => [
    _PayMethod(code: 1, emoji: '₮', name: l.payWithUsdt, desc: 'TRC20 / ERC20', color: const Color(0xFF26A17B)),
    _PayMethod(code: 2, emoji: '🏦', name: l.payWithAba, desc: 'ABA Bank', color: const Color(0xFF003087)),
    _PayMethod(code: 3, emoji: '💰', name: l.payWithBalance, desc: '\$12.50 ${l.balance}', color: AppTheme.primaryColor),
  ];

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final methods = _buildMethods(l);
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: AppTheme.gray900), onPressed: () => Get.back()),
        title: Text(l.selectPayMethod, style: const TextStyle(color: AppTheme.gray900, fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // 订单摘要卡片
                  _buildOrderSummary(l),
                  const SizedBox(height: 16),
                  // 支付方式列表
                  Container(
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: methods.asMap().entries.map((entry) {
                        final i = entry.key;
                        final method = entry.value;
                        return Column(
                          children: [
                            _buildMethodTile(l, method),
                            if (i < methods.length - 1) const Divider(height: 1, indent: 64),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 支付倒计时提示
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFFFFF8E6), borderRadius: BorderRadius.circular(8)),
                    child: Row(children: [
                      const Icon(Icons.access_time, color: AppTheme.primaryColor, size: 16),
                      const SizedBox(width: 8),
                      Text(l.payBeforeExpiry, style: const TextStyle(fontSize: 13, color: AppTheme.gray700)),
                    ]),
                  ),
                ],
              ),
            ),
          ),
          // 底部确认按钮
          _buildBottomBar(l),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(AppLocalizations l) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l.orderDetail, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.gray900)),
              Text('CB20260412001', style: TextStyle(fontSize: 12, color: AppTheme.gray400, fontFamily: 'monospace')),
            ],
          ),
          const Divider(height: 20),
          _SummaryRow(label: l.serviceName, value: l.selectedPackage),
          const SizedBox(height: 6),
          _SummaryRow(label: l.totalAmount, value: '\$45.00'),
          const SizedBox(height: 6),
          _SummaryRow(label: l.discountAmount, value: '-\$5.00', valueColor: Colors.green),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l.payAmount, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              Text('\$40.00', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.red)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMethodTile(AppLocalizations l, _PayMethod method) {
    final isSelected = _selectedMethod == method.code;
    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = method.code),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: method.color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Center(child: Text(method.emoji, style: const TextStyle(fontSize: 20))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(method.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  Text(method.desc, style: const TextStyle(fontSize: 12, color: AppTheme.gray500)),
                ],
              ),
            ),
            // 单选按钮
            Container(
              width: 22, height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: isSelected ? AppTheme.primaryColor : AppTheme.gray300, width: isSelected ? 2 : 1.5),
                color: isSelected ? AppTheme.primaryColor : Colors.transparent,
              ),
              child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 14) : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(AppLocalizations l) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, -2))],
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l.payAmount, style: const TextStyle(fontSize: 12, color: AppTheme.gray500)),
              const Text('\$40.00', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.red)),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _isLoading ? null : () => _handlePay(l),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(l.payConfirm, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  void _handlePay(AppLocalizations l) {
    switch (_selectedMethod) {
      case 1:
        Get.toNamed('/payment/usdt?orderId=${widget.orderId}');
        break;
      case 2:
        Get.toNamed('/payment/aba?orderId=${widget.orderId}');
        break;
      case 3:
        // 余额支付直接扣款
        setState(() => _isLoading = true);
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) Get.toNamed('/payment/result?success=true&orderNo=CB20260412001');
        });
        break;
    }
  }
}

class _PayMethod {
  final int code;
  final String emoji, name, desc;
  final Color color;
  const _PayMethod({required this.code, required this.emoji, required this.name, required this.desc, required this.color});
}

class _SummaryRow extends StatelessWidget {
  final String label, value;
  final Color? valueColor;
  const _SummaryRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.gray500)),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: valueColor ?? AppTheme.gray900)),
      ],
    );
  }
}
