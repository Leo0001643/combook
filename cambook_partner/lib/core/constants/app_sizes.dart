/// 全局尺寸常量
abstract class AppSizes {
  // ── 内边距 ────────────────────────────────────────────────────────
  static const double pagePadding  = 16.0;
  static const double cardPadding  = 14.0;
  static const double itemPadding  = 12.0;

  // ── 圆角 ──────────────────────────────────────────────────────────
  static const double radiusXs  = 6.0;
  static const double radiusSm  = 8.0;
  static const double radiusMd  = 12.0;
  static const double radiusLg  = 16.0;
  static const double radiusXl  = 20.0;
  static const double radiusXxl = 24.0;
  static const double radiusFull= 100.0;

  // ── 间距 ──────────────────────────────────────────────────────────
  static const double gap4  = 4.0;
  static const double gap6  = 6.0;
  static const double gap8  = 8.0;
  static const double gap10 = 10.0;
  static const double gap12 = 12.0;
  static const double gap16 = 16.0;
  static const double gap20 = 20.0;
  static const double gap24 = 24.0;
  static const double gap32 = 32.0;

  // ── 图标 ──────────────────────────────────────────────────────────
  static const double iconXs = 14.0;
  static const double iconSm = 18.0;
  static const double iconMd = 22.0;
  static const double iconLg = 28.0;
  static const double iconXl = 36.0;

  // ── 按钮高度 ─────────────────────────────────────────────────────
  static const double btnHeightSm = 38.0;
  static const double btnHeightMd = 48.0;
  static const double btnHeightLg = 54.0;

  // ── 底部导航栏 ────────────────────────────────────────────────────
  static const double tabBarHeight = 60.0;

  // ── 头像 ─────────────────────────────────────────────────────────
  static const double avatarSm = 32.0;
  static const double avatarMd = 44.0;
  static const double avatarLg = 64.0;
  static const double avatarXl = 86.0;
}

/// 全局图片 / 资源路径常量
abstract class AppImages {
  static const String _base = 'assets/images/';
  static const String logo       = '${_base}logo.png';
  static const String placeholder= '${_base}placeholder.png';
  static const String avatar     = '${_base}avatar_default.png';
  static const String emptyBox   = '${_base}empty_box.png';
}

/// 全局图标路径（SVG）
abstract class AppIcons {
  static const String _base = 'assets/icons/';
  static const String home     = '${_base}home.svg';
  static const String order    = '${_base}order.svg';
  static const String message  = '${_base}message.svg';
  static const String income   = '${_base}income.svg';
  static const String profile  = '${_base}profile.svg';
}
