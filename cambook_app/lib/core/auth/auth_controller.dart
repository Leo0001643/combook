import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/storage_service.dart';
import '../network/auth_api.dart';
import '../network/models/login_vo.dart';
import '../routes/app_routes.dart';

/// 全局认证控制器（单例，permanent）
/// 管理登录状态、Token、用户信息，驱动路由跳转
/// 不属于任何单一页面，放在 core/auth/ 而非 features/ 的 controllers/ 子目录
class AuthController extends GetxController {
  static AuthController get to => Get.find();

  // ── 响应式状态 ────────────────────────────────────────────────────
  final isLoading   = true.obs;
  final isLoggedIn  = false.obs;
  final userId      = RxnInt();
  final userType    = RxnInt();    // 1=会员 2=技师 3=商户
  final nickname    = RxnString();
  final avatar      = RxnString();
  final accessToken = RxnString();
  final refreshToken= RxnString();

  /// App 当前语言（登录前也可切换）
  /// 初始值由 _detectSystemLocale() 决定，之后由持久化覆盖
  final appLocale = 'zh-CN'.obs;

  // ── 派生属性 ──────────────────────────────────────────────────────
  Locale get locale {
    switch (appLocale.value) {
      case 'vi': return const Locale('vi');
      case 'km': return const Locale('km');
      case 'en': return const Locale('en');
      default:   return const Locale('zh', 'CN');
    }
  }

  String get languageCode => appLocale.value;

  // ── 生命周期 ──────────────────────────────────────────────────────
  @override
  void onInit() {
    super.onInit();
    _detectSystemLocale(); // 先设系统默认，restoreSession 内会被持久化值覆盖
    _restoreSession();
  }

  /// 根据设备系统语言设置初始 locale（仅在无持久化偏好时生效）
  void _detectSystemLocale() {
    try {
      // ui.PlatformDispatcher 提供原生系统语言列表，取第一个
      final systemLocale = ui.PlatformDispatcher.instance.locale;
      final code = _mapToSupportedLocale(systemLocale.languageCode);
      appLocale.value = code;
      Get.updateLocale(locale);
    } catch (_) {
      // fallback: zh-CN
    }
  }

  /// 将任意系统语言 code 映射到应用支持的四种语言之一
  static String _mapToSupportedLocale(String langCode) {
    switch (langCode) {
      case 'zh': return 'zh-CN';
      case 'vi': return 'vi';
      case 'km': return 'km';
      default:   return 'en';   // 其余语言均 fallback 到英文
    }
  }

  // ── 登录态恢复（从安全存储读取 Token） ──────────────────────────
  Future<void> _restoreSession() async {
    isLoading.value = true;
    try {
      final storage = StorageService.to;
      final token = await storage.readAccessToken();
      if (token != null && token.isNotEmpty) {
        final uid      = await storage.readUserId();
        final uType    = await storage.readUserType();
        final nick     = await storage.readNickname();
        final ava      = await storage.readAvatar();
        final lang     = await storage.readLanguage();

        accessToken.value  = token;
        refreshToken.value = await storage.readRefreshToken();
        userId.value       = uid;
        userType.value     = uType;
        nickname.value     = nick;
        avatar.value       = ava;
        if (lang != null) {
          appLocale.value = lang;
          Get.updateLocale(locale);
        }

        isLoggedIn.value = true;
      }
    } catch (e) {
      debugPrint('⚠️ 恢复登录态失败: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ── 登录成功（由各 Logic 调用） ───────────────────────────────────
  Future<void> loginSuccess(LoginVo vo) async {
    accessToken.value  = vo.accessToken;
    refreshToken.value = vo.refreshToken;
    userId.value       = vo.userId;
    userType.value     = vo.userType;
    nickname.value     = vo.nickname;
    avatar.value       = vo.avatar;
    if (vo.language != null) appLocale.value = vo.language!;

    // 持久化
    final storage = StorageService.to;
    await storage.saveTokens(
      accessToken:  vo.accessToken,
      refreshToken: vo.refreshToken,
    );
    await storage.saveUserInfo(
      userId:   vo.userId,
      userType: vo.userType,
      nickname: vo.nickname,
      avatar:   vo.avatar,
      language: vo.language,
    );

    isLoggedIn.value = true;
    _navigateToHome();
  }

  // ── 退出登录 ──────────────────────────────────────────────────────
  Future<void> logout() async {
    // 通知服务端将 Token 加入黑名单（best-effort，即使失败也清除本地状态）
    final at = accessToken.value;
    final rt = refreshToken.value;
    if (at != null && at.isNotEmpty) {
      try {
        await AuthApi.logout(accessToken: at, refreshToken: rt);
      } catch (e) {
        debugPrint('⚠️ 服务端 logout 失败（忽略）: $e');
      }
    }
    await StorageService.to.clearAll();
    isLoggedIn.value   = false;
    userId.value       = null;
    userType.value     = null;
    nickname.value     = null;
    avatar.value       = null;
    accessToken.value  = null;
    refreshToken.value = null;
    Get.offAllNamed(AppRoutes.login);
  }

  // ── 切换语言 ──────────────────────────────────────────────────────
  void switchLanguage(String langCode) {
    appLocale.value = langCode;
    // Get.updateLocale() 会更新 GetMaterialController 内部的 locale 并强制
    // 刷新整个 widget 树，使 Localizations.of(context) 返回新的 AppLocalizations
    Get.updateLocale(locale);
    // 持久化语言偏好（best-effort）
    StorageService.to.saveLanguage(langCode);
  }

  // ── 内部导航 ──────────────────────────────────────────────────────
  void _navigateToHome() {
    final route = _homeRoute();
    Get.offAllNamed(route);
  }

  String _homeRoute() {
    switch (userType.value) {
      case 2:  return AppRoutes.techHome;
      case 3:  return AppRoutes.merchantHome;
      default: return AppRoutes.memberHome;
    }
  }
}
