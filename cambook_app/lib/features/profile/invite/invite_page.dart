import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';

/// 邀请好友页
class InvitePage extends StatelessWidget {
  const InvitePage({super.key});

  static const _inviteCode = 'CAMBOOK8866';

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: Text(l.inviteFriends, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 17)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildHeroBanner(l),
                  _buildRewardCards(l),
                  _buildInviteCode(context, l),
                  _buildSteps(l),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          _buildShareBar(context, l),
        ],
      ),
    );
  }

  Widget _buildHeroBanner(AppLocalizations l) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
      child: Column(children: [
        Container(
          width: 120, height: 120,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: const Center(child: Icon(Icons.card_giftcard, size: 60, color: Colors.white)),
        ),
        const SizedBox(height: 20),
        Text(l.inviteFriends, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
        const SizedBox(height: 8),
        Text(l.inviteDesc, style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.85)), textAlign: TextAlign.center),
      ]),
    );
  }

  Widget _buildRewardCards(AppLocalizations l) {
    return Transform.translate(
      offset: const Offset(0, -20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(children: [
          Expanded(child: _rewardCard(icon: Icons.person_add_outlined, title: l.yourReward, subtitle: '\$5 coupon', color: const Color(0xFFFF6B6B))),
          const SizedBox(width: 12),
          Expanded(child: _rewardCard(icon: Icons.people_outline, title: l.friendReward, subtitle: '\$3 coupon', color: const Color(0xFF4ECDC4))),
        ]),
      ),
    );
  }

  Widget _rewardCard({required IconData icon, required String title, required String subtitle, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 10),
        Text(title, style: const TextStyle(fontSize: 13, color: AppTheme.gray500)),
        const SizedBox(height: 4),
        Text(subtitle, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
      ]),
    );
  }

  Widget _buildInviteCode(BuildContext context, AppLocalizations l) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 3))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.myInviteCode, style: const TextStyle(fontSize: 13, color: AppTheme.gray500)),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F7F7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    _inviteCode,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.primaryColor, letterSpacing: 3),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(const ClipboardData(text: _inviteCode));
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(l.copied),
                    backgroundColor: AppTheme.primaryColor,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    duration: const Duration(seconds: 2),
                  ));
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(children: [
                    const Icon(Icons.copy, color: Colors.white, size: 18),
                    const SizedBox(width: 6),
                    Text(l.copy, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildSteps(AppLocalizations l) {
    final steps = [
      {'no': '1', 'textKey': 'step1', 'icon': Icons.share_outlined},
      {'no': '2', 'textKey': 'step2', 'icon': Icons.how_to_reg_outlined},
      {'no': '3', 'textKey': 'step3', 'icon': Icons.card_giftcard_outlined},
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.inviteRules, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.gray900)),
          const SizedBox(height: 12),
          ...steps.map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Center(child: Text(s['no'] as String, style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w800))),
              ),
              const SizedBox(width: 12),
              Icon(s['icon'] as IconData, size: 20, color: AppTheme.gray400),
              const SizedBox(width: 8),
              Expanded(child: Text(
                s['textKey'] == 'step1' ? l.inviteStep1 : s['textKey'] == 'step2' ? l.inviteStep2 : l.inviteStep3,
                style: const TextStyle(fontSize: 14, color: AppTheme.gray700),
              )),
            ]),
          )),
        ],
      ),
    );
  }

  Widget _buildShareBar(BuildContext context, AppLocalizations l) {
    return Container(
      padding: EdgeInsets.only(left: 20, right: 20, bottom: MediaQuery.of(context).padding.bottom + 16, top: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, -3))],
      ),
      child: Row(children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.share, color: Colors.white, size: 18),
            label: Text(l.shareLink, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
          ),
        ),
      ]),
    );
  }
}
