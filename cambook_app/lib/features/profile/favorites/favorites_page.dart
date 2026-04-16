import 'package:get/get.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';

class _FavoriteTech {
  const _FavoriteTech({
    required this.id,
    required this.name,
    required this.rating,
    required this.tagNew,
    required this.tagTop,
    required this.specialty,
    required this.priceMin,
    required this.priceMax,
    required this.avatarLetter,
    required this.gradient,
  });

  final String id;
  final String name;
  final double rating;
  final bool tagNew;
  final bool tagTop;
  final String specialty;
  final int priceMin;
  final int priceMax;
  final String avatarLetter;
  final List<Color> gradient;
}

/// 收藏技师网格；列表状态由内层 [StatefulWidget] 管理以满足 [StatelessWidget] 对外类型要求。
class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) => const _FavoritesScaffold();
}

class _FavoritesScaffold extends StatefulWidget {
  const _FavoritesScaffold();

  @override
  State<_FavoritesScaffold> createState() => _FavoritesScaffoldState();
}

class _FavoritesScaffoldState extends State<_FavoritesScaffold> {
  static final List<_FavoriteTech> _seed = [
    _FavoriteTech(
      id: '1',
      name: 'Sokha',
      rating: 4.9,
      tagNew: true,
      tagTop: false,
      specialty: 'Thai / Deep tissue',
      priceMin: 35,
      priceMax: 88,
      avatarLetter: 'S',
      gradient: [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
    ),
    _FavoriteTech(
      id: '2',
      name: 'Linh',
      rating: 4.8,
      tagNew: false,
      tagTop: true,
      specialty: 'Swedish / Aromatherapy',
      priceMin: 40,
      priceMax: 95,
      avatarLetter: 'L',
      gradient: [const Color(0xFFF59E0B), const Color(0xFFF97316)],
    ),
    _FavoriteTech(
      id: '3',
      name: 'Mei',
      rating: 5.0,
      tagNew: true,
      tagTop: true,
      specialty: 'Hot stone / Foot care',
      priceMin: 45,
      priceMax: 120,
      avatarLetter: 'M',
      gradient: [const Color(0xFF10B981), const Color(0xFF059669)],
    ),
    _FavoriteTech(
      id: '4',
      name: 'Vanna',
      rating: 4.7,
      tagNew: false,
      tagTop: false,
      specialty: 'Sports recovery',
      priceMin: 38,
      priceMax: 90,
      avatarLetter: 'V',
      gradient: [const Color(0xFFEC4899), const Color(0xFFDB2777)],
    ),
  ];

  late List<_FavoriteTech> _items;

  @override
  void initState() {
    super.initState();
    _items = List<_FavoriteTech>.from(_seed);
  }

  Future<void> _onLongPress(AppLocalizations l, _FavoriteTech t) async {
    final remove = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.removeFromFavorites),
        content: Text(l.removeFavoriteConfirm(t.name)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.confirm, style: const TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );
    if (remove == true && mounted) {
      setState(() => _items.removeWhere((e) => e.id == t.id));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.operationSuccess)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: Text(l.myFavorites),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Get.back(),
        ),
      ),
      body: _items.isEmpty ? _buildEmpty(l) : _buildGrid(l),
    );
  }

  Widget _buildEmpty(AppLocalizations l) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: 72, color: AppTheme.gray400.withValues(alpha: 0.9)),
            const SizedBox(height: 16),
            Text(
              l.favoritesEmptyTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.gray900),
            ),
            const SizedBox(height: 8),
            Text(
              l.favoritesEmptySubtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppTheme.gray600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(AppLocalizations l) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemCount: _items.length,
      itemBuilder: (context, i) {
        final t = _items[i];
        return GestureDetector(
          onLongPress: () => _onLongPress(l, t),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            elevation: 0,
            shadowColor: Colors.black.withValues(alpha: 0.06),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(colors: t.gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
                        ),
                        child: Text(
                          t.avatarLetter,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
                        ),
                      ),
                      const Spacer(),
                      if (t.tagNew)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.successColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            l.newArrival,
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.successColor),
                          ),
                        ),
                      if (t.tagNew && t.tagTop) const SizedBox(width: 4),
                      if (t.tagTop)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            l.tagTop,
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.primaryColor),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    t.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.gray900),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, size: 16, color: Color(0xFFFBBF24)),
                      const SizedBox(width: 2),
                      Text(
                        t.rating.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.gray700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    t.specialty,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: AppTheme.gray600, height: 1.25),
                  ),
                  const Spacer(),
                  Text(
                    '\$${t.priceMin} – \$${t.priceMax}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.gray800),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 36,
                    child: ElevatedButton(
                      onPressed: () => Get.toNamed('/create-order?technicianId=${t.id}&packageId=demo'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(l.bookNow, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
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
}
