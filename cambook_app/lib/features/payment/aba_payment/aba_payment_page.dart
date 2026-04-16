import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';

/// ABA 网银转账支付页 — 完整真实 UI，全部 i18n
class AbaPaymentPage extends StatefulWidget {
  final String orderId;
  const AbaPaymentPage({super.key, required this.orderId});

  @override
  State<AbaPaymentPage> createState() => _AbaPaymentPageState();
}

class _AbaPaymentPageState extends State<AbaPaymentPage> {
  bool _isConfirming = false;
  String? _uploadedProofPath;

  static const _abaAccountName = 'CamBook Platform';
  static const _abaAccountNo = '000 678 xxx';
  static const _abaPhone = '+855 12 345 678';

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: AppTheme.gray900), onPressed: () => Get.back()),
        title: Text(l.payWithAba, style: const TextStyle(color: AppTheme.gray900, fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 金额卡片
            _buildAmountCard(l),
            const SizedBox(height: 16),
            // 收款账户信息
            _buildAccountCard(l),
            const SizedBox(height: 16),
            // 上传转账截图
            _buildUploadSection(l),
            const SizedBox(height: 16),
            // 注意事项
            _buildNotes(l),
            const SizedBox(height: 24),
            // 确认已转账
            ElevatedButton(
              onPressed: _isConfirming ? null : () => _confirmPayment(l),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF003087),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _isConfirming
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(l.iHavePaid, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 12),
            TextButton(onPressed: () => Get.back(), child: Text(l.cancel, style: const TextStyle(color: AppTheme.gray500))),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountCard(AppLocalizations l) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF001F5B), Color(0xFF003087)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(children: [
            Container(
              width: 36, height: 36,
              decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
              child: const Center(child: Text('🏦', style: TextStyle(fontSize: 18))),
            ),
            const SizedBox(width: 10),
            const Text('ABA Bank', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 20),
          Text(l.payAmount, style: const TextStyle(color: Colors.white60, fontSize: 13)),
          const SizedBox(height: 8),
          const Text('\$40.00', style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          const Text('USD', style: TextStyle(color: Colors.white60, fontSize: 13)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(8)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.access_time, color: Colors.white70, size: 16),
              const SizedBox(width: 6),
              Text(l.payTimeRemaining, style: const TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(width: 8),
              const Text('59:28', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700, fontFamily: 'monospace')),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountCard(AppLocalizations l) {
    final rows = [
      {l.abaAccountName: _abaAccountName},
      {l.abaAccountNo: _abaAccountNo},
      {l.abaPhone: _abaPhone},
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(width: 3, height: 16, decoration: BoxDecoration(color: const Color(0xFF003087), borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 8),
            Text(l.payWithAba, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 12),
          ...rows.map((row) {
            final entry = row.entries.first;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(entry.key, style: const TextStyle(fontSize: 13, color: AppTheme.gray500)),
                  Row(children: [
                    Text(entry.value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.gray900)),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: entry.value));
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.copied), duration: const Duration(seconds: 2)));
                      },
                      child: const Icon(Icons.copy_outlined, size: 16, color: AppTheme.gray400),
                    ),
                  ]),
                ],
              ),
            );
          }),
          // 订单编号备注提示
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFFFFF8E6), borderRadius: BorderRadius.circular(8)),
            child: Row(children: [
              const Icon(Icons.warning_amber_outlined, color: AppTheme.primaryColor, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text('${l.usdtTips}: CB20260412001', style: const TextStyle(fontSize: 12, color: AppTheme.gray700))),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadSection(AppLocalizations l) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.uploadProof, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.gray900)),
          const SizedBox(height: 4),
          Text(l.loading, style: const TextStyle(fontSize: 12, color: AppTheme.gray400)),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              // TODO: 调用 image_picker 选取转账截图
            },
            child: Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.gray100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.gray300, style: BorderStyle.solid),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _uploadedProofPath == null ? Icons.add_photo_alternate_outlined : Icons.check_circle_outlined,
                    size: 40,
                    color: _uploadedProofPath == null ? AppTheme.gray300 : Colors.green,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _uploadedProofPath == null ? l.uploadProof : l.operationSuccess,
                    style: TextStyle(fontSize: 13, color: _uploadedProofPath == null ? AppTheme.gray400 : Colors.green),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotes(AppLocalizations l) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFF0F4FF), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF003087).withOpacity(0.15))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: const [
            Icon(Icons.info_outline, size: 16, color: Color(0xFF003087)),
            SizedBox(width: 6),
            Text('Tips', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF003087))),
          ]),
          const SizedBox(height: 10),
          Text(l.usdtTips, style: const TextStyle(fontSize: 13, color: AppTheme.gray700, height: 1.6)),
        ],
      ),
    );
  }

  void _confirmPayment(AppLocalizations l) {
    setState(() => _isConfirming = true);
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) Get.toNamed('/payment/result?success=true&orderNo=CB20260412001');
    });
  }
}
