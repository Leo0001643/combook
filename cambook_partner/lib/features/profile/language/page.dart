import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/i18n/l10n_ext.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/widgets/common_widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// 支持的语言列表
// ─────────────────────────────────────────────────────────────────────────────
class _LangItem {
  final String code;
  final String flag;
  final String name;    // 该语言的本地名称
  final String nameZh;  // 中文名称（便于识别）
  final Color  accent;
  const _LangItem(this.code, this.flag, this.name, this.nameZh, this.accent);
}

const _kLangs = [
  _LangItem('zh', '🇨🇳', '中文简体',    '中文',   Color(0xFFEF4444)),
  _LangItem('en', '🇺🇸', 'English',     '英语',   Color(0xFF3B82F6)),
  _LangItem('vi', '🇻🇳', 'Tiếng Việt',  '越南语', Color(0xFF10B981)),
  _LangItem('km', '🇰🇭', 'ភាសាខ្មែរ',  '高棉语', Color(0xFF8B5CF6)),
  _LangItem('ko', '🇰🇷', '한국어',      '韩语',   Color(0xFF06B6D4)),
  _LangItem('ja', '🇯🇵', '日本語',      '日语',   Color(0xFFF59E0B)),
];

// ─────────────────────────────────────────────────────────────────────────────
// 语言选择页
// ─────────────────────────────────────────────────────────────────────────────
class LanguagePage extends StatefulWidget {
  const LanguagePage({super.key});

  @override
  State<LanguagePage> createState() => _LanguagePageState();
}

class _LanguagePageState extends State<LanguagePage> {
  late String _selected;

  @override
  void initState() {
    super.initState();
    _selected = Get.find<StorageService>().locale;
  }

  void _apply(String code) {
    if (_selected == code) return;
    setState(() => _selected = code);
    changeAppLocale(code);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) Get.back();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () => Get.back(),
        ),
        title: Text(l.langTitle,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        centerTitle: true,
        actions: const [MainAppBarActions()],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
        children: [
          // ── 提示文字 ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 14),
            child: Text(l.langHint,
                style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500)),
          ),
          // ── 语言列表 ────────────────────────────────────────────────
          ...List.generate(_kLangs.length, (i) => _LangTile(
            item:     _kLangs[i],
            selected: _selected == _kLangs[i].code,
            onTap:    () => _apply(_kLangs[i].code),
          )),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 单个语言行
// ─────────────────────────────────────────────────────────────────────────────
class _LangTile extends StatelessWidget {
  final _LangItem item;
  final bool      selected;
  final VoidCallback onTap;

  const _LangTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: BounceTap(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: selected
                ? item.accent.withValues(alpha: 0.08)
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? item.accent.withValues(alpha: 0.50)
                  : const Color(0xFFE5E7EB),
              width: selected ? 1.8 : 1.0,
            ),
            boxShadow: selected
                ? [BoxShadow(
                    color: item.accent.withValues(alpha: 0.18),
                    blurRadius: 12, offset: const Offset(0, 4))]
                : [const BoxShadow(
                    color: Color(0x06000000),
                    blurRadius: 4, offset: Offset(0, 2))],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(children: [
              // 国旗
              Text(item.flag, style: const TextStyle(fontSize: 30)),
              const SizedBox(width: 16),
              // 名称
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name,
                    style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700,
                      color: selected ? item.accent : const Color(0xFF111827),
                    )),
                  const SizedBox(height: 3),
                  Text(item.nameZh,
                    style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w500,
                      color: Color(0xFF9CA3AF))),
                ],
              )),
              // 选中指示器
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: selected
                    ? Container(
                        key: const ValueKey('check'),
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          color: item.accent,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(
                            color: item.accent.withValues(alpha: 0.40),
                            blurRadius: 8, offset: const Offset(0, 3))],
                        ),
                        child: const Icon(Icons.check_rounded,
                            color: Colors.white, size: 16),
                      )
                    : Container(
                        key: const ValueKey('ring'),
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: const Color(0xFFE5E7EB), width: 1.5)),
                      ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
