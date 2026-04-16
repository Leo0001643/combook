import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';

/// 发现页 — 内容社区（类似小红书），全部 i18n
class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  int _selectedTab = 0;

  final _topics = ['#春日拍花大赛 🌸', '#旅游风光 📷', '#今日分享'];

  final _posts = [
    {'id': '1', 'title': '春天来了', 'cover': null, 'author': '李班', 'likes': 62, 'location': '合肥', 'left': true},
    {'id': '2', 'title': '踏春赏花🌸', 'cover': null, 'author': '赵小琼', 'likes': 54, 'location': '上海', 'left': false},
    {'id': '3', 'title': '百花齐放的春天', 'cover': null, 'author': '熊义芳', 'likes': 42, 'location': '马鞍山', 'left': true},
    {'id': '4', 'title': '迟日江山丽，春风花草香', 'cover': null, 'author': '王海清', 'likes': 38, 'location': '湛江', 'left': false},
  ];

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: NestedScrollView(
        headerSliverBuilder: (_, innerBoxIsScrolled) => [
          SliverAppBar(
            backgroundColor: Colors.white,
            floating: true,
            elevation: 0,
            title: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [l.recommended, l.nearby, l.followedPosts].asMap().entries.map((entry) => GestureDetector(
                onTap: () => setState(() => _selectedTab = entry.key),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(entry.value, style: TextStyle(
                        fontSize: 15, color: _selectedTab == entry.key ? AppTheme.gray900 : AppTheme.gray400,
                        fontWeight: _selectedTab == entry.key ? FontWeight.w700 : FontWeight.normal,
                      )),
                      const SizedBox(height: 4),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: _selectedTab == entry.key ? 20 : 0, height: 3,
                        decoration: BoxDecoration(color: AppTheme.primaryColor, borderRadius: BorderRadius.circular(2)),
                      ),
                    ],
                  ),
                ),
              )).toList(),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(44),
              child: _buildTopics(),
            ),
          ),
        ],
        body: _buildGrid(l),
      ),
    );
  }

  Widget _buildTopics() {
    return Container(
      color: Colors.white,
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: _topics.length + 1,
        itemBuilder: (_, i) {
          if (i == _topics.length) return const SizedBox(width: 12);
          return Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
            ),
            child: Row(children: [
              Text(_topics[i], style: const TextStyle(fontSize: 12, color: AppTheme.primaryColor, fontWeight: FontWeight.w500)),
              const SizedBox(width: 4),
              Builder(builder: (ctx) {
                final lc = AppLocalizations.of(ctx);
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(color: AppTheme.primaryColor, borderRadius: BorderRadius.circular(8)),
                  child: Text(lc.specialOffer.substring(0, 1), style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
                );
              }),
            ]),
          );
        },
      ),
    );
  }

  Widget _buildGrid(AppLocalizations l) {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.72,
      ),
      itemCount: _posts.length,
      itemBuilder: (_, i) => _buildPostCard(l, _posts[i]),
    );
  }

  Widget _buildPostCard(AppLocalizations l, Map<String, dynamic> post) {
    final colors = [
      [const Color(0xFFFFD6A5), const Color(0xFFFF8C42)],
      [const Color(0xFFD4F0C4), const Color(0xFF82C341)],
      [const Color(0xFFFFB3C1), const Color(0xFFFF4D6D)],
      [const Color(0xFFC8E6FF), const Color(0xFF4499FF)],
    ];
    final i = _posts.indexOf(post);
    return GestureDetector(
      onTap: () {},
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8)]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 封面
            Expanded(
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors[i % colors.length]),
                    ),
                    child: Center(child: Icon(Icons.photo, size: 40, color: Colors.white.withOpacity(0.5))),
                  ),
                  Positioned(
                    bottom: 8, left: 8,
                    child: Row(children: [
                      const Icon(Icons.location_on, color: Colors.white, size: 12),
                      Text(post['location'] as String, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500)),
                    ]),
                  ),
                  // 收藏按钮
                  Positioned(
                    right: 8, bottom: 8,
                    child: Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(14)),
                      child: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
            // 信息
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(post['title'] as String, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.gray900), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        width: 20, height: 20,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.gray100),
                        child: const Icon(Icons.person, size: 14, color: AppTheme.gray500),
                      ),
                      const SizedBox(width: 4),
                      Expanded(child: Text(post['author'] as String, style: const TextStyle(fontSize: 11, color: AppTheme.gray500), overflow: TextOverflow.ellipsis)),
                      const Icon(Icons.favorite_outline, size: 14, color: AppTheme.gray400),
                      const SizedBox(width: 2),
                      Text('${post['likes']}', style: const TextStyle(fontSize: 11, color: AppTheme.gray400)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
