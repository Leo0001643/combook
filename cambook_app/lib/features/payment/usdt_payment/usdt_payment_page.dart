import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';

/// USDT 支付页 — 显示收款地址/二维码/网络选择，全部 i18n
class UsdtPaymentPage extends StatefulWidget {
  final String orderId;
  const UsdtPaymentPage({super.key, required this.orderId});

  @override
  State<UsdtPaymentPage> createState() => _UsdtPaymentPageState();
}

class _UsdtPaymentPageState extends State<UsdtPaymentPage> {
  String _network = 'TRC20';
  bool _isConfirming = false;

  static const _trc20Address = 'TYourTRC20AddressHere1234567890ABC';
  static const _erc20Address = '0xYourERC20AddressHere1234567890ABCDEF';

  String get _currentAddress => _network == 'TRC20' ? _trc20Address : _erc20Address;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: AppTheme.gray900), onPressed: () => Get.back()),
        title: Text(l.payWithUsdt, style: const TextStyle(color: AppTheme.gray900, fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 金额卡片
            _buildAmountCard(l),
            const SizedBox(height: 16),
            // 网络选择
            _buildNetworkSelector(l),
            const SizedBox(height: 16),
            // 收款地址 + 二维码
            _buildAddressCard(l),
            const SizedBox(height: 16),
            // 操作说明
            _buildInstructions(l),
            const SizedBox(height: 24),
            // 已完成转账按钮
            ElevatedButton(
              onPressed: _isConfirming ? null : () => _confirmPayment(l),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF26A17B), // USDT绿
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
            TextButton(
              onPressed: () => Get.back(),
              child: Text(l.cancel, style: const TextStyle(color: AppTheme.gray500)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountCard(AppLocalizations l) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF1A2F2A), Color(0xFF26A17B)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 32, height: 32,
                decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                child: const Center(child: Text('₮', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800))),
              ),
              const SizedBox(width: 10),
              const Text('USDT', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 20),
          Text(l.usdtAmount, style: const TextStyle(color: Colors.white60, fontSize: 13)),
          const SizedBox(height: 8),
          const Text('40.00 USDT', style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          const Text('≈ \$40.00 USD', style: TextStyle(color: Colors.white60, fontSize: 13)),
          const SizedBox(height: 16),
          // 倒计时
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(8)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.access_time, color: Colors.white70, size: 16),
              const SizedBox(width: 6),
              Text(l.payTimeRemaining, style: const TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(width: 8),
              const Text('14:32', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700, fontFamily: 'monospace')),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkSelector(AppLocalizations l) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.usdtNetwork, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.gray900)),
          const SizedBox(height: 12),
          Row(
            children: ['TRC20', 'ERC20'].map((net) => GestureDetector(
              onTap: () => setState(() => _network = net),
              child: Container(
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: _network == net ? const Color(0xFF26A17B).withOpacity(0.1) : AppTheme.gray100,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _network == net ? const Color(0xFF26A17B) : AppTheme.gray200, width: _network == net ? 1.5 : 1),
                ),
                child: Column(children: [
                  Text(net, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _network == net ? const Color(0xFF26A17B) : AppTheme.gray600)),
                  Text(net == 'TRC20' ? 'Tron' : 'Ethereum', style: const TextStyle(fontSize: 10, color: AppTheme.gray400)),
                ]),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard(AppLocalizations l) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.usdtAddress, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.gray900)),
          const SizedBox(height: 12),
          // 二维码占位
          Container(
            width: double.infinity, height: 160,
            decoration: BoxDecoration(color: AppTheme.gray100, borderRadius: BorderRadius.circular(8)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.qr_code_2, size: 80, color: AppTheme.gray400),
                const SizedBox(height: 8),
                Text(_network, style: const TextStyle(fontSize: 11, color: AppTheme.gray400)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // 地址
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppTheme.gray100, borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                Expanded(
                  child: Text(_currentAddress, style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: AppTheme.gray700), overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: _currentAddress));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(AppLocalizations.of(context).copied), duration: const Duration(seconds: 2)),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: const Color(0xFF26A17B), borderRadius: BorderRadius.circular(6)),
                    child: Text(l.copyAddress, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructions(AppLocalizations l) {
    final steps = [
      '1. ${l.usdtAmount}: 40.00 USDT',
      '2. ${l.usdtNetwork}: $_network',
      '3. ${l.usdtTips}: CB20260412001',
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFF0FAF7), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF26A17B).withOpacity(0.2))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: const [
            Icon(Icons.info_outline, size: 16, color: Color(0xFF26A17B)),
            SizedBox(width: 6),
            Text('Tips', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF26A17B))),
          ]),
          const SizedBox(height: 10),
          ...steps.map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(s, style: const TextStyle(fontSize: 13, color: AppTheme.gray700, height: 1.5)),
          )),
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
