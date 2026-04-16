import 'package:get/get.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';

/// 帮助中心 — FAQ 折叠面板 + 联系客服
class HelpPage extends StatefulWidget {
  const HelpPage({super.key});

  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  final TextEditingController _search = TextEditingController();
  String _filter = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// FAQ 分组与问答（动态，由 AppLocalizations 提供翻译）
  List<_FaqCategory> _buildCategories(AppLocalizations l) => [
    _FaqCategory(
      title: l.faqCatOrders,
      items: [
        _FaqItem(q: l.faqOQ1, a: l.faqOA1),
        _FaqItem(q: l.faqOQ2, a: l.faqOA2),
        _FaqItem(q: l.faqOQ3, a: l.faqOA3),
      ],
    ),
    _FaqCategory(
      title: l.faqCatPayment,
      items: [
        _FaqItem(q: l.faqPQ1, a: l.faqPA1),
        _FaqItem(q: l.faqPQ2, a: l.faqPA2),
        _FaqItem(q: l.faqPQ3, a: l.faqPA3),
      ],
    ),
    _FaqCategory(
      title: l.faqCatTech,
      items: [
        _FaqItem(q: l.faqTQ1, a: l.faqTA1),
        _FaqItem(q: l.faqTQ2, a: l.faqTA2),
      ],
    ),
    _FaqCategory(
      title: l.faqCatAccount,
      items: [
        _FaqItem(q: l.faqAQ1, a: l.faqAA1),
        _FaqItem(q: l.faqAQ2, a: l.faqAA2),
      ],
    ),
  ];

  bool _match(String text) {
    if (_filter.isEmpty) return true;
    return text.contains(_filter);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final categories = _buildCategories(l);
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
          l.helpCenter,
          style: const TextStyle(color: AppTheme.gray900, fontWeight: FontWeight.w700, fontSize: 17),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // 顶部搜索
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
            child: TextField(
              controller: _search,
              onChanged: (v) => setState(() => _filter = v.trim()),
              decoration: InputDecoration(
                hintText: l.faqSearchHint,
                prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.gray400),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...categories.expand((cat) {
            final visibleItems = cat.items
                .where((e) => _match(e.q) || _match(e.a) || _match(cat.title))
                .toList();
            if (visibleItems.isEmpty) return <Widget>[];
            return [
              Padding(
                padding: const EdgeInsets.only(bottom: 8, left: 4),
                child: Text(
                  cat.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.gray500,
                  ),
                ),
              ),
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
                  children: List.generate(visibleItems.length, (i) {
                    final item = visibleItems[i];
                    return Column(
                      children: [
                        Theme(
                          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            tilePadding: const EdgeInsets.symmetric(horizontal: 14),
                            childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                            title: Text(
                              item.q,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.gray900,
                              ),
                            ),
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  item.a,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    height: 1.55,
                                    color: AppTheme.gray600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (i < visibleItems.length - 1)
                          const Divider(height: 1, indent: 14, endIndent: 14),
                      ],
                    );
                  }),
                ),
              ),
              const SizedBox(height: 16),
            ];
          }),
          const SizedBox(height: 8),
          // 仍需帮助 CTA
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryLight,
                  Colors.white,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.faqNeedHelp,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.gray900),
                ),
                const SizedBox(height: 6),
                Text(
                  l.faqSupportDesc,
                  style: TextStyle(fontSize: 13, color: AppTheme.gray600.withValues(alpha: 0.95)),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: () => Get.toNamed('/im'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.chat_bubble_outline_rounded),
                    label: Text(l.faqOnlineSupport),
                  ),
                ),
                const SizedBox(height: 12),
                _contactRow(Icons.phone_in_talk_rounded, '+855 23 888 0123'),
                const SizedBox(height: 8),
                _contactRow(Icons.email_outlined, 'support@cambook.app'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _contactRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.gray500),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 14, color: AppTheme.gray700)),
        ),
      ],
    );
  }
}

class _FaqCategory {
  const _FaqCategory({required this.title, required this.items});

  final String title;
  final List<_FaqItem> items;
}

class _FaqItem {
  const _FaqItem({required this.q, required this.a});

  final String q;
  final String a;
}
