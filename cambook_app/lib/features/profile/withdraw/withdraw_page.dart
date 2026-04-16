import 'package:get/get.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';

/// 提现：金额、方式、账户信息、确认
class WithdrawPage extends StatefulWidget {
  const WithdrawPage({super.key});

  @override
  State<WithdrawPage> createState() => _WithdrawPageState();
}

class _WithdrawPageState extends State<WithdrawPage> {
  static const _available = 152.50;
  static const _minWithdraw = 10.0;
  static const _feePercent = 1.0;

  final _amountCtrl = TextEditingController();
  final _usdtCtrl = TextEditingController();
  final _abaNameCtrl = TextEditingController();
  final _abaNoCtrl = TextEditingController();

  int _method = 0;
  bool _saveAccount = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _usdtCtrl.dispose();
    _abaNameCtrl.dispose();
    _abaNoCtrl.dispose();
    super.dispose();
  }

  double? _amountValue() => double.tryParse(_amountCtrl.text.trim());

  void _fillAll() {
    setState(() => _amountCtrl.text = _available.toStringAsFixed(2));
  }

  Future<void> _submit(AppLocalizations l) async {
    final a = _amountValue();
    if (a == null || a < _minWithdraw) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.minWithdraw)));
      return;
    }
    if (a > _available) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.withdrawMaxHint)));
      return;
    }
    if (_method == 0 && _usdtCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.enterWalletAddress)));
      return;
    }
    if (_method == 1) {
      if (_abaNameCtrl.text.trim().isEmpty || _abaNoCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.abaAccountName)));
        return;
      }
    }

    final fee = a * _feePercent / 100;
    final receive = a - fee;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.confirmWithdraw),
        content: Text(
          '${l.withdrawSubmitConfirmMessage}\n\n${l.withdrawAmount}: \$${a.toStringAsFixed(2)}\n${l.platformFeeOnePercent}\n${l.withdrawReceiveApprox("\$${receive.toStringAsFixed(2)}")}',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.confirm)),
        ],
      ),
    );
    if (ok == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.operationSuccess)));
      Get.back();
    }
  }

  void _mockScan() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).scanQrCode)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: Text(l.withdraw),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _balanceBanner(l),
            const SizedBox(height: 20),
            Text(l.withdrawAmount, style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.gray900)),
            const SizedBox(height: 6),
            Text(l.minWithdraw, style: const TextStyle(fontSize: 12, color: AppTheme.gray600)),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      hintText: '\$0.00',
                      prefixText: '\$ ',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppTheme.gray300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppTheme.gray300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                TextButton(
                  onPressed: _fillAll,
                  child: Text(l.all, style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            Text(l.withdrawMaxHint, style: const TextStyle(fontSize: 11, color: AppTheme.gray500)),
            const SizedBox(height: 20),
            Text(l.withdrawMethod, style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.gray900)),
            const SizedBox(height: 10),
            _methodTile(
              selected: _method == 0,
              title: l.usdtWalletLabel,
              subtitle: l.usdtRechargeSubtitle,
              icon: Icons.currency_bitcoin,
              iconColor: const Color(0xFFF7931A),
              onTap: () => setState(() => _method = 0),
            ),
            const SizedBox(height: 8),
            _methodTile(
              selected: _method == 1,
              title: l.abaAccountLabel,
              subtitle: l.payWithAba,
              icon: Icons.account_balance,
              iconColor: const Color(0xFF005B9A),
              onTap: () => setState(() => _method = 1),
            ),
            const SizedBox(height: 16),
            if (_method == 0) ...[
              TextField(
                controller: _usdtCtrl,
                decoration: InputDecoration(
                  labelText: l.enterWalletAddress,
                  filled: true,
                  fillColor: Colors.white,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.qr_code_scanner_outlined, color: AppTheme.primaryColor),
                    onPressed: _mockScan,
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ] else ...[
              TextField(
                controller: _abaNameCtrl,
                decoration: InputDecoration(
                  labelText: l.abaAccountName,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _abaNoCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l.abaAccountNo,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
            const SizedBox(height: 12),
            CheckboxListTile(
              value: _saveAccount,
              onChanged: (v) => setState(() => _saveAccount = v ?? false),
              title: Text(l.saveAccountForNextTime, style: const TextStyle(fontSize: 14)),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              activeColor: AppTheme.primaryColor,
            ),
            const SizedBox(height: 8),
            Text(l.platformFeeOnePercent, style: const TextStyle(fontSize: 13, color: AppTheme.gray700)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _submit(l),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: Text(l.confirmWithdraw, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _balanceBanner(AppLocalizations l) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.gray200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.balance, style: const TextStyle(fontSize: 12, color: AppTheme.gray600)),
              const SizedBox(height: 4),
              Text('\$${_available.toStringAsFixed(2)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(l.withdraw, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.primaryColor)),
          ),
        ],
      ),
    );
  }

  Widget _methodTile({
    required bool selected,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? AppTheme.primaryColor : AppTheme.gray300, width: selected ? 1.5 : 1),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.gray600)),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? AppTheme.primaryColor : AppTheme.gray400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
