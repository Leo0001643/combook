/// 全局应用配置
/// 通过 --dart-define 注入，避免硬编码密钥进源码
/// 示例：flutter run --dart-define=GOOGLE_MAPS_API_KEY=AIza...
class AppConfig {
  AppConfig._();

  /// Google Maps API Key
  /// 需在 Google Cloud Console 启用 Geocoding API 和 Places API
  static const googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: '',
  );

  /// 后端 API 基础 URL（可通过 --dart-define 覆盖）
  static const backendBaseUrl = String.fromEnvironment(
    'BACKEND_BASE_URL',
    defaultValue: 'http://127.0.0.1:8080',
  );
}
