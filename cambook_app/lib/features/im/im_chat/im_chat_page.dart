import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:just_audio/just_audio.dart';
import '../models/im_models.dart';
import '../_shared/im_theme.dart';
import '../_shared/im_avatar.dart';
import '../_shared/im_time_util.dart';
import '../voice_call/voice_call_logic.dart';
import 'im_chat_logic.dart';

/// IM 单聊页 — WhatsApp 暗色风格
class ImChatPage extends StatelessWidget {
  const ImChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    final logic = Get.find<ImChatLogic>();
    return Scaffold(
      backgroundColor: ImTheme.bg,
      appBar: _buildAppBar(context, logic),
      body: Column(children: [
        Expanded(child: _MessageList(logic: logic)),
        _InputBar(logic: logic),
      ]),
    );
  }

  AppBar _buildAppBar(BuildContext context, ImChatLogic logic) => AppBar(
    backgroundColor: ImTheme.header,
    elevation: 0,
    leading: IconButton(
      icon: const Icon(Icons.arrow_back, color: ImTheme.textPrimary),
      onPressed: () => Get.back(),
    ),
    title: Row(children: [
      ImAvatar(name: logic.peerName, size: 36),
      const SizedBox(width: 10),
      Expanded(child: Text(
        logic.peerName,
        style: const TextStyle(color: ImTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w600),
        overflow: TextOverflow.ellipsis,
      )),
    ]),
    titleSpacing: 0,
    actions: [
      // 语音通话按钮
      IconButton(
        icon: const Icon(Icons.phone_outlined, color: ImTheme.textSub),
        onPressed: () => _startVoiceCall(logic),
      ),
      IconButton(
        icon: const Icon(Icons.more_vert, color: ImTheme.textSub),
        onPressed: () {},
      ),
    ],
  );

  void _startVoiceCall(ImChatLogic logic) {
    final vc = Get.find<VoiceCallLogic>();
    vc.startCall(
      peerType: logic.peerType,
      peerId:   logic.peerId,
      name:     logic.peerName,
    );
  }
}

// ── 消息列表 ──────────────────────────────────────────────────────────────────

class _MessageList extends StatelessWidget {
  final ImChatLogic logic;
  const _MessageList({required this.logic});

  @override
  Widget build(BuildContext context) => Obx(() {
    final msgs = logic.messages;
    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n is ScrollStartNotification && n.metrics.pixels < 80) logic.loadMore();
        return false;
      },
      child: Stack(children: [
        // 背景
        Positioned.fill(child: Image.asset('assets/images/chat_bg.png', fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(color: ImTheme.bg))),
        ListView.builder(
          controller: logic.scrollCtrl,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          itemCount: msgs.length,
          itemBuilder: (_, i) {
            final msg    = msgs[i];
            final prev   = i > 0 ? msgs[i - 1] : null;
            final showDate = prev == null || !ImTimeUtil.sameDay(
              DateTime.fromMillisecondsSinceEpoch(prev.createTime * 1000),
              DateTime.fromMillisecondsSinceEpoch(msg.createTime * 1000),
            );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (showDate) _DateLabel(ts: msg.createTime),
                _BubbleRow(
                  msg:      msg,
                  isMine:   msg.senderType == logic.myType && msg.senderId == logic.myId,
                  isLast:   i == msgs.length - 1 || msgs[i + 1].senderId != msg.senderId,
                ),
              ],
            );
          },
        ),
        // 加载更多指示器
        Obx(() => logic.loadingMore.value
          ? const Positioned(
              top: 8, left: 0, right: 0,
              child: Center(child: SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: ImTheme.accent))))
          : const SizedBox.shrink()),
      ]),
    );
  });
}

class _DateLabel extends StatelessWidget {
  final int ts;
  const _DateLabel({required this.ts});

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2C34).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(ImTimeUtil.fmtDateLabel(ts),
        style: const TextStyle(color: ImTheme.textMuted, fontSize: 11)),
    ),
  );
}

// ── 气泡行 ────────────────────────────────────────────────────────────────────

class _BubbleRow extends StatelessWidget {
  final ImMessage msg;
  final bool      isMine;
  final bool      isLast;
  const _BubbleRow({required this.msg, required this.isMine, required this.isLast});

  @override
  Widget build(BuildContext context) {
    if (msg.isSystem) return _SystemMsg(content: msg.content);

    final bubble = _Bubble(msg: msg, isMine: isMine, isLast: isLast);
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 6 : 2),
      child: Row(
        mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: isMine
          ? [bubble, const SizedBox(width: 4)]
          : [const SizedBox(width: 4), bubble],
      ),
    );
  }
}

class _SystemMsg extends StatelessWidget {
  final String content;
  const _SystemMsg({required this.content});

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2C34).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(content, style: const TextStyle(color: ImTheme.textMuted, fontSize: 11.5)),
    ),
  );
}

// ── 消息气泡 ──────────────────────────────────────────────────────────────────

class _Bubble extends StatelessWidget {
  final ImMessage msg;
  final bool      isMine;
  final bool      isLast;
  const _Bubble({required this.msg, required this.isMine, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final bg = isMine ? ImTheme.bubbleMine : ImTheme.bubbleOther;
    final radius = BorderRadius.only(
      topLeft:     const Radius.circular(10),
      topRight:    const Radius.circular(10),
      bottomLeft:  Radius.circular(isMine || !isLast ? 10 : 2),
      bottomRight: Radius.circular(!isMine || !isLast ? 10 : 2),
    );

    Widget content;
    if (msg.isImage) {
      content = _ImageContent(url: msg.content, isMine: isMine, ts: msg.createTime, status: msg.status, radius: radius);
    } else if (msg.isVoice) {
      content = _VoiceContent(msg: msg, isMine: isMine, bg: bg, radius: radius);
    } else if (msg.isVideo) {
      content = _VideoContent(url: msg.content, isMine: isMine, ts: msg.createTime, status: msg.status, radius: radius);
    } else {
      content = _TextContent(msg: msg, isMine: isMine, bg: bg, radius: radius);
    }

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
      child: content,
    );
  }
}

// ── 文本气泡 ──────────────────────────────────────────────────────────────────

class _TextContent extends StatelessWidget {
  final ImMessage msg;
  final bool      isMine;
  final Color     bg;
  final BorderRadius radius;
  const _TextContent({required this.msg, required this.isMine, required this.bg, required this.radius});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(9, 6, 9, 6),
    decoration: BoxDecoration(color: bg, borderRadius: radius,
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 2, offset: const Offset(0, 1))]),
    child: Wrap(
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.end,
      children: [
        Text(msg.content, style: const TextStyle(color: ImTheme.textPrimary, fontSize: 14, height: 1.35)),
        const SizedBox(width: 6),
        _TimeTick(ts: msg.createTime, status: msg.status, isMine: isMine),
      ],
    ),
  );
}

// ── 图片气泡 ──────────────────────────────────────────────────────────────────

class _ImageContent extends StatelessWidget {
  final String url;
  final bool   isMine;
  final int    ts;
  final int    status;
  final BorderRadius radius;
  const _ImageContent({required this.url, required this.isMine, required this.ts, required this.status, required this.radius});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => _showPreview(context),
    child: ClipRRect(
      borderRadius: radius,
      child: Stack(
        children: [
          CachedNetworkImage(
            imageUrl: url, width: 220, height: 220,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(
              width: 220, height: 220,
              color: ImTheme.bubbleOther,
              child: const Center(child: CircularProgressIndicator(color: ImTheme.accent, strokeWidth: 2)),
            ),
            errorWidget: (_, __, ___) => Container(
              width: 220, height: 220, color: ImTheme.bubbleOther,
              child: const Icon(Icons.broken_image_outlined, color: ImTheme.textMuted, size: 48),
            ),
          ),
          Positioned(
            bottom: 6, right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(8),
              ),
              child: _TimeTick(ts: ts, status: status, isMine: isMine, lightBg: true),
            ),
          ),
        ],
      ),
    ),
  );

  void _showPreview(BuildContext context) => showDialog(
    context: context,
    barrierColor: Colors.black87,
    builder: (_) => GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Center(child: InteractiveViewer(
        child: CachedNetworkImage(imageUrl: url),
      )),
    ),
  );
}

// ── 视频气泡 ──────────────────────────────────────────────────────────────────

class _VideoContent extends StatelessWidget {
  final String url;
  final bool   isMine;
  final int    ts, status;
  final BorderRadius radius;
  const _VideoContent({required this.url, required this.isMine, required this.ts, required this.status, required this.radius});

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: radius,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Container(width: 220, height: 160, color: Colors.black87,
          child: const Icon(Icons.videocam, color: Colors.white38, size: 48)),
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: Colors.black45, shape: BoxShape.circle,
            border: Border.all(color: Colors.white54, width: 2),
          ),
          child: const Icon(Icons.play_arrow, color: Colors.white, size: 28),
        ),
        Positioned(
          bottom: 6, right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _TimeTick(ts: ts, status: status, isMine: isMine, lightBg: true),
          ),
        ),
      ],
    ),
  );
}

// ── 语音气泡 ──────────────────────────────────────────────────────────────────

class _VoiceContent extends StatefulWidget {
  final ImMessage   msg;
  final bool        isMine;
  final Color       bg;
  final BorderRadius radius;
  const _VoiceContent({required this.msg, required this.isMine, required this.bg, required this.radius});

  @override
  State<_VoiceContent> createState() => _VoiceContentState();
}

class _VoiceContentState extends State<_VoiceContent> {
  final _player  = AudioPlayer();
  bool  _playing = false;
  int   _elapsed = 0;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_playing) {
      await _player.pause();
      setState(() => _playing = false);
      return;
    }
    try {
      await _player.setUrl(widget.msg.voiceUrl);
      await _player.play();
      setState(() => _playing = true);
      _player.positionStream.listen((pos) {
        if (!mounted) return;
        setState(() => _elapsed = pos.inSeconds);
      });
      _player.playerStateStream.listen((state) {
        if (!mounted) return;
        if (state.processingState == ProcessingState.completed) {
          setState(() { _playing = false; _elapsed = 0; });
        }
      });
    } catch (_) {
      Get.snackbar('播放失败', '', snackPosition: SnackPosition.TOP);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dur  = widget.msg.voiceDurSec;
    final prog = dur > 0 ? (_elapsed / dur).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 10, 6),
      decoration: BoxDecoration(
        color: widget.bg, borderRadius: widget.radius,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 2, offset: const Offset(0, 1))],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        GestureDetector(
          onTap: _toggle,
          child: Container(
            width: 36, height: 36, alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _playing ? Icons.pause : Icons.play_arrow,
              color: Colors.white, size: 22,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
            width: 110,
            child: LinearProgressIndicator(
              value: prog.toDouble(),
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              color: ImTheme.accent,
              minHeight: 3,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            ImTimeUtil.fmtDuration(_playing ? _elapsed : dur),
            style: const TextStyle(color: ImTheme.textMuted, fontSize: 11),
          ),
        ]),
        const SizedBox(width: 8),
        _TimeTick(ts: widget.msg.createTime, status: widget.msg.status, isMine: widget.isMine),
      ]),
    );
  }
}

// ── 时间 + 勾 ─────────────────────────────────────────────────────────────────

class _TimeTick extends StatelessWidget {
  final int  ts, status;
  final bool isMine;
  final bool lightBg;
  const _TimeTick({required this.ts, required this.status, required this.isMine, this.lightBg = false});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Text(
        ImTimeUtil.fmtMsgTime(ts),
        style: TextStyle(
          fontSize: 10.5,
          color: lightBg ? Colors.white.withValues(alpha: 0.85) : ImTheme.timeText,
        ),
      ),
      if (isMine) ...[
        const SizedBox(width: 3),
        _DoubleTick(status: status),
      ],
    ],
  );
}

class _DoubleTick extends StatelessWidget {
  final int status;
  const _DoubleTick({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = status >= 3 ? ImTheme.tickBlue : ImTheme.tickGray;
    return CustomPaint(painter: _TickPainter(color: color, status: status), size: const Size(16, 11));
  }
}

class _TickPainter extends CustomPainter {
  final Color color;
  final int   status;
  const _TickPainter({required this.color, required this.status});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.6
      ..strokeCap   = StrokeCap.round
      ..strokeJoin  = StrokeJoin.round
      ..style       = PaintingStyle.stroke;

    final p1 = Path()
      ..moveTo(0, size.height * 0.5)
      ..lineTo(size.width * 0.27, size.height)
      ..lineTo(size.width * 0.62, size.height * 0.18);
    final p2 = Path()
      ..moveTo(size.width * 0.32, size.height * 0.5)
      ..lineTo(size.width * 0.59, size.height)
      ..lineTo(size.width,        size.height * 0.18);

    canvas.drawPath(p1, paint);
    if (status >= 2) canvas.drawPath(p2, paint);
  }

  @override
  bool shouldRepaint(_TickPainter old) => old.color != color || old.status != status;
}

// ── 输入栏 ────────────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  final ImChatLogic logic;
  const _InputBar({required this.logic});

  @override
  Widget build(BuildContext context) => Container(
    color: ImTheme.header,
    padding: EdgeInsets.only(
      left: 8, right: 8,
      top: 8,
      bottom: MediaQuery.of(context).padding.bottom + 8,
    ),
    child: Obx(() => logic.recording.value
      ? _RecordingBar(logic: logic)
      : _NormalBar(logic: logic)),
  );
}

class _NormalBar extends StatelessWidget {
  final ImChatLogic logic;
  const _NormalBar({required this.logic});

  @override
  Widget build(BuildContext context) => Row(children: [
    // 图片选择
    Obx(() => logic.uploadingImg.value
      ? const Padding(padding: EdgeInsets.all(10), child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: ImTheme.accent)))
      : IconButton(
          icon: const Icon(Icons.image_outlined, color: ImTheme.textSub, size: 24),
          onPressed: logic.pickAndSendImage,
        )),
    // 语音录制
    GestureDetector(
      onLongPressStart: (_) => logic.startRecording(),
      onLongPressEnd:   (_) => logic.stopRecording(),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 4),
        child: Icon(Icons.mic_none, color: ImTheme.textSub, size: 26),
      ),
    ),
    const SizedBox(width: 4),
    // 文本输入框
    Expanded(child: Container(
      constraints: const BoxConstraints(maxHeight: 120),
      decoration: BoxDecoration(
        color: ImTheme.inputBg,
        borderRadius: BorderRadius.circular(22),
      ),
      child: TextField(
        controller:    logic.inputCtrl,
        style:         const TextStyle(color: ImTheme.textPrimary, fontSize: 14),
        decoration: const InputDecoration(
          hintText:        '消息',
          hintStyle:       TextStyle(color: ImTheme.textMuted, fontSize: 14),
          border:          InputBorder.none,
          contentPadding:  EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
        maxLines:      null,
        textInputAction: TextInputAction.send,
        onSubmitted:   (_) => logic.sendText(),
      ),
    )),
    const SizedBox(width: 8),
    // 发送按钮
    GestureDetector(
      onTap: logic.sendText,
      child: Container(
        width: 42, height: 42,
        decoration: const BoxDecoration(color: ImTheme.accent, shape: BoxShape.circle),
        child: const Icon(Icons.send, color: Colors.white, size: 20),
      ),
    ),
  ]);
}

class _RecordingBar extends StatelessWidget {
  final ImChatLogic logic;
  const _RecordingBar({required this.logic});

  @override
  Widget build(BuildContext context) => Row(children: [
    GestureDetector(
      onTap: logic.cancelRecording,
      child: const Icon(Icons.delete_outline, color: ImTheme.danger, size: 28),
    ),
    const SizedBox(width: 12),
    Expanded(child: Row(children: [
      Container(
        width: 10, height: 10,
        decoration: const BoxDecoration(color: ImTheme.danger, shape: BoxShape.circle),
      ),
      const SizedBox(width: 6),
      Obx(() => Text(
        ImTimeUtil.fmtDuration(logic.recSeconds.value),
        style: const TextStyle(color: ImTheme.textPrimary, fontSize: 14),
      )),
      const SizedBox(width: 8),
      const Text('松开发送', style: TextStyle(color: ImTheme.textMuted, fontSize: 12)),
    ])),
    GestureDetector(
      onTap: logic.stopRecording,
      child: Container(
        width: 42, height: 42,
        decoration: const BoxDecoration(color: ImTheme.accent, shape: BoxShape.circle),
        child: const Icon(Icons.send, color: Colors.white, size: 20),
      ),
    ),
  ]);
}
