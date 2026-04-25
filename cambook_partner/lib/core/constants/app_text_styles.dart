import 'package:flutter/material.dart';
import 'app_colors.dart';

/// 全局文字样式 — 系统字体，统一层级（精品系统：字号稍大、字重稍粗，可读性更强）
abstract class AppTextStyles {
  // ── 标题 ──────────────────────────────────────────────────────────
  static const TextStyle h1 = TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: AppColors.textPrimary, height: 1.2);
  static const TextStyle h2 = TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary, height: 1.3);
  static const TextStyle h3 = TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary, height: 1.3);

  // ── 正文 ──────────────────────────────────────────────────────────
  static const TextStyle body1 = TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textPrimary, height: 1.5);
  static const TextStyle body2 = TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textPrimary, height: 1.5);
  static const TextStyle body3 = TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textSecond, height: 1.5);

  // ── 标签 / 按钮 ───────────────────────────────────────────────────
  static const TextStyle label1 = TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary);
  static const TextStyle label2 = TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary);
  static const TextStyle label3 = TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary);

  // ── 辅助 ──────────────────────────────────────────────────────────
  static const TextStyle caption = TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textHint);
  static const TextStyle hint    = TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: AppColors.textHint);

  // ── 金额专用 ─────────────────────────────────────────────────────
  static const TextStyle amountLg = TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: AppColors.primary);
  static const TextStyle amountMd = TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primary);
  static const TextStyle amountSm = TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.primary);

  // ── 白色系（用于渐变背景上）────────────────────────────────────────
  static const TextStyle whiteH   = TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white);
  static const TextStyle whiteMd  = TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white);
  static const TextStyle whiteSm  = TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white70);
  static const TextStyle whiteXs  = TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: Colors.white60);
}
