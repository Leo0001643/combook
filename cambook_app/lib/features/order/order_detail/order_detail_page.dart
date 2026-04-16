import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';

/// 订单详情页 — 全部 i18n
class OrderDetailPage extends StatelessWidget {
  final String orderId;
  const OrderDetailPage({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: AppTheme.gray900), onPressed: () => Get.back()),
        title: Text(l.orderDetail, style: const TextStyle(color: AppTheme.gray900, fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 订单状态
            _buildStatusCard(l),
            const SizedBox(height: 12),
            // 技师信息
            _buildTechCard(context, l),
            const SizedBox(height: 12),
            // 服务信息
            _buildServiceInfo(l),
            const SizedBox(height: 12),
            // 支付信息
            _buildPaymentInfo(l),
          ],
        ),
      ),
      bottomNavigationBar: _buildActions(l, context),
    );
  }

  Widget _buildStatusCard(AppLocalizations l) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.check_circle, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Text(l.orderCompleted, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 8),
        Text(l.serviceDatetime + ': 2026-04-12 14:00', style: const TextStyle(color: Colors.white70, fontSize: 13)),
        const SizedBox(height: 4),
        Text(l.orderNo + ': CB20260412001', style: const TextStyle(color: Colors.white70, fontSize: 11, fontFamily: 'monospace')),
      ]),
    );
  }

  Widget _buildTechCard(BuildContext context, AppLocalizations l) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l.technicianInfo, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.gray700)),
        const SizedBox(height: 12),
        Row(children: [
          Container(
            width: 50, height: 50,
            decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [AppTheme.primaryColor, AppTheme.accentColor])),
            child: const Center(child: Icon(Icons.person, color: Colors.white, size: 28)),
          ),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('陈秀玲', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            Row(children: [
              const Icon(Icons.star, color: Colors.amber, size: 14),
              const Text(' 4.9', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            ]),
          ]),
          const Spacer(),
          Row(children: [
            _CircleIconBtn(icon: Icons.chat_bubble_outline, onTap: () => Get.toNamed('/im/chat/tech1')),
            const SizedBox(width: 10),
            _CircleIconBtn(icon: Icons.phone_outlined, onTap: () {}),
          ]),
        ]),
      ]),
    );
  }

  Widget _buildServiceInfo(AppLocalizations l) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l.services, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.gray700)),
        const Divider(height: 20),
        _InfoRow(label: l.serviceName, value: l.selectedPackage),
        const SizedBox(height: 8),
        _InfoRow(label: l.serviceDatetime, value: '2026-04-12 14:00'),
        const SizedBox(height: 8),
        _InfoRow(label: l.serviceAddressLabel, value: 'Phnom Penh, Building 5, Room 201'),
      ]),
    );
  }

  Widget _buildPaymentInfo(AppLocalizations l) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l.payAmount, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.gray700)),
        const Divider(height: 20),
        _InfoRow(label: l.originalPrice, value: '\$45.00'),
        const SizedBox(height: 8),
        _InfoRow(label: l.discountAmount, value: '-\$5.00', valueColor: Colors.green),
        const Divider(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(l.payAmount, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const Text('\$40.00', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.primaryColor)),
        ]),
        const SizedBox(height: 8),
        _InfoRow(label: l.payWithAba, value: l.orderCompleted),
      ]),
    );
  }

  Widget _buildActions(AppLocalizations l, BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: const BoxDecoration(color: Colors.white),
      child: Row(children: [
        Expanded(child: OutlinedButton(
          onPressed: () {},
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.primaryColor,
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            side: const BorderSide(color: AppTheme.primaryColor),
          ),
          child: Text(l.applyRefund),
        )),
        const SizedBox(width: 12),
        Expanded(child: ElevatedButton(
          onPressed: () => Get.toNamed('/order/review/$orderId?techName=技师'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0,
          ),
          child: Text(l.reviewOrder),
        )),
      ]),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  final Color? valueColor;
  const _InfoRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.gray500)),
      Flexible(child: Text(value, style: TextStyle(fontSize: 13, color: valueColor ?? AppTheme.gray900, fontWeight: FontWeight.w500), textAlign: TextAlign.end)),
    ]);
  }
}

class _CircleIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleIconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppTheme.gray200)),
        child: Icon(icon, size: 18, color: AppTheme.gray600),
      ),
    );
  }
}
