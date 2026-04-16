import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide Response;
import '../auth/auth_controller.dart';
import '../config/app_config.dart';

/// 地理编码服务（Google Maps Geocoding API）
/// 按当前用户语言将坐标 (lat/lng) 转换为本地化地址文本
/// 内置内存缓存，语言切换时自动清空
class GeocodingService extends GetxService {
  static GeocodingService get to => Get.find();

  /// 缓存键：'lat,lng,googleLang'  → 格式化地址
  final _cache = <String, String>{};

  late final Dio _dio;

  @override
  void onInit() {
    super.onInit();
    _dio = Dio(BaseOptions(
      baseUrl:        'https://maps.googleapis.com',
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 10),
      responseType:   ResponseType.json,
    ));
  }

  // ── 公开 API ────────────────────────────────────────────────────────

  /// 反向地理编码：(lat, lng) → 当前 App 语言的格式化地址
  /// [fallback]     — API 调用失败时返回的兜底文本
  /// [overrideLang] — 强制使用指定语言（忽略当前 App 语言）
  Future<String> reverseGeocode(
    double lat,
    double lng, {
    String fallback = '',
    String? overrideLang,
  }) async {
    if (AppConfig.googleMapsApiKey.isEmpty) {
      debugPrint('[GeocodingService] Google Maps API key not configured.');
      return fallback;
    }

    final lang     = overrideLang ?? _appLangToGoogle();
    final cacheKey = '${lat.toStringAsFixed(6)},${lng.toStringAsFixed(6)},$lang';

    if (_cache.containsKey(cacheKey)) return _cache[cacheKey]!;

    try {
      final resp = await _dio.get(
        '/maps/api/geocode/json',
        queryParameters: {
          'latlng':      '$lat,$lng',
          'language':    lang,
          'result_type': 'street_address|route|sublocality|locality',
          'key':         AppConfig.googleMapsApiKey,
        },
      );

      if (resp.statusCode == 200 && resp.data['status'] == 'OK') {
        final results = resp.data['results'] as List?;
        if (results != null && results.isNotEmpty) {
          final address = results.first['formatted_address'] as String? ?? fallback;
          _cache[cacheKey] = address;
          return address;
        }
      }
    } on DioException catch (e) {
      debugPrint('[GeocodingService] reverseGeocode error: ${e.message}');
    }

    return fallback;
  }

  /// 清空地址缓存（语言切换时调用，确保下次请求按新语言重新获取）
  void clearCache() => _cache.clear();

  // ── 私有工具 ────────────────────────────────────────────────────────

  /// 将 App locale code 映射到 Google Maps language 参数
  String _appLangToGoogle() {
    try {
      switch (AuthController.to.appLocale.value) {
        case 'zh': return 'zh-CN';
        case 'vi': return 'vi';
        case 'km': return 'km';
        default:   return 'en';
      }
    } catch (_) {
      return 'en';
    }
  }
}
