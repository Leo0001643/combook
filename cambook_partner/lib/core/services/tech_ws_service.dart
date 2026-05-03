import 'dart:async';
import 'dart:convert';

import 'package:get/get.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../config/app_config.dart';
import '../utils/log_util.dart';
import 'storage_service.dart';

/// WebSocket 连接状态
enum WsState { disconnected, connecting, connected }

/// 技师端 WebSocket 实时推送服务
///
/// 高可用机制：
/// - 登录后自动连接 `/ws/tech?token=<jwt>`
/// - 后端每 5 秒推送 `HOME_DATA`（stats + schedule + pendingCount）
/// - 后端在新订单时立即推送 `NEW_ORDER`，App 播放语音提示
/// - 断线后指数退避自动重连（1→2→4→8→16→30s，最长 30s）
/// - 客户端每 20 秒发送 JSON PING 保活
/// - **PONG 超时检测**：若 PING 发出后一个周期未收到 PONG，判定死连接并强制重连
/// - **消息心跳监控**：若超过 [_msgTimeoutSecs] 秒无任何消息，触发 HTTP 兜底刷新信号
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
  WebSocketChannel?   _channel;
  StreamSubscription? _sub;
  Timer?              _pingTimer;
  Timer?              _reconnectTimer;
  bool                _manualClose  = false;
  int                 _retryCount   = 0;

  /// 连续未收到任何消息的 PING 次数。
  ///
  /// 设计理念：服务端每 5s 推送一次 HOME_DATA，任意消息到达均视为"连接存活"。
  /// 不依赖服务端响应特定 PONG 帧，天然兼容"只推不应答"的服务端实现。
  ///
  /// 当连续 [_maxMissedPings] 次 PING 发出后仍无任何消息到达 → 判定为死连接 → 强制重连。
  int                 _missedPings    = 0;
  static const        _maxMissedPings = 2; // 连续 2 次无消息 = _pingInterval*2 秒后判定死连接

  /// 最近一次收到任意 WS 消息的时间（供外部健康检测使用）
  DateTime?           _lastMsgTime;
  DateTime? get lastMsgTime => _lastMsgTime;

  static const _maxRetryDelay  = 30;  // 最大重连间隔（秒）
  static const _pingInterval   = 5;   // 心跳间隔（秒）

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
    _missedPings  = 0;
    wsState.value = WsState.disconnected;
  }

  // ── 连接逻辑 ──────────────────────────────────────────────────────────────

  void _doConnect() {
    if (wsState.value == WsState.connecting || _manualClose) return;
    if (wsState.value == WsState.connected) return;

    final token = Get.find<StorageService>().token;
    if (token == null || token.isEmpty) return;

    wsState.value = WsState.connecting;

    // 关闭旧连接（重连场景），防止资源泄漏
    _sub?.cancel();
    _sub = null;
    try { _channel?.sink.close(); } catch (_) {}
    _channel = null;
    _missedPings = 0;

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
        onDone:  _onDone,
        cancelOnError: false,
      );

      wsState.value = WsState.connected;
      _retryCount   = 0;
      _lastMsgTime  = DateTime.now();
      _startPingTimer();
      LogUtil.i('[TechWs] 已连接 → $wsUrl/ws/tech');

      // 请求服务端立即推送 HOME_DATA（减少首屏等待，避免等第一个定时推送周期）
      Future.microtask(() {
        try {
          _channel?.sink.add('SYNC');
          LogUtil.d('[TechWs] → SYNC 请求立即推送');
        } catch (_) {}
      });
    } catch (e) {
      LogUtil.e('[TechWs] 连接异常: $e');
      wsState.value = WsState.disconnected;
      _scheduleReconnect();
    }
  }

  // ── 消息处理 ──────────────────────────────────────────────────────────────

  void _onMessage(dynamic raw) {
    _lastMsgTime = DateTime.now();
    // 任意消息到达 = 连接存活证明，重置计数器
    // 不依赖服务端是否响应 PONG，HOME_DATA / NEW_ORDER 均有效
    _missedPings = 0;

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
          }

        case 'PONG':
          LogUtil.d('[TechWs] PONG ✓');

        default:
          LogUtil.d('[TechWs] unknown type: $type');
      }
    } catch (_) {
      // 非法 JSON（如服务端发送原始字符串）忽略，_missedPings 已在上方重置
    }
  }

  void _onError(Object error) {
    LogUtil.w('[TechWs] onError: $error → 触发重连');
    wsState.value = WsState.disconnected;
    _missedPings = 0;
    _scheduleReconnect();
  }

  void _onDone() {
    if (_manualClose) return;
    LogUtil.w('[TechWs] onDone（非主动断开）→ 触发重连');
    wsState.value = WsState.disconnected;
    _missedPings = 0;
    _scheduleReconnect();
  }

  // ── 重连 ─────────────────────────────────────────────────────────────────

  void _scheduleReconnect() {
    if (_manualClose) return;
    _cancelTimers();

    final delay = _retryDelay();
    _retryCount++;
    wsState.value = WsState.disconnected;

    LogUtil.i('[TechWs] 将在 ${delay}s 后重连（第 $_retryCount 次）');
    _reconnectTimer = Timer(Duration(seconds: delay), () {
      if (!_manualClose) _doConnect();
    });
  }

  int _retryDelay() {
    final d = 1 << _retryCount;   // 指数退避：1, 2, 4, 8, 16, 30, 30...
    return d.clamp(1, _maxRetryDelay);
  }

  // ── 心跳 & 连接存活检测 ───────────────────────────────────────────────────

  void _startPingTimer() {
    _pingTimer?.cancel();
    _missedPings = 0;

    _pingTimer = Timer.periodic(
      const Duration(seconds: _pingInterval),
      (_) {
        if (wsState.value != WsState.connected || _manualClose) return;

        if (_missedPings >= _maxMissedPings) {
          // 连续 _maxMissedPings 个 PING 周期内未收到任何消息 → 判定死连接
          LogUtil.w('[TechWs] 连续 $_maxMissedPings 次无消息，判定死连接 → 强制重连');
          _forceReconnect();
          return;
        }

        try {
          _channel?.sink.add('PING');
          _missedPings++;
          LogUtil.d('[TechWs] PING → (missed=$_missedPings)');
        } catch (e) {
          LogUtil.w('[TechWs] PING 发送失败: $e → 触发重连');
          _forceReconnect();
        }
      },
    );
  }

  /// 强制关闭当前连接并立即触发重连（不经过指数退避，直接进入下一次连接）
  void _forceReconnect() {
    _sub?.cancel();
    _sub = null;
    try { _channel?.sink.close(); } catch (_) {}
    _channel = null;
    _missedPings = 0;
    wsState.value = WsState.disconnected;
    _cancelTimers();
    if (!_manualClose) _doConnect();
  }

  void _cancelTimers() {
    _pingTimer?.cancel();
    _pingTimer = null;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }
}
