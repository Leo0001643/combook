import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../../core/events/app_events.dart';
import '../../../core/i18n/l10n_ext.dart';
import '../../../core/models/models.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/im_ws_service.dart';
import '../../../core/services/message_service.dart';
import '../../../core/utils/event_bus_util.dart';
import '../../../core/utils/log_util.dart';
import '../voice_call/logic.dart';
import 'state.dart';

class ChatLogic extends GetxController {
  final ChatState state = ChatState();
  final inputCtrl  = TextEditingController();
  final scrollCtrl = ScrollController();

  final _recorder  = AudioRecorder();
  String? _recPath;
  int     _recSecs = 0;
  Timer?  _recTimer;         // cancellable recording tick timer

  // ── real-time channels ────────────────────────────────────────────────────
  StreamSubscription<NewMessageEvent>? _msgSub;
  Timer? _pollTimer;
  bool   _pollInFlight = false;  // prevents overlapping HTTP poll ticks

  MessageService get _svc   => Get.find<MessageService>();
  String         get _convId => state.conversationId.value;

  @override
  void onInit() {
    super.onInit();
    inputCtrl.addListener(() {
      state.inputHasText.value = inputCtrl.text.trim().isNotEmpty;
    });

    final args = Get.arguments as Map<String, dynamic>? ?? {};
    state.conversationId.value   = args['id']       as String? ?? '';
    state.conversationName.value = args['name']      as String? ?? '';
    state.customerId.value       = args['customerId']?.toString() ?? '';

    final conv = _svc.conversations.where((c) => c.id == _convId).firstOrNull;
    state.customerPhone.value = conv?.phone   ?? '';
    state.peerType.value      = conv?.peerType ?? 'member';
    state.peerId.value        = conv?.peerId   ?? 0;
    state.peerAvatar.value    = conv?.avatar   ?? '';

    _init();
  }

  @override
  void onClose() {
    _msgSub?.cancel();
    _pollTimer?.cancel();
    _recTimer?.cancel();
    _svc.setChatPageCallback(null);
    // Sync read state on exit
    final lastId = _lastMsgIdInt();
    _svc.markRead(_convId, lastMsgId: lastId);
    inputCtrl.dispose();
    scrollCtrl.dispose();
    _recorder.dispose();
    super.onClose();
  }

  Future<void> _init() async {
    // Channel 1: direct WS callback — lowest latency, zero HTTP
    _svc.setChatPageCallback(_onNewWsMessage);

    // Channel 2: EventBus broadcast — survives callback changes
    _msgSub = EventBusUtil.on<NewMessageEvent>().listen((e) {
      if (e.conversationId != _convId) return;
      reload();
      _scrollToBottom(animate: true);
    });

    // Channel 3: HTTP fallback — fires every 5s **only when the WS is down**.
    // When the WS is healthy this is a no-op; MSG_NOTIFY pushes carry messages
    // with sub-100ms latency, so we never want HTTP racing the WS.
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (ImWsService.to.connected.value) return;     // WS works → skip HTTP
      if (_pollInFlight) return;
      _pollInFlight = true;
      try {
        final hasNew = await _svc.pollMessages(_convId);
        if (hasNew) {
          reload();
          _scrollToBottom(animate: true);
          _svc.markRead(_convId, lastMsgId: _lastMsgIdInt());
        }
      } finally {
        _pollInFlight = false;
      }
    });

    await _svc.loadHistory(_convId);
    reload();
    _scrollToBottom();
    _svc.markRead(_convId, lastMsgId: _lastMsgIdInt());
  }

  void _onNewWsMessage(ChatMessageModel msg) {
    if (msg.conversationId != _convId) return;
    reload();
    _scrollToBottom(animate: true);
    _svc.markRead(_convId, lastMsgId: int.tryParse(msg.id) ?? 0);
  }

  void reload() => state.messages.assignAll(_svc.getMessages(_convId));

  int _lastMsgIdInt() => int.tryParse(
      state.messages.isNotEmpty ? state.messages.last.id : '0') ?? 0;

  // ── 发送文本 ──────────────────────────────────────────────────────────────

  Future<void> send() async {
    final text = inputCtrl.text.trim();
    if (text.isEmpty) return;
    inputCtrl.clear();
    try {
      await _svc.sendMessage(_convId, text);
      reload();
      _scrollToBottom(animate: true);
    } catch (_) {
      Get.snackbar(gL10n.imSendFailed, gL10n.imCheckNetwork,
          snackPosition: SnackPosition.TOP);
    }
  }

  void sendQuickReply(String text) {
    inputCtrl.text = text;
    send();
  }

  // ── 发送图片 ──────────────────────────────────────────────────────────────

  Future<void> pickAndSendImage() async {
    final xfile = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (xfile == null) return;
    state.uploadingMedia.value = true;
    try {
      await _svc.sendImage(_convId, xfile.path);
      reload();
      _scrollToBottom(animate: true);
    } catch (e) {
      LogUtil.e('[ChatLogic] sendImage: $e');
      Get.snackbar(gL10n.imImageSendFailed, '',
          snackPosition: SnackPosition.TOP);
    } finally {
      state.uploadingMedia.value = false;
    }
  }

  // ── 语音录制 ──────────────────────────────────────────────────────────────

  Future<void> startRecording() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      Get.snackbar(gL10n.imMicPermission, '',
          snackPosition: SnackPosition.TOP);
      return;
    }
    final dir = await getTemporaryDirectory();
    _recPath  = '${dir.path}/rec_${DateTime.now().millisecondsSinceEpoch}.aac';
    _recSecs  = 0;
    state.recSeconds.value = 0;

    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 64000),
      path: _recPath!,
    );
    state.recording.value = true;

    // Timer-based tick: properly tracked and cancellable
    _recTimer?.cancel();
    _recTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!state.recording.value) { _recTimer?.cancel(); return; }
      _recSecs++;
      state.recSeconds.value = _recSecs;
    });
  }

  Future<void> stopRecording() async {
    if (!state.recording.value) return;
    state.recording.value = false;
    _recTimer?.cancel();
    final path = await _recorder.stop();
    if (path == null || _recSecs < 1) return;

    state.uploadingMedia.value = true;
    try {
      await _svc.sendVoice(_convId, path, _recSecs);
      reload();
      _scrollToBottom(animate: true);
    } catch (e) {
      LogUtil.e('[ChatLogic] sendVoice: $e');
      Get.snackbar(gL10n.imVoiceSendFailed, '',
          snackPosition: SnackPosition.TOP);
    } finally {
      state.uploadingMedia.value = false;
    }
  }

  Future<void> cancelRecording() async {
    state.recording.value = false;
    _recTimer?.cancel();
    await _recorder.cancel();
  }

  // ── 语音通话 ──────────────────────────────────────────────────────────────

  void startVoiceCall() {
    Get.find<VoiceCallLogic>().startCall(
      peerType: state.peerType.value,
      peerId:   state.peerId.value,
      name:     state.conversationName.value,
    );
    if (Get.currentRoute != AppRoutes.voiceCall) Get.toNamed(AppRoutes.voiceCall);
  }

  // ── 发送位置 ──────────────────────────────────────────────────────────────

  Future<void> sendLocation(double lat, double lng, String address) async {
    try {
      await _svc.sendLocation(_convId, lat, lng, address);
      reload();
      _scrollToBottom(animate: true);
    } catch (e) {
      LogUtil.e('[ChatLogic] sendLocation: $e');
      Get.snackbar(gL10n.imSendFailed, '',
          snackPosition: SnackPosition.TOP);
    }
  }

  // ── 加载更多 ──────────────────────────────────────────────────────────────

  Future<void> loadMore() async {
    if (state.messages.isEmpty) return;
    final before = int.tryParse(state.messages.first.id);
    if (before == null) return;
    await _svc.loadHistory(_convId, beforeMsgId: before);
    reload();
  }

  void _scrollToBottom({bool animate = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollCtrl.hasClients) return;
      final target = scrollCtrl.position.maxScrollExtent;
      if (animate) {
        scrollCtrl.animateTo(target,
          duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
      } else {
        scrollCtrl.jumpTo(target);
      }
    });
  }
}
