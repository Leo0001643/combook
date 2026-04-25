import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'core/network/http_util.dart';
import 'core/utils/audio_util.dart';
import 'core/routes/app_pages.dart';
import 'core/routes/app_routes.dart';
import 'core/services/auth_guard_service.dart';
import 'core/services/global_notification_service.dart';
import 'core/services/message_service.dart';
import 'core/services/order_service.dart';
import 'core/services/storage_service.dart';
import 'core/services/tech_ws_service.dart';
import 'core/services/user_service.dart';
import 'core/theme/app_theme.dart';
import 'l10n/gen/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpUtil.init();
  await AudioUtil.init();   // 初始化本地通知插件（必须在 runApp 前调用）
  await _initServices();
  runApp(const App());
}

Future<void> _initServices() async {
  await Get.putAsync<StorageService>(() => StorageService().init());
  await Get.putAsync<UserService>(() => UserService().init());
  await Get.putAsync<OrderService>(() => OrderService().init());
  await Get.putAsync<MessageService>(() => MessageService().init());
  await Get.putAsync<TechWsService>(() => TechWsService().init());
  // GlobalNotificationService 倒数第二初始化，确保其他服务都就绪
  await Get.putAsync<GlobalNotificationService>(() => GlobalNotificationService().init());
  // AuthGuardService 最后初始化：监听 UserService.isSessionExpired 弹出登出弹窗
  await Get.putAsync<AuthGuardService>(() => AuthGuardService().init());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = Get.find<StorageService>();
    final initial = Get.find<UserService>().isLoggedIn ? AppRoutes.main : AppRoutes.login;

    return GetMaterialApp(
      title: 'CamBook Partner',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,

      // ── 国际化 ─────────────────────────────────────────────────────
      locale: Locale(storage.locale),
      fallbackLocale: const Locale('zh'),
      supportedLocales: const [
        Locale('zh'), Locale('en'), Locale('vi'),
        Locale('km'), Locale('ko'), Locale('ja'),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // ── 翻译（GetX 内置简单 key-value，用于 .tr 调用）──────────────
      translations: _AppTranslations(),

      // ── 路由 ──────────────────────────────────────────────────────
      initialRoute: initial,
      getPages: AppPages.pages,
      defaultTransition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 180),
    );
  }
}

/// GetX 内置翻译 —— 提供少量全局通用词（confirm / cancel 等）
/// 页面级文案优先使用 ARB（AppLocalizations），保持分层清晰
class _AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'zh': {'confirm': '确认', 'cancel': '取消'},
    'en': {'confirm': 'Confirm', 'cancel': 'Cancel'},
    'vi': {'confirm': 'Xác nhận', 'cancel': 'Hủy'},
    'km': {'confirm': 'បញ្ជាក់', 'cancel': 'បោះបង់'},
    'ko': {'confirm': '확인', 'cancel': '취소'},
    'ja': {'confirm': '確認', 'cancel': 'キャンセル'},
  };
}
