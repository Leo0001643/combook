import 'dart:async';
import 'dart:convert';
import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;
import 'package:get/get.dart';
import '../../../core/services/im_service.dart';
import '../../../core/auth/auth_controller.dart';
import '../models/im_models.dart';

// ── IM 信令命令码（镜像 ImCmd.java）──────────────────────────────────────────
abstract class _Cmd {
  static const callInvite = 5001;
  static const callAccept = 5002;
  static const callReject = 5003;
  static const callIce    = 5004;
  static const callSdp    = 5005;
  static const callEnd    = 5006;
  static const callBusy   = 5007;
}

/// 语音通话 GetxController（全局 permanent，与 ImService 共生命周期）
///
/// 设计：
///  - 单实例，由 main.dart 注册（permanent: true）
///  - 通过 ImService.registerSignalCallback 接收信令
///  - 状态用 Rx，VoiceCallPage 通过 Obx 响应
class VoiceCallLogic extends GetxController {
  static VoiceCallLogic get to => Get.find();

  // ── 状态 ─────────────────────────────────────────────────────────────────
  final callState = CallState.idle.obs;
  final peerName  = ''.obs;
  final muted     = false.obs;
  final duration  = 0.obs;   // 通话秒数

  // ── 私有字段 ──────────────────────────────────────────────────────────────
  String   _callId    = '';
  String   _peerType  = '';
  int      _peerId    = 0;
  Timer?   _timer;
  bool     _remoteDescSet = false;
  final _pendingIce = <Map<String, dynamic>>[];

  webrtc.RTCPeerConnection? _pc;
  webrtc.MediaStream?       _localStream;

  String get _myType => 'tech';
  int    get _myId   => AuthController.to.userId.value ?? 0;
  String get _myName => AuthController.to.nickname.value ?? '技师';

  static const _iceServers = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
    ]
  };

  // ── 生命周期 ──────────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    ImService.to.registerSignalCallback(_onSignal);
  }

  @override
  void onClose() {
    ImService.to.unregisterSignalCallback();
    _cleanup();
    super.onClose();
  }

  // ── 公开 API ──────────────────────────────────────────────────────────────

  void startCall({required String peerType, required int peerId, required String name}) {
    if (callState.value != CallState.idle) return;
    _callId   = 'call-${DateTime.now().millisecondsSinceEpoch}';
    _peerType = peerType;
    _peerId   = peerId;
    peerName.value = name;

    callState.value = CallState.calling;
    _sendSignal(_Cmd.callInvite);
    _createPc(isOffer: true);
    Get.toNamed('/im/voice-call');
  }

  void acceptCall() async {
    if (callState.value != CallState.incoming) return;
    callState.value = CallState.connecting;
    _sendSignal(_Cmd.callAccept);
    await _createPc(isOffer: false);
  }

  void rejectCall() {
    if (callState.value != CallState.incoming) return;
    _sendSignal(_Cmd.callReject);
    _cleanup(next: CallState.idle);
    Get.back();
  }

  void hangUp() {
    if (callState.value == CallState.idle) return;
    _sendSignal(_Cmd.callEnd);
    _cleanup(next: CallState.ended);
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (callState.value == CallState.ended) {
        callState.value = CallState.idle;
        if (Get.currentRoute == '/im/voice-call') Get.back();
      }
    });
  }

  void toggleMute() {
    _localStream?.getAudioTracks().forEach((t) => t.enabled = !t.enabled);
    muted.value = !muted.value;
  }

  // ── 信令接收 ──────────────────────────────────────────────────────────────

  Future<void> _onSignal(int cmd, CallSignal signal) async {
    switch (cmd) {
      case _Cmd.callInvite:
        if (callState.value != CallState.idle) {
          _sendSignalTo(signal.fromType, signal.fromId, _Cmd.callBusy, callId: signal.callId);
          return;
        }
        _callId   = signal.callId;
        _peerType = signal.fromType;
        _peerId   = signal.fromId;
        peerName.value = signal.fromName ?? '对方';
        callState.value = CallState.incoming;
        Get.toNamed('/im/voice-call');

      case _Cmd.callAccept:
        if (callState.value != CallState.calling || _pc == null) return;
        callState.value = CallState.connecting;
        await _addLocalStream();
        final offer = await _pc!.createOffer({'offerToReceiveAudio': true});
        await _pc!.setLocalDescription(offer);
        _sendSignal(_Cmd.callSdp, sdp: offer.sdp, sdpType: 'offer');

      case _Cmd.callSdp:
        if (_pc == null || signal.sdp == null || signal.sdpType == null) return;
        final desc = webrtc.RTCSessionDescription(signal.sdp, signal.sdpType);
        await _pc!.setRemoteDescription(desc);
        _remoteDescSet = true;
        for (final c in _pendingIce) {
          await _pc!.addCandidate(webrtc.RTCIceCandidate(
            c['candidate'] as String?, c['sdpMid'] as String?, c['sdpMLineIndex'] as int?));
        }
        _pendingIce.clear();
        if (signal.sdpType == 'offer') {
          final answer = await _pc!.createAnswer({});
          await _pc!.setLocalDescription(answer);
          _sendSignal(_Cmd.callSdp, sdp: answer.sdp, sdpType: 'answer');
        }

      case _Cmd.callIce:
        if (signal.candidate == null) return;
        final candJson = jsonDecode(signal.candidate!) as Map<String, dynamic>;
        if (_remoteDescSet && _pc != null) {
          await _pc!.addCandidate(webrtc.RTCIceCandidate(
            candJson['candidate'] as String?,
            candJson['sdpMid']    as String?,
            candJson['sdpMLineIndex'] as int?,
          ));
        } else {
          _pendingIce.add(candJson);
        }

      case _Cmd.callReject:
      case _Cmd.callEnd:
      case _Cmd.callBusy:
        _cleanup(next: CallState.ended);
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (callState.value == CallState.ended) callState.value = CallState.idle;
        });
    }
  }

  // ── WebRTC 核心 ───────────────────────────────────────────────────────────

  Future<webrtc.RTCPeerConnection> _createPc({required bool isOffer}) async {
    _pc = await webrtc.createPeerConnection(_iceServers);

    _pc!.onIceCandidate = (candidate) {
      if (candidate.candidate != null) {
        _sendSignal(_Cmd.callIce, candidate: jsonEncode({
          'candidate':     candidate.candidate,
          'sdpMid':        candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        }));
      }
    };

    _pc!.onConnectionState = (state) {
      if (state == webrtc.RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        callState.value = CallState.active;
        _startTimer();
      } else if (
        state == webrtc.RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
        state == webrtc.RTCPeerConnectionState.RTCPeerConnectionStateFailed    ||
        state == webrtc.RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
        if (callState.value != CallState.idle && callState.value != CallState.ended) {
          _cleanup(next: CallState.ended);
        }
      }
    };

    _pc!.onTrack = (_) {}; // 远端音频由 WebRTC 内部自动路由

    if (!isOffer) await _addLocalStream();
    return _pc!;
  }

  Future<void> _addLocalStream() async {
    _localStream = await webrtc.navigator.mediaDevices.getUserMedia({'audio': true, 'video': false});
    _localStream!.getTracks().forEach((t) => _pc!.addTrack(t, _localStream!));
  }

  // ── 辅助 ──────────────────────────────────────────────────────────────────

  void _sendSignal(int cmd, {String? sdp, String? sdpType, String? candidate}) {
    final signal = CallSignal(
      callId:     _callId,
      targetType: _peerType,
      targetId:   _peerId,
      fromType:   _myType,
      fromId:     _myId,
      fromName:   _myName,
      sdp:        sdp,
      sdpType:    sdpType,
      candidate:  candidate,
    );
    ImService.to.sendSignal(cmd, signal);
  }

  void _sendSignalTo(String type, int id, int cmd, {required String callId}) {
    ImService.to.sendSignal(cmd, CallSignal(
      callId:     callId,
      targetType: type, targetId: id,
      fromType:   _myType, fromId: _myId,
    ));
  }

  void _startTimer() {
    _timer?.cancel();
    duration.value = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => duration.value++);
  }

  void _cleanup({CallState next = CallState.idle}) {
    _timer?.cancel();
    _localStream?.getTracks().forEach((t) => t.stop());
    _localStream?.dispose();
    _localStream = null;
    _pc?.close();
    _pc = null;
    _remoteDescSet = false;
    _pendingIce.clear();
    duration.value  = 0;
    muted.value     = false;
    callState.value = next;
  }
}
