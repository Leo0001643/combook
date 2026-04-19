/// 多商户运行时配置 —— 通过 dart-define 在构建时注入，实现一套代码多商户打包
///
/// 打包命令示例:
///   商户 A:
///     flutter build apk
///       --dart-define=MERCHANT_ID=merchant_a
///       --dart-define=MERCHANT_NAME=CamBook
///       --dart-define=API_BASE_URL=https://api.cambook.io
///       --dart-define=APP_NAME=CamBook Partner
///
///   商户 B:
///     flutter build apk
///       --dart-define=MERCHANT_ID=merchant_b
///       --dart-define=MERCHANT_NAME=SpaVibe
///       --dart-define=API_BASE_URL=https://api.spavibe.io
///       --dart-define=APP_NAME=SpaVibe Partner
///
/// 本地开发不传参数时使用默认值（cambook）
abstract class AppConfig {
  /// 商户唯一标识 —— 用于 API 请求头 X-Merchant-Id
  static const merchantId = String.fromEnvironment(
    'MERCHANT_ID', defaultValue: 'cambook',
  );

  /// 商户显示名称
  static const merchantName = String.fromEnvironment(
    'MERCHANT_NAME', defaultValue: 'CamBook',
  );

  /// API 根路径
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL', defaultValue: 'https://api.cambook.io',
  );

  /// APP 名称（显示在标题栏）
  static const appName = String.fromEnvironment(
    'APP_NAME', defaultValue: 'CamBook Partner',
  );

  /// 是否开发模式（dart-define=DEV=true 时启用 mock 数据 / DEV 按钮）
  static const isDev = bool.fromEnvironment('DEV', defaultValue: false);
}
