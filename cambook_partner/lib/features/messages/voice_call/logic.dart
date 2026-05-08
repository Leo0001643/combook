import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;
import 'package:get/get.dart';

import '../../../core/i18n/l10n_ext.dart';
import '../../../core/services/im_ws_service.dart';
import '../../../core/services/user_service.dart';
import '../../../core/utils/audio_util.dart';
import '../../../core/utils/log_util.dart';

// ── 信令命令码 ────────────────────────────────────────────────────────────────
abstract class _Cmd {
  static const callInvite = 5001;
  static const callAccept = 5002;
  static const callReject = 5003;
  static const callIce    = 5004;
  static const callSdp    = 5005;
  static const callEnd    = 5006;
  static const callBusy   = 5007;
}

enum VcState { idle, calling, incoming, connecting, active, ended }

/// WebRTC 语音通话控制器（全局 permanent）
class VoiceCallLogic extends GetxController {
  static VoiceCallLogic get to => Get.find();

  final vcState   = VcState.idle.obs;
  final peerName  = ''.obs;
  final muted     = false.obs;
  final duration  = 0.obs;

  String _callId    = '';
  String _peerType  = '';
  int    _peerId    = 0;
  Timer? _timer;
  bool   _remoteSet = false;
  final  _pendingIce = <Map<String, dynamic>>[];

  webrtc.RTCPeerConnection? _pc;
  webrtc.MediaStream?       _local;

  static const _ice = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
    ],
  };

  /// Must match the JWT claim `userType` used during IM authentication.
  String get _myType => 'technician';
  int    get _myId   => Get.find<UserService>().technician.value?.id ?? 0;
  String get _myName {
    final nick = Get.find<UserService>().technician.value?.nickname;
    if (nick != null && nick.isNotEmpty) return nick;
    try { return gL10n.workbenchTitle; } catch (_) { return 'Tech'; }
  }

  // ── 生命周期 ──────────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    ImWsService.to.registerSignalCallback(_onSignal);
  }

  @override
  void onClose() {
    ImWsService.to.unregisterSignalCallback();
    _cleanup();
    super.onClose();
  }

  // ── 公开 API ──────────────────────────────────────────────────────────────

  void startCall({required String peerType, required int peerId, required String name}) {
    if (vcState.value != VcState.idle) return;
    _callId   = 'c-${DateTime.now().millisecondsSinceEpoch}';
    _peerType = peerType;
    _peerId   = peerId;
    peerName.value = name;
    vcState.value  = VcState.calling;
    _sendSig(_Cmd.callInvite);
    _createPc(isOffer: true);
  }

  void acceptCall() {
    if (vcState.value != VcState.incoming) return;
    _ringStop();
    vcState.value = VcState.connecting;
    _sendSig(_Cmd.callAccept);
    _createPc(isOffer: false);
  }

  void rejectCall() {
    if (vcState.value != VcState.incoming) return;
    _ringStop();
    _sendSig(_Cmd.callReject);
    _cleanup();
    Get.back();
  }

  void hangUp() {
    if (vcState.value == VcState.idle) return;
    _sendSig(_Cmd.callEnd);
    _cleanup(next: VcState.ended);
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (vcState.value == VcState.ended) {
        vcState.value = VcState.idle;
        if (Get.currentRoute == '/voice-call') Get.back();
      }
    });
  }

  void toggleMute() {
    _local?.getAudioTracks().forEach((t) => t.enabled = !t.enabled);
    muted.value = !muted.value;
  }

  // ── 信令处理 ──────────────────────────────────────────────────────────────

  Future<void> _onSignal(int cmd, Map<String, dynamic> body) async {
    LogUtil.i('[VC] signal cmd=$cmd body=${body.keys.toList()}');
    switch (cmd) {
      case _Cmd.callInvite:
        if (vcState.value != VcState.idle) {
          _sendSigTo(
            body['fromType'] as String,
            (body['fromId'] as num).toInt(),
            _Cmd.callBusy,
            body['callId'] as String,
          );
          return;
        }
        _callId   = body['callId']   as String;
        _peerType = body['fromType'] as String;
        _peerId   = (body['fromId'] as num).toInt();
        peerName.value  = (body['fromName'] as String?) ?? '';
        vcState.value   = VcState.incoming;
        _ringStart();
        if (Get.currentRoute != '/voice-call') Get.toNamed('/voice-call');

      case _Cmd.callAccept:
        if (vcState.value != VcState.calling || _pc == null) return;
        vcState.value = VcState.connecting;
        await _addLocal();
        final offer = await _pc!.createOffer({'offerToReceiveAudio': true});
        await _pc!.setLocalDescription(offer);
        _sendSig(_Cmd.callSdp, sdp: offer.sdp, sdpType: 'offer');

      case _Cmd.callSdp:
        if (_pc == null) return;
        final desc = webrtc.RTCSessionDescription(
            body['sdp'] as String?, body['sdpType'] as String?);
        await _pc!.setRemoteDescription(desc);
        _remoteSet = true;
        for (final c in _pendingIce) {
          await _pc!.addCandidate(webrtc.RTCIceCandidate(
            c['candidate'] as String?,
            c['sdpMid'] as String?,
            (c['sdpMLineIndex'] as num?)?.toInt(),
          ));
        }
        _pendingIce.clear();
        if (body['sdpType'] == 'offer') {
          final ans = await _pc!.createAnswer({});
          await _pc!.setLocalDescription(ans);
          _sendSig(_Cmd.callSdp, sdp: ans.sdp, sdpType: 'answer');
        }

      case _Cmd.callIce:
        final cand = body['candidate'];
        if (cand == null) return;
        final j = jsonDecode(cand as String) as Map<String, dynamic>;
        final ice = webrtc.RTCIceCandidate(
          j['candidate'] as String?,
          j['sdpMid'] as String?,
          (j['sdpMLineIndex'] as num?)?.toInt(),
        );
        if (_remoteSet && _pc != null) {
          await _pc!.addCandidate(ice);
        } else {
          _pendingIce.add(j);
        }

      case _Cmd.callReject:
      case _Cmd.callEnd:
      case _Cmd.callBusy:
        _ringStop();
        _cleanup(next: VcState.ended);
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (vcState.value == VcState.ended) vcState.value = VcState.idle;
        });
    }
  }

  // ── WebRTC ────────────────────────────────────────────────────────────────

  Future<void> _createPc({required bool isOffer}) async {
    _pc = await webrtc.createPeerConnection(_ice);

    _pc!.onIceCandidate = (c) {
      if (c.candidate != null) {
        _sendSig(_Cmd.callIce, candidate: jsonEncode({
          'candidate': c.candidate, 'sdpMid': c.sdpMid, 'sdpMLineIndex': c.sdpMLineIndex,
        }));
      }
    };

    _pc!.onConnectionState = (state) {
      if (state == webrtc.RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        vcState.value = VcState.active;
        _startTimer();
      } else if (
        state == webrtc.RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
        state == webrtc.RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
        if (vcState.value != VcState.idle && vcState.value != VcState.ended) {
          _cleanup(next: VcState.ended);
        }
      }
    };

    if (!isOffer) await _addLocal();
  }

  Future<void> _addLocal() async {
    _local = await webrtc.navigator.mediaDevices
        .getUserMedia({'audio': true, 'video': false});
    _local!.getTracks().forEach((t) => _pc!.addTrack(t, _local!));
  }

  // ── 辅助 ──────────────────────────────────────────────────────────────────

  void _sendSig(int cmd, {String? sdp, String? sdpType, String? candidate}) {
    ImWsService.to.sendSignalPacket(cmd, {
      'callId': _callId, 'targetType': _peerType, 'targetId': _peerId,
      'fromType': _myType, 'fromId': _myId, 'fromName': _myName,
      if (sdp       != null) 'sdp':       sdp,
      if (sdpType   != null) 'sdpType':   sdpType,
      if (candidate != null) 'candidate': candidate,
    });
  }

  void _sendSigTo(String type, int id, int cmd, String callId) {
    ImWsService.to.sendSignalPacket(cmd, {
      'callId': callId, 'targetType': type, 'targetId': id,
      'fromType': _myType, 'fromId': _myId,
    });
  }

  void _startTimer() {
    _timer?.cancel();
    duration.value = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => duration.value++);
  }

  // ── 来电振铃 ──────────────────────────────────────────────────────────────

  Timer? _ringTimer;

  /// Pulsing vibration + alert tone while call is incoming.
  void _ringStart() {
    _ringStop();
    AudioUtil.playAlert();
    HapticFeedback.heavyImpact();
    _ringTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      AudioUtil.playAlert();
      HapticFeedback.heavyImpact();
    });
  }

  void _ringStop() {
    _ringTimer?.cancel();
    _ringTimer = null;
  }

  void _cleanup({VcState next = VcState.idle}) {
    _ringStop();
    _timer?.cancel();
    _local?.getTracks().forEach((t) => t.stop());
    _local?.dispose();
    _local = null;
    _pc?.close();
    _pc = null;
    _remoteSet = false;
    _pendingIce.clear();
    duration.value = 0;
    muted.value    = false;
    vcState.value  = next;
  }
}
