import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:get/get.dart';

import '../config/app_config.dart';
import '../models/models.dart';
import '../utils/log_util.dart';
import 'storage_service.dart';
import 'user_service.dart';

// Protocol constants mirror backend ImCmd.java exactly; some are declared for
// documentation / future use even if not yet consumed client-side.
// ignore_for_file: unused_field

// ── IM 协议命令码（严格镜像后端 ImCmd.java，保持同步）────────────────────────
abstract class _Cmd {
  static const ping         = 1001;
  static const pong         = 1002;
  static const auth         = 1003;
  static const authResult   = 1004;
  static const kick         = 1005;
  static const error        = 1099;
  static const sendMsg      = 2001;
  static const msgNotify    = 2002;
  static const msgAck       = 2003;
  static const msgDelivered = 2004;
  static const markRead     = 2005;
  static const msgRead      = 2006;
  static const groupNotify  = 3002;
  // 4xxx 会话/离线
  static const pullOffline  = 4001;  // client → server: request offline msgs
  static const offlineMsgs  = 4002;  // server → client: batched offline msgs (pushed on auth)
  static const convList     = 4003;  // server → client: full conv list on connect
  static const convUpdate   = 4004;  // server → client: single conv update on new msg
  static const callInvite   = 5001;
  static const callAccept   = 5002;
  static const callReject   = 5003;
  static const callIce      = 5004;
  static const callSdp      = 5005;
  static const callEnd      = 5006;
  static const callBusy     = 5007;
  static const Set<int> signalingCmds = {
    callInvite, callAccept, callReject, callIce, callSdp, callEnd, callBusy,
  };
}

/// 单条消息回调（ChatLogic 注册）— 触发通知 / 音效
typedef ImMsgCallback    = void Function(ChatMessageModel msg);
/// 信令回调（VoiceCallLogic 注册）
typedef ImSignalCallback = void Function(int cmd, Map<String, dynamic> body);
/// 会话列表回调（MessageService 注册）
/// [isFullList] = true → 全量替换；false → 单条更新
typedef ImConvCallback   = void Function(List<Map<String, dynamic>> convs, bool isFullList);
/// 批量离线消息回调（MessageService 注册）— 静默回放，不触发通知/音效
typedef ImBatchCallback  = void Function(List<ChatMessageModel> msgs);

/// IM 专用 WebSocket 服务
///
/// 连接 `/ws/im`，心跳 + 指数退避重连，命令分发走静态路由表（OCP：新增命令只需
/// 在 [_buildDispatch] 中添加一条映射，无需修改任何现有分支）。
class ImWsService extends GetxService {
  static ImWsService get to => Get.find();

  final connected = false.obs;

  io.WebSocket?       _rawWs;   // dart:io socket — the source of truth for status
  StreamSubscription? _sub;
  Timer?              _heartbeat;
  Timer?              _reconnTimer;
  Timer?              _authTimer;         // cancellable AUTH frame timer
  bool                _disposed   = false;
  bool                _connecting = false; // prevents overlapping connect attempts
  // Fast reconnect: 500ms → 750ms → … → max 5s.
  // Minimises the WS-dead window so OFFLINE_MSGS + CONV_LIST arrive quickly.
  int                 _retryMs   = 500;

  ImMsgCallback?    _msgCallback;
  ImSignalCallback? _signalCallback;
  ImConvCallback?   _convCallback;
  ImBatchCallback?  _batchCallback;

  // ── 命令分发表（OCP：扩展时只需在此表新增条目）──────────────────────────────
  late final Map<int, void Function(Map<String, dynamic>)> _dispatch;

  // ── 生命周期 ──────────────────────────────────────────────────────────────

  Future<ImWsService> init() async {
    _buildDispatch();
    final token = Get.find<StorageService>().token;
    LogUtil.i('[ImWs] init() tokenPresent=${token != null && token.isNotEmpty}');
    if (token != null && token.isNotEmpty) _connect();
    return this;
  }

  @override
  void onClose() {
    _disposed = true;
    _authTimer?.cancel();
    _disconnect();
    super.onClose();
  }

  // ── 公开方法 ──────────────────────────────────────────────────────────────

  /// Establishes a WS connection if one isn't already active.
  ///
  /// Safe to call multiple times — also auto-resets the `_disposed` flag in
  /// case a previous logout marked the service "stopped" (the GetX service
  /// itself is permanent across login cycles).
  void connectIfNeeded() {
    _disposed = false;
    // CRITICAL: skip if a connect attempt is already in flight OR already
    // connected. Without this guard, two near-simultaneous calls (one from
    // LoginLogic, one from UserService.loginFromApi) race and create two
    // overlapping `WebSocketChannel.connect` attempts, with the second one
    // overwriting `_ws` while the first becomes a zombie that never resolves
    // its `ready` future. Result: WS appears to "connect" but never works.
    if (_connecting || connected.value) {
      LogUtil.d('[ImWs] connectIfNeeded skipped (connecting=$_connecting connected=${connected.value})');
      return;
    }
    final token = Get.find<StorageService>().token;
    if (token != null && token.isNotEmpty) _connect();
  }

  /// User logout: tear down the current connection but **preserve the ability
  /// to reconnect** when the user logs back in. `_disposed` is only set true
  /// here so that the in-flight reconnect timer doesn't keep firing after
  /// logout; [connectIfNeeded] flips it back to false on the next login.
  void disconnectManual() {
    _disposed = true;
    _disconnect();
  }

  void registerMsgCallback(ImMsgCallback cb)       => _msgCallback    = cb;
  void unregisterMsgCallback()                     => _msgCallback    = null;
  void registerSignalCallback(ImSignalCallback cb)  => _signalCallback = cb;
  void unregisterSignalCallback()                   => _signalCallback = null;
  void registerConvCallback(ImConvCallback cb)      => _convCallback   = cb;
  void unregisterConvCallback()                     => _convCallback   = null;
  void registerBatchCallback(ImBatchCallback cb)    => _batchCallback  = cb;
  void unregisterBatchCallback()                    => _batchCallback  = null;

  void sendPacket(Map<String, dynamic> packet) {
    final ws = _rawWs;
    if (ws != null && connected.value && ws.readyState == io.WebSocket.open) {
      ws.add(jsonEncode(packet));
    } else {
      LogUtil.w('[ImWs] sendPacket skipped: ws=${ws?.readyState} connected=${connected.value}');
    }
  }

  void sendSignalPacket(int cmd, Map<String, dynamic> body) =>
      sendPacket({'cmd': cmd, 'seq': 'sig-${DateTime.now().millisecondsSinceEpoch}', 'body': body});

  // ── 连接管理 ──────────────────────────────────────────────────────────────

  void _connect() {
    if (_disposed) {
      LogUtil.w('[ImWs] _connect() skipped: disposed');
      return;
    }
    if (_connecting || connected.value) {
      LogUtil.w('[ImWs] _connect() skipped (connecting=$_connecting connected=${connected.value})');
      return;
    }
    final token = Get.find<StorageService>().token;
    if (token == null || token.isEmpty) {
      LogUtil.w('[ImWs] _connect() skipped: empty token');
      return;
    }

    _teardownTransport();
    _connecting = true;

    final wsUrl = AppConfig.imWsBaseUrl
        .replaceFirst('http://', 'ws://')
        .replaceFirst('https://', 'wss://');
    final fullUrl = '$wsUrl/ws/im?token=$token';
    LogUtil.i('[ImWs] → 正在连接 $wsUrl/ws/im (tokenLen=${token.length})');

    // Use dart:io WebSocket directly — `web_socket_channel`'s `ready` future
    // hangs indefinitely on iOS Simulator when the WS upgrade succeeds at the
    // TCP/HTTP layer but something in the wrapper stalls. The raw `dart:io`
    // `WebSocket.connect()` returns a proper `Future<WebSocket>` that either
    // completes or throws, giving us reliable, predictable connect semantics.
    io.WebSocket.connect(fullUrl).then((rawWs) {
      if (_disposed) {
        rawWs.close();
        return;
      }
      _rawWs = rawWs;
      _connecting = false;
      connected.value = true;
      _retryMs = 500;
      LogUtil.i('[ImWs] ✓ 已连接 $wsUrl/ws/im');

      _sub = rawWs.listen(
        (data) => _onData(data),
        onError: (e) {
          LogUtil.w('[ImWs] 连接错误: $e');
          _scheduleReconnect();
        },
        onDone: () {
          LogUtil.w('[ImWs] 连接断开，重连中...');
          _scheduleReconnect();
        },
        cancelOnError: false,
      );

      _sendAuthNow(token);
      _startHeartbeat();
    }).catchError((Object e) {
      LogUtil.e('[ImWs] ✗ 连接失败: $e');
      _connecting = false;
      _scheduleReconnect();
    });
  }

  /// Cancel the old connection **before** reconnecting to avoid phantom listeners.
  void _teardownTransport() {
    _sub?.cancel();
    _sub = null;
    try { _rawWs?.close(); } catch (_) {}
    _rawWs = null;
  }

  void _disconnect() {
    _authTimer?.cancel();
    _heartbeat?.cancel();
    _reconnTimer?.cancel();
    _teardownTransport();
    _connecting = false;
    connected.value = false;
  }

  void _scheduleReconnect() {
    if (_disposed) return;
    connected.value = false;
    _connecting = false;
    _heartbeat?.cancel();
    _reconnTimer?.cancel();
    _teardownTransport();   // ← ensure old socket is torn down before a new one opens
    _reconnTimer = Timer(Duration(milliseconds: _retryMs), () {
      _retryMs = (_retryMs * 1.5).clamp(500, 5000).toInt(); // cap at 5s
      _connect();
    });
  }

  /// Send the AUTH frame immediately after the connection is established.
  /// Sends directly on the raw socket (always open at this point) and schedules
  /// one retry 1s later in case the first frame is lost during WS setup.
  void _sendAuthNow(String token) {
    _authTimer?.cancel();
    final authPayload = jsonEncode({
      'cmd':  _Cmd.auth,
      'seq':  'auth-${DateTime.now().millisecondsSinceEpoch}',
      'body': token,
    });
    // Direct send — bypass readyState check since we just got the socket
    try {
      _rawWs?.add(authPayload);
      LogUtil.i('[ImWs] → AUTH frame sent (direct)');
    } catch (e) {
      LogUtil.w('[ImWs] AUTH direct send failed: $e');
    }
    // Retry once after 1s to handle any WS setup race
    _authTimer = Timer(const Duration(seconds: 1), () {
      if (connected.value && _rawWs != null && _rawWs!.readyState == io.WebSocket.open) {
        _rawWs!.add(jsonEncode({
          'cmd':  _Cmd.auth,
          'seq':  'auth-retry-${DateTime.now().millisecondsSinceEpoch}',
          'body': token,
        }));
        LogUtil.i('[ImWs] → AUTH frame retry sent');
      }
      _authTimer = null;
    });
  }

  void _startHeartbeat() {
    _heartbeat?.cancel();
    _heartbeat = Timer.periodic(const Duration(seconds: 30), (_) {
      sendPacket({'cmd': _Cmd.ping, 'seq': '${DateTime.now().millisecondsSinceEpoch}'});
    });
  }

  // ── 命令分发表构建（OCP：扩展时仅修改此方法）──────────────────────────────

  void _buildDispatch() {
    _dispatch = {
      _Cmd.pong:        (_) {},         // no-op
      _Cmd.authResult:  _onAuthResult,  // log + request missed msgs explicitly
      _Cmd.offlineMsgs: _onOfflineMsgs, // ← critical: replay batched offline messages
      _Cmd.convList:    _onConvList,    // full conv list pushed on connect
      _Cmd.convUpdate:  _onConvUpdate,  // single conv update on new message
      _Cmd.msgNotify:   _onMsgNotify,
      _Cmd.groupNotify: _onMsgNotify,
    };
    for (final cmd in _Cmd.signalingCmds) {
      _dispatch[cmd] = _onSignaling;
    }
  }

  // ── 消息分发入口 ──────────────────────────────────────────────────────────

  void _onData(dynamic raw) {
    try {
      final packet = jsonDecode(raw as String) as Map<String, dynamic>;
      final cmd    = (packet['cmd'] as num).toInt();
      (_dispatch[cmd] ?? _onUnknown)(packet);
    } catch (e) {
      LogUtil.e('[ImWs] 消息解析失败: $e');
    }
  }

  void _onUnknown(Map<String, dynamic> p) =>
      LogUtil.w('[ImWs] 未知 cmd=${p['cmd']}');

  // ── 命令处理器 ────────────────────────────────────────────────────────────

  void _onAuthResult(Map<String, dynamic> packet) {
    LogUtil.i('[ImWs] 鉴权成功，主动拉取离线消息');
    // Explicit PULL_OFFLINE as a reliability belt-and-suspenders:
    // server already auto-pushes OFFLINE_MSGS in onUserOnline, but sending
    // this ensures we never miss messages on reconnect edge-cases.
    sendPacket({
      'cmd': _Cmd.pullOffline,
      'seq': '${DateTime.now().millisecondsSinceEpoch}',
    });
  }

  /// Handles server-pushed OFFLINE_MSGS (cmd=4002).
  ///
  /// Body: {"msgs": [...ImMessageVO], "count": n}
  /// Routes each message silently through [_batchCallback] so
  /// [MessageService] can replay them without triggering audio/notifications.
  void _onOfflineMsgs(Map<String, dynamic> packet) {
    final body = packet['body'];
    if (body is! Map) return;
    final rawMsgs = body['msgs'];
    if (rawMsgs is! List || rawMsgs.isEmpty) return;

    final myId = Get.find<UserService>().technician.value?.id ?? 0;
    final msgs = rawMsgs
        .whereType<Map>()
        .map((e) => ChatMessageModel.fromImJson(
              Map<String, dynamic>.from(e),
              myType: 'technician',
              myId: myId,
            ))
        .toList();

    LogUtil.i('[ImWs] OFFLINE_MSGS count=${msgs.length}');
    _batchCallback?.call(msgs);
  }

  void _onConvList(Map<String, dynamic> packet) {
    final body = packet['body'];
    if (body is! List) return;
    final list = body
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    LogUtil.d('[ImWs] CONV_LIST count=${list.length}');
    _convCallback?.call(list, true);
  }

  void _onConvUpdate(Map<String, dynamic> packet) {
    final body = packet['body'];
    if (body is! Map) return;
    LogUtil.d('[ImWs] CONV_UPDATE convId=${body['conversationId']}');
    _convCallback?.call([Map<String, dynamic>.from(body)], false);
  }

  void _onMsgNotify(Map<String, dynamic> packet) {
    final body = packet['body'];
    if (body is! Map) return;
    final data = Map<String, dynamic>.from(body);
    final myId = Get.find<UserService>().technician.value?.id ?? 0;
    final msg  = ChatMessageModel.fromImJson(data, myType: 'technician', myId: myId);

    LogUtil.d('[ImWs] 收到消息 convId=${msg.conversationId} isMe=${msg.isMe}');
    _msgCallback?.call(msg);

    // ACK
    sendPacket({
      'cmd':  _Cmd.msgAck,
      'seq':  packet['seq'],
      'body': {'msgId': int.tryParse(msg.id) ?? 0},
    });
  }

  void _onSignaling(Map<String, dynamic> packet) {
    final cmd  = (packet['cmd'] as num).toInt();
    final body = packet['body'];
    if (body is Map<String, dynamic>) {
      _signalCallback?.call(cmd, body);
    }
  }
}
