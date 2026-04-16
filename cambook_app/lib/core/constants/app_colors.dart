import 'package:flutter/material.dart';

/// 全局颜色常量
/// 整个项目唯一的颜色来源，所有组件直接引用此类
///
/// 品牌色系：金橙（CamBook 高端 SPA 调性）
abstract final class AppColors {
  AppColors._();

  // ── 品牌主色（金橙渐变） ──────────────────────────────────────────
  /// 主色：金橙
  static const Color primary = Color(0xFFF5A623);
  /// 主色深：用于悬停、按压态
  static const Color primaryDark = Color(0xFFE8960B);
  /// 主色浅：用于背景高亮、选中态底色
  static const Color primaryLight = Color(0xFFFFF3DC);
  /// 强调色：与主色形成渐变
  static const Color accent = Color(0xFFFF7D00);

  // ── 品牌渐变 ──────────────────────────────────────────────────────
  /// 按钮/标签主渐变（primary → accent）
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, accent],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
  /// 暗色头部渐变（深蓝黑，常用于 header/banner 背景）
  static const LinearGradient darkHeaderGradient = LinearGradient(
    colors: [Color(0xFF1A1F2E), Color(0xFF2A3348)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── 功能色 ────────────────────────────────────────────────────────
  /// 成功
  static const Color success = Color(0xFF10B981);
  /// 警告
  static const Color warning = Color(0xFFF59E0B);
  /// 错误 / 价格红
  static const Color error = Color(0xFFDC2626);
  /// 信息
  static const Color info = Color(0xFF3B82F6);

  // ── 中性色阶（灰度系列） ──────────────────────────────────────────
  static const Color gray50  = Color(0xFFF9FAFB);
  static const Color gray100 = Color(0xFFF3F4F6);
  static const Color gray200 = Color(0xFFE5E7EB);
  static const Color gray300 = Color(0xFFD1D5DB);
  static const Color gray400 = Color(0xFF9CA3AF);
  static const Color gray500 = Color(0xFF6B7280);
  static const Color gray600 = Color(0xFF4B5563);
  static const Color gray700 = Color(0xFF374151);
  static const Color gray800 = Color(0xFF1F2937);
  static const Color gray900 = Color(0xFF111827);

  // ── 背景 ──────────────────────────────────────────────────────────
  /// 主背景（页面底色）
  static const Color bgPage    = Color(0xFFF6F7FA);
  /// 卡片背景
  static const Color bgCard    = Color(0xFFFFFFFF);
  /// 输入框填充色
  static const Color bgInput   = Color(0xFFF3F4F6);
  /// 暗色背景（header / splash）
  static const Color bgDark    = Color(0xFF1A1F2E);
  static const Color bgDarker  = Color(0xFF0D1117);

  // ── 文字 ──────────────────────────────────────────────────────────
  static const Color textPrimary   = gray900;
  static const Color textSecondary = gray600;
  static const Color textHint      = gray400;
  static const Color textOnDark    = Colors.white;
  static const Color textOnPrimary = Colors.white;

  // ── 边框 ──────────────────────────────────────────────────────────
  static const Color border       = gray200;
  static const Color borderLight  = Color(0xFFF0F0F0);
  static const Color borderDark   = gray300;

  // ── 遮罩 ──────────────────────────────────────────────────────────
  static const Color overlay     = Color(0x80000000);
  static const Color overlayLight= Color(0x1A000000);

  // ── 服务品类色（技师卡片 / 分类图标） ────────────────────────────
  static const Color categoryMassage  = Color(0xFF5B5BD6); // 全身按摩 — 靛紫
  static const Color categoryAroma    = Color(0xFFD97706); // 精油 SPA  — 琥珀
  static const Color categoryFoot     = Color(0xFF0D9488); // 足底按摩 — 翠绿
  static const Color categoryPostnatal= Color(0xFFEC4899); // 产后护理 — 玫红
  static const Color categoryMerchant = Color(0xFF8B5CF6); // 商户合作 — 紫罗兰
  static const Color categoryTag1     = Color(0xFF5B5BD6);
  static const Color categoryTag2     = Color(0xFF0D9488);
  static const Color categoryTag3     = Color(0xFFD97706);
}
