import 'dart:async';
import 'dart:convert';

import 'package:get/get.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../config/app_config.dart';
import 'storage_service.dart';

/// WebSocket 连接状态
enum WsState { disconnected, connecting, connected }

/// 技师端 WebSocket 实时推送服务
///
/// 功能：
/// - 登录后自动连接 `/ws/tech?token=<jwt>`
/// - 后端每 5 秒推送 `HOME_DATA`（stats + schedule + pendingCount）
/// - 后端在新订单时立即推送 `NEW_ORDER`，App 播放语音提示
/// - 断线后指数退避自动重连（1→2→4→8→16→30s，最长 30s）
/// - 客户端每 20 秒发送 PING 保活
///
/// 消费方通过订阅 [homeDataStream] / [newOrderStream] 获取数据。
class TechWsService extends GetxService {
  // ── 公开状态 ──────────────────────────────────────────────────────────────
  final wsState = WsState.disconnected.obs;

  /// HOME_DATA 数据流（stats + schedule + pendingCount）
  final _homeDataCtrl   = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get homeDataStream => _homeDataCtrl.stream;

  /// 缓存最后一次 HOME_DATA，供订阅方主动查询初始值（解决 broadcast 不缓存问题）
  Map<String, dynamic>? lastHomeData;

  /// NEW_ORDER 数据流（供 GlobalNotificationService 订阅，触发横幅+弹窗+音频）
  final _newOrderCtrl   = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get newOrderStream => _newOrderCtrl.stream;

  // ── 内部状态 ──────────────────────────────────────────────────────────────
  WebSocketChannel?  _channel;
  StreamSubscription? _sub;
  Timer?             _pingTimer;
  Timer?             _reconnectTimer;
  bool               _manualClose = false;
  int                _retryCount  = 0;

  static const _maxRetryDelay = 30;   // 最大重连间隔（秒）
  static const _pingInterval  = 20;   // 心跳间隔（秒）

  // ── 生命周期 ──────────────────────────────────────────────────────────────

  Future<TechWsService> init() async {
    // 若 token 已存在（App 重启场景），立即建立 WS 连接
    final token = Get.find<StorageService>().token;
    if (token != null && token.isNotEmpty) {
      connect();
    }
    return this;
  }

  @override
  void onClose() {
    disconnect();
    _homeDataCtrl.close();
    _newOrderCtrl.close();
    super.onClose();
  }

  // ── 公开方法 ──────────────────────────────────────────────────────────────

  /// 登录成功后调用，建立 WebSocket 连接。
  void connect() {
    _manualClose = false;
    _retryCount  = 0;
    _doConnect();
  }

  /// 登出时调用，永久断开连接。
  void disconnect() {
    _manualClose = true;
    _cancelTimers();
    _sub?.cancel();
    _sub = null;
    _channel?.sink.close();
    _channel = null;
    wsState.value = WsState.disconnected;
  }

  // ── 连接逻辑 ──────────────────────────────────────────────────────────────

  void _doConnect() {
    if (wsState.value == WsState.connecting || _manualClose) return;
    // 若已连接，不重复建立（避免双 session）
    if (wsState.value == WsState.connected) return;

    final token = Get.find<StorageService>().token;
    if (token == null || token.isEmpty) return;

    wsState.value = WsState.connecting;

    // 关闭旧连接（重连场景），防止资源泄漏
    _sub?.cancel();
    _sub = null;
    try { _channel?.sink.close(); } catch (_) {}
    _channel = null;

    final wsUrl = AppConfig.apiBaseUrl
        .replaceFirst('http://', 'ws://')
        .replaceFirst('https://', 'wss://');

    try {
      _channel = WebSocketChannel.connect(
        Uri.parse('$wsUrl/ws/tech?token=$token'),
      );

      _sub = _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
      );

      wsState.value = WsState.connected;
      _retryCount   = 0;
      _startPingTimer();
    } catch (e) {
      wsState.value = WsState.disconnected;
      _scheduleReconnect();
    }
  }

  // ── 消息处理 ──────────────────────────────────────────────────────────────

  void _onMessage(dynamic raw) {
    try {
      final msg  = jsonDecode(raw as String) as Map<String, dynamic>;
      final type = msg['type'] as String?;
      final data = msg['data'];

      switch (type) {
        case 'HOME_DATA':
          if (data is Map<String, dynamic>) {
            lastHomeData = data;
            _homeDataCtrl.add(data);
          }

        case 'NEW_ORDER':
          if (data is Map<String, dynamic>) {
            _newOrderCtrl.add(data);
            // GlobalNotificationService 订阅此流并负责音频+横幅+弹窗
          }

        case 'PONG':
          // 心跳应答，无需处理
          break;

        default:
          break;
      }
    } catch (_) {
      // 非法 JSON 忽略
    }
  }

  void _onError(Object error) {
    wsState.value = WsState.disconnected;
    _scheduleReconnect();
  }

  void _onDone() {
    if (_manualClose) return;
    wsState.value = WsState.disconnected;
    _scheduleReconnect();
  }

  // ── 重连 ─────────────────────────────────────────────────────────────────

  void _scheduleReconnect() {
    if (_manualClose) return;
    _cancelTimers();

    final delay = _retryDelay();
    _retryCount++;
    wsState.value = WsState.disconnected;

    _reconnectTimer = Timer(Duration(seconds: delay), () {
      if (!_manualClose) _doConnect();
    });
  }

  int _retryDelay() {
    // 指数退避：1, 2, 4, 8, 16, 30, 30...
    final d = 1 << _retryCount;   // 2^retryCount
    return d.clamp(1, _maxRetryDelay);
  }

  // ── 心跳 ─────────────────────────────────────────────────────────────────

  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(
      const Duration(seconds: _pingInterval),
      (_) {
        try {
          _channel?.sink.add('PING');
        } catch (_) {}
      },
    );
  }

  void _cancelTimers() {
    _pingTimer?.cancel();
    _pingTimer = null;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

}
