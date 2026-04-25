import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart' hide Response;
import '../config/app_config.dart';
import '../services/storage_service.dart';
import '../services/user_service.dart';
import '../utils/log_util.dart';
import '../utils/toast_util.dart';
import '../i18n/l10n_ext.dart';

/// 当前应用语言码（每次请求动态取，支持运行时切换）
String get _currentLang => Get.locale?.languageCode ?? 'zh';

/// 统一网络请求封装
class HttpUtil {
  HttpUtil._();

  static const int _timeout = 15000;

  static late final Dio _dio;
  static bool _initialized = false;

  /// 必须在 main() 中、runApp() 之前调用
  static void init() {
    if (_initialized) return;

    _dio = Dio(BaseOptions(
      baseUrl:        AppConfig.apiBaseUrl,
      // 使用表单参数提交，Spring @ModelAttribute 直接绑定
      contentType:    'application/x-www-form-urlencoded',
      responseType:   ResponseType.json,
      connectTimeout: const Duration(milliseconds: _timeout),
      receiveTimeout: const Duration(milliseconds: _timeout),
      headers: {
        'Accept':        'application/json',
        'X-Merchant-Id': '${AppConfig.merchantId}',
        // Accept-Language 由 _I18nInterceptor 动态注入
      },
    ));

    _dio.interceptors.addAll([
      _I18nInterceptor(),
      _AuthInterceptor(),
      _ToastInterceptor(),
      _LogInterceptor(),
    ]);

    _initialized = true;
  }

  // ── GET ────────────────────────────────────────────────────────────
  static Future<T> get<T>(String path, {
    Map<String, dynamic>? params,
    T Function(dynamic)? fromJson,
  }) => _call(() => _dio.get(path, queryParameters: params), fromJson);

  // ── POST ───────────────────────────────────────────────────────────
  static Future<T> post<T>(String path, {
    dynamic data,
    T Function(dynamic)? fromJson,
  }) => _call(
    () => _dio.post(path, data: _encodeBody(data)),
    fromJson,
  );

  // ── PUT ────────────────────────────────────────────────────────────
  static Future<T> put<T>(String path, {
    dynamic data,
    T Function(dynamic)? fromJson,
  }) => _call(
    () => _dio.put(path, data: _encodeBody(data)),
    fromJson,
  );

  // ── PATCH ──────────────────────────────────────────────────────────
  static Future<T> patch<T>(String path, {
    dynamic data,
    T Function(dynamic)? fromJson,
  }) => _call(
    () => _dio.patch(path, data: _encodeBody(data)),
    fromJson,
  );

  // ── POST JSON ──────────────────────────────────────────────────
  /// 发送 JSON 请求体（对应后端 @RequestBody）
  static Future<T> postJson<T>(String path, {
    dynamic data,
    T Function(dynamic)? fromJson,
  }) => _call(
    () => _dio.post(path,
      data: data,
      options: Options(contentType: 'application/json'),
    ),
    fromJson,
  );

  // ── PUT JSON ───────────────────────────────────────────────────
  /// 发送 JSON 请求体（对应后端 @RequestBody）
  static Future<T> putJson<T>(String path, {
    dynamic data,
    T Function(dynamic)? fromJson,
  }) => _call(
    () => _dio.put(path,
      data: data,
      options: Options(contentType: 'application/json'),
    ),
    fromJson,
  );

  // ── DELETE ─────────────────────────────────────────────────────────
  static Future<T> delete<T>(String path, {T Function(dynamic)? fromJson}) =>
      _call(() => _dio.delete(path), fromJson);

  // ── 私有：统一调用入口 ──────────────────────────────────────────────
  static Future<T> _call<T>(
    Future<Response> Function() request,
    T Function(dynamic)? fromJson,
  ) async {
    try {
      final resp = await request();
      return _parse<T>(resp.data, fromJson);
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  /// 表单提交：Map 直接透传，Dio 自动 URL 编码；FormData/String/null 原样透传
  static dynamic _encodeBody(dynamic data) => data;

  /// 解析后端统一响应体 { code, message, data }
  static T _parse<T>(dynamic raw, T Function(dynamic)? fromJson) {
    final body = raw is Map<String, dynamic>
        ? raw
        : <String, dynamic>{'data': raw};

    final code = body['code'];
    if (code != null && code != 0 && code != 200) {
      final msg = body['message'] as String?
          ?? body['msg'] as String?
          ?? 'Server error';
      throw ApiException(msg, code);
    }
    final data = body['data'] ?? body;
    return fromJson != null ? fromJson(data) : data as T;
  }

  /// 将 DioException 统一转换为 ApiException（只暴露一种异常类型给业务层）
  static ApiException _toApiException(DioException e) {
    final respData = e.response?.data;
    if (respData is Map) {
      final msg  = respData['message'] as String?
                ?? respData['msg'] as String?;
      final code = respData['code'];
      if (msg != null && msg.isNotEmpty) return ApiException(msg, code);
    }
    final fallback = switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout      ||
      DioExceptionType.receiveTimeout   => 'Request timeout',
      DioExceptionType.connectionError  => 'Network unavailable',
      _                                 => e.message ?? 'Request failed',
    };
    return ApiException(fallback);
  }
}

// ── 国际化拦截器 ─────────────────────────────────────────────────────────────
class _I18nInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions opts, RequestInterceptorHandler handler) {
    opts.headers['Accept-Language'] = _currentLang;
    handler.next(opts);
  }
}

// ── 认证拦截器 ────────────────────────────────────────────────────────────────
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
      // 触发"已登出"模态弹窗，由 AuthGuardService 统一处理 UI 与跳转
      Get.find<UserService>().onSessionExpired();
    }
    handler.next(err);
  }
}

// ── 网络错误 Toast 拦截器 ──────────────────────────────────────────────────────
/// 在 Dio 层拦截网络级错误（超时、断网），自动弹出本地化 Toast，
/// 业务层无需每处都处理网络异常，只需关注业务逻辑错误。
class _ToastInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // 仅处理网络层错误；业务错误（有 response body）交由业务层处理
    if (err.response == null) {
      final msg = _networkMessage(err.type);
      if (msg != null) {
        // 通过 WidgetsBinding.instance.addPostFrameCallback 确保在帧渲染后弹出，
        // 避免在 dispose 过程中调用 Overlay
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ToastUtil.error(msg);
        });
      }
    }
    handler.next(err);
  }

  String? _networkMessage(DioExceptionType type) {
    // 安全获取 l10n，若 context 尚未就绪则降级为英文文案
    try {
      final l = gL10n;
      return switch (type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.sendTimeout      ||
        DioExceptionType.receiveTimeout   => l.networkTimeout,
        DioExceptionType.connectionError  => l.networkUnavailable,
        _                                 => null,
      };
    } catch (_) {
      return switch (type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.sendTimeout      ||
        DioExceptionType.receiveTimeout   => 'Request timed out. Please check your connection.',
        DioExceptionType.connectionError  => 'Network unavailable. Please check your connection.',
        _                                 => null,
      };
    }
  }
}

// ── 日志拦截器（含请求体，方便排查编码问题）──────────────────────────────────
class _LogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions opts, RequestInterceptorHandler handler) {
    LogUtil.d('[HTTP] ▶ ${opts.method} ${opts.uri}');
    if (opts.data != null) LogUtil.d('[HTTP] body: ${opts.data}');
    handler.next(opts);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    LogUtil.d('[HTTP] ◀ ${response.statusCode} ${response.requestOptions.path}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    LogUtil.e('[HTTP] ✗ ${err.type.name} ${err.requestOptions.path} | '
        'status=${err.response?.statusCode} | '
        'body=${err.response?.data}');
    handler.next(err);
  }
}

/// 统一业务/网络异常（业务层只需 catch ApiException）
class ApiException implements Exception {
  final String  message;
  final dynamic code;
  const ApiException(this.message, [this.code]);
  @override String toString() => message;
}
