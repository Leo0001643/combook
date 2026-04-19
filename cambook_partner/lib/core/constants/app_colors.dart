import 'package:flutter/material.dart';

/// 全局颜色常量 — 所有页面统一使用，禁止硬编码颜色值
abstract class AppColors {
  // ── 主色调 ─────────────────────────────────────────────────────────
  static const Color primary      = Color(0xFF4F46E5);
  static const Color primaryDark  = Color(0xFF3730A3);
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color secondary    = Color(0xFF7C3AED);

  // ── 功能色 ─────────────────────────────────────────────────────────
  static const Color success  = Color(0xFF059669);
  static const Color warning  = Color(0xFFD97706);
  static const Color danger   = Color(0xFFDC2626);
  static const Color info     = Color(0xFF0284C7);

  // ── 技师状态色 ────────────────────────────────────────────────────
  static const Color online = Color(0xFF059669);
  static const Color busy   = Color(0xFFD97706);
  static const Color rest   = Color(0xFF6B7280);

  // ── 订单状态色 ────────────────────────────────────────────────────
  static const Color orderPending   = Color(0xFFF59E0B);
  static const Color orderAccepted  = Color(0xFF3B82F6);
  static const Color orderInService = Color(0xFF8B5CF6);
  static const Color orderCompleted = Color(0xFF059669);
  static const Color orderCancelled = Color(0xFFEF4444);

  // ── 中性色 ────────────────────────────────────────────────────────
  static const Color background  = Color(0xFFF5F6FA);
  static const Color surface     = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecond  = Color(0xFF6B7280);
  static const Color textHint    = Color(0xFF9CA3AF);
  static const Color border      = Color(0xFFE5E7EB);
  static const Color divider     = Color(0xFFF3F4F6);

  // ── 渐变 ─────────────────────────────────────────────────────────
  static const LinearGradient gradientPrimary = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
  );
  static const LinearGradient gradientSuccess = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFF059669), Color(0xFF10B981)],
  );
  static const LinearGradient gradientWarm = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
  );
  static const LinearGradient gradientDark = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFF1E1B4B), Color(0xFF4C1D95)],
  );
}
