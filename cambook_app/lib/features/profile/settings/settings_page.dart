import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/auth/auth_controller.dart';

/// 设置页 — 语言、通知、账号安全、关于
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _orderNotify = true;
  bool _promotionNotify = true;
  bool _systemNotify = true;

  // 语言列表中的 code 与 AuthController.appLocale 保持一致
  static const _langs = [
    {'code': 'zh-CN', 'label': '中文', 'flag': '🇨🇳'},
    {'code': 'en',    'label': 'English', 'flag': '🇺🇸'},
    {'code': 'vi',    'label': 'Tiếng Việt', 'flag': '🇻🇳'},
    {'code': 'km',    'label': 'ភាសាខ្មែរ', 'flag': '🇰🇭'},
  ];

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppTheme.gray900),
          onPressed: () => Get.back(),
        ),
        title: Text(l.settings, style: const TextStyle(color: AppTheme.gray900, fontWeight: FontWeight.w700, fontSize: 17)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          _buildSectionHeader(l.langAndLanguage),
          _buildLangSection(),
          const SizedBox(height: 16),
          _buildSectionHeader(l.notifSettings),
          _buildNotificationSection(l),
          const SizedBox(height: 16),
          _buildSectionHeader(l.accountSecurity),
          _buildSecuritySection(l),
          const SizedBox(height: 16),
          _buildSectionHeader(l.aboutUs),
          _buildAboutSection(l),
          const SizedBox(height: 24),
          _buildLogoutButton(context, l),
          const SizedBox(height: 40),
        ]),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(title, style: const TextStyle(fontSize: 13, color: AppTheme.gray500, fontWeight: FontWeight.w500)),
      ),
    );
  }

  Widget _buildLangSection() {
    return Obx(() {
      final currentCode = AuthController.to.appLocale.value;
      return Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: List.generate(_langs.length, (i) {
            final lang = _langs[i];
            final selected = currentCode == lang['code'];
            return Column(
              children: [
                InkWell(
                  onTap: () => AuthController.to.switchLanguage(lang['code']!),
                  borderRadius: i == 0
                      ? const BorderRadius.vertical(top: Radius.circular(16))
                      : i == _langs.length - 1
                          ? const BorderRadius.vertical(bottom: Radius.circular(16))
                          : BorderRadius.zero,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Text(lang['flag']!, style: const TextStyle(fontSize: 24)),
                        const SizedBox(width: 14),
                        Text(lang['label']!, style: const TextStyle(fontSize: 15, color: AppTheme.gray900)),
                        const Spacer(),
                        if (selected)
                          const Icon(Icons.check_circle, color: AppTheme.primaryColor, size: 20),
                      ],
                    ),
                  ),
                ),
                if (i < _langs.length - 1) const Divider(height: 1, indent: 56),
              ],
            );
          }),
        ),
      );
    });
  }

  Widget _buildNotificationSection(AppLocalizations l) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          _switchTile(
            title: l.orderNotifTitle,
            subtitle: l.orderNotifSubtitle,
            value: _orderNotify,
            onChanged: (v) => setState(() => _orderNotify = v),
          ),
          const Divider(height: 1, indent: 16),
          _switchTile(
            title: l.promoNotifTitle,
            subtitle: l.promoNotifSubtitle,
            value: _promotionNotify,
            onChanged: (v) => setState(() => _promotionNotify = v),
          ),
          const Divider(height: 1, indent: 16),
          _switchTile(
            title: l.sysNotifTitle,
            subtitle: l.sysNotifSubtitle,
            value: _systemNotify,
            onChanged: (v) => setState(() => _systemNotify = v),
          ),
        ],
      ),
    );
  }

  Widget _switchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 15, color: AppTheme.gray900)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.gray400)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildSecuritySection(AppLocalizations l) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          _arrowTile(icon: Icons.phone_android_outlined, title: l.changePhone, color: AppTheme.primaryColor),
          const Divider(height: 1, indent: 56),
          _arrowTile(icon: Icons.lock_outline, title: l.changePassword, color: Colors.orange),
          const Divider(height: 1, indent: 56),
          _arrowTile(icon: Icons.fingerprint, title: l.biometric, color: Colors.purple),
        ],
      ),
    );
  }

  Widget _buildAboutSection(AppLocalizations l) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          _arrowTile(icon: Icons.info_outline, title: l.aboutUs, trailing: 'v1.0.0'),
          const Divider(height: 1, indent: 56),
          _arrowTile(icon: Icons.description_outlined, title: l.userAgreement),
          const Divider(height: 1, indent: 56),
          _arrowTile(icon: Icons.privacy_tip_outlined, title: l.privacyPolicy),
          const Divider(height: 1, indent: 56),
          _arrowTile(icon: Icons.star_outline, title: l.rateUs, trailing: '⭐ 5.0'),
          const Divider(height: 1, indent: 56),
          _arrowTile(icon: Icons.headset_mic_outlined, title: l.contactUs),
        ],
      ),
    );
  }

  Widget _arrowTile({required IconData icon, required String title, Color? color, String? trailing}) {
    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(color: (color ?? AppTheme.gray400).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, size: 17, color: color ?? AppTheme.gray500),
            ),
            const SizedBox(width: 12),
            Text(title, style: const TextStyle(fontSize: 15, color: AppTheme.gray900)),
            const Spacer(),
            if (trailing != null) ...[
              Text(trailing, style: const TextStyle(fontSize: 13, color: AppTheme.gray400)),
              const SizedBox(width: 4),
            ],
            const Icon(Icons.chevron_right, size: 18, color: AppTheme.gray300),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, AppLocalizations l) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: () => _confirmLogout(context, l),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.red),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Text(l.logout, style: const TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }

  void _confirmLogout(BuildContext context, AppLocalizations l) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l.logout),
        content: Text(l.confirmLogout),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              AuthController.to.logout();
            },
            child: Text(l.confirm, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
