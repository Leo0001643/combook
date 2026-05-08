import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../_shared/im_theme.dart';
import '../_shared/im_avatar.dart';
import '../_shared/im_time_util.dart';
import '../models/im_models.dart';
import 'voice_call_logic.dart';

/// 语音通话页（来电弹窗 / 拨出等待 / 通话中）
class VoiceCallPage extends StatelessWidget {
  const VoiceCallPage({super.key});

  @override
  Widget build(BuildContext context) {
    final vc = Get.find<VoiceCallLogic>();
    return Scaffold(
      backgroundColor: const Color(0xFF1A2533),
      body: SafeArea(child: Obx(() {
        switch (vc.callState.value) {
          case CallState.incoming:    return _IncomingView(vc: vc);
          case CallState.calling:
          case CallState.connecting:  return _CallingView(vc: vc);
          case CallState.active:      return _ActiveView(vc: vc);
          case CallState.ended:       return _EndedView(vc: vc);
          default:                    return const SizedBox.shrink();
        }
      })),
    );
  }
}

// ── 来电视图 ──────────────────────────────────────────────────────────────────

class _IncomingView extends StatelessWidget {
  final VoiceCallLogic vc;
  const _IncomingView({required this.vc});

  @override
  Widget build(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      const SizedBox(height: 60),
      // 头像 + 来电信息
      Column(children: [
        _PulsingAvatar(name: vc.peerName.value),
        const SizedBox(height: 24),
        Text(vc.peerName.value,
          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        const Text('语音通话邀请',
          style: TextStyle(color: Colors.white60, fontSize: 15)),
      ]),
      // 操作按钮
      Padding(
        padding: const EdgeInsets.only(bottom: 60),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _CallButton(icon: Icons.call_end, label: '拒绝', color: ImTheme.danger, onTap: vc.rejectCall),
            _CallButton(icon: Icons.call,     label: '接听', color: ImTheme.accent, onTap: vc.acceptCall),
          ],
        ),
      ),
    ],
  );
}

// ── 拨出 / 连接中视图 ─────────────────────────────────────────────────────────

class _CallingView extends StatelessWidget {
  final VoiceCallLogic vc;
  const _CallingView({required this.vc});

  @override
  Widget build(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      const SizedBox(height: 60),
      Column(children: [
        _PulsingAvatar(name: vc.peerName.value),
        const SizedBox(height: 24),
        Text(vc.peerName.value,
          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Obx(() => Text(
          vc.callState.value == CallState.connecting ? '连接中...' : '等待接听...',
          style: const TextStyle(color: Colors.white60, fontSize: 15),
        )),
      ]),
      Padding(
        padding: const EdgeInsets.only(bottom: 60),
        child: _CallButton(icon: Icons.call_end, label: '取消', color: ImTheme.danger, onTap: vc.hangUp),
      ),
    ],
  );
}

// ── 通话中视图 ────────────────────────────────────────────────────────────────

class _ActiveView extends StatelessWidget {
  final VoiceCallLogic vc;
  const _ActiveView({required this.vc});

  @override
  Widget build(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      const SizedBox(height: 60),
      Column(children: [
        ImAvatar(name: vc.peerName.value, size: 96),
        const SizedBox(height: 24),
        Text(vc.peerName.value,
          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        // 通话时长
        Obx(() => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 8, height: 8,
              decoration: const BoxDecoration(color: ImTheme.accent, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(
              ImTimeUtil.fmtDuration(vc.duration.value),
              style: const TextStyle(color: ImTheme.accent, fontSize: 15),
            ),
          ],
        )),
      ]),
      // 操作面板
      Padding(
        padding: const EdgeInsets.only(bottom: 60),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // 静音
            Obx(() => _CallButton(
              icon:  vc.muted.value ? Icons.mic_off : Icons.mic,
              label: vc.muted.value ? '取消静音' : '静音',
              color: vc.muted.value ? Colors.orange : const Color(0xFF2A3942),
              onTap: vc.toggleMute,
            )),
            // 挂断
            _CallButton(icon: Icons.call_end, label: '挂断', color: ImTheme.danger, onTap: vc.hangUp),
          ],
        ),
      ),
    ],
  );
}

// ── 通话结束视图 ──────────────────────────────────────────────────────────────

class _EndedView extends StatelessWidget {
  final VoiceCallLogic vc;
  const _EndedView({required this.vc});

  @override
  Widget build(BuildContext context) => const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.call_end, color: ImTheme.danger, size: 64),
        SizedBox(height: 16),
        Text('通话已结束', style: TextStyle(color: Colors.white70, fontSize: 16)),
      ],
    ),
  );
}

// ── 公共组件 ──────────────────────────────────────────────────────────────────

/// 带脉冲波纹的头像
class _PulsingAvatar extends StatefulWidget {
  final String name;
  const _PulsingAvatar({required this.name});

  @override
  State<_PulsingAvatar> createState() => _PulsingAvatarState();
}

class _PulsingAvatarState extends State<_PulsingAvatar> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 160, height: 160,
    child: Stack(alignment: Alignment.center, children: [
      // 波纹
      ...List.generate(3, (i) => AnimatedBuilder(
        animation: _anim,
        builder: (_, __) {
          final v = (_anim.value - i * 0.3).clamp(0.0, 1.0);
          return Transform.scale(
            scale: 1 + v * 0.6,
            child: Opacity(
              opacity: (1 - v) * 0.4,
              child: Container(
                width: 96, height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: ImTheme.accent, width: 1.5),
                ),
              ),
            ),
          );
        },
      )),
      ImAvatar(name: widget.name, size: 96),
    ]),
  );
}

/// 圆形操作按钮
class _CallButton extends StatelessWidget {
  final IconData icon;
  final String   label;
  final Color    color;
  final VoidCallback onTap;
  const _CallButton({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 64, height: 64,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4))]),
        child: Icon(icon, color: Colors.white, size: 28),
      ),
      const SizedBox(height: 8),
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
    ]),
  );
}
