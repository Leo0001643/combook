/// Shared premium widgets for login & register pages.
library;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/config/app_config.dart';
import '../../core/constants/app_colors.dart';
import '../../core/i18n/l10n_ext.dart';
import '../../core/widgets/app_dialog.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AppBar 品牌 LOGO（左侧）
// ─────────────────────────────────────────────────────────────────────────────
class AuthAppBarBrand extends StatelessWidget {
  const AuthAppBarBrand({super.key});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 34, height: 34,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.20),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.40)),
        ),
        child: const Icon(Icons.spa_rounded, color: Colors.white, size: 18),
      ),
      const SizedBox(width: 9),
      const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(AppConfig.appName,
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w800,
                  fontSize: 14, height: 1.1)),
          Text(AppConfig.merchantName,
              style: TextStyle(
                  color: Colors.white60, fontSize: 10, height: 1.2,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero 区块（AppBar 下方精品渐变横幅，无右侧图标，含装饰圆）
// ─────────────────────────────────────────────────────────────────────────────
class AuthHeroSection extends StatelessWidget {
  final String title;
  final String subtitle;
  const AuthHeroSection(
      {super.key, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    clipBehavior: Clip.hardEdge,
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
      ),
    ),
    child: Stack(children: [
      // 装饰圆 1 — 右上大圆
      Positioned(
        top: -35, right: -18,
        child: Container(
          width: 150, height: 150,
          decoration: const BoxDecoration(
              shape: BoxShape.circle, color: Color(0x0CFFFFFF)),
        ),
      ),
      // 装饰圆 2 — 右侧小圆
      Positioned(
        top: 18, right: 52,
        child: Container(
          width: 48, height: 48,
          decoration: const BoxDecoration(
              shape: BoxShape.circle, color: Color(0x09FFFFFF)),
        ),
      ),
      // 装饰圆 3 — 左下圆
      Positioned(
        bottom: -20, left: -22,
        child: Container(
          width: 100, height: 100,
          decoration: const BoxDecoration(
              shape: BoxShape.circle, color: Color(0x08FFFFFF)),
        ),
      ),
      // 内容
      Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title,
                style: const TextStyle(
                    color: Colors.white, fontSize: 30,
                    fontWeight: FontWeight.w800, height: 1.15,
                    letterSpacing: -0.3)),
            const SizedBox(height: 8),
            Text(subtitle,
                style: const TextStyle(
                    color: Colors.white70, fontSize: 13,
                    fontWeight: FontWeight.w500, height: 1.4)),
          ],
        ),
      ),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// 右侧抽屉（多项设置）
// ─────────────────────────────────────────────────────────────────────────────
class AuthMoreDrawer extends StatelessWidget {
  final void Function(String code) onLangChanged;
  const AuthMoreDrawer({super.key, required this.onLangChanged});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Drawer(
      width: 292,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.horizontal(left: Radius.circular(24))),
      child: Column(children: [
        // ── 顶部品牌 ────────────────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(
              20, MediaQuery.of(context).padding.top + 20, 20, 28),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
            ),
            borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24)),
          ),
          child: const Row(children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: Color(0x2EFFFFFF),
              child: Icon(Icons.spa_rounded, color: Colors.white, size: 26),
            ),
            SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppConfig.appName,
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w800,
                        fontSize: 16)),
                SizedBox(height: 2),
                Row(children: [
                  Icon(Icons.verified_rounded,
                      color: Colors.white70, size: 12),
                  SizedBox(width: 4),
                  Text(AppConfig.merchantName,
                      style: TextStyle(
                          color: Colors.white70, fontSize: 12,
                          fontWeight: FontWeight.w500)),
                ]),
              ],
            )),
          ]),
        ),

        // ── 菜单列表 ────────────────────────────────────────────────────
        Expanded(child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 10),
          children: [
            AuthDrawerItem(
              icon: Icons.campaign_rounded,
              color: const Color(0xFF4F46E5),
              label: l.announcements,
              onTap: () {
                Navigator.pop(context);
                AppToast.info(l.comingSoon);
              },
            ),
            AuthDrawerLangItem(
              label: l.langTitle,
              onChanged: (code) {
                Navigator.pop(context);
                onLangChanged(code);
              },
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              child: Divider(color: Color(0xFFF0F0F6)),
            ),
            AuthDrawerItem(
              icon: Icons.shield_outlined,
              color: const Color(0xFF059669),
              label: l.privacyPolicy,
              onTap: () {
                Navigator.pop(context);
                AppToast.info(l.comingSoon);
              },
            ),
            AuthDrawerItem(
              icon: Icons.description_outlined,
              color: const Color(0xFF0284C7),
              label: l.terms,
              onTap: () {
                Navigator.pop(context);
                AppToast.info(l.comingSoon);
              },
            ),
            AuthDrawerItem(
              icon: Icons.help_outline_rounded,
              color: const Color(0xFFD97706),
              label: l.helpAndSupport,
              onTap: () {
                Navigator.pop(context);
                AppToast.info(l.comingSoon);
              },
            ),
            AuthDrawerItem(
              icon: Icons.star_outline_rounded,
              color: const Color(0xFFF59E0B),
              label: l.rateApp,
              onTap: () {
                Navigator.pop(context);
                AppToast.info(l.comingSoon);
              },
            ),
          ],
        )),

        // ── 版本号 ──────────────────────────────────────────────────────
        Padding(
          padding: EdgeInsets.fromLTRB(
              20, 8, 20, MediaQuery.of(context).padding.bottom + 16),
          child: const Row(children: [
            Icon(Icons.info_outline_rounded, size: 14,
                color: Color(0xFFD1D5DB)),
            SizedBox(width: 6),
            Text('v1.0.0',
                style: TextStyle(
                    color: Color(0xFF9CA3AF), fontSize: 12,
                    fontWeight: FontWeight.w500)),
          ]),
        ),
      ]),
    );
  }
}

class AuthDrawerItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;
  const AuthDrawerItem(
      {super.key, required this.icon, required this.color,
       required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
    leading: Container(
      width: 38, height: 38,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 18, color: color),
    ),
    title: Text(label,
        style: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.w600,
            color: Color(0xFF1F2937))),
    trailing: const Icon(Icons.chevron_right_rounded,
        size: 18, color: Color(0xFFD1D5DB)),
    onTap: onTap,
  );
}

class AuthDrawerLangItem extends StatelessWidget {
  final String label;
  final void Function(String) onChanged;
  const AuthDrawerLangItem(
      {super.key, required this.label, required this.onChanged});

  static const _langs = [
    ('zh', '🇨🇳', '中文'),
    ('en', '🇺🇸', 'English'),
    ('vi', '🇻🇳', 'Tiếng Việt'),
    ('km', '🇰🇭', 'ភាសាខ្មែរ'),
    ('ko', '🇰🇷', '한국어'),
    ('ja', '🇯🇵', '日本語'),
  ];

  @override
  Widget build(BuildContext context) {
    final current = Localizations.localeOf(context).languageCode;
    return PopupMenuButton<String>(
      onSelected: onChanged,
      itemBuilder: (_) => _langs.map((lang) {
        final active = current == lang.$1;
        return PopupMenuItem<String>(
          value: lang.$1,
          child: Row(children: [
            Text(lang.$2, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Text(lang.$3,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        active ? FontWeight.w700 : FontWeight.w500,
                    color: active
                        ? AppColors.primary
                        : const Color(0xFF374151))),
            if (active) ...[
              const Spacer(),
              const Icon(Icons.check_rounded,
                  size: 16, color: AppColors.primary),
            ],
          ]),
        );
      }).toList(),
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
        leading: Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.language_rounded,
              size: 18, color: AppColors.primary),
        ),
        title: Text(label,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937))),
        trailing: const Icon(Icons.chevron_right_rounded,
            size: 18, color: Color(0xFFD1D5DB)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 字段标签
// ─────────────────────────────────────────────────────────────────────────────
class AuthFieldLabel extends StatelessWidget {
  final String text;
  const AuthFieldLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize: 13, fontWeight: FontWeight.w700,
          color: Color(0xFF374151), letterSpacing: 0.1));
}

// ─────────────────────────────────────────────────────────────────────────────
// 密码框
// ─────────────────────────────────────────────────────────────────────────────
class AuthPasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final VoidCallback onToggle;
  const AuthPasswordField(
      {super.key, required this.controller, required this.hint,
       required this.obscure, required this.onToggle});

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    obscureText: obscure,
    decoration: InputDecoration(
      hintText: hint,
      prefixIcon: const Icon(Icons.lock_rounded, size: 18,
          color: Color(0xFFADB5C8)),
      suffixIcon: IconButton(
        icon: Icon(
          obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
          size: 18, color: const Color(0xFFADB5C8),
        ),
        onPressed: onToggle,
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// 渐变主按钮（带右箭头）
// ─────────────────────────────────────────────────────────────────────────────
class AuthGradientButton extends StatelessWidget {
  final bool loading;
  final String label;
  final VoidCallback onTap;
  const AuthGradientButton(
      {super.key, required this.loading, required this.label,
       required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: loading ? null : onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      height: 56,
      decoration: BoxDecoration(
        gradient: loading
            ? const LinearGradient(
                colors: [Color(0xFFB0AEF0), Color(0xFFCBAAF8)])
            : const LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: loading
            ? null
            : [
                const BoxShadow(
                    color: Color(0x554F46E5),
                    blurRadius: 20, offset: Offset(0, 8)),
                const BoxShadow(
                    color: Color(0x224F46E5),
                    blurRadius: 6, offset: Offset(0, 2)),
              ],
      ),
      child: Center(
        child: loading
            ? const SizedBox(width: 22, height: 22,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5))
            : Row(mainAxisSize: MainAxisSize.min, children: [
                Text(label,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 16,
                        fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded,
                    color: Colors.white, size: 18),
              ]),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// 国家/地区选择底部弹窗
// ─────────────────────────────────────────────────────────────────────────────
class AuthCountrySheet extends StatelessWidget {
  final List<(String, String, String)> countries;
  final String title;
  final void Function(String code, String flag) onSelect;
  const AuthCountrySheet(
      {super.key, required this.countries, required this.title,
       required this.onSelect});

  @override
  Widget build(BuildContext context) => Container(
    constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.65),
    decoration: const BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const SizedBox(height: 8),
      Container(
          width: 36, height: 4,
          decoration: BoxDecoration(
              color: const Color(0xFFDDE1EE),
              borderRadius: BorderRadius.circular(2))),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 8, 10),
        child: Row(children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w700)),
          const Spacer(),
          IconButton(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.close_rounded,
                color: Color(0xFF6B7280)),
          ),
        ]),
      ),
      const Divider(height: 1, color: Color(0xFFF3F4F6)),
      Flexible(child: ListView(
        padding: const EdgeInsets.only(bottom: 16),
        children: countries.map((c) => ListTile(
          leading: Text(c.$2, style: const TextStyle(fontSize: 22)),
          title: Text(c.$3,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600)),
          trailing: Text(c.$1,
              style: const TextStyle(
                  color: AppColors.textSecond, fontWeight: FontWeight.w600,
                  fontSize: 13)),
          onTap: () { onSelect(c.$1, c.$2); Get.back(); },
        )).toList(),
      )),
    ]),
  );
}
