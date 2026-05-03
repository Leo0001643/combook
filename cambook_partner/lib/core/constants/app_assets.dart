/// 全局资源路径常量
///
/// 所有 asset 路径集中管理，修改文件名只需改此处，编译器静态检查防止路径拼写错误。
abstract final class AppAssets {
  // ── 首页背景 ──────────────────────────────────────────────────────────────
  static const bgHomePink   = 'assets/images/background_home_pink.jpeg';
  static const bgHomePurple = 'assets/images/background_home_geey.jpeg';
  static const bgHomeGreen  = 'assets/images/background_home_green.jpeg';

  // ── 登录/注册背景 ─────────────────────────────────────────────────────────
  static const bgAuthPink   = 'assets/images/background_pink.jpeg';
  static const bgAuthPurple = 'assets/images/background_geey.jpeg';
  static const bgAuthGreen  = 'assets/images/background_green.jpeg';

  // ── 音效 ──────────────────────────────────────────────────────────────────
  /// audioplayers AssetSource 相对路径（不含 assets/ 前缀）。
  /// audioplayers 在 iOS/Android 均原生支持 .mp3，无需区分平台。
  static const sfxNewOrder = 'mp3/prompt_tone.mp3';

  // ── 图标 ──────────────────────────────────────────────────────────────────
  static const icLogo = 'assets/icons/logo.png';
}
