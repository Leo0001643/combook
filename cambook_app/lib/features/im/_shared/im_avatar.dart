import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// 通用 IM 头像组件：有 URL 时显示网络图，否则显示名字首字母 + 渐变背景
class ImAvatar extends StatelessWidget {
  final String  name;
  final String? url;
  final double  size;
  final int?    userId;

  const ImAvatar({
    super.key,
    required this.name,
    this.url,
    this.size = 40,
    this.userId,
  });

  @override
  Widget build(BuildContext context) {
    if (url != null && url!.isNotEmpty) {
      return ClipOval(child: CachedNetworkImage(
        imageUrl: url!,
        width: size, height: size,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => _initials(),
      ));
    }
    return _initials();
  }

  Widget _initials() {
    final initials = name.length >= 2 ? name.substring(name.length - 2) : name;
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: _gradient(userId),
        ),
      ),
      child: Center(child: Text(
        initials.toUpperCase(),
        style: TextStyle(color: Colors.white, fontSize: size * 0.35, fontWeight: FontWeight.w700),
      )),
    );
  }

  static List<Color> _gradient(int? id) {
    final palettes = [
      [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
      [const Color(0xFF00A884), const Color(0xFF007A63)],
      [const Color(0xFFEC4899), const Color(0xFFF59E0B)],
      [const Color(0xFF3B82F6), const Color(0xFF06B6D4)],
      [const Color(0xFFEF4444), const Color(0xFFF97316)],
      [const Color(0xFF10B981), const Color(0xFF059669)],
    ];
    return palettes[(id ?? 0) % palettes.length];
  }
}
