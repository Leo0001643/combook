import 'package:get/get.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';

/// 帖子头图渐变（Canvas 绘制）
class _PostHeaderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final gradient = LinearGradient(
      colors: [
        AppTheme.primaryColor,
        AppTheme.accentColor,
        AppTheme.primaryDark,
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    final paint = Paint()..shader = gradient.createShader(rect);
    canvas.drawRect(rect, paint);

    // 装饰性柔光圆
    final glow = Paint()..color = Colors.white.withValues(alpha: 0.12);
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.2), size.width * 0.35, glow);
    canvas.drawCircle(Offset(size.width * 0.15, size.height * 0.75), size.width * 0.25, glow);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 单条评论 Mock
class _Comment {
  const _Comment({
    required this.name,
    required this.avatarColor,
    required this.time,
    required this.text,
  });

  final String name;
  final Color avatarColor;
  final String time;
  final String text;
}

/// 帖子详情 — 头图、正文、互动、评论
class PostDetailPage extends StatefulWidget {
  const PostDetailPage({super.key, required this.postId});

  final String postId;

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  bool _followed = false;
  bool _liked = false;
  bool _collected = false;
  int _likes = 128;

  static const List<_Comment> _comments = [
    _Comment(
      name: '小雨',
      avatarColor: Color(0xFFFFCCBC),
      time: '10 分钟前',
      text: '写得真好，周末也想去试试这家 SPA～',
    ),
    _Comment(
      name: '阿杰',
      avatarColor: Color(0xFFC5E1A5),
      time: '32 分钟前',
      text: '摄影师加鸡腿！构图和光线都很舒服。',
    ),
    _Comment(
      name: 'Momo',
      avatarColor: Color(0xFFB3E5FC),
      time: '1 小时前',
      text: '请问预约要提前多久呀？',
    ),
    _Comment(
      name: 'CamBook 用户',
      avatarColor: AppTheme.gray300,
      time: '2 小时前',
      text: '已收藏，等发工资就去下单哈哈。',
    ),
    _Comment(
      name: '林悦',
      avatarColor: Color(0xFFFFE082),
      time: '3 小时前',
      text: '谢谢喜欢，欢迎来体验我们的芳香理疗套餐。',
    ),
  ];

  void _toggleLike() {
    setState(() {
      _liked = !_liked;
      _likes += _liked ? 1 : -1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  elevation: 0,
                  backgroundColor: Colors.white,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppTheme.gray900),
                    onPressed: () => Get.back(),
                  ),
                  title: Text(
                    l.postDetail,
                    style: const TextStyle(color: AppTheme.gray900, fontWeight: FontWeight.w700, fontSize: 17),
                  ),
                  centerTitle: true,
                ),
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 头图区域：Canvas 渐变
                      SizedBox(
                        height: 200,
                        width: double.infinity,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CustomPaint(painter: _PostHeaderPainter()),
                            Positioned(
                              left: 16,
                              right: 16,
                              bottom: 20,
                              child: Text(
                                '春日疗愈日记 · Post #${widget.postId}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  shadows: [Shadow(blurRadius: 8, color: Colors.black26)],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 作者信息行
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: const Color(0xFFFFE0B2),
                                  child: const Text('李', style: TextStyle(fontWeight: FontWeight.w700)),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        '李班',
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.gray900),
                                      ),
                                      Text(
                                        '2026-04-12 · 合肥',
                                        style: TextStyle(fontSize: 12, color: AppTheme.gray500.withValues(alpha: 0.9)),
                                      ),
                                    ],
                                  ),
                                ),
                                OutlinedButton(
                                  onPressed: () => setState(() => _followed = !_followed),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: _followed ? AppTheme.gray500 : AppTheme.primaryColor,
                                    side: BorderSide(
                                      color: _followed ? AppTheme.gray300 : AppTheme.primaryColor,
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                                    minimumSize: const Size(72, 34),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  ),
                                  child: Text(_followed ? l.following : l.follow),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // 正文
                            const Text(
                              '四月的风里带着一点花香，最适合约一次上门 SPA。技师准时到达，热敷与肩颈手法让整个人的紧绷感慢慢松开。房间只留一盏暖灯，音乐和精油味道都刚刚好。',
                              style: TextStyle(fontSize: 15, height: 1.65, color: AppTheme.gray700),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              '如果你也长期伏案，可以试试「肩颈舒缓 + 精油推拿」组合；结束后记得多喝温水，当晚睡眠质量会明显提升。CamBook 上可以直接看技师评价与距离，预约很省心。',
                              style: TextStyle(fontSize: 15, height: 1.65, color: AppTheme.gray700),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              '把这份放松分享给同样需要喘口气的你，愿我们都能在忙碌里留一点温柔给自己。',
                              style: TextStyle(fontSize: 15, height: 1.65, color: AppTheme.gray700),
                            ),
                            const SizedBox(height: 16),
                            // 标签
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: ['#春日疗愈', '#上门 SPA', '#CamBook 精选', '#放松时刻']
                                  .map(
                                    (t) => Chip(
                                      label: Text(t, style: const TextStyle(fontSize: 12)),
                                      backgroundColor: AppTheme.primaryLight,
                                      side: BorderSide.none,
                                      padding: EdgeInsets.zero,
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  )
                                  .toList(),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Text(l.messages, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                                Text(' (${_comments.length})', style: const TextStyle(color: AppTheme.gray500)),
                              ],
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final c = _comments[i];
                      return Container(
                        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(radius: 18, backgroundColor: c.avatarColor),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        c.name,
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                      ),
                                      const Spacer(),
                                      Text(c.time, style: const TextStyle(fontSize: 11, color: AppTheme.gray400)),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(c.text, style: const TextStyle(fontSize: 14, height: 1.5, color: AppTheme.gray700)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    childCount: _comments.length,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
          ),
          // 底部互动条 + 评论框
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _DetailActionPill(
                          icon: _liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: _liked ? Colors.redAccent : AppTheme.gray600,
                          label: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
                            transitionBuilder: (child, anim) =>
                                ScaleTransition(scale: anim, child: child),
                            child: Text(
                              '$_likes',
                              key: ValueKey(_likes),
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                          ),
                          onTap: _toggleLike,
                        ),
                        _DetailActionPill(
                          icon: _collected ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                          color: _collected ? AppTheme.primaryColor : AppTheme.gray600,
                          label: Text(l.saveFavorite),
                          onTap: () => setState(() => _collected = !_collected),
                        ),
                        _DetailActionPill(
                          icon: Icons.share_rounded,
                          color: AppTheme.gray600,
                          label: Text(l.share),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l.share)),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      decoration: InputDecoration(
                        hintText: l.commentHint,
                        filled: true,
                        fillColor: AppTheme.gray100,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.send_rounded, color: AppTheme.primaryColor),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l.commentSent)),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 底部操作按钮单元（避免与 Material [ActionChip] 混淆）
class _DetailActionPill extends StatelessWidget {
  const _DetailActionPill({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final Widget label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(width: 6),
            DefaultTextStyle.merge(
              style: TextStyle(color: color, fontWeight: FontWeight.w500),
              child: label,
            ),
          ],
        ),
      ),
    );
  }
}
