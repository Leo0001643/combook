import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path_provider/path_provider.dart';
import '../constants/app_assets.dart';
import 'log_util.dart';

/// iOS 原生播音 MethodChannel（AppDelegate.swift 中注册）
const _iosChannel = MethodChannel('com.cambook.partner/sound');

/// 音效 & 通知工具
///
/// 播放策略（按优先级降级）：
///   L0 iOS: 原生 AVAudioPlayer + setActive(true)，穿透静音开关
///   L1: audioplayers AssetSource（Android 主路径）
///   L2: audioplayers DeviceFileSource（本地临时文件）
///   L3: SystemSound.alert（兜底）
class AudioUtil {
  AudioUtil._();

  static final FlutterLocalNotificationsPlugin _fln =
      FlutterLocalNotificationsPlugin();

  static String? _sfxTempPath;
  static bool _initialized   = false;
  static bool _notifyEnabled = false;
  static bool _inForeground  = true;

  // ── 初始化 ────────────────────────────────────────────────────────────────

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    WidgetsBinding.instance.addObserver(_LifecycleObserver());
    await Future.wait([
      _initAudio(),
      _initNotification(),
    ]);
  }

  static Future<void> _initAudio() async {
    // Android：配置 audioplayers 音频上下文
    if (Platform.isAndroid) {
      try {
        await AudioPlayer.global.setAudioContext(AudioContext(
          android: const AudioContextAndroid(
            isSpeakerphoneOn: false,
            stayAwake: false,
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.notificationEvent,
            audioFocus: AndroidAudioFocus.gainTransientMayDuck,
          ),
        ));
        LogUtil.i('[AudioUtil] Android 音频上下文配置 ✓');
      } catch (e) {
        LogUtil.w('[AudioUtil] Android 音频上下文配置失败: $e');
      }
    }
    // 提取 MP3 到临时文件（iOS 用于 L0 AVAudioPlayer，Android 用于 L2 DeviceFileSource）
    await _extractSfxToFile();
    LogUtil.i('[AudioUtil] 音频初始化完成');
  }

  static Future<void> _extractSfxToFile() async {
    try {
      const assetKey = 'assets/${AppAssets.sfxNewOrder}';
      final data  = await rootBundle.load(assetKey);
      final bytes = data.buffer.asUint8List();
      final dir   = await getTemporaryDirectory();
      final file  = File('${dir.path}/prompt_tone_alert.mp3');
      await file.writeAsBytes(bytes, flush: true);
      _sfxTempPath = file.path;
      LogUtil.i('[AudioUtil] L2 临时文件 size=${bytes.length}B → $_sfxTempPath');
    } catch (e) {
      _sfxTempPath = null;
      LogUtil.w('[AudioUtil] L2 临时文件提取失败: $e');
    }
  }

  static Future<void> _initNotification() async {
    try {
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      await _fln.initialize(
        const InitializationSettings(android: androidSettings, iOS: iosSettings),
        onDidReceiveNotificationResponse: (_) {},
      );
      final androidPlugin = _fln.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.requestNotificationsPermission();
      _notifyEnabled = true;
      LogUtil.i('[AudioUtil] 本地通知初始化 ✓');
    } catch (e) {
      _notifyEnabled = false;
      LogUtil.w('[AudioUtil] 本地通知不可用: $e');
    }
  }

  // ── 播放新订单提示音 ──────────────────────────────────────────────────────

  static Future<void> playNewOrder() async {
    LogUtil.i('[AudioUtil] ▶ playNewOrder');
    await _playSfx();
  }

  static Future<void> _playSfx() async {
    // ── L0: iOS 原生 AVAudioPlayer（最优先）──────────────────────────────
    // 把 Dart 已提取的 temp 文件路径传给 Swift，Swift 用 AVAudioPlayer 播放。
    // 这样完全绕开 Flutter Bundle 路径问题（Debug 模式 assets 不是物理文件）
    // 以及 audioplayers 用 AVPlayer 在 iOS 模拟器上的已知 Bug。
    if (Platform.isIOS) {
      if (_sfxTempPath == null) await _extractSfxToFile();
      final tempPath = _sfxTempPath;
      if (tempPath != null) {
        LogUtil.d('[AudioUtil] L0 iOS Native path=$tempPath');
        try {
          final ok = await _iosChannel.invokeMethod<dynamic>(
            'playNewOrder',
            {'path': tempPath},
          );
          if (ok == true) {
            LogUtil.i('[AudioUtil] L0 iOS Native 播放 ✓');
            return;
          }
          LogUtil.w('[AudioUtil] L0 iOS Native 返回 $ok，降级');
        } catch (e) {
          LogUtil.w('[AudioUtil] L0 iOS Native 异常: $e，降级');
        }
      } else {
        LogUtil.w('[AudioUtil] L0 temp 文件提取失败，降级');
      }
    }

    // ── L1: audioplayers AssetSource ─────────────────────────────────────
    LogUtil.d('[AudioUtil] L1 AssetSource: ${AppAssets.sfxNewOrder}');
    try {
      final p = AudioPlayer();
      await p.play(AssetSource(AppAssets.sfxNewOrder));
      LogUtil.i('[AudioUtil] L1 AssetSource 播放 ✓');
      p.onPlayerComplete.first
          .then((_) => p.dispose())
          .catchError((_) => p.dispose());
      return;
    } catch (e) {
      LogUtil.w('[AudioUtil] L1 失败: $e');
    }

    // ── L2: audioplayers DeviceFileSource ─────────────────────────────────
    if (_sfxTempPath == null) await _extractSfxToFile();
    if (_sfxTempPath != null) {
      LogUtil.d('[AudioUtil] L2 DeviceFileSource');
      try {
        final p = AudioPlayer();
        await p.play(DeviceFileSource(_sfxTempPath!));
        LogUtil.i('[AudioUtil] L2 DeviceFileSource 播放 ✓');
        p.onPlayerComplete.first
            .then((_) => p.dispose())
            .catchError((_) => p.dispose());
        return;
      } catch (e) {
        LogUtil.w('[AudioUtil] L2 失败: $e');
        _sfxTempPath = null;
      }
    }

    // ── L3: 系统提示音（兜底）────────────────────────────────────────────
    LogUtil.w('[AudioUtil] L0/L1/L2 均失败，L3 系统提示音');
    try {
      await SystemSound.play(SystemSoundType.alert);
      LogUtil.i('[AudioUtil] L3 SystemSound ✓');
    } catch (e) {
      LogUtil.e('[AudioUtil] 全部方式失败: $e');
    }
  }

  // ── 后台通知 ──────────────────────────────────────────────────────────────

  static Future<void> notifyNewOrder({
    String title = '新订单',
    String body  = '您有一笔新的预约订单，请及时查看！',
  }) async {
    if (_inForeground || !_notifyEnabled) return;
    try {
      const androidDetails = AndroidNotificationDetails(
        'new_order', '新订单提醒',
        channelDescription: '有新的预约订单时发送提醒',
        importance:       Importance.max,
        priority:         Priority.high,
        playSound:        true,
        enableVibration:  true,
        ticker:           '新订单',
        styleInformation: BigTextStyleInformation(''),
      );
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      await _fln.show(0, title, body,
          const NotificationDetails(android: androidDetails, iOS: iosDetails));
    } catch (e) {
      LogUtil.e('[AudioUtil] 通知失败: $e');
    }
  }

  static void dispose() {
    _sfxTempPath = null;
  }
}

class _LifecycleObserver with WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    AudioUtil._inForeground = state == AppLifecycleState.resumed;
  }
}
