import 'package:get/get.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';

/// 订单退款申请
class RefundPage extends StatefulWidget {
  const RefundPage({super.key, required this.orderId});

  final String orderId;

  @override
  State<RefundPage> createState() => _RefundPageState();
}

class _RefundPageState extends State<RefundPage> {
  static const _serviceName = 'Premium Swedish 90min';
  static const _paid = 88.0;
  static const _statusCompleted = true;

  int _reasonIndex = 0;
  final _otherCtrl = TextEditingController();
  final List<String> _evidenceIds = [];

  @override
  void dispose() {
    _otherCtrl.dispose();
    super.dispose();
  }

  double _refundAmount() {
    if (_statusCompleted) return _paid;
    return _paid * 0.85;
  }

  void _addEvidence(AppLocalizations l) {
    setState(() => _evidenceIds.add('p${_evidenceIds.length}'));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.addPhoto)));
  }

  void _removeEvidence(int i) {
    setState(() => _evidenceIds.removeAt(i));
  }

  void _submit(AppLocalizations l) {
    if (_reasonIndex == 3 && _otherCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.refundOtherReasonHint)));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.operationSuccess)));
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final reasons = [
      l.refundReasonNotArrived,
      l.refundReasonMismatch,
      l.refundReasonCancel,
      l.refundReasonOther,
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: Text(l.applyRefund),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Get.back(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _summaryCard(l),
                  const SizedBox(height: 20),
                  Text(l.refundReason, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.gray200),
                    ),
                    child: Column(
                      children: List.generate(reasons.length, (i) {
                        return RadioListTile<int>(
                          value: i,
                          groupValue: _reasonIndex,
                          onChanged: (v) => setState(() => _reasonIndex = v ?? 0),
                          title: Text(reasons[i], style: const TextStyle(fontSize: 14)),
                          activeColor: AppTheme.primaryColor,
                        );
                      }),
                    ),
                  ),
                  if (_reasonIndex == 3) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: _otherCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: l.refundOtherReasonHint,
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(l.estimatedRefundAmount, style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text(
                          '\$${_refundAmount().toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l.refundOriginalMethodNote,
                    style: const TextStyle(fontSize: 12, color: AppTheme.gray600, height: 1.4),
                  ),
                  const SizedBox(height: 20),
                  Text(l.refundEvidenceOptional, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      ...List.generate(_evidenceIds.length, (i) {
                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: AppTheme.gray200,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppTheme.gray300),
                              ),
                              child: Icon(Icons.image_outlined, color: AppTheme.gray500.withValues(alpha: 0.8)),
                            ),
                            Positioned(
                              top: -6,
                              right: -6,
                              child: InkWell(
                                onTap: () => _removeEvidence(i),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(color: AppTheme.errorColor, shape: BoxShape.circle),
                                  child: const Icon(Icons.close, size: 14, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                      InkWell(
                        onTap: () => _addEvidence(l),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.gray300, style: BorderStyle.solid),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate_outlined, color: AppTheme.gray500.withValues(alpha: 0.9)),
                              const SizedBox(height: 2),
                              Text(l.addPhoto, style: const TextStyle(fontSize: 9, color: AppTheme.gray600)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, -2)),
              ],
            ),
            child: SafeArea(
              top: false,
              child: ElevatedButton(
                onPressed: () => _submit(l),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: Text(l.submit, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(AppLocalizations l) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.gray200),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.orderSummary, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 12),
          _row(l.orderNo, widget.orderId),
          const SizedBox(height: 8),
          _row(l.serviceName, _serviceName),
          const SizedBox(height: 8),
          _row(l.amountPaidLabel, '\$${_paid.toStringAsFixed(2)}'),
          const SizedBox(height: 8),
          _row(
            l.orderStatusLabel,
            _statusCompleted ? l.orderCompleted : l.orderCancelled,
          ),
        ],
      ),
    );
  }

  Widget _row(String k, String v) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 96,
          child: Text(k, style: const TextStyle(fontSize: 13, color: AppTheme.gray600)),
        ),
        Expanded(
          child: Text(v, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.gray900)),
        ),
      ],
    );
  }
}
