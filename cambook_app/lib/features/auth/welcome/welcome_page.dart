import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/language_switcher_button.dart';
import '../../../l10n/app_localizations.dart';

/// 公开首页 — 所有用户进入 App 后看到的第一个页面
/// 展示平台角色，引导登录 / 注册
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1F2E), Color(0xFF0D1117)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── 顶部：引导页入口 ──────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 引导页
                    TextButton(
                      onPressed: () => Get.toNamed('/onboarding'),
                      child: Text(
                        l.skip,
                        style: const TextStyle(color: Colors.white38, fontSize: 13),
                      ),
                    ),
                    const LanguageSwitcherButton(showLabel: true),
                  ],
                ),
              ),

              // ── 主内容（可滚动） ───────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      SizedBox(height: size.height * 0.04),

                      // Logo
                      Container(
                        width: 92,
                        height: 92,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppTheme.primaryColor, AppTheme.accentColor],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(26),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withOpacity(0.45),
                              blurRadius: 36,
                              offset: const Offset(0, 14),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'C',
                            style: TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),

                      const SizedBox(height: 22),
                      const Text(
                        'CamBook',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l.appTaglineLong,
                        style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 14, letterSpacing: 0.5),
                      ),

                      SizedBox(height: size.height * 0.05),

                      // ── 角色卡片 ────────────────────────────────────
                      _RoleCard(
                        emoji: '👤',
                        title: l.roleMember,
                        subtitle: l.roleMemberSubtitle,
                        color: AppTheme.primaryColor,
                        onTap: () => Get.toNamed('/login'),
                      ),
                      const SizedBox(height: 12),
                      _RoleCard(
                        emoji: '💆',
                        title: l.roleTechnicianTitle,
                        subtitle: l.roleTechnicianSubtitle,
                        color: const Color(0xFF10B981),
                        onTap: () => Get.toNamed('/login'),
                      ),
                      const SizedBox(height: 12),
                      _RoleCard(
                        emoji: '🏢',
                        title: l.roleMerchantTitle,
                        subtitle: l.roleMerchantSubtitle,
                        color: const Color(0xFFF5A623),
                        onTap: () => Get.toNamed('/login'),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),

              // ── 底部：登录 / 注册 按钮 ───────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 36),
                child: Column(
                  children: [
                    ElevatedButton(
                      onPressed: () => Get.toNamed('/login'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                        shadowColor: AppTheme.primaryColor.withOpacity(0.5),
                      ),
                      child: Text(
                        l.login,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => Get.toNamed('/register'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        side: const BorderSide(color: Colors.white24, width: 1.5),
                      ),
                      child: Text(
                        l.register,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                    ),
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

// ── 角色卡片 ────────────────────────────────────────────────────────────
class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final String emoji;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.22), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Center(child: Text(emoji, style: const TextStyle(fontSize: 28))),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios_rounded, color: color.withOpacity(0.7), size: 15),
          ],
        ),
      ),
    );
  }
}
