import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'log_util.dart';

/// 音效 & 通知工具
///
/// - 前台：[audioplayers] 直接播放 MP3 提示音
/// - 后台 / 息屏：[flutter_local_notifications] 发出系统通知（带提示音），
///   用户点击通知可唤起 App。
class AudioUtil with WidgetsBindingObserver {
  AudioUtil._();

  static final AudioPlayer _player = AudioPlayer();
  static final FlutterLocalNotificationsPlugin _fln =
      FlutterLocalNotificationsPlugin();

  static bool _initialized   = false;
  static bool _notifyEnabled = false;
  static bool _inForeground  = true;   // 前台时不发系统通知（避免双重声音）

  /// 在 main() 启动后立即调用一次，完成通知插件初始化。
  ///
  /// 若原生端尚未编译（首次 pod install 前）会捕获异常并降级运行，
  /// 不会导致 App 崩溃；通知功能在完整构建后自动生效。
  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // 监听前后台切换，动态更新 _inForeground
    WidgetsBinding.instance.addObserver(_AudioLifecycleObserver());

    try {
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const initSettings =
          InitializationSettings(android: androidSettings, iOS: iosSettings);

      await _fln.initialize(initSettings,
          onDidReceiveNotificationResponse: (_) {});

      // Android 13+ 主动请求通知权限
      final androidPlugin = _fln.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.requestNotificationsPermission();

      _notifyEnabled = true;
      LogUtil.i('[AudioUtil] 本地通知插件已初始化');
    } catch (e) {
      // MissingPluginException：原生插件尚未注册（需 pod install + 完整重建）
      _notifyEnabled = false;
      LogUtil.w('[AudioUtil] 本地通知不可用，降级为仅音频模式: $e');
    }
  }

  /// 播放提示音（资源路径，相对于 assets 目录）
  static Future<void> playAsset(String assetPath) async {
    try {
      await _player.stop();
      await _player.play(AssetSource(assetPath));
    } catch (e) {
      LogUtil.e('[AudioUtil] 播放失败: $e');
    }
  }

  /// 播放新订单提示音
  static Future<void> playNewOrder() =>
      playAsset('mp3/prompt_tone.mp3');

  /// 发送新订单本地通知（App 在后台 / 息屏时调用；前台时跳过以避免双重声音）
  ///
  /// [title] 通知标题，[body] 通知正文。
  /// Android 会同时播放默认提示音 + 震动。
  static Future<void> notifyNewOrder({
    String title  = '新订单',
    String body   = '您有一笔新的预约订单，请及时查看！',
  }) async {
    // 前台时 in-app 音频已播放，跳过系统通知避免双重声音
    if (_inForeground) return;
    if (!_notifyEnabled) return;
    try {
      const androidDetails = AndroidNotificationDetails(
        'new_order',       // channelId
        '新订单提醒',       // channelName
        channelDescription: '有新的预约订单时发送提醒',
        importance:   Importance.max,
        priority:     Priority.high,
        playSound:    true,
        enableVibration: true,
        ticker:       '新订单',
        styleInformation: BigTextStyleInformation(''),
      );
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      const details =
          NotificationDetails(android: androidDetails, iOS: iosDetails);
      await _fln.show(0, title, body, details);
    } catch (e) {
      LogUtil.e('[AudioUtil] 通知发送失败: $e');
    }
  }

  /// 释放资源（应用退出时调用）
  static Future<void> dispose() async {
    await _player.dispose();
  }
}

/// 内部生命周期观察器，追踪前后台状态
class _AudioLifecycleObserver with WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    AudioUtil._inForeground = state == AppLifecycleState.resumed;
  }
}
