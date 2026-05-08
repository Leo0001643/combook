import 'dart:async';

import 'package:dio/dio.dart' as dio show FormData, MultipartFile;
import 'package:get/get.dart';

import '../events/app_events.dart';
import '../models/models.dart';
import '../i18n/l10n_ext.dart';
import '../network/api_endpoints.dart';
import '../network/http_util.dart';
import '../utils/event_bus_util.dart';
import '../utils/log_util.dart';
import 'im_ws_service.dart';
import 'user_service.dart';

/// IM 消息服务 —— 真实 API + WS 实时推送（全局单例）
///
/// 架构：
///  - [conversations] RxList + [messages] RxMap 均为响应式，UI 通过 Obx 自动更新
///  - 发送消息走 HTTP（乐观 UI），接收消息走 WS 回调
///  - [_chatPageCallback]: 当聊天页打开时注册，确保页面内实时刷新（不抢占 ImWsService 唯一回调）
///  - 本地清空 / 删除 (clearLocalMessages / deleteLocalConversation) 只影响内存，不调后端
class MessageService extends GetxService with EventBusMixin {
  static MessageService get to => Get.find();

  final RxList<ConversationModel>             conversations = <ConversationModel>[].obs;
  final RxMap<String, List<ChatMessageModel>> messages     = <String, List<ChatMessageModel>>{}.obs;
  final RxList<ImContactModel>                contacts     = <ImContactModel>[].obs;

  // 聊天页实时回调（由 ChatLogic 注册/注销，不干扰 ImWsService 唯一回调）
  void Function(ChatMessageModel)? _chatPageCallback;

  Timer?  _convRefreshTimer;     // WS-down safety net (30s)
  Worker? _wsConnWorker;          // listens for WS reconnects → triggers refresh

  Future<MessageService> init() async {
    ImWsService.to.registerMsgCallback(_onWsMessage);
    // CONV_LIST (on-connect full list) + CONV_UPDATE (per-message patch)
    ImWsService.to.registerConvCallback(_onWsConvPush);
    // OFFLINE_MSGS: batched replay, no audio/notification side-effects
    ImWsService.to.registerBatchCallback(_onOfflineBatch);
    // One-time bootstrap HTTP fetch — gives us instant data on cold start
    // before the WS handshake completes. Subsequent updates are entirely
    // WS-driven via CONV_LIST / CONV_UPDATE pushes.
    await _fetchConversations();
    await _loadContacts();
    _startConvRefreshTimer();
    // Listen for WS reconnects: when the WS comes back up after a disconnect,
    // the backend will auto-push a fresh CONV_LIST, but we also do one HTTP
    // fetch as belt-and-suspenders to avoid any race.
    _wsConnWorker = ever<bool>(ImWsService.to.connected, (online) {
      if (online) {
        LogUtil.d('[MsgSvc] WS reconnected → refreshing conversations');
        _fetchConversations();
      }
    });
    return this;
  }

  void _startConvRefreshTimer() {
    _convRefreshTimer?.cancel();
    // WS-DOWN-ONLY safety net: poll every 30s **iff the WS is disconnected**.
    // When the WS is healthy this timer is a no-op — server-pushed CONV_LIST /
    // CONV_UPDATE drive the UI in real time.  This keeps the app functional
    // during network partitions without wasting requests when WS works.
    _convRefreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!ImWsService.to.connected.value) {
        _fetchConversations();
      }
    });
  }

  @override
  void onClose() {
    _convRefreshTimer?.cancel();
    _wsConnWorker?.dispose();
    ImWsService.to.unregisterMsgCallback();
    ImWsService.to.unregisterConvCallback();
    ImWsService.to.unregisterBatchCallback();
    _chatPageCallback = null;
    cancelAllSubscriptions();
    super.onClose();
  }

  // ── 聊天页回调 ────────────────────────────────────────────────────────────

  void setChatPageCallback(void Function(ChatMessageModel)? cb) =>
      _chatPageCallback = cb;

  // ── 公开查询 ──────────────────────────────────────────────────────────────

  int get totalUnread => conversations.fold(0, (s, c) => s + c.unread);

  List<ChatMessageModel> getMessages(String convId) => messages[convId] ?? [];

  Future<void> refresh() => _fetchConversations();

  /// 标记会话为已读 — 优先 WS（零延迟），失败再 HTTP 兜底。
  ///
  /// 流程：
  ///   1. 本地立即清零 → UI 即时反馈
  ///   2. WS 发送 MARK_READ（cmd=2005）→ 服务端持久化 + 推送 CONV_UPDATE 给所有端
  ///   3. 若 WS 未连，HTTP 兜底
  void markRead(String convId, {int? lastMsgId}) {
    final i = conversations.indexWhere((c) => c.id == convId);
    if (i < 0) return;
    if (conversations[i].unread == 0) return;   // already clean

    final lastId = lastMsgId ?? _lastMsgId(convId);
    final convIdInt = int.tryParse(convId) ?? 0;
    if (convIdInt <= 0 || lastId <= 0) return;

    // ① local clear → instant UI feedback
    conversations[i] = conversations[i].copyWith(unread: 0);
    conversations.refresh();
    _fireUnreadChanged();

    // ② Try WS first; fall back to HTTP only if not connected.
    final ws = ImWsService.to;
    if (ws.connected.value) {
      ws.sendPacket({
        'cmd':  2005, // MARK_READ
        'seq':  'mr-${DateTime.now().millisecondsSinceEpoch}',
        'body': {'conversationId': convIdInt, 'lastReadMsgId': lastId},
      });
      LogUtil.d('[MsgSvc] → MARK_READ via WS conv=$convIdInt last=$lastId');
    } else {
      _serverMarkReadHttp(convIdInt, lastId);
    }
  }

  /// HTTP 兜底（仅在 WS 完全断开时使用）
  Future<void> _serverMarkReadHttp(int convId, int lastMsgId) async {
    try {
      await HttpUtil.postJson(
        '${ApiEndpoints.imMessagesRead}'
        '?conversationId=$convId&lastReadMsgId=$lastMsgId',
      );
    } catch (e) {
      LogUtil.w('[MsgSvc] serverMarkRead HTTP failed (non-critical): $e');
    }
  }

  int _lastMsgId(String convId) {
    final list = messages[convId];
    if (list == null || list.isEmpty) return 0;
    return int.tryParse(list.last.id) ?? 0;
  }

  void _fireUnreadChanged() =>
      EventBusUtil.fire(ImUnreadChangedEvent(totalUnread));

  /// 仅清空本地缓存中的消息记录（不调后端）
  void clearLocalMessages(String convId) {
    messages[convId] = [];
    messages.refresh();
    // 清空会话预览
    final i = conversations.indexWhere((c) => c.id == convId);
    if (i >= 0) {
      conversations[i] = conversations[i].copyWith(lastMessage: '', unread: 0);
    }
  }

  /// 仅从本地会话列表中删除（不调后端）
  void deleteLocalConversation(String convId) {
    conversations.removeWhere((c) => c.id == convId);
    messages.remove(convId);
    messages.refresh();
  }

  // ── 历史消息 ──────────────────────────────────────────────────────────────

  Future<void> loadHistory(String convId, {int? beforeMsgId}) async {
    try {
      final resp = await HttpUtil.get(ApiEndpoints.imMessagesHistory, params: {
        'conversationId': int.tryParse(convId) ?? convId,
        if (beforeMsgId != null) 'beforeMsgId': beforeMsgId,
        'limit': 30,
      });
      final List items = resp is List ? resp : const [];
      final list = items
          .map((e) => ChatMessageModel.fromImJson(e as Map<String, dynamic>,
              myType: 'technician', myId: _myId))
          .toList();

      if (beforeMsgId == null) {
        messages[convId] = list.reversed.toList();
      } else {
        final existing = List<ChatMessageModel>.from(messages[convId] ?? []);
        existing.insertAll(0, list.reversed);
        messages[convId] = existing;
      }
      messages.refresh();
    } catch (e) {
      LogUtil.e('[MsgSvc] loadHistory error: $e');
    }
  }

  /// 轮询新消息（WS push 失败时的兜底机制）。
  ///
  /// 拉取最新 30 条，与本地缓存做 ID 级 merge，有新消息时返回 true。
  /// 不替换已有缓存，避免 UI 闪烁。
  Future<bool> pollMessages(String convId) async {
    try {
      final resp = await HttpUtil.get(ApiEndpoints.imMessagesHistory, params: {
        'conversationId': int.tryParse(convId) ?? convId,
        'limit': 30,
      });
      final List items = resp is List ? resp : const [];
      final incoming = items
          .map((e) => ChatMessageModel.fromImJson(e as Map<String, dynamic>,
              myType: 'technician', myId: _myId))
          .toList()
          .reversed   // ascending (oldest → newest)
          .toList();

      final existing   = messages[convId] ?? [];
      final existingIds = {for (final m in existing) m.id};
      final novel       = incoming.where((m) => !existingIds.contains(m.id)).toList();

      if (novel.isEmpty) return false;

      // Append new messages (they are newer than any cached ones)
      messages[convId] = [...existing, ...novel];
      messages.refresh();
      // No local conversation/unread mutation — server's CONV_UPDATE owns that.
      return true;
    } catch (e) {
      LogUtil.d('[MsgSvc] pollMessages: $e');
      return false;
    }
  }

  // ── 发送文本 ──────────────────────────────────────────────────────────────

  Future<void> sendMessage(String convId, String content) async {
    final (type, receiver) = _resolveReceiver(convId);
    if (receiver == null) return;

    final tempMsg = _optimistic(convId, content, MessageType.text);
    _appendMsg(convId, tempMsg);
    _bumpConv(convId, content);

    try {
      await HttpUtil.postJson(ApiEndpoints.imMessagesSend, data: {
        ...receiver,
        'msgType': 1,
        'content': content,
      });
    } catch (e) {
      messages[convId]?.removeWhere((m) => m.id == tempMsg.id);
      messages.refresh();
      LogUtil.e('[MsgSvc] sendMessage error: $e');
      rethrow;
    }
  }

  // ── 发送图片 ──────────────────────────────────────────────────────────────

  Future<void> sendImage(String convId, String localPath) async {
    final (_, receiver) = _resolveReceiver(convId);
    if (receiver == null) return;

    // Upload first; if it fails, caller handles the exception — no stale bubble.
    final url = await _uploadFile(localPath, ApiEndpoints.imMediaImage);
    final msg = _optimistic(convId, url, MessageType.image);
    _appendMsg(convId, msg);
    _bumpConv(convId, '[Image]');

    try {
      await HttpUtil.postJson(ApiEndpoints.imMessagesSend, data: {
        ...receiver, 'msgType': 2, 'content': url,
      });
    } catch (e) {
      // Roll back optimistic bubble so it doesn't linger as a phantom message
      messages[convId]?.removeWhere((m) => m.id == msg.id);
      messages.refresh();
      LogUtil.e('[MsgSvc] sendImage error: $e');
      rethrow;
    }
  }

  // ── 发送语音 ──────────────────────────────────────────────────────────────

  Future<void> sendVoice(String convId, String localPath, int durationSec) async {
    final (_, receiver) = _resolveReceiver(convId);
    if (receiver == null) return;

    final url     = await _uploadFile(localPath, ApiEndpoints.imMediaVoice, filename: 'voice.aac');
    final content = '$url|$durationSec';
    final msg = ChatMessageModel(
      id: '${DateTime.now().millisecondsSinceEpoch}', conversationId: convId,
      isMe: true, content: content, type: MessageType.voice,
      time: DateTime.now(), voiceUrl: url, voiceDurSec: durationSec,
    );
    _appendMsg(convId, msg);
    _bumpConv(convId, '[Voice]');

    try {
      await HttpUtil.postJson(ApiEndpoints.imMessagesSend, data: {
        ...receiver, 'msgType': 3, 'content': content,
      });
    } catch (e) {
      messages[convId]?.removeWhere((m) => m.id == msg.id);
      messages.refresh();
      LogUtil.e('[MsgSvc] sendVoice error: $e');
      rethrow;
    }
  }

  /// 发送位置消息（content 为 JSON 字符串 {"lat":…,"lng":…,"address":…}）
  Future<void> sendLocation(String convId, double lat, double lng, String address) async {
    final (_, receiver) = _resolveReceiver(convId);
    if (receiver == null) return;

    final content = '{"lat":$lat,"lng":$lng,"address":"${address.replaceAll('"', '\\"')}"}';
    final msg = ChatMessageModel(
      id: '${DateTime.now().millisecondsSinceEpoch}', conversationId: convId,
      isMe: true, content: content, type: MessageType.location, time: DateTime.now(),
    );
    _appendMsg(convId, msg);
    _bumpConv(convId, '📍 $address');

    try {
      await HttpUtil.postJson(ApiEndpoints.imMessagesSend, data: {
        ...receiver, 'msgType': 5, 'content': content,
      });
    } catch (e) {
      messages[convId]?.removeWhere((m) => m.id == msg.id);
      messages.refresh();
      LogUtil.e('[MsgSvc] sendLocation error: $e');
      rethrow;
    }
  }

  // ── WS 批量离线消息回放（OFFLINE_MSGS）────────────────────────────────────

  /// 静默回放服务端推送的离线消息批次（OFFLINE_MSGS / cmd=4002）。
  ///
  /// 与 [_onWsMessage] 一致：不本地修改 unread，会话列表由紧随其后的
  /// CONV_LIST 推送驱动权威更新。这里只负责把历史消息塞进 [messages]
  /// 缓存，确保当用户进入聊天页时立即看到完整的对话上下文。
  void _onOfflineBatch(List<ChatMessageModel> msgs) {
    if (msgs.isEmpty) return;
    for (final msg in msgs) {
      _appendMsg(msg.conversationId, msg);
      _chatPageCallback?.call(msg);
    }
    LogUtil.i('[MsgSvc] 离线消息回放完成 count=${msgs.length}');
  }

  // ── WS 会话推送（CONV_LIST / CONV_UPDATE）─────────────────────────────────

  /// 处理服务端主动推送的会话数据。
  ///
  /// * [isFullList] = true  → CONV_LIST（上线时全量替换）
  /// * [isFullList] = false → CONV_UPDATE（新消息时单条更新）
  void _onWsConvPush(List<Map<String, dynamic>> data, bool isFullList) {
    if (isFullList) {
      // Full list: replace all conversations (same as HTTP fetch result)
      conversations.assignAll(
        data.map((e) => ConversationModel.fromImJson(e)),
      );
      LogUtil.d('[MsgSvc] WS CONV_LIST 更新 count=${conversations.length}');
    } else {
      // Single update: find and update (or prepend if new)
      for (final raw in data) {
        final updated = ConversationModel.fromImJson(raw);
        final i = conversations.indexWhere((c) => c.id == updated.id);
        if (i >= 0) {
          conversations[i] = updated;
          if (i != 0) {
            final c = conversations.removeAt(i);
            conversations.insert(0, c);
          } else {
            conversations.refresh();
          }
        } else {
          // New conversation — prepend
          conversations.insert(0, updated);
        }
        LogUtil.d('[MsgSvc] WS CONV_UPDATE convId=${updated.id} unread=${updated.unread}');
      }
    }
    _fireUnreadChanged();
  }

  // ── WS 实时消息 ───────────────────────────────────────────────────────────

  /// 处理 MSG_NOTIFY（cmd=2002）。
  ///
  /// 关键设计：**不在客户端本地递增 unread**。服务端在转发 MSG_NOTIFY 之后会
  /// 紧接着推送 CONV_UPDATE（cmd=4004），其中包含权威的 `unreadCount` 值。
  /// 如果客户端再本地 +1，就会与服务端数据双重叠加，导致已读/未读混乱。
  ///
  /// 因此本方法只做：
  ///   1) 追加消息到 [messages]（聊天窗实时滚动）
  ///   2) 通过 callback 通知当前聊天页（如已打开）
  ///   3) 广播 [NewMessageEvent] 供其他模块订阅（音效/通知）
  ///
  /// 会话列表预览、未读数、排序均由后续到达的 CONV_UPDATE 驱动。
  void _onWsMessage(ChatMessageModel msg) {
    _appendMsg(msg.conversationId, msg);
    _chatPageCallback?.call(msg);
    EventBusUtil.fire(NewMessageEvent(
      msg.conversationId,
      _convById(msg.conversationId)?.name ?? gL10n.imNewMessage,
      msg.preview,
      ConversationType.customer,
    ));
    // ⚠ 不调 _bumpConv，也不 _fireUnreadChanged ─ 等 CONV_UPDATE 推送
  }

  // ── 联系人（运营/营销）────────────────────────────────────────────────────

  Future<void> _loadContacts() async {
    // 后期对接后端 /chat/contacts；当前以本地数据提供扩展点
    try {
      // TODO: replace with real API call when endpoint is ready
      // final resp = await HttpUtil.get('/chat/contacts');
      // contacts.assignAll(...);
    } catch (e) {
      LogUtil.e('[MsgSvc] loadContacts error: $e');
    }
  }

  // ── 私有辅助 ──────────────────────────────────────────────────────────────

  (String?, Map<String, dynamic>?) _resolveReceiver(String convId) {
    final conv = _convById(convId);
    if (conv == null) return (null, null);
    final type = conv.peerType ?? 'member';
    final id   = conv.peerId ?? conv.customerId ?? 0;
    return (type, {'receiverType': type, 'receiverId': id});
  }

  Future<String> _uploadFile(String path, String endpoint, {String? filename}) async {
    final form = dio.FormData.fromMap({
      'file': await dio.MultipartFile.fromFile(path,
          filename: filename ?? path.split('/').last),
    });
    final resp = await HttpUtil.postMultipart(endpoint, formData: form);
    return (resp['data'] as Map)['fileUrl'] as String;
  }

  Future<void> _fetchConversations() async {
    try {
      final resp = await HttpUtil.get(ApiEndpoints.imConversations);
      final List items = resp is List ? resp : const [];
      conversations.assignAll(
        items.map((e) => ConversationModel.fromImJson(e as Map<String, dynamic>)),
      );
    } catch (e) {
      LogUtil.e('[MsgSvc] fetchConversations error: $e');
    }
  }

  int get _myId => Get.find<UserService>().technician.value?.id ?? 0;

  ConversationModel? _convById(String id) =>
      conversations.where((c) => c.id == id).firstOrNull;

  void _appendMsg(String convId, ChatMessageModel msg) {
    final list = List<ChatMessageModel>.from(messages[convId] ?? []);
    if (list.any((m) => m.id == msg.id)) return;
    list.add(msg);
    messages[convId] = list;
    messages.refresh();
  }

  void _bumpConv(String convId, String preview, {bool incr = false}) {
    final i = conversations.indexWhere((c) => c.id == convId);
    if (i < 0) {
      _fetchConversations();
      return;
    }
    final old = conversations[i];
    conversations[i] = old.copyWith(
      unread:      incr ? old.unread + 1 : old.unread,
      lastMessage: preview,
      lastTime:    DateTime.now(),
    );
    if (i != 0) {
      final updated = conversations.removeAt(i);
      conversations.insert(0, updated);
    } else {
      // Already at top — removeAt/insert won't fire; force observer notification.
      conversations.refresh();
    }
  }

  ChatMessageModel _optimistic(String convId, String content, MessageType type) =>
      ChatMessageModel(
        id:             '${DateTime.now().millisecondsSinceEpoch}',
        conversationId: convId,
        isMe:           true,
        content:        content,
        type:           type,
        time:           DateTime.now(),
      );
}
