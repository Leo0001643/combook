import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../config/app_config.dart';
import '../constants/app_colors.dart';
import '../services/storage_service.dart';
import '../../features/auth/auth_shared.dart';

// ─────────────────────────────────────────────────────────────────────────────
// 支持的主题变体（开闭原则：新增变体只需扩展 enum + extension，不改其他代码）
// ─────────────────────────────────────────────────────────────────────────────
enum AppThemeVariant { pink, purple, green }

extension AppThemeVariantExt on AppThemeVariant {
  String get key => name; // 'pink' | 'purple' | 'green'

  static AppThemeVariant fromKey(String? k) => switch (k) {
    'purple' => AppThemeVariant.purple,
    'green'  => AppThemeVariant.green,
    'ivory'  => AppThemeVariant.purple, // backward-compat alias
    _        => AppThemeVariant.pink,
  };

  /// 主强调色
  Color get primary => switch (this) {
    AppThemeVariant.pink   => const Color(0xFFE8608A),
    AppThemeVariant.purple => const Color(0xFF9874C8),
    AppThemeVariant.green  => const Color(0xFF4B9B6F),
  };

  /// 深一阶（渐变深色端、AppBar）
  Color get primaryDark => switch (this) {
    AppThemeVariant.pink   => const Color(0xFFD04070),
    AppThemeVariant.purple => const Color(0xFF7A5DB8),
    AppThemeVariant.green  => const Color(0xFF357A52),
  };

  /// 浅一阶（focus border、浅背景）
  Color get primaryLight => switch (this) {
    AppThemeVariant.pink   => const Color(0xFFFF9FC0),
    AppThemeVariant.purple => const Color(0xFFCDB8E8),
    AppThemeVariant.green  => const Color(0xFF8ECBAA),
  };

  /// 对应 SpaAuthTheme 变体（认证页使用）
  SpaThemeVariant get spaVariant => switch (this) {
    AppThemeVariant.pink   => SpaThemeVariant.pink,
    AppThemeVariant.purple => SpaThemeVariant.purple,
    AppThemeVariant.green  => SpaThemeVariant.green,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// 全局主题控制器 — 单例，应用内任意位置可读写
// ─────────────────────────────────────────────────────────────────────────────
class AppThemeController extends GetxController {
  static AppThemeController get to => Get.find<AppThemeController>();

  /// 唯一可观察状态——所有 Obx 都依赖这个字段
  final Rx<AppThemeVariant> variantRx = AppThemeVariant.pink.obs;

  @override
  void onInit() {
    super.onInit();
    // Priority: user's stored preference > build-time JSON config > fallback pink
    final stored = Get.find<StorageService>().storedThemeColor;
    variantRx.value = AppThemeVariantExt.fromKey(
      stored ?? AppConfig.themeVariant,
    );
  }

  // ── Getters ─────────────────────────────────────────────────────────────────

  AppThemeVariant get variant   => variantRx.value;
  Color           get primary   => variantRx.value.primary;
  Color           get primaryDk => variantRx.value.primaryDark;
  Color           get primaryLt => variantRx.value.primaryLight;
  SpaAuthTheme    get spaTheme  => SpaAuthTheme(variantRx.value.spaVariant);

  /// 供 main.dart 中 Obx 响应式 ThemeData
  ThemeData get themeData => _buildTheme(variantRx.value);

  // ── Mutations ───────────────────────────────────────────────────────────────

  void select(AppThemeVariant v) {
    variantRx.value = v;
    Get.find<StorageService>().saveThemeColor(v.key);
  }

  void toggle() {
    final next = switch (variantRx.value) {
      AppThemeVariant.pink   => AppThemeVariant.purple,
      AppThemeVariant.purple => AppThemeVariant.green,
      AppThemeVariant.green  => AppThemeVariant.pink,
    };
    select(next);
  }

  // ── ThemeData builder ────────────────────────────────────────────────────────

  static ThemeData _buildTheme(AppThemeVariant v) {
    final p  = v.primary;
    final pd = v.primaryDark;
    final pl = v.primaryLight;

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: p).copyWith(
        primary:   p,
        secondary: pd,
        surface:   AppColors.surface,
      ),
      scaffoldBackgroundColor: AppColors.background,

      textTheme: const TextTheme(
        bodyLarge:   TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
        bodyMedium:  TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
        bodySmall:   TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecond),
        titleLarge:  TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        titleMedium: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        titleSmall:  TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        labelLarge:  TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        labelMedium: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecond),
        labelSmall:  TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textHint),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: p,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      cardTheme: CardTheme(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p,
          side: BorderSide(color: p),
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p,
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: p,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF8F9FE),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: p, width: 2)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.danger)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.danger, width: 2)),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(color: p),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? p : null),
      ),

      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? p : null),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? p : null),
        trackColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? pl : null),
      ),

      dividerTheme: const DividerThemeData(
          color: AppColors.divider, thickness: 1, space: 1),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: p,
        unselectedItemColor: AppColors.textHint,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }
}
