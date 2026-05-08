import 'dart:async';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../auth/auth_controller.dart';
import '../../features/im/models/im_models.dart';
import '../../features/im/api/im_api.dart';

// ── IM 协议命令码（与后端 ImCmd.java 保持一致）─────────────────────────────
abstract class _Cmd {
  static const ping          = 1001;
  static const pong          = 1002;
  static const msgNotify     = 2002;
  static const msgAck        = 2003;
  static const msgDelivered  = 2004;
  static const groupNotify   = 3002;
  static const groupAck      = 3003;
  static const callInvite    = 5001;
  static const callAccept    = 5002;
  static const callReject    = 5003;
  static const callIce       = 5004;
  static const callSdp       = 5005;
  static const callEnd       = 5006;
  static const callBusy      = 5007;

  static const Set<int> signalingCmds = {
    callInvite, callAccept, callReject, callIce, callSdp, callEnd, callBusy,
  };
}

/// 消息到达回调（ImChatLogic 注册，会话切走后注销）
typedef MessageCallback = void Function(ImMessage msg);

/// 信令回调（VoiceCallLogic 注册）
typedef SignalCallback = void Function(int cmd, CallSignal signal);

/// 全局 IM 服务（GetxService，随 main.dart 启动，永不销毁）
///
/// 职责：
///  1. WebSocket 连接管理（自动心跳 + 指数退避重连）
///  2. 维护全局会话列表 + 未读总数
///  3. 维护各会话消息缓存（Map<convId, List<ImMessage>>）
///  4. 通知注册的 UI 回调（新消息 / 信令）
class ImService extends GetxService {
  static ImService get to => Get.find();

  // ── 响应式状态（供 UI 监听）──────────────────────────────────────────────

  final connected      = false.obs;
  final conversations  = <ImConversation>[].obs;
  final unreadTotal    = 0.obs;

  /// convId → 消息列表（正序，最新在末尾）
  final messages = <int, List<ImMessage>>{}.obs;

  // ── 内部字段 ──────────────────────────────────────────────────────────────

  WebSocketChannel? _ws;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  int    _retryMs   = 2000;
  bool   _disposed  = false;

  /// 当前激活会话的消息回调（覆盖注册，同时只有一个聊天页打开）
  MessageCallback? _msgCallback;

  /// 信令回调（VoiceCallLogic 注册）
  SignalCallback? _signalCallback;

  /// WS URL（与 ApiClient._baseUrl 保持同主机，端口 9090）
  static const _wsUrl = 'ws://127.0.0.1:9090/ws/im';
  // Android 模拟器: 'ws://10.0.2.2:9090/ws/im'
  // 真机调试:       'ws://192.168.x.x:9090/ws/im'

  // ── 生命周期 ──────────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    // 登录后立即连接，登出后断开
    ever(AuthController.to.isLoggedIn, (bool loggedIn) {
      if (loggedIn) {
        _connect();
      } else {
        _disconnect();
        conversations.clear();
        messages.clear();
        unreadTotal.value = 0;
      }
    });
    if (AuthController.to.isLoggedIn.value) {
      _connect();
      _loadConversations();
    }
  }

  @override
  void onClose() {
    _disposed = true;
    _disconnect();
    super.onClose();
  }

  // ── 公开 API ──────────────────────────────────────────────────────────────

  /// 注册当前聊天页消息监听（同时只注册一个）
  void registerMessageCallback(MessageCallback cb)   { _msgCallback    = cb; }
  void unregisterMessageCallback()                   { _msgCallback    = null; }

  /// 注册信令监听（VoiceCallLogic）
  void registerSignalCallback(SignalCallback cb)     { _signalCallback = cb; }
  void unregisterSignalCallback()                    { _signalCallback = null; }

  /// 发送 WS 数据包
  void sendPacket(Map<String, dynamic> packet) {
    if (_ws != null && connected.value) {
      _ws!.sink.add(jsonEncode(packet));
    }
  }

  /// 发送信令包（VoiceCallLogic 调用）
  void sendSignal(int cmd, CallSignal signal) {
    sendPacket({'cmd': cmd, 'seq': 'sig-${DateTime.now().millisecondsSinceEpoch}', 'body': signal.toJson()});
  }

  // ── 会话缓存操作 ──────────────────────────────────────────────────────────

  Future<void> loadConversations() => _loadConversations();

  Future<void> loadHistory(int convId) async {
    if (messages[convId]?.isNotEmpty == true) return;
    try {
      final list = await ImApi.history(convId);
      messages[convId] = list;
      messages.refresh();
    } catch (_) {}
  }

  Future<void> loadMore(int convId) async {
    final current = messages[convId] ?? [];
    if (current.isEmpty) return;
    final before = current.first.msgId;
    try {
      final older = await ImApi.history(convId, beforeMsgId: before);
      if (older.isNotEmpty) {
        messages[convId] = [...older, ...current];
        messages.refresh();
      }
    } catch (_) {}
  }

  void clearUnread(int convId) {
    final idx = conversations.indexWhere((c) => c.conversationId == convId);
    if (idx < 0) return;
    conversations[idx] = conversations[idx].copyWith(unreadCount: 0);
    _recomputeUnread();
  }

  /// 乐观追加消息（发送成功后立即展示，服务端确认后替换）
  void appendOptimistic(ImMessage msg) {
    final list = List<ImMessage>.from(messages[msg.conversationId] ?? []);
    list.add(msg);
    messages[msg.conversationId] = list;
    messages.refresh();
    _updateConvPreview(msg);
  }

  /// 用服务端 msgId 替换乐观消息
  void confirmOptimistic(int convId, int tempId, int realId) {
    final list = messages[convId];
    if (list == null) return;
    final idx = list.indexWhere((m) => m.msgId == tempId && m.isOptimistic);
    if (idx < 0) return;
    list[idx] = list[idx].copyWith(status: 1);
    messages[convId] = list;
    messages.refresh();
  }

  // ── WS 连接管理 ──────────────────────────────────────────────────────────

  void _connect() {
    if (_disposed) return;
    final token = AuthController.to.accessToken.value;
    if (token == null || token.isEmpty) return;
    try {
      final uri = Uri.parse('$_wsUrl?token=${Uri.encodeComponent(token)}');
      _ws = WebSocketChannel.connect(uri);
      connected.value = true;
      _retryMs = 2000;
      _startHeartbeat();

      _ws!.stream.listen(
        _onData,
        onError: (_) => _scheduleReconnect(),
        onDone:  ()  => _scheduleReconnect(),
      );
    } catch (_) {
      _scheduleReconnect();
    }
  }

  void _disconnect() {
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
    _ws?.sink.close();
    _ws = null;
    connected.value = false;
  }

  void _scheduleReconnect() {
    if (_disposed || !AuthController.to.isLoggedIn.value) return;
    connected.value = false;
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(milliseconds: _retryMs), () {
      _retryMs = (_retryMs * 1.5).clamp(2000, 30000).toInt();
      _connect();
    });
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      sendPacket({'cmd': _Cmd.ping, 'seq': '${DateTime.now().millisecondsSinceEpoch}'});
    });
  }

  // ── 消息分发 ──────────────────────────────────────────────────────────────

  void _onData(dynamic raw) {
    try {
      final packet = jsonDecode(raw as String) as Map<String, dynamic>;
      final cmd    = packet['cmd'] as int;

      if (cmd == _Cmd.pong) return;

      // 信令包 → VoiceCallLogic
      if (_Cmd.signalingCmds.contains(cmd)) {
        final body = packet['body'];
        if (body is Map<String, dynamic> && _signalCallback != null) {
          _signalCallback!(cmd, CallSignal.fromJson(body));
        }
        return;
      }

      if (cmd == _Cmd.msgNotify || cmd == _Cmd.groupNotify) {
        _handleIncoming(packet, cmd);
      } else if (cmd == _Cmd.msgDelivered) {
        _handleDelivered(packet);
      }
    } catch (_) {}
  }

  void _handleIncoming(Map<String, dynamic> packet, int cmd) {
    final payload = packet['payload'];
    if (payload == null) return;
    final data    = jsonDecode(payload as String) as Map<String, dynamic>;
    final msg     = ImMessage.fromJson(data);

    // 追加消息缓存
    final list = List<ImMessage>.from(messages[msg.conversationId] ?? []);
    if (!list.any((m) => m.msgId == msg.msgId)) {
      list.add(msg);
      messages[msg.conversationId] = list;
      messages.refresh();
    }

    // 通知激活聊天页
    _msgCallback?.call(msg);

    // 更新会话预览 + 未读
    _updateConvPreview(msg, incr: true);

    // 发送 ACK
    sendPacket({
      'cmd':     cmd == _Cmd.groupNotify ? _Cmd.groupAck : _Cmd.msgAck,
      'seq':     packet['seq'],
      'payload': jsonEncode({'msgId': msg.msgId}),
    });
  }

  void _handleDelivered(Map<String, dynamic> packet) {
    final payload = packet['payload'];
    if (payload == null) return;
    try {
      final data   = jsonDecode(payload as String) as Map<String, dynamic>;
      final msgId  = data['msgId'] as int;
      final status = data['status'] as int;
      for (final convId in messages.keys) {
        final list = messages[convId]!;
        final idx  = list.indexWhere((m) => m.msgId == msgId);
        if (idx >= 0) {
          list[idx] = list[idx].copyWith(status: status);
          messages[convId] = list;
          messages.refresh();
          break;
        }
      }
    } catch (_) {}
  }

  // ── 私有辅助 ──────────────────────────────────────────────────────────────

  Future<void> _loadConversations() async {
    try {
      final list = await ImApi.conversations();
      conversations.assignAll(list);
      _recomputeUnread();
    } catch (_) {}
  }

  void _updateConvPreview(ImMessage msg, {bool incr = false}) {
    final idx = conversations.indexWhere((c) => c.conversationId == msg.conversationId);
    final preview = _preview(msg);
    if (idx >= 0) {
      final old     = conversations[idx];
      final unread  = incr ? old.unreadCount + 1 : old.unreadCount;
      conversations[idx] = old.copyWith(
        lastMsgPreview: preview,
        lastMsgTime:    msg.createTime,
        unreadCount:    unread,
      );
      // 置顶：把最新会话移到列表头
      final updated = conversations.removeAt(idx);
      conversations.insert(0, updated);
    } else {
      // 陌生会话：刷新列表
      _loadConversations();
    }
    _recomputeUnread();
  }

  void _recomputeUnread() {
    unreadTotal.value = conversations.fold(0, (s, c) => s + c.unreadCount);
  }

  String _preview(ImMessage m) {
    switch (m.msgType) {
      case 2: return '[图片]';
      case 3: return '[语音]';
      case 4: return '[视频]';
      case 6: return '[系统通知]';
      default: return m.content.length > 60 ? '${m.content.substring(0, 60)}…' : m.content;
    }
  }
}
