import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/extensions/theme_ext.dart';
import '../../../core/i18n/l10n_ext.dart';
import 'logic.dart';

// ── Color tokens (WhatsApp call screen) ──────────────────────────────────────
abstract class _C {
  static const bg      = Color(0xFF0B141A);
  static const text    = Color(0xFFE9EDEF);
  static const sub     = Color(0xFF8696A0);
  static const green   = Color(0xFF00A884);
  static const red     = Color(0xFFFF3B30);
  static const mute    = Color(0xFF3A4751);
}

/// Voice call page — WhatsApp call style, fully localised.
class VoiceCallPage extends StatefulWidget {
  const VoiceCallPage({super.key});
  @override State<VoiceCallPage> createState() => _VoiceCallPageState();
}

class _VoiceCallPageState extends State<VoiceCallPage> {
  late final VoiceCallLogic _vc;

  @override
  void initState() {
    super.initState();
    _vc = Get.find<VoiceCallLogic>();
    final args = Get.arguments as Map<String, dynamic>?;
    if (args != null && _vc.vcState.value == VcState.idle) {
      _vc.startCall(
        peerType: args['peerType'] as String? ?? 'member',
        peerId:   args['peerId']   as int?    ?? 0,
        name:     args['peerName'] as String? ?? '',
      );
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, _) {
      if (didPop) return;
      if (_vc.vcState.value == VcState.idle ||
          _vc.vcState.value == VcState.ended) {
        Get.back();
        return;
      }
      _vc.hangUp();
    },
    child: Scaffold(
      backgroundColor: _C.bg,
      body: SafeArea(
        child: Obx(() => AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: switch (_vc.vcState.value) {
            VcState.incoming   => _IncomingView(vc: _vc, key: const ValueKey('in')),
            VcState.calling ||
            VcState.connecting => _CallingView(vc: _vc, key: const ValueKey('calling')),
            VcState.active     => _ActiveView(vc: _vc, key: const ValueKey('active')),
            VcState.ended      => _EndedView(vc: _vc, key: const ValueKey('ended')),
            _                  => const SizedBox.shrink(),
          },
        )),
      ),
    ),
  );
}

// ── Shared layout helper ──────────────────────────────────────────────────────

class _CallLayout extends StatelessWidget {
  final Widget avatar;
  final String name;
  final String subtitle;
  final Color subtitleColor;
  final Widget bottomControls;

  const _CallLayout({
    required this.avatar, required this.name, required this.subtitle,
    this.subtitleColor = _C.sub,
    required this.bottomControls,
  });

  @override
  Widget build(BuildContext context) => Column(
    children: [
      // ── Top spacer + background gradient ──────────────────────────────────
      Expanded(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            avatar,
            const SizedBox(height: 28),
            Text(name,
              style: const TextStyle(
                color: _C.text, fontSize: 26, fontWeight: FontWeight.w700,
                letterSpacing: -0.3),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(subtitle,
              style: TextStyle(
                color: subtitleColor, fontSize: 15, fontWeight: FontWeight.w400),
            ),
          ],
        ),
      ),
      // ── Controls ─────────────────────────────────────────────────────────
      Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 48),
        child: bottomControls,
      ),
    ],
  );
}

// ── Incoming Call ─────────────────────────────────────────────────────────────

class _IncomingView extends StatelessWidget {
  final VoiceCallLogic vc;
  const _IncomingView({required this.vc, super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return _CallLayout(
      avatar:    _PulsingAvatar(name: vc.peerName.value),
      name:      vc.peerName.value,
      subtitle:  l.imVoiceInvite,
      subtitleColor: _C.green,
      bottomControls: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _RoundBtn(
            icon: Icons.call_end,
            label: l.imReject,
            color: _C.red,
            onTap: vc.rejectCall,
          ),
          _RoundBtn(
            icon: Icons.call,
            label: l.imAnswer,
            color: _C.green,
            onTap: vc.acceptCall,
          ),
        ],
      ),
    );
  }
}

// ── Outgoing / Connecting ─────────────────────────────────────────────────────

class _CallingView extends StatelessWidget {
  final VoiceCallLogic vc;
  const _CallingView({required this.vc, super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Obx(() => _CallLayout(
      avatar:   _PulsingAvatar(name: vc.peerName.value),
      name:     vc.peerName.value,
      subtitle: vc.vcState.value == VcState.connecting
          ? l.imConnecting : l.imWaiting,
      bottomControls: Center(
        child: _RoundBtn(
          icon: Icons.call_end,
          label: l.imCancelCall,
          color: _C.red,
          onTap: vc.hangUp,
        ),
      ),
    ));
  }
}

// ── Active Call ───────────────────────────────────────────────────────────────

class _ActiveView extends StatelessWidget {
  final VoiceCallLogic vc;
  const _ActiveView({required this.vc, super.key});

  String _fmt(int s) {
    final m = s ~/ 60, sec = s % 60;
    return '${m.toString().padLeft(2,'0')}:${sec.toString().padLeft(2,'0')}';
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Obx(() => _CallLayout(
      avatar: _StaticAvatar(name: vc.peerName.value, size: 100),
      name:   vc.peerName.value,
      subtitle: _fmt(vc.duration.value),
      subtitleColor: _C.green,
      bottomControls: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _RoundBtn(
            icon:  vc.muted.value ? Icons.mic_off_rounded : Icons.mic_rounded,
            label: vc.muted.value ? l.imUnmute : l.imMute,
            color: vc.muted.value ? Colors.orange.shade700 : _C.mute,
            onTap: vc.toggleMute,
          ),
          _RoundBtn(
            icon:  Icons.call_end,
            label: l.imHangUp,
            color: _C.red,
            onTap: vc.hangUp,
          ),
          _RoundBtn(
            icon:  Icons.volume_up_rounded,
            label: '',
            color: _C.mute,
            onTap: () {},
          ),
        ],
      ),
    ));
  }
}

// ── Ended ─────────────────────────────────────────────────────────────────────

class _EndedView extends StatelessWidget {
  final VoiceCallLogic vc;
  const _EndedView({required this.vc, super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            color: _C.red.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.call_end, color: _C.red, size: 36),
        ),
        const SizedBox(height: 20),
        Text(l.imCallEnded,
          style: const TextStyle(color: _C.text, fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Obx(() => Text(
          vc.duration.value > 0
              ? l.imCallEndedDuration(_fmtDur(vc.duration.value))
              : '',
          style: const TextStyle(color: _C.sub, fontSize: 14),
        )),
      ]),
    );
  }

  String _fmtDur(int s) {
    final m = s ~/ 60, sec = s % 60;
    return '${m.toString().padLeft(2,'0')}:${sec.toString().padLeft(2,'0')}';
  }
}

// ── Shared Widgets ────────────────────────────────────────────────────────────

class _StaticAvatar extends StatelessWidget {
  final String name;
  final double size;
  const _StaticAvatar({required this.name, required this.size});

  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [context.primary, context.primary.withValues(alpha: 0.5)],
      ),
    ),
    child: Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(
          color: Colors.white, fontSize: size * 0.38, fontWeight: FontWeight.w700),
      ),
    ),
  );
}

class _PulsingAvatar extends StatefulWidget {
  final String name;
  const _PulsingAvatar({required this.name});
  @override State<_PulsingAvatar> createState() => _PulsingAvatarState();
}

class _PulsingAvatarState extends State<_PulsingAvatar>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 170, height: 170,
    child: Stack(alignment: Alignment.center, children: [
      // Three concentric pulsing rings
      ...List.generate(3, (i) => AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) {
          final v = (_ctrl.value - i * 0.33).clamp(0.0, 1.0);
          return Transform.scale(
            scale: 1 + v * 0.55,
            child: Opacity(
              opacity: (1 - v) * 0.35,
              child: Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: context.primary.withValues(alpha: 0.8),
                    width: 2),
                ),
              ),
            ),
          );
        },
      )),
      _StaticAvatar(name: widget.name, size: 100),
    ]),
  );
}

class _RoundBtn extends StatelessWidget {
  final IconData icon;
  final String   label;
  final Color    color;
  final VoidCallback onTap;
  const _RoundBtn({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 64, height: 64,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 14, offset: const Offset(0, 4))],
        ),
        child: Icon(icon, color: Colors.white, size: 28),
      ),
      if (label.isNotEmpty) ...[
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: _C.sub, fontSize: 12.5)),
      ],
    ]),
  );
}
