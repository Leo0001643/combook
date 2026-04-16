import 'package:get/get.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';

/// 搜索结果：技师或服务
class _SearchHit {
  const _SearchHit({
    required this.id,
    required this.name,
    required this.rating,
    required this.specialty,
    required this.distanceKm,
    required this.avatarColor,
    required this.isTechnician,
  });

  final String id;
  final String name;
  final double rating;
  final String specialty;
  final double distanceKm;
  final Color avatarColor;
  final bool isTechnician;
}

/// 全局搜索 — 历史、热搜、实时结果
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();

  /// 模拟全量可检索数据
  late final List<_SearchHit> _catalog;

  /// 最近搜索关键词
  final List<String> _recent = ['泰式按摩', '林悦', '足疗', 'SPA 芳香'];

  /// 热搜榜
  static const List<String> _hot = [
    '上门推拿',
    '肩颈理疗',
    '精油 SPA',
    '运动恢复',
    '足底按摩',
    '女性专享',
    '深夜可约',
    '五星技师',
  ];

  @override
  void initState() {
    super.initState();
    _catalog = [
      _SearchHit(
        id: 't1',
        name: '林悦',
        rating: 4.9,
        specialty: '泰式 · 拉伸',
        distanceKm: 1.2,
        avatarColor: const Color(0xFFFFB4A2),
        isTechnician: true,
      ),
      _SearchHit(
        id: 't2',
        name: '陈静',
        rating: 4.8,
        specialty: '精油 SPA · 芳香',
        distanceKm: 2.4,
        avatarColor: const Color(0xFFA8D8EA),
        isTechnician: true,
      ),
      _SearchHit(
        id: 't3',
        name: '王磊',
        rating: 4.7,
        specialty: '运动康复 · 筋膜放松',
        distanceKm: 3.1,
        avatarColor: const Color(0xFFB8E986),
        isTechnician: true,
      ),
      _SearchHit(
        id: 's1',
        name: '尊享足疗套餐',
        rating: 4.6,
        specialty: '服务 · 60 分钟',
        distanceKm: 0.8,
        avatarColor: AppTheme.primaryLight,
        isTechnician: false,
      ),
      _SearchHit(
        id: 's2',
        name: '全身精油 SPA',
        rating: 4.9,
        specialty: '服务 · 90 分钟',
        distanceKm: 1.0,
        avatarColor: AppTheme.primaryLight,
        isTechnician: false,
      ),
    ];
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  String get _query => _controller.text.trim();

  List<_SearchHit> get _results {
    if (_query.isEmpty) return [];
    final q = _query.toLowerCase();
    return _catalog.where((e) {
      return e.name.toLowerCase().contains(q) || e.specialty.toLowerCase().contains(q);
    }).toList();
  }

  void _addRecent(String q) {
    final v = q.trim();
    if (v.isEmpty) return;
    setState(() {
      _recent.remove(v);
      _recent.insert(0, v);
      if (_recent.length > 10) _recent.removeLast();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final showResults = _query.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppTheme.gray900),
          onPressed: () => Get.back(),
        ),
        titleSpacing: 0,
        title: TextField(
          controller: _controller,
          focusNode: _focus,
          autofocus: true,
          textInputAction: TextInputAction.search,
          onSubmitted: _addRecent,
          decoration: InputDecoration(
            hintText: l.search,
            hintStyle: const TextStyle(color: AppTheme.gray400, fontSize: 15),
            border: InputBorder.none,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.clear_rounded, color: AppTheme.gray400),
                    onPressed: () {
                      _controller.clear();
                      setState(() {});
                    },
                  ),
          ),
        ),
      ),
      body: showResults ? _buildResults(l) : _buildExplore(l),
    );
  }

  /// 输入中：实时结果列表
  Widget _buildResults(AppLocalizations l) {
    final hits = _results;
    if (hits.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 56, color: AppTheme.gray300),
            const SizedBox(height: 12),
            Text(l.noData, style: const TextStyle(color: AppTheme.gray500, fontSize: 15)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: hits.length,
      itemBuilder: (context, i) {
        final h = hits[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: h.avatarColor,
                    child: Icon(
                      h.isTechnician ? Icons.person_rounded : Icons.spa_rounded,
                      color: AppTheme.gray700,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          h.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.gray900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, size: 16, color: Color(0xFFFFB020)),
                            Text(
                              h.rating.toStringAsFixed(1),
                              style: const TextStyle(fontSize: 13, color: AppTheme.gray700),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                h.specialty,
                                style: const TextStyle(fontSize: 12, color: AppTheme.gray500),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${h.distanceKm.toStringAsFixed(1)} km',
                          style: const TextStyle(fontSize: 12, color: AppTheme.gray400),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 36,
                    child: FilledButton(
                      onPressed: () {
                        _addRecent(_query);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${l.bookService}: ${h.name}')),
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(l.bookService, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// 默认：最近搜索 + 热搜
  Widget _buildExplore(AppLocalizations l) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        if (_recent.isNotEmpty) ...[
          Row(
            children: [
              Text(
                l.recentSearch,
                style: const TextStyle(fontSize: 13, color: AppTheme.gray500, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => setState(() => _recent.clear()),
                child: Text(l.clearAll, style: const TextStyle(fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(_recent.length, (i) {
              final word = _recent[i];
              return InputChip(
                label: Text(word),
                onPressed: () {
                  _controller.text = word;
                  _controller.selection = TextSelection.collapsed(offset: word.length);
                  setState(() {});
                },
                deleteIcon: const Icon(Icons.close_rounded, size: 16),
                onDeleted: () => setState(() => _recent.removeAt(i)),
                backgroundColor: Colors.white,
                side: const BorderSide(color: AppTheme.gray300),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              );
            }),
          ),
          const SizedBox(height: 24),
        ],
        Text(
          l.hotSearch,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.gray900),
        ),
        const SizedBox(height: 12),
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
            children: List.generate(_hot.length, (i) {
              final kw = _hot[i];
              return InkWell(
                onTap: () {
                  _controller.text = kw;
                  _controller.selection = TextSelection.collapsed(offset: kw.length);
                  setState(() {});
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 28,
                        child: Text(
                          '${i + 1}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: i < 3 ? AppTheme.accentColor : AppTheme.gray400,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(kw, style: const TextStyle(fontSize: 15, color: AppTheme.gray900)),
                      ),
                      const Icon(Icons.trending_up_rounded, size: 18, color: AppTheme.gray300),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
