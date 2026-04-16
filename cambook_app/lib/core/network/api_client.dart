import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide Response;
import '../auth/auth_controller.dart';
import '../routes/app_routes.dart';
import '../services/device_service.dart';

/// Dio 网络客户端单例
/// 负责：基础 URL、请求/响应拦截、Token 注入、错误统一处理
class ApiClient {
  ApiClient._();

  /// 开发环境基础 URL
  /// iOS 模拟器：127.0.0.1（与 Mac 共享网络栈）
  /// Android 模拟器：10.0.2.2
  /// 真机调试：填写局域网 IP（如 192.168.x.x）
  static const _baseUrl = 'http://127.0.0.1:8080'; // iOS Simulator
  // static const _baseUrl = 'http://10.0.2.2:8080';   // Android Emulator
  // static const _baseUrl = 'http://192.168.x.x:8080'; // 真机调试

  static Dio? _dio;

  static Dio get instance {
    _dio ??= _create();
    return _dio!;
  }

  static Dio _create() {
    final dio = Dio(BaseOptions(
      baseUrl:        _baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      responseType:   ResponseType.json,
    ));

    dio.interceptors.addAll([
      _FormEncodingInterceptor(),
      _AuthInterceptor(),
      if (kDebugMode) LogInterceptor(
        requestHeader:  false,
        requestBody:    true,
        responseHeader: false,
        responseBody:   true,
        error:          true,
      ),
    ]);

    return dio;
  }
}

/// 表单编码拦截器
/// 对所有 POST / PUT / PATCH 请求，将 Map<String, dynamic> 显式转换为
/// application/x-www-form-urlencoded 格式，确保与后端 @ModelAttribute 匹配。
class _FormEncodingInterceptor extends Interceptor {
  static const _formMethods = {'POST', 'PUT', 'PATCH'};

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_formMethods.contains(options.method.toUpperCase()) &&
        options.data is Map) {
      final encoded = (options.data as Map)
          .entries
          .where((e) => e.value != null)
          .map((e) =>
              '${Uri.encodeQueryComponent(e.key.toString())}'
              '=${Uri.encodeQueryComponent(e.value.toString())}')
          .join('&');
      options.data = encoded;
      options.headers[Headers.contentTypeHeader] =
          Headers.formUrlEncodedContentType;
    }
    handler.next(options);
  }
}

/// Token 注入拦截器
/// 自动在请求头加入 Bearer Token，处理 401 并尝试 Token 刷新
class _AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // 白名单路径不注入 Token
    const whiteList = [
      '/api/auth/login',
      '/api/auth/register',
      '/api/auth/sms',
      '/api/auth/refresh',
    ];
    final isWhite = whiteList.any((p) => options.path.startsWith(p));

    if (!isWhite) {
      final token = _getToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    // 注入设备信息头（所有请求均携带）
    try {
      final ds = DeviceService.to;
      options.headers['X-Device-Id']   = ds.deviceId;
      options.headers['X-Device-Info'] = ds.deviceInfo;
      options.headers['X-App-Version'] = ds.appVersion;
    } catch (_) {
      // DeviceService 未注册（单元测试环境）时忽略
    }

    // 注入 Accept-Language 头（后端据此返回本地化内容）
    try {
      final lang = AuthController.to.appLocale.value;
      options.headers['Accept-Language'] = lang == 'zh' ? 'zh-CN' : lang;
    } catch (_) {}

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // 401：Token 过期，尝试刷新
    if (err.response?.statusCode == 401) {
      try {
        final refreshed = await _refreshToken();
        if (refreshed) {
          final retryOpts = err.requestOptions;
          retryOpts.headers['Authorization'] = 'Bearer ${_getToken()}';
          final response = await ApiClient.instance.fetch(retryOpts);
          return handler.resolve(response);
        }
      } catch (_) {}
      // 刷新失败：退出登录
      _logout();
    }
    handler.next(err);
  }

  String? _getToken() {
    try {
      return AuthController.to.accessToken.value;
    } catch (_) {
      return null;
    }
  }

  Future<bool> _refreshToken() async {
    try {
      final auth = AuthController.to;
      final rt   = auth.refreshToken.value;
      if (rt == null || rt.isEmpty) return false;

      final resp = await ApiClient.instance.post(
        '/api/auth/refresh',
        queryParameters: {'refreshToken': rt},
      );
      final data = resp.data;
      if (data['code'] == 200 && data['data'] != null) {
        auth.accessToken.value  = data['data']['accessToken'];
        auth.refreshToken.value = data['data']['refreshToken'];
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  void _logout() {
    try {
      Get.offAllNamed(AppRoutes.login);
    } catch (_) {}
  }
}
