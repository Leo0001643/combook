import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

/// CamBook 全局主题配置
/// 颜色常量统一由 AppColors 定义，本类只负责 ThemeData 组装
class AppTheme {
  AppTheme._();

  // ── 向下兼容的别名（逐步迁移到直接使用 AppColors） ──────────────
  static const Color primaryColor   = AppColors.categoryMassage;  // 紫靛（当前主色）
  static const Color primaryDark    = Color(0xFF4F46E5);
  static const Color primaryLight   = Color(0xFFEEF2FF);
  static const Color secondaryColor = AppColors.bgDark;
  static const Color accentColor    = AppColors.categoryMerchant;

  static const Color successColor = AppColors.success;
  static const Color warningColor = AppColors.warning;
  static const Color errorColor   = AppColors.error;
  static const Color infoColor    = AppColors.info;

  static const Color gray100 = AppColors.gray50;
  static const Color gray200 = AppColors.gray100;
  static const Color gray300 = AppColors.gray200;
  static const Color gray400 = AppColors.gray300;
  static const Color gray500 = AppColors.gray400;
  static const Color gray600 = AppColors.gray500;
  static const Color gray700 = AppColors.gray600;
  static const Color gray800 = AppColors.gray700;
  static const Color gray900 = AppColors.gray800;

  // ==================== 浅色主题 ====================
  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          brightness: Brightness.light,
          primary: primaryColor,
          secondary: accentColor,
          surface: Colors.white,
          background: gray100,
          error: errorColor,
        ),
        scaffoldBackgroundColor: gray100,

        // 全局字体：Plus Jakarta Sans（拉丁/越南文）+ 系统字体回退（中文/高棉文）
        fontFamily: GoogleFonts.plusJakartaSans().fontFamily,

        // 文字样式
        textTheme: _buildTextTheme(isDark: false),

        // AppBar 样式
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: gray900,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: gray900),
          titleTextStyle: GoogleFonts.plusJakartaSans(
            color: gray900,
            fontSize: 17,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.black.withOpacity(0.08),
        ),

        // 底部导航栏样式
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: primaryColor,
          unselectedItemColor: gray500,
          type: BottomNavigationBarType.fixed,
          elevation: 12,
          selectedLabelStyle: GoogleFonts.plusJakartaSans(
            fontSize: 11, fontWeight: FontWeight.w700,
          ),
          unselectedLabelStyle: GoogleFonts.plusJakartaSans(
            fontSize: 11, fontWeight: FontWeight.w400,
          ),
          showUnselectedLabels: true,
        ),

        // 卡片样式
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: EdgeInsets.zero,
          shadowColor: Colors.black.withOpacity(0.06),
        ),

        // 按钮样式
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
            shadowColor: primaryColor.withOpacity(0.4),
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ),

        // 文本按钮
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: primaryColor,
            textStyle: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // 输入框样式
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: gray100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: gray300, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: gray300, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: primaryColor, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: errorColor, width: 1),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          hintStyle: TextStyle(color: gray500, fontSize: 14),
        ),

        // Chip 样式
        chipTheme: ChipThemeData(
          backgroundColor: gray100,
          selectedColor: primaryLight,
          labelStyle: const TextStyle(fontSize: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),

        // 分割线
        dividerTheme: const DividerThemeData(
          color: gray200,
          thickness: 1,
          space: 0,
        ),
      );

  // ==================== 深色主题（备用） ====================
  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          brightness: Brightness.dark,
          primary: primaryColor,
          secondary: accentColor,
        ),
        fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
        textTheme: _buildTextTheme(isDark: true),
      );

  // ── 字体工具 ────────────────────────────────────────────────────────────────

  /// 全局字体回退链：中文→Noto Sans SC / PingFang SC；高棉语→Noto Sans Khmer；
  /// 其余由系统 sans-serif 兜底。移动设备均内置这些字体，无需额外下载。
  static const List<String> _fontFallback = [
    'Noto Sans SC',     // Android 中文
    'PingFang SC',      // iOS 中文
    'Noto Sans Khmer',  // 高棉语（柬埔寨）
    'Noto Sans',        // 其余 Unicode 兜底
  ];

  /// 构建 Plus Jakarta Sans 风格的 TextStyle，带多语言回退链
  static TextStyle _ts({
    required double size,
    required FontWeight weight,
    required Color color,
    double height   = 1.55,
    double tracking = 0,
  }) =>
      GoogleFonts.plusJakartaSans(
        fontSize:      size,
        fontWeight:    weight,
        color:         color,
        height:        height,
        letterSpacing: tracking,
      ).copyWith(fontFamilyFallback: _fontFallback);

  /// 构建文字主题（Plus Jakarta Sans + 多语言回退）
  static TextTheme _buildTextTheme({required bool isDark}) {
    final base = isDark ? Colors.white : gray900;
    final sub  = isDark ? Colors.white70 : gray600;
    final hint = isDark ? Colors.white54 : gray500;

    return TextTheme(
      // Display — 超大标题（欢迎页、营销页）
      displayLarge:  _ts(size: 32, weight: FontWeight.w800, color: base, height: 1.2),
      displayMedium: _ts(size: 28, weight: FontWeight.w700, color: base, height: 1.2),
      displaySmall:  _ts(size: 24, weight: FontWeight.w700, color: base, height: 1.3),

      // Headline — 页面主标题
      headlineLarge:  _ts(size: 22, weight: FontWeight.w700, color: base, height: 1.3),
      headlineMedium: _ts(size: 20, weight: FontWeight.w700, color: base, height: 1.35),
      headlineSmall:  _ts(size: 18, weight: FontWeight.w600, color: base, height: 1.4),

      // Title — 卡片标题、导航项
      titleLarge:  _ts(size: 17, weight: FontWeight.w700, color: base, height: 1.4, tracking: 0.1),
      titleMedium: _ts(size: 15, weight: FontWeight.w600, color: base, height: 1.5),
      titleSmall:  _ts(size: 13, weight: FontWeight.w600, color: base, height: 1.5),

      // Body — 正文内容
      bodyLarge:  _ts(size: 16, weight: FontWeight.w400, color: base, height: 1.65),
      bodyMedium: _ts(size: 14, weight: FontWeight.w400, color: base, height: 1.6),
      bodySmall:  _ts(size: 12, weight: FontWeight.w400, color: sub,  height: 1.55),

      // Label — 标签、徽章、辅助文字
      labelLarge:  _ts(size: 14, weight: FontWeight.w700, color: base, height: 1.4, tracking: 0.1),
      labelMedium: _ts(size: 12, weight: FontWeight.w600, color: base, height: 1.4),
      labelSmall:  _ts(size: 11, weight: FontWeight.w500, color: hint, height: 1.4, tracking: 0.2),
    );
  }
}
