import 'package:get/get.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';

/// 关于我们 — 品牌、数据、链接与社媒
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppTheme.gray900),
          onPressed: () => Get.back(),
        ),
        title: Text(
          l.aboutUs,
          style: const TextStyle(color: AppTheme.gray900, fontWeight: FontWeight.w700, fontSize: 17),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 8),
          // Logo：渐变圆 + SPA 图标
          Center(
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.accentColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.spa_rounded, size: 48, color: Colors.white),
            ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'CamBook',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.gray900),
            ),
          ),
          const Center(
            child: Text(
              'v1.0.0',
              style: TextStyle(fontSize: 13, color: AppTheme.gray500),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              l.aboutTagline,
              style: TextStyle(fontSize: 14, color: AppTheme.gray600.withValues(alpha: 0.95)),
            ),
          ),
          const SizedBox(height: 24),
          // 数据卡片
          LayoutBuilder(
            builder: (context, c) {
              final w = (c.maxWidth - 12) / 2;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _statCard(w, l.aboutStatUsers, '50,000+'),
                  _statCard(w, l.aboutStatTechs, '2,000+'),
                  _statCard(w, l.aboutStatCities, '12'),
                  _statCard(w, l.aboutStatRating, '98%'),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          // 链接列表
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                _linkTile(
                  context,
                  l.userAgreement,
                  () => Get.toNamed('/profile/terms'),
                ),
                const Divider(height: 1, indent: 16),
                _linkTile(
                  context,
                  l.privacyPolicy,
                  () => Get.toNamed('/profile/privacy'),
                ),
                const Divider(height: 1, indent: 16),
                _linkTile(
                  context,
                  l.aboutOpenSource,
                  () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l.aboutOpenSourceComingSoon)),
                    );
                  },
                ),
                const Divider(height: 1, indent: 16),
                _linkTile(
                  context,
                  l.aboutWebsite,
                  () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('https://cambook.app')),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              l.aboutFollowUs,
              style: const TextStyle(fontSize: 13, color: AppTheme.gray500, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 12),
          // 社媒图标行
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _socialBtn(Icons.facebook_rounded, 'Facebook'),
              const SizedBox(width: 20),
              _socialBtn(Icons.send_rounded, 'Telegram'),
              const SizedBox(width: 20),
              _socialBtn(Icons.camera_alt_rounded, 'Instagram'),
            ],
          ),
          const SizedBox(height: 32),
          Center(
            child: Text(
              '© 2026 CamBook. All rights reserved.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: AppTheme.gray400.withValues(alpha: 0.9)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(double width, String label, String value) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppTheme.gray500),
          ),
        ],
      ),
    );
  }

  Widget _linkTile(BuildContext context, String title, VoidCallback onTap) {
    return ListTile(
      title: Text(title, style: const TextStyle(fontSize: 15, color: AppTheme.gray900)),
      trailing: const Icon(Icons.chevron_right, color: AppTheme.gray300),
      onTap: onTap,
    );
  }

  Widget _socialBtn(IconData icon, String tip) {
    return Tooltip(
      message: tip,
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(),
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Icon(icon, color: AppTheme.gray700, size: 22),
          ),
        ),
      ),
    );
  }
}
