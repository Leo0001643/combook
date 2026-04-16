import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/auth/auth_controller.dart';
import '../../../l10n/app_localizations.dart';

/// 个人中心页 — 完整真实 UI，全部 i18n
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(context, l)),
          SliverToBoxAdapter(child: _buildStats(l)),
          SliverToBoxAdapter(child: _buildMenuGroup(l)),
          SliverToBoxAdapter(child: _buildLogout(context, l)),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Row(
            children: [
              // 头像
              Stack(
                children: [
                  Container(
                    width: 68, height: 68,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: [AppTheme.primaryColor.withOpacity(0.6), AppTheme.primaryColor]),
                    ),
                    child: const Center(child: Icon(Icons.person, size: 36, color: Colors.white)),
                  ),
                  Positioned(
                    bottom: 0, right: 0,
                    child: Container(
                      width: 22, height: 22,
                      decoration: const BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle),
                      child: const Icon(Icons.edit, size: 12, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              // 用户信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Sokha Chan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.gray900)),
                    const SizedBox(height: 4),
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [AppTheme.primaryColor, AppTheme.accentColor]),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(l.memberLevel, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 8),
                      const Text('+855 12 xxx 678', style: TextStyle(fontSize: 12, color: AppTheme.gray400)),
                    ]),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined, color: AppTheme.gray500),
                onPressed: () => Get.toNamed(AppRoutes.settings),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStats(AppLocalizations l) {
    return Builder(builder: (context) {
      final stats = [
        {'label': l.points, 'value': '1280', 'icon': Icons.stars_outlined, 'color': AppTheme.primaryColor, 'route': ''},
        {'label': l.myCoupons, 'value': '3', 'icon': Icons.local_offer_outlined, 'color': Colors.red, 'route': '/profile/coupons'},
        {'label': l.myFavorites, 'value': '4', 'icon': Icons.favorite_outline, 'color': Colors.pink, 'route': '/profile/favorites'},
        {'label': l.myOrders, 'value': '24', 'icon': Icons.receipt_long_outlined, 'color': Colors.blue, 'route': '/member/orders'},
      ];
      return Container(
        margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: stats.map((s) => Expanded(
            child: GestureDetector(
              onTap: () { final r = s['route'] as String; if (r.isNotEmpty) Get.toNamed(r); },
              child: Column(
                children: [
                  Icon(s['icon'] as IconData, color: s['color'] as Color, size: 24),
                  const SizedBox(height: 6),
                  Text(s['value'] as String, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: s['color'] as Color)),
                  const SizedBox(height: 2),
                  Text(s['label'] as String, style: const TextStyle(fontSize: 11, color: AppTheme.gray500)),
                ],
              ),
            ),
          )).toList(),
        ),
      );
    });
  }

  Widget _buildMenuGroup(AppLocalizations l) {
    return Builder(builder: (context) {
      final groups = [
        {
          'title': l.myOrders,
          'items': [
            {'icon': Icons.pending_actions_outlined, 'label': l.orderPendingPay, 'badge': '1', 'route': '/member/orders'},
            {'icon': Icons.engineering_outlined, 'label': l.orderInService, 'badge': '', 'route': '/member/orders'},
            {'icon': Icons.check_circle_outline, 'label': l.orderCompleted, 'badge': '', 'route': '/member/orders'},
            {'icon': Icons.cancel_outlined, 'label': l.applyRefund, 'badge': '', 'route': '/member/orders'},
          ],
        },
        {
          'title': l.myProfile,
          'items': [
            {'icon': Icons.person_outline, 'label': l.editProfile, 'badge': '', 'route': '/profile/edit'},
            {'icon': Icons.location_on_outlined, 'label': l.addressManage, 'badge': '', 'route': '/profile/addresses'},
            {'icon': Icons.card_giftcard_outlined, 'label': l.inviteFriends, 'badge': '', 'route': '/profile/invite'},
            {'icon': Icons.wallet_outlined, 'label': l.myWallet, 'badge': '', 'route': '/wallet'},
            {'icon': Icons.local_offer_outlined, 'label': l.myCoupons, 'badge': '3', 'route': '/profile/coupons'},
          ],
        },
        {
          'title': l.settings,
          'items': [
            {'icon': Icons.lock_outline, 'label': l.accountSecurity, 'badge': '', 'route': '/profile/settings'},
            {'icon': Icons.language_outlined, 'label': l.language, 'badge': '', 'route': '/profile/settings'},
            {'icon': Icons.help_outline, 'label': l.helpCenter, 'badge': '', 'route': ''},
            {'icon': Icons.info_outline, 'label': l.aboutUs, 'badge': '', 'route': '/profile/settings'},
          ],
        },
      ];

      return Column(
        children: groups.map((group) => Container(
          margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Text(group['title'] as String, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.gray400)),
              ),
              ...(group['items'] as List<Map<String, dynamic>>).asMap().entries.map((entry) {
                final item = entry.value;
                final isLast = entry.key == (group['items'] as List).length - 1;
                return Column(
                  children: [
                    ListTile(
                      leading: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: BorderRadius.circular(8)),
                        child: Icon(item['icon'] as IconData, size: 20, color: AppTheme.primaryColor),
                      ),
                      title: Text(item['label'] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if ((item['badge'] as String).isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                              child: Text(item['badge'] as String, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                            ),
                          const Icon(Icons.chevron_right, color: AppTheme.gray300, size: 20),
                        ],
                      ),
                      onTap: () { final r = item['route'] as String; if (r.isNotEmpty) Get.toNamed(r); },
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                      dense: true,
                    ),
                    if (!isLast) const Divider(height: 1, indent: 68),
                  ],
                );
              }).toList(),
            ],
          ),
        )).toList(),
      );
    });
  }

  Widget _buildLogout(BuildContext context, AppLocalizations l) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 16, 12, 0),
      child: ElevatedButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(l.logout),
              content: Text(l.confirm),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    AuthController.to.logout();
                  },
                  child: Text(l.logout, style: const TextStyle(color: Colors.red)),
                ),
              ],
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.red,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.red, width: 1)),
          elevation: 0,
        ),
        child: Text(l.logout, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.red)),
      ),
    );
  }
}
