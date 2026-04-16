import 'package:get/get.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';

/// 钱包充值：快捷金额、自定义金额、支付方式
class RechargePage extends StatefulWidget {
  const RechargePage({super.key});

  @override
  State<RechargePage> createState() => _RechargePageState();
}

class _RechargePageState extends State<RechargePage> {
  static const _quickAmounts = [10, 20, 50, 100, 200, 500];
  static const _balance = 152.50;

  int? _selectedQuick;
  final _customCtrl = TextEditingController();
  int _method = 0;

  @override
  void dispose() {
    _customCtrl.dispose();
    super.dispose();
  }

  double? _parsedAmount() {
    if (_customCtrl.text.trim().isNotEmpty) {
      return double.tryParse(_customCtrl.text.trim());
    }
    if (_selectedQuick != null) return _selectedQuick!.toDouble();
    return null;
  }

  void _confirm(AppLocalizations l) {
    final amt = _parsedAmount();
    if (amt == null || amt <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.customAmount)));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.operationSuccess)));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: Text(l.recharge),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Get.back(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _balanceCard(l),
                  const SizedBox(height: 20),
                  Text(l.customAmount, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.gray900)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _quickAmounts.map((v) {
                      final sel = _selectedQuick == v && _customCtrl.text.isEmpty;
                      return ChoiceChip(
                        label: Text('\$$v'),
                        selected: sel,
                        onSelected: (_) {
                          setState(() {
                            _selectedQuick = v;
                            _customCtrl.clear();
                          });
                        },
                        selectedColor: AppTheme.primaryLight,
                        labelStyle: TextStyle(
                          color: sel ? AppTheme.primaryColor : AppTheme.gray700,
                          fontWeight: FontWeight.w600,
                        ),
                        side: BorderSide(color: sel ? AppTheme.primaryColor : AppTheme.gray300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _customCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(() {
                      if (_customCtrl.text.isNotEmpty) _selectedQuick = null;
                    }),
                    decoration: InputDecoration(
                      hintText: l.customAmount,
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
                  const SizedBox(height: 24),
                  Text(l.selectPayMethod, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.gray900)),
                  const SizedBox(height: 10),
                  _payCard(
                    selected: _method == 0,
                    icon: Icons.currency_bitcoin,
                    iconColor: const Color(0xFFF7931A),
                    title: l.payWithUsdt,
                    subtitle: l.usdtRechargeSubtitle,
                    onTap: () => setState(() => _method = 0),
                  ),
                  const SizedBox(height: 10),
                  _payCard(
                    selected: _method == 1,
                    icon: Icons.account_balance,
                    iconColor: const Color(0xFF005B9A),
                    title: l.payWithAba,
                    subtitle: l.abaRechargeSubtitle,
                    onTap: () => setState(() => _method = 1),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l.rechargeArrivalNote,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: AppTheme.gray600, height: 1.35),
                  ),
                  const SizedBox(height: 12),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1A1F2E), AppTheme.primaryColor],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                    child: ElevatedButton(
                      onPressed: () => _confirm(l),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        elevation: 0,
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(l.confirmRecharge, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _balanceCard(AppLocalizations l) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1F2E), AppTheme.primaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.currentBalance,
            style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.75)),
          ),
          const SizedBox(height: 6),
          Text(
            '\$${_balance.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _payCard({
    required bool selected,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
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
            border: Border.all(
              color: selected ? AppTheme.primaryColor : AppTheme.gray300,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14))),
                        Icon(
                          selected ? Icons.radio_button_checked : Icons.radio_button_off,
                          color: selected ? AppTheme.primaryColor : AppTheme.gray400,
                          size: 22,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.gray600)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
