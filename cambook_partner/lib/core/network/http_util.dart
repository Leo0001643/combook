import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;
import '../config/app_config.dart';
import '../services/storage_service.dart';
import '../utils/log_util.dart';
import '../routes/app_routes.dart';

/// 统一网络请求封装
/// 用法：HttpUtil.get('/path') / HttpUtil.post('/path', data:{})
class HttpUtil {
  HttpUtil._();

  static const String _baseUrl = AppConfig.apiBaseUrl;
  static const int    _timeout = 15000;

  static late final Dio _dio;
  static bool _initialized = false;

  /// 必须在 main() 初始化
  static void init() {
    if (_initialized) return;
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(milliseconds: _timeout),
      receiveTimeout: const Duration(milliseconds: _timeout),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-Merchant-Id': AppConfig.merchantId,   // 多商户标识
      },
    ));
    _dio.interceptors.addAll([_AuthInterceptor(), _LogInterceptor(), _ErrorInterceptor()]);
    _initialized = true;
  }

  // ── GET ───────────────────────────────────────────────────────────
  static Future<T> get<T>(String path, {
    Map<String, dynamic>? params,
    T Function(dynamic)? fromJson,
  }) async {
    final resp = await _dio.get(path, queryParameters: params);
    return _parse<T>(resp.data, fromJson);
  }

  // ── POST ──────────────────────────────────────────────────────────
  static Future<T> post<T>(String path, {
    dynamic data,
    T Function(dynamic)? fromJson,
  }) async {
    final resp = await _dio.post(path, data: data);
    return _parse<T>(resp.data, fromJson);
  }

  // ── PUT ───────────────────────────────────────────────────────────
  static Future<T> put<T>(String path, {
    dynamic data,
    T Function(dynamic)? fromJson,
  }) async {
    final resp = await _dio.put(path, data: data);
    return _parse<T>(resp.data, fromJson);
  }

  // ── PATCH ─────────────────────────────────────────────────────────
  static Future<T> patch<T>(String path, {
    dynamic data,
    T Function(dynamic)? fromJson,
  }) async {
    final resp = await _dio.patch(path, data: data);
    return _parse<T>(resp.data, fromJson);
  }

  // ── DELETE ────────────────────────────────────────────────────────
  static Future<T> delete<T>(String path, {T Function(dynamic)? fromJson}) async {
    final resp = await _dio.delete(path);
    return _parse<T>(resp.data, fromJson);
  }

  static T _parse<T>(dynamic raw, T Function(dynamic)? fromJson) {
    final body = raw is Map<String, dynamic> ? raw : {'data': raw};
    if (body['code'] != null && body['code'] != 0 && body['code'] != 200) {
      throw ApiException(body['msg'] ?? 'Server error', body['code']);
    }
    final data = body['data'] ?? body;
    return fromJson != null ? fromJson(data) : data as T;
  }
}

// ── 认证拦截器 ─────────────────────────────────────────────────────────────────
class _AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions opts, RequestInterceptorHandler handler) {
    final token = Get.find<StorageService>().token;
    if (token != null) opts.headers['Authorization'] = 'Bearer $token';
    handler.next(opts);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      Get.find<StorageService>().clear();
      Get.offAllNamed(AppRoutes.login);
    }
    handler.next(err);
  }
}

// ── 日志拦截器 ─────────────────────────────────────────────────────────────────
class _LogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions opts, RequestInterceptorHandler handler) {
    LogUtil.d('[HTTP] ▶ ${opts.method} ${opts.path}');
    handler.next(opts);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    LogUtil.d('[HTTP] ◀ ${response.statusCode} ${response.requestOptions.path}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    LogUtil.e('[HTTP] ✗ ${err.message}');
    handler.next(err);
  }
}

// ── 统一错误处理拦截器 ────────────────────────────────────────────────────────
class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    String msg;
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        msg = 'Request timeout'; break;
      case DioExceptionType.connectionError:
        msg = 'Network unavailable'; break;
      default:
        msg = err.response?.data?['msg'] ?? 'Request failed';
    }
    handler.reject(DioException(
      requestOptions: err.requestOptions, message: msg, error: err.error,
    ));
  }
}

/// 业务异常
class ApiException implements Exception {
  final String message;
  final dynamic code;
  const ApiException(this.message, [this.code]);
  @override String toString() => message;
}
