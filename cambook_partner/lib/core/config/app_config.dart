/// 多商户运行时配置
///
/// 所有字段均通过 `--dart-define=KEY=VALUE` 在构建时注入，
/// 实现"一套代码、多商户打包"，不同商户只需修改构建参数。
///
/// ─── 使用方式 ────────────────────────────────────────────────
/// 直接运行（开发默认值）：
///   flutter run
///
/// 单商户构建：
///   flutter build ipa --dart-define-from-file=merchants/cambook.json
///
/// 批量打包（所有商户）：
///   ./scripts/build_all_merchants.sh
///
/// ─── 参数说明 ────────────────────────────────────────────────
/// | Key               | 说明                     | 示例                      |
/// |-------------------|--------------------------|---------------------------|
/// | MERCHANT_ID       | 商户数字 ID（对应数据库）  | 1                         |
/// | MERCHANT_KEY      | 商户唯一标识（英文）       | cambook                   |
/// | MERCHANT_NAME     | 商户显示名称              | CamBook                   |
/// | API_BASE_URL      | 后端接口根路径            | https://api.cambook.io    |
/// | APP_NAME          | 应用名称（标题栏）         | CamBook Partner           |
/// | THEME_COLOR       | 主题主色（十六进制）       | 4F46E5                    |
/// | BANNER_URL        | 首页 Banner 图片 URL      | https://cdn.../banner.jpg |
/// | LOGO_URL          | 商户 Logo URL             | https://cdn.../logo.png   |
/// | SUPPORT_PHONE     | 客服电话                  | +85512345678              |
/// | DEV               | 是否开发模式               | true                      |
abstract class AppConfig {

  // ── 商户身份 ────────────────────────────────────────────────────────────────

  /// 商户数字 ID —— 对应数据库 `cb_merchant.id`，登录时随请求上传做租户隔离
  static const merchantId = int.fromEnvironment(
    'MERCHANT_ID', defaultValue: 1,
  );

  /// 商户唯一标识（英文，用于埋点/日志区分商户）
  static const merchantKey = String.fromEnvironment(
    'MERCHANT_KEY', defaultValue: 'cambook',
  );

  /// 商户显示名称（UI 展示用）
  static const merchantName = String.fromEnvironment(
    'MERCHANT_NAME', defaultValue: 'CamBook',
  );

  // ── 网络 ────────────────────────────────────────────────────────────────────

  /// 后端 API 根路径
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL', defaultValue: 'http://127.0.0.1:8080',
  );

  // ── 应用信息 ────────────────────────────────────────────────────────────────

  /// 应用名称（标题栏 / 关于页面）
  static const appName = String.fromEnvironment(
    'APP_NAME', defaultValue: 'CamBook Partner',
  );

  // ── 品牌视觉 ────────────────────────────────────────────────────────────────

  /// 主题主色（6位十六进制，不含 #），用于动态生成 ColorScheme
  static const themeColorHex = String.fromEnvironment(
    'THEME_COLOR', defaultValue: '4F46E5',
  );

  /// 首页 Banner 远程图片 URL（空字符串表示使用默认渐变背景）
  static const bannerUrl = String.fromEnvironment(
    'BANNER_URL', defaultValue: '',
  );

  /// 商户 Logo 远程图片 URL（空字符串表示使用默认 Icon）
  static const logoUrl = String.fromEnvironment(
    'LOGO_URL', defaultValue: '',
  );

  /// 客服电话（显示在设置页面 / 帮助页面）
  static const supportPhone = String.fromEnvironment(
    'SUPPORT_PHONE', defaultValue: '',
  );

  // ── 开发控制 ────────────────────────────────────────────────────────────────

  /// 是否为开发模式（true 时显示 DEV 按钮、使用 Mock 数据）
  static const isDev = bool.fromEnvironment('DEV', defaultValue: false);

  // ── 工具方法 ────────────────────────────────────────────────────────────────

  /// 将 themeColorHex 转换为 Flutter Color 对象
  static int get themeColorValue =>
      int.parse('FF$themeColorHex', radix: 16);
}
