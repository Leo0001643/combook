import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';

/// 技师列表页 — 精美还原截图风格
/// 列表视图 + 地图视图切换，全部 i18n
class TechnicianListPage extends StatefulWidget {
  const TechnicianListPage({super.key});

  @override
  State<TechnicianListPage> createState() => _TechnicianListPageState();
}

class _TechnicianListPageState extends State<TechnicianListPage> {
  bool _isMapView = false;
  int _selectedFilter = 0;

  final _technicians = <Map<String, dynamic>>[
    {
      'id': '1',
      'name': '张文玲',
      'age': '25岁',
      'badge': '新到',
      'badgeColor': Color(0xFF4CAF50),
      'freeTransport': true,
      'rating': 5.0,
      'goodReviews': 98,
      'orders60': 60,
      'location': '锡上MONO附近',
      'dist': '<1km',
      'availableTime': '今 15:30 可约',
      'tags': ['超多回头客', '新到', '百分百好评'],
      'rankBadge': '2026年无锡市单量榜·第3名',
      'offerTags': ['免车费'],
      'comment': '"专业敬业，手法精湛，态度热情，沟...',
      'emoji': '👩',
      'viewers': 3,
    },
    {
      'id': '2',
      'name': '周玉梅',
      'age': '00后',
      'badge': '新到',
      'badgeColor': Color(0xFF4CAF50),
      'freeTransport': false,
      'rating': 4.9,
      'goodReviews': 462,
      'orders60': 100,
      'location': '运河艺术公园附近',
      'dist': '1.3km',
      'availableTime': '今 15:30 可约',
      'tags': ['超多回头客', '新到', '回复超快'],
      'rankBadge': '2026年无锡市回头客榜·第7名',
      'offerTags': ['特惠套餐'],
      'comment': '"手法很好，人很漂亮"',
      'emoji': '👩🏻',
      'viewers': 0,
    },
    {
      'id': '3',
      'name': '徐世兰',
      'age': '85后',
      'badge': '免车费',
      'badgeColor': Color(0xFFFF9800),
      'freeTransport': true,
      'rating': 4.9,
      'goodReviews': 847,
      'orders60': 200,
      'location': '珠宝城商厦附近',
      'dist': '<1km',
      'availableTime': '今 15:30 可约',
      'tags': ['超多回头客', '回复超快'],
      'rankBadge': null,
      'offerTags': ['免车费', '特惠套餐'],
      'comment': '"服务很好，态度很好"',
      'emoji': '👩🏼',
      'viewers': 0,
    },
    {
      'id': '4',
      'name': '王春花',
      'age': '80后',
      'badge': '免车费',
      'badgeColor': Color(0xFFFF9800),
      'freeTransport': true,
      'rating': 4.8,
      'goodReviews': 41,
      'orders60': 1,
      'location': '国联大厦（圆通路）附近',
      'dist': '<1km',
      'availableTime': '今 15:30 可约',
      'tags': ['超多回头客', '新到'],
      'rankBadge': null,
      'offerTags': ['免车费'],
      'comment': '"手法专业，值得推荐"',
      'emoji': '👩🏽',
      'viewers': 0,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final filters = [l.skillFirst, l.newUser, l.specialOffer, l.godCoupon, l.freeTransport];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          _buildTopBar(context, l),
          _buildSortBar(l),
          _buildFilterChips(filters),
          Expanded(
            child: _isMapView ? _buildMapView(l) : _buildListView(l),
          ),
        ],
      ),
    );
  }

  // ── 顶部导航栏 ────────────────────────────────────────────────────
  Widget _buildTopBar(BuildContext context, AppLocalizations l) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              // 位置选择
              Expanded(
                child: GestureDetector(
                  onTap: () {},
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on_rounded, color: AppColors.categoryMassage, size: 16),
                      const SizedBox(width: 4),
                      Flexible(
                        child: const Text(
                          '西哈努克市',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF222222)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF666666)),
                    ],
                  ),
                ),
              ),
              // 搜索图标
              GestureDetector(
                onTap: () => Get.toNamed('/search'),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  child: const Icon(Icons.search_rounded, size: 22, color: Color(0xFF444444)),
                ),
              ),
              const SizedBox(width: 4),
              // 列表/地图切换
              _ViewToggle(
                isMapView: _isMapView,
                onListTap: () => setState(() => _isMapView = false),
                onMapTap: () => setState(() => _isMapView = true),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── 排序筛选栏 ────────────────────────────────────────────────────
  Widget _buildSortBar(AppLocalizations l) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {},
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(l.smartSort, style: const TextStyle(fontSize: 13, color: Color(0xFF333333), fontWeight: FontWeight.w500)),
                  const Icon(Icons.arrow_drop_down, size: 16, color: Color(0xFF666666)),
                ],
              ),
            ),
          ),
          Container(width: 0.5, height: 16, color: const Color(0xFFDDDDDD)),
          Expanded(
            child: GestureDetector(
              onTap: () {},
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(l.serviceTime, style: const TextStyle(fontSize: 13, color: Color(0xFF333333), fontWeight: FontWeight.w500)),
                  const Icon(Icons.arrow_drop_down, size: 16, color: Color(0xFF666666)),
                ],
              ),
            ),
          ),
          Container(width: 0.5, height: 16, color: const Color(0xFFDDDDDD)),
          Expanded(
            child: GestureDetector(
              onTap: () {},
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.tune_rounded, size: 14, color: Color(0xFF333333)),
                  const SizedBox(width: 4),
                  Text(l.allFilters, style: const TextStyle(fontSize: 13, color: Color(0xFF333333), fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 筛选 Chip ─────────────────────────────────────────────────────
  Widget _buildFilterChips(List<String> filters) {
    return Container(
      color: Colors.white,
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
        itemCount: filters.length,
        itemBuilder: (_, i) {
          final selected = _selectedFilter == i;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = i),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
              decoration: BoxDecoration(
                color: selected ? AppTheme.primaryColor : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected ? AppTheme.primaryColor : const Color(0xFFDDDDDD),
                ),
              ),
              child: Text(
                filters[i],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  color: selected ? Colors.white : const Color(0xFF555555),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── 列表视图 ──────────────────────────────────────────────────────
  Widget _buildListView(AppLocalizations l) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      itemCount: _technicians.length,
      itemBuilder: (_, i) => _buildTechCard(l, _technicians[i]),
    );
  }

  // ── 技师卡片 ──────────────────────────────────────────────────────
  Widget _buildTechCard(AppLocalizations l, Map<String, dynamic> tech) {
    final tags = tech['tags'] as List<String>;
    final offerTags = tech['offerTags'] as List<String>;
    final badge = tech['badge'] as String?;
    final badgeColor = tech['badgeColor'] as Color;
    final rankBadge = tech['rankBadge'] as String?;

    return Container(
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─ 顶部徽章标签 ─────────────────────────────────────────
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: Text(badge, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
            ),

          // ─ 主内容 ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 头像区域
                _buildAvatar(l, tech),
                const SizedBox(width: 12),
                // 信息区域
                Expanded(child: _buildInfo(l, tech, tags, offerTags, rankBadge)),
              ],
            ),
          ),

          // ─ 分割线 ────────────────────────────────────────────────
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Divider(height: 1, color: Color(0xFFF0F0F0)),
          ),

          // ─ 评论 + 预订按钮 ────────────────────────────────────────
          _buildCommentRow(l, tech),
        ],
      ),
    );
  }

  Widget _buildAvatar(AppLocalizations l, Map<String, dynamic> tech) {
    return Stack(
      children: [
        Container(
          width: 80,
          height: 108,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.primaryColor.withValues(alpha: 0.25),
                AppTheme.primaryColor.withValues(alpha: 0.08),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(tech['emoji'] as String, style: const TextStyle(fontSize: 44)),
            ],
          ),
        ),
        // 免车费角标
        if (tech['freeTransport'] == true)
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: const BoxDecoration(
                color: Color(0xFFFF6B35),
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(10),
                  bottomLeft: Radius.circular(6),
                ),
              ),
              child: Text(l.freeTransport, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
            ),
          ),
      ],
    );
  }

  Widget _buildInfo(AppLocalizations l, Map<String, dynamic> tech, List<String> tags,
      List<String> offerTags, String? rankBadge) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 姓名 + 年龄 + 可约时间
        Row(
          children: [
            Text(tech['name'] as String, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF222222))),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(tech['age'] as String, style: const TextStyle(fontSize: 11, color: Color(0xFF888888))),
            ),
            const Spacer(),
            // 可约时间
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.access_time_rounded, size: 11, color: Color(0xFF4CAF50)),
                const SizedBox(width: 2),
                Text(
                  tech['availableTime'] as String,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF4CAF50), fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 5),

        // 评分 + 好评数 + 接单数
        Row(
          children: [
            const Icon(Icons.star_rounded, color: Color(0xFFFFA726), size: 14),
            const SizedBox(width: 2),
            Text(
              '${tech['rating']}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF222222)),
            ),
            const SizedBox(width: 8),
            Text(
              '${l.goodReviews(tech['goodReviews'] as int)}  ${l.orders60d(tech['orders60'] as int)}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF888888)),
            ),
          ],
        ),
        const SizedBox(height: 4),

        // 位置 + 距离
        Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 12, color: Color(0xFFAAAAAA)),
                  const SizedBox(width: 2),
                  Flexible(
                    child: Text(
                      tech['location'] as String,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF888888)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6, height: 6,
                  decoration: const BoxDecoration(color: Color(0xFFAAAAAA), shape: BoxShape.circle),
                ),
                const SizedBox(width: 3),
                Text(l.distanceFmt(tech['dist'] as String), style: const TextStyle(fontSize: 11, color: Color(0xFFAAAAAA))),
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),

        // 服务标签（绿色轮廓）
        Wrap(
          spacing: 5,
          runSpacing: 4,
          children: tags.map((tag) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FBF5),
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: const Color(0xFFB2DFC8)),
            ),
            child: Text(tag, style: const TextStyle(fontSize: 10, color: Color(0xFF3DAB6E), fontWeight: FontWeight.w500)),
          )).toList(),
        ),

        // 榜单徽章
        if (rankBadge != null) ...[
          const SizedBox(height: 5),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9800),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(l.rankBadgeAbbr, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 4),
              Text(rankBadge, style: const TextStyle(fontSize: 11, color: Color(0xFFFF9800), fontWeight: FontWeight.w500)),
            ],
          ),
        ],

        // 优惠标签（橙色轮廓）
        if (offerTags.isNotEmpty) ...[
          const SizedBox(height: 5),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFFF9800)),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(l.offerAbbr, style: const TextStyle(color: Color(0xFFFF9800), fontSize: 10, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 4),
              Wrap(
                spacing: 5,
                children: offerTags.map((tag) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8F0),
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: const Color(0xFFFFCC80)),
                  ),
                  child: Text(tag, style: const TextStyle(fontSize: 10, color: Color(0xFFFF9800), fontWeight: FontWeight.w500)),
                )).toList(),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildCommentRow(AppLocalizations l, Map<String, dynamic> tech) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Row(
        children: [
          // 头像叠加
          SizedBox(
            width: 56,
            height: 22,
            child: Stack(
              children: [
                for (int i = 0; i < 3; i++)
                  Positioned(
                    left: i * 16.0,
                    child: Container(
                      width: 22, height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: [const Color(0xFFFCE4EC), const Color(0xFFE3F2FD), const Color(0xFFF3E5F5)][i],
                        border: const Border.fromBorderSide(BorderSide(color: Colors.white, width: 1.5)),
                      ),
                      child: Center(child: Text(['😊', '🙂', '😄'][i], style: const TextStyle(fontSize: 12))),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              tech['comment'] as String,
              style: const TextStyle(fontSize: 12, color: Color(0xFF888888), fontStyle: FontStyle.italic),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          // 预订按钮
          GestureDetector(
            onTap: () => Get.toNamed('/member/home/technician/${tech['id']}'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(l.bookNow, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  // ── 地图视图 ──────────────────────────────────────────────────────
  Widget _buildMapView(AppLocalizations l) {
    return Stack(
      children: [
        Container(
          color: const Color(0xFFE8F0E8),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.map_outlined, size: 64, color: Color(0xFFBBBBBB)),
                const SizedBox(height: 12),
                Text(l.mapView, style: const TextStyle(color: Color(0xFF999999), fontSize: 16)),
              ],
            ),
          ),
        ),
        ..._technicians.asMap().entries.map((entry) => Positioned(
          top: 100.0 + entry.key * 65,
          left: 60.0 + entry.key * 55,
          child: GestureDetector(
            onTap: () => Get.toNamed('/member/home/technician/${entry.value['id']}'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: entry.key == 0 ? AppTheme.primaryColor : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8)],
              ),
              child: Text(
                entry.value['name'] as String,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: entry.key == 0 ? Colors.white : const Color(0xFF222222),
                ),
              ),
            ),
          ),
        )),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 列表/地图 切换按钮
// ─────────────────────────────────────────────────────────────────────────────
class _ViewToggle extends StatelessWidget {
  final bool isMapView;
  final VoidCallback onListTap;
  final VoidCallback onMapTap;
  const _ViewToggle({required this.isMapView, required this.onListTap, required this.onMapTap});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      height: 30,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleItem(label: l.listView, icon: Icons.list_rounded, active: !isMapView, onTap: onListTap, isFirst: true),
          _ToggleItem(label: l.mapView, icon: Icons.map_outlined, active: isMapView, onTap: onMapTap, isFirst: false),
        ],
      ),
    );
  }
}

class _ToggleItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final bool isFirst;
  final VoidCallback onTap;
  const _ToggleItem({required this.label, required this.icon, required this.active, required this.isFirst, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(5),
          boxShadow: active
              ? [const BoxShadow(color: Color(0x1A000000), blurRadius: 4, offset: Offset(0, 1))]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: active ? AppTheme.primaryColor : const Color(0xFF888888)),
            const SizedBox(width: 3),
            Text(label, style: TextStyle(fontSize: 12, color: active ? AppTheme.primaryColor : const Color(0xFF888888), fontWeight: active ? FontWeight.w600 : FontWeight.w400)),
          ],
        ),
      ),
    );
  }
}
