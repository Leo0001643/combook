import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';

/// 技师详情页 — 套餐/评价/相册/预约日历，全部 i18n
class TechnicianDetailPage extends StatefulWidget {
  final String id;
  const TechnicianDetailPage({super.key, required this.id});

  @override
  State<TechnicianDetailPage> createState() => _TechnicianDetailPageState();
}

class _TechnicianDetailPageState extends State<TechnicianDetailPage> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  bool _isFavorite = false;

  final _packages = [
    {'name': '全身推拿', 'duration': 60, 'price': '\$45.00', 'memberPrice': '\$40.00', 'desc': '专业全身经络推拿，舒缓疲劳，改善循环'},
    {'name': '精油SPA', 'duration': 90, 'price': '\$88.00', 'memberPrice': '\$80.00', 'desc': '天然精油，深层按摩，放松身心'},
    {'name': '头颈肩理疗', 'duration': 60, 'price': '\$50.00', 'memberPrice': '\$45.00', 'desc': '缓解颈椎不适，改善肩膀酸痛'},
  ];

  final _reviews = [
    {'user': 'S***a', 'star': 5, 'content': 'Very professional! Highly recommended.', 'time': '2026-04-10', 'tags': ['Professional', 'Punctual']},
    {'user': '李**', 'star': 5, 'content': '手法很专业，服务态度很好，下次还会预约！', 'time': '2026-04-08', 'tags': ['手法专业', '态度好']},
    {'user': 'N***n', 'star': 4, 'content': 'Good service, will book again.', 'time': '2026-04-05', 'tags': ['Good']},
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: Colors.white,
            leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white), onPressed: () => Get.back()),
            actions: [
              IconButton(
                icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border, color: _isFavorite ? Colors.red : Colors.white),
                onPressed: () => setState(() => _isFavorite = !_isFavorite),
              ),
              IconButton(icon: const Icon(Icons.share_outlined, color: Colors.white), onPressed: () {}),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFD4A0C0), AppTheme.primaryColor]),
                    ),
                    child: const Center(child: Icon(Icons.person, size: 100, color: Colors.white54)),
                  ),
                  Positioned(
                    bottom: 0, left: 0, right: 0,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.7)]),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          const Text('陈秀玲', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(4)),
                            child: const Text('90后', style: TextStyle(color: Colors.white, fontSize: 11)),
                          ),
                        ]),
                        const SizedBox(height: 6),
                        Row(children: [
                          const Icon(Icons.star, color: Colors.amber, size: 14),
                          const Text(' 4.9  ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                          Text(l.goodReviews(52), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          const SizedBox(width: 8),
                          Text(l.orders(226), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        ]),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
            bottom: TabBar(
              controller: _tabCtrl,
              labelColor: AppTheme.primaryColor,
              unselectedLabelColor: AppTheme.gray500,
              indicatorColor: AppTheme.primaryColor,
              indicatorSize: TabBarIndicatorSize.label,
              tabs: [Tab(text: l.services), Tab(text: l.reviews), Tab(text: l.album)],
              dividerHeight: 0,
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabCtrl,
          children: [
            _buildPackageList(l),
            _buildReviewList(l),
            _buildAlbum(l),
          ],
        ),
      ),
      bottomNavigationBar: _buildBookButton(l),
    );
  }

  Widget _buildPackageList(AppLocalizations l) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _packages.length,
      itemBuilder: (_, i) {
        final pkg = _packages[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.spa, color: AppTheme.primaryColor, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text(pkg['name'] as String, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 6),
                  Text(l.duration(pkg['duration'] as int), style: const TextStyle(fontSize: 12, color: AppTheme.gray400)),
                ]),
                const SizedBox(height: 4),
                Text(pkg['desc'] as String, style: const TextStyle(fontSize: 12, color: AppTheme.gray500), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                Row(children: [
                  Text(pkg['memberPrice'] as String, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.red)),
                  const SizedBox(width: 8),
                  Text(pkg['price'] as String, style: const TextStyle(fontSize: 12, color: AppTheme.gray300, decoration: TextDecoration.lineThrough)),
                ]),
              ])),
              ElevatedButton(
                onPressed: () => Get.toNamed('/create-order?technicianId=${widget.id}&packageId=$i'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white,
                  minimumSize: const Size(64, 36), padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)), elevation: 0,
                ),
                child: Text(l.bookNow, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReviewList(AppLocalizations l) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _reviews.length,
      itemBuilder: (_, i) {
        final r = _reviews[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.gray100),
                child: const Center(child: Icon(Icons.person, color: AppTheme.gray400, size: 20)),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(r['user'] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                Row(children: List.generate(r['star'] as int, (_) => const Icon(Icons.star, color: Colors.amber, size: 12))),
              ])),
              Text(r['time'] as String, style: const TextStyle(fontSize: 11, color: AppTheme.gray400)),
            ]),
            const SizedBox(height: 10),
            Text(r['content'] as String, style: const TextStyle(fontSize: 13, color: AppTheme.gray700, height: 1.5)),
            const SizedBox(height: 8),
            Wrap(spacing: 6, children: (r['tags'] as List<String>).map((tag) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: BorderRadius.circular(10)),
              child: Text(tag, style: const TextStyle(fontSize: 11, color: AppTheme.primaryColor)),
            )).toList()),
          ]),
        );
      },
    );
  }

  Widget _buildAlbum(AppLocalizations l) {
    final colors = [AppTheme.primaryColor.withOpacity(0.3), const Color(0xFFFFB3C1), const Color(0xFFC8E6FF), const Color(0xFFD4F0C4), const Color(0xFFFFE0B2), const Color(0xFFE1BEE7)];
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 6, mainAxisSpacing: 6),
      itemCount: 6,
      itemBuilder: (_, i) => Container(
        decoration: BoxDecoration(color: colors[i % colors.length], borderRadius: BorderRadius.circular(8)),
        child: const Center(child: Icon(Icons.photo, color: Colors.white54, size: 28)),
      ),
    );
  }

  Widget _buildBookButton(AppLocalizations l) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, -2))]),
      child: Row(children: [
        IconButton(icon: const Icon(Icons.chat_bubble_outline, color: AppTheme.gray600, size: 26), onPressed: () => Get.toNamed('/im/chat/${widget.id}')),
        IconButton(icon: const Icon(Icons.phone_outlined, color: AppTheme.gray600, size: 26), onPressed: () {}),
        const SizedBox(width: 8),
        Expanded(child: ElevatedButton(
          onPressed: () => Get.toNamed('/create-order?technicianId=${widget.id}&packageId=0'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0,
          ),
          child: Text(l.bookNow, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        )),
      ]),
    );
  }
}
