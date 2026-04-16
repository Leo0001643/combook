import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../auth/auth_controller.dart';
import '../../l10n/app_localizations.dart';

// ─────────────────────────────────────────────────────────────────────────────
// 支持的语言列表
// ─────────────────────────────────────────────────────────────────────────────
const _kLanguages = [
  _LangOption(code: 'zh-CN', flag: '🇨🇳', nativeName: '中文',         countryName: 'Chinese'),
  _LangOption(code: 'en',    flag: '🇺🇸', nativeName: 'English',      countryName: 'English'),
  _LangOption(code: 'vi',    flag: '🇻🇳', nativeName: 'Tiếng Việt',   countryName: 'Vietnamese'),
  _LangOption(code: 'km',    flag: '🇰🇭', nativeName: 'ភាសាខ្មែរ',    countryName: 'Khmer'),
];

class _LangOption {
  final String code;
  final String flag;
  final String nativeName;
  final String countryName;
  const _LangOption({
    required this.code,
    required this.flag,
    required this.nativeName,
    required this.countryName,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// 语言切换按钮
//
// 使用：在 AppBar/Header 的 Row 中嵌入，自动读取当前语言并展示对应国旗。
// 点击后弹出精美底部面板，用户选择后立即生效（GetX + Get.updateLocale）。
//
// 参数：
//   iconColor  — 按钮图标/文字颜色（深色/浅色背景分别传入）
//   showLabel  — 是否在图标旁显示两字简写（如「中」「EN」），默认 false
// ─────────────────────────────────────────────────────────────────────────────
class LanguageSwitcherButton extends StatelessWidget {
  final Color  iconColor;
  final bool   showLabel;

  const LanguageSwitcherButton({
    super.key,
    this.iconColor = Colors.white,
    this.showLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final auth    = AuthController.to;
      final current = _kLanguages.firstWhere(
        (l) => l.code == auth.appLocale.value,
        orElse: () => _kLanguages.first,
      );
      return GestureDetector(
        onTap: () => _showSheet(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.25), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(current.flag, style: const TextStyle(fontSize: 16, height: 1.1)),
              if (showLabel) ...[
                const SizedBox(width: 5),
                Text(
                  _shortLabel(current.code),
                  style: TextStyle(
                    color: iconColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    });
  }

  String _shortLabel(String code) {
    switch (code) {
      case 'zh-CN': return '中';
      case 'vi':    return 'VI';
      case 'km':    return 'KH';
      default:      return 'EN';
    }
  }

  void _showSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _LanguageSheet(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 语言选择底部面板
// ─────────────────────────────────────────────────────────────────────────────
class _LanguageSheet extends StatelessWidget {
  const _LanguageSheet();

  @override
  Widget build(BuildContext context) {
    final auth = AuthController.to;
    final l    = AppLocalizations.of(context);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 抓手条
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // 标题
          Row(
            children: [
              const Icon(Icons.language_rounded, size: 22, color: Color(0xFF4F46E5)),
              const SizedBox(width: 10),
              Text(
                l.switchLang,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1F2E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            l.language,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 20),

          // 语言列表
          Obx(() {
            final selected = auth.appLocale.value;
            return Column(
              children: _kLanguages.map((lang) {
                final isSelected = lang.code == selected;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _LangTile(
                    lang: lang,
                    isSelected: isSelected,
                    onTap: () {
                      auth.switchLanguage(lang.code);
                      Navigator.pop(context);
                    },
                  ),
                );
              }).toList(),
            );
          }),
        ],
      ),
    );
  }
}

class _LangTile extends StatelessWidget {
  final _LangOption lang;
  final bool        isSelected;
  final VoidCallback onTap;

  const _LangTile({
    required this.lang,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF4F46E5);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEEF2FF) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? primary : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // 国旗
            Text(lang.flag, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 14),

            // 语言名称
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lang.nativeName,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? primary : const Color(0xFF1A1F2E),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    lang.countryName,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),

            // 选中勾
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: isSelected
                  ? Container(
                      key: const ValueKey('check'),
                      width: 24, height: 24,
                      decoration: const BoxDecoration(
                        color: primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, color: Colors.white, size: 14),
                    )
                  : const SizedBox(key: ValueKey('empty'), width: 24, height: 24),
            ),
          ],
        ),
      ),
    );
  }
}
