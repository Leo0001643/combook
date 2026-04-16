import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:device_info_plus/device_info_plus.dart';

import 'core/auth/auth_controller.dart';
import 'core/routes/app_pages.dart';
import 'core/services/device_service.dart';
import 'core/services/geocoding_service.dart';
import 'core/services/storage_service.dart';
import 'core/theme/app_theme.dart';
import 'l10n/app_localizations.dart';
import 'firebase_options.dart';

/// CamBook App 入口
/// 状态管理 & 路由：GetX（GetMaterialApp + GetPage）
/// 多语言：中文 / 英文 / 越南文 / 柬埔寨文
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor:       Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await _initFirebase();

  // ── 注册全局服务（GetX Service，生命周期跟随 App） ───────────────
  await Get.putAsync<StorageService>(() => StorageService().init());
  Get.put(DeviceService(),    permanent: true);
  Get.put(GeocodingService(), permanent: true);

  // ── 注册全局 Controller（permanent，不随路由销毁） ────────────────
  Get.put(AuthController(), permanent: true);

  runApp(const CamBookApp());
}

/// Firebase 初始化（Web 直接初始化；iOS Simulator 跳过，避免 Rosetta 崩溃）
Future<void> _initFirebase() async {
  if (!kIsWeb && Platform.isIOS) {
    try {
      final info = await DeviceInfoPlugin().iosInfo;
      if (!info.isPhysicalDevice) {
        debugPrint('⚠️  iOS Simulator: Firebase init skipped.');
        return;
      }
    } catch (_) {}
  }
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

/// 应用根组件
class CamBookApp extends StatelessWidget {
  const CamBookApp({super.key});

  @override
  Widget build(BuildContext context) {
    // GetMaterialApp 不放在 Obx 里，语言切换通过 Get.updateLocale() 驱动。
    // 若放在 Obx 里，GetMaterialApp 内部的 GetMaterialController 不会同步
    // 更新 locale，导致 Localizations.of(context) 依然返回旧实例。
    return GetMaterialApp(
      title:                    'CamBook',
      debugShowCheckedModeBanner: false,

      // ── GetX 路由 ──────────────────────────────────────────────
      initialRoute:  AppPages.initial,
      getPages:      AppPages.routes,
      unknownRoute:  GetPage(name: '/not-found', page: () => const SizedBox()),

      // ── 主题 ───────────────────────────────────────────────────
      theme:      AppTheme.lightTheme,
      darkTheme:  AppTheme.darkTheme,
      themeMode:  ThemeMode.light,

      // ── 多语言 ─────────────────────────────────────────────────
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('zh', 'CN'),
        Locale('en'),
        Locale('vi'),
        Locale('km'),
      ],
      // 初始 locale 取 AuthController 中的值
      locale: AuthController.to.locale,

      defaultTransition: Transition.cupertino,
    );
  }
}
