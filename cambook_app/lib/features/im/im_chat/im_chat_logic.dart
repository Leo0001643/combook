import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/services/im_service.dart';
import '../../../core/auth/auth_controller.dart';
import '../api/im_api.dart';
import '../models/im_models.dart';

class ImChatLogic extends GetxController {
  // ── 参数（由路由注参） ────────────────────────────────────────────────────
  late final int    conversationId;
  late final String peerName;
  late final String peerType;
  late final int    peerId;

  // ── 状态 ──────────────────────────────────────────────────────────────────
  final messages     = <ImMessage>[].obs;
  final sending      = false.obs;
  final uploadingImg = false.obs;
  final recording    = false.obs;
  final recSeconds   = 0.obs;
  final loadingMore  = false.obs;

  final inputCtrl  = TextEditingController();
  final scrollCtrl = ScrollController();

  final _recorder  = AudioRecorder();
  String? _recPath;
  int     _recSecs = 0;   // ref mirror（避免 closure 陈旧值）

  // ── 当前用户身份 ──────────────────────────────────────────────────────────
  String get myType => 'tech';   // 技师端固定
  int    get myId   => AuthController.to.userId.value ?? 0;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    conversationId = args['conversationId'] as int? ?? 0;
    peerName       = args['peerName']       as String? ?? '对方';
    peerType       = args['peerType']       as String? ?? 'member';
    peerId         = args['peerId']         as int?    ?? 0;

    // 加载历史 + 注册 WS 回调
    _init();
  }

  @override
  void onClose() {
    ImService.to.unregisterMessageCallback();
    ImService.to.clearUnread(conversationId);
    inputCtrl.dispose();
    scrollCtrl.dispose();
    _recorder.dispose();
    super.onClose();
  }

  // ── 初始化 ────────────────────────────────────────────────────────────────

  Future<void> _init() async {
    ImService.to.registerMessageCallback(_onNewMessage);
    await ImService.to.loadHistory(conversationId);
    final cached = ImService.to.messages[conversationId] ?? [];
    messages.assignAll(cached);
    ImService.to.clearUnread(conversationId);
    _scrollToBottom();
  }

  void _onNewMessage(ImMessage msg) {
    if (msg.conversationId != conversationId) return;
    if (!messages.any((m) => m.msgId == msg.msgId)) {
      messages.add(msg);
      _scrollToBottom(animate: true);
    }
  }

  // ── 发送文本 ──────────────────────────────────────────────────────────────

  Future<void> sendText() async {
    final text = inputCtrl.text.trim();
    if (text.isEmpty || sending.value) return;
    inputCtrl.clear();
    sending.value = true;

    final tempId  = -DateTime.now().millisecondsSinceEpoch;
    final optimistic = ImMessage(
      msgId:          tempId,
      conversationId: conversationId,
      senderType:     myType, senderId: myId,
      isGroup: 0, msgType: 1, content: text,
      status: 1, createTime: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      isOptimistic: true,
    );
    messages.add(optimistic);
    ImService.to.appendOptimistic(optimistic);
    _scrollToBottom(animate: true);

    try {
      final realId = await ImApi.sendMessage(
        receiverType: peerType, receiverId: peerId,
        msgType: 1, content: text,
        clientMsgId: 'tmp-$tempId',
      );
      final idx = messages.indexWhere((m) => m.msgId == tempId);
      if (idx >= 0) messages[idx] = messages[idx].copyWith(status: 1);
      ImService.to.confirmOptimistic(conversationId, tempId, realId);
    } catch (_) {
      messages.removeWhere((m) => m.msgId == tempId);
      Get.snackbar('发送失败', '请检查网络连接', snackPosition: SnackPosition.TOP);
    } finally {
      sending.value = false;
    }
  }

  // ── 发送图片 ──────────────────────────────────────────────────────────────

  Future<void> pickAndSendImage() async {
    final xfile = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (xfile == null) return;
    uploadingImg.value = true;
    try {
      final url = await ImApi.uploadImage(xfile.path);
      await _sendMedia(url, 2);
    } catch (_) {
      Get.snackbar('图片发送失败', '', snackPosition: SnackPosition.TOP);
    } finally {
      uploadingImg.value = false;
    }
  }

  // ── 语音录制 ──────────────────────────────────────────────────────────────

  Future<void> startRecording() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      Get.snackbar('需要麦克风权限', '', snackPosition: SnackPosition.TOP);
      return;
    }
    final dir  = await getTemporaryDirectory();
    _recPath   = '${dir.path}/rec_${DateTime.now().millisecondsSinceEpoch}.aac';
    _recSecs   = 0;
    recSeconds.value = 0;

    await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 64000), path: _recPath!);
    recording.value = true;

    // 计时
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!recording.value) return false;
      _recSecs++;
      recSeconds.value = _recSecs;
      return true;
    });
  }

  Future<void> stopRecording() async {
    if (!recording.value) return;
    recording.value = false;
    final path = await _recorder.stop();
    if (path == null || _recSecs < 1) return;   // 忽略过短录音

    try {
      final url = await ImApi.uploadVoice(path);
      final content = '$url|$_recSecs';
      await _sendMedia(content, 3, previewContent: url);
    } catch (_) {
      Get.snackbar('语音发送失败', '', snackPosition: SnackPosition.TOP);
    }
  }

  Future<void> cancelRecording() async {
    recording.value = false;
    await _recorder.cancel();
  }

  // ── 加载更多历史 ──────────────────────────────────────────────────────────

  Future<void> loadMore() async {
    if (loadingMore.value || messages.isEmpty) return;
    loadingMore.value = true;
    final before = messages.first.msgId;
    try {
      await ImService.to.loadMore(conversationId);
      final updated = ImService.to.messages[conversationId] ?? [];
      messages.assignAll(updated);
      if (updated.isNotEmpty && before > 0) {
        final newIdx = updated.indexWhere((m) => m.msgId == before);
        if (newIdx > 0 && scrollCtrl.hasClients) {
          final offset = (newIdx / updated.length) * scrollCtrl.position.maxScrollExtent;
          scrollCtrl.jumpTo(offset);
        }
      }
    } finally {
      loadingMore.value = false;
    }
  }

  // ── 私有辅助 ──────────────────────────────────────────────────────────────

  Future<void> _sendMedia(String content, int msgType, {String? previewContent}) async {
    final realId = await ImApi.sendMessage(
      receiverType: peerType, receiverId: peerId,
      msgType: msgType, content: content,
    );
    final msg = ImMessage(
      msgId:          realId,
      conversationId: conversationId,
      senderType:     myType, senderId: myId,
      isGroup: 0, msgType: msgType, content: content,
      status: 1, createTime: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
    messages.add(msg);
    ImService.to.appendOptimistic(msg);
    _scrollToBottom(animate: true);
  }

  void _scrollToBottom({bool animate = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollCtrl.hasClients) return;
      final target = scrollCtrl.position.maxScrollExtent;
      if (animate) {
        scrollCtrl.animateTo(target, duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
      } else {
        scrollCtrl.jumpTo(target);
      }
    });
  }
}
