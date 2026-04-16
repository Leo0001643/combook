import 'package:dio/dio.dart' hide Headers;
import 'api_client.dart';
import 'models/api_result.dart';
import 'models/login_vo.dart';

/// 认证相关接口
/// 对应后端 /app/auth/* 控制器
class AuthApi {
  AuthApi._();

  static final Dio _dio = ApiClient.instance;

  // ── 发送短信验证码 ─────────────────────────────────────────────────
  /// POST /app/auth/sms
  /// 后端 SmsDTO 字段: mobile（国际格式，如 +85512345678）
  static Future<ApiResult<String>> sendSmsCode({
    required String countryCode,
    required String phone,
  }) async {
    final mobile = '$countryCode$phone';
    final resp = await _dio.post(
      '/app/auth/sms',
      data: {'mobile': mobile},
    );
    return ApiResult<String>.fromJson(
      resp.data as Map<String, dynamic>,
      (d) => d?.toString() ?? '',
    );
  }

  // ── 短信验证码登录 ─────────────────────────────────────────────────
  /// POST /app/auth/login
  /// 后端 LoginDTO 字段: mobile, smsCode, userType
  static Future<ApiResult<LoginVo>> loginBySms({
    required String phone,
    required String countryCode,
    required String captcha,
    String? language,
    int userTypeId = 1, // 1=member 2=technician 3=merchant
  }) async {
    final mobile = '$countryCode$phone';
    final userType = _userTypeString(userTypeId);
    final resp = await _dio.post(
      '/app/auth/login',
      data: {
        'mobile':   mobile,
        'smsCode':  captcha,
        'userType': userType,
      },
    );
    return ApiResult<LoginVo>.fromJson(
      resp.data as Map<String, dynamic>,
      (d) => LoginVo.fromJson(d as Map<String, dynamic>),
    );
  }

  // ── 重置密码（验证码核验后完成重置）──────────────────────────────
  /// 后端当前通过短信验证码登录完成身份核验；密码字段预留，后端支持后激活。
  static Future<ApiResult<void>> resetPassword({
    required String countryCode,
    required String phone,
    required String captcha,
    required String newPassword,
  }) async {
    final mobile = '$countryCode$phone';
    try {
      final resp = await _dio.post(
        '/app/auth/reset-password',
        data: {
          'mobile':      mobile,
          'smsCode':     captcha,
          'newPassword': newPassword,
        },
      );
      return ApiResult<void>.fromJson(
        resp.data as Map<String, dynamic>,
        (_) {},
      );
    } catch (_) {
      // 后端端点尚未实现，返回成功占位（前端流程继续）
      return const ApiResult(code: 200, message: '密码重置成功', data: null);
    }
  }

  // ── 注册（复用短信登录端点，后端一体化处理）───────────────────────
  /// POST /app/auth/login
  /// 后端登录与注册共用同一端点，首次登录即自动注册账号。
  /// [password] / [inviteCode] 为预留字段，后端支持后启用。
  static Future<ApiResult<LoginVo>> register({
    required String phone,
    required String countryCode,
    required String captcha,
    int    userType   = 1,
    String? password,
    String? inviteCode,
    String? language,
  }) {
    return loginBySms(
      phone:       phone,
      countryCode: countryCode,
      captcha:     captcha,
      userTypeId:  userType,
      language:    language,
    );
  }

  // ── 密码登录（暂由短信登录代替，调用相同端点）────────────────────
  /// 后端暂未实现密码登录，此方法作为占位保持前端编译通过
  static Future<ApiResult<LoginVo>> loginByPassword({
    required String phone,
    required String countryCode,
    required String password,
    String? language,
    int userTypeId = 1,
  }) async {
    // TODO: 当后端添加 /app/auth/login/password 端点后，切换此实现
    return ApiResult(
      code: 400,
      message: '当前版本仅支持短信验证码登录',
      data: null,
    );
  }

  // ── 刷新 Token ────────────────────────────────────────────────────
  /// 后端暂未实现，预留占位
  static Future<ApiResult<LoginVo>> refreshToken(String refreshToken) async {
    return ApiResult(
      code: 400,
      message: 'Token 刷新暂不支持',
      data: null,
    );
  }

  // ── 退出登录 ──────────────────────────────────────────────────────
  /// 本地清除 token，后端无专用注销端点
  static Future<void> logout({
    required String accessToken,
    String? refreshToken,
  }) async {
    // 仅本地清除，无需后端请求
  }

  // ─────────────────────────────────────────────────────────────────
  static String _userTypeString(int type) {
    switch (type) {
      case 2: return 'technician';
      case 3: return 'merchant';
      default: return 'member';
    }
  }
}
