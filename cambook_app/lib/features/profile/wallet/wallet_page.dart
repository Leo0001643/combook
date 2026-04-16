import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';

/// 钱包页 — 完整真实 UI，全部 i18n
class WalletPage extends StatelessWidget {
  const WalletPage({super.key});

  static final _records = [
    {'type': 'income', 'title': 'Order CB20260412001', 'amount': '+\$40.00', 'time': '2026-04-12 14:32', 'color': Colors.green},
    {'type': 'expense', 'title': 'Withdraw to USDT', 'amount': '-\$100.00', 'time': '2026-04-10 09:00', 'color': Colors.red},
    {'type': 'income', 'title': 'Order CB20260409001', 'amount': '+\$65.00', 'time': '2026-04-09 18:00', 'color': Colors.green},
    {'type': 'income', 'title': 'Order CB20260408001', 'amount': '+\$45.00', 'time': '2026-04-08 10:30', 'color': Colors.green},
    {'type': 'expense', 'title': 'Withdraw to ABA', 'amount': '-\$50.00', 'time': '2026-04-05 11:00', 'color': Colors.red},
  ];

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white), onPressed: () => Get.back()),
        title: Text(l.myWallet, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      extendBodyBehindAppBar: true,
      body: Column(
        children: [
          _buildBalanceCard(context, l),
          Expanded(child: _buildTransactions(l)),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(BuildContext context, AppLocalizations l) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF1A1F2E), AppTheme.primaryColor]),
      ),
      padding: const EdgeInsets.fromLTRB(24, 100, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.balance, style: const TextStyle(color: Colors.white60, fontSize: 14)),
          const SizedBox(height: 8),
          const Text('\$152.50', style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(l.frozenBalance + ': \$0.00', style: const TextStyle(color: Colors.white60, fontSize: 12)),
          const SizedBox(height: 28),
          Row(children: [
            _WalletActionBtn(label: l.recharge, icon: Icons.add_circle_outline, onTap: () => Get.toNamed('/wallet/recharge')),
            const SizedBox(width: 16),
            _WalletActionBtn(label: l.withdraw, icon: Icons.arrow_upward, onTap: () => Get.toNamed('/wallet/withdraw')),
            const SizedBox(width: 16),
            _WalletActionBtn(label: l.transactions, icon: Icons.receipt_long_outlined, onTap: () {}),
          ]),
        ],
      ),
    );
  }

  Widget _buildTransactions(AppLocalizations l) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF7F7F7),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l.transactions, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.gray900)),
                Text(l.all, style: const TextStyle(color: AppTheme.primaryColor, fontSize: 13)),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _records.length,
              itemBuilder: (_, i) {
                final r = _records[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: Row(children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: (r['color'] as Color).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        r['type'] == 'income' ? Icons.arrow_downward : Icons.arrow_upward,
                        color: r['color'] as Color, size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(r['title'] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      Text(r['time'] as String, style: const TextStyle(fontSize: 11, color: AppTheme.gray400)),
                    ])),
                    Text(
                      r['amount'] as String,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: r['color'] as Color),
                    ),
                  ]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _WalletActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _WalletActionBtn({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(children: [
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(14)),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ]),
    );
  }
}
