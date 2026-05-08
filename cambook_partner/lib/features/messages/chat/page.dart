import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart' as dio;
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart' hide Path;

import '../../../core/extensions/theme_ext.dart';
import '../../../core/i18n/l10n_ext.dart';
import '../../../core/models/models.dart';
import '../../../core/services/message_service.dart';
import '../../../core/utils/date_util.dart';
import '../../../core/widgets/common_widgets.dart';
import 'logic.dart';

// ── Static palette (theme-neutral neutrals) ───────────────────────────────────
abstract class _C {
  // Light background palette
  static const bg           = Color(0xFFF0F2F5);   // scaffold background
  static const inputFieldBg = Color(0xFFF0F2F5);
  static const bubbleRecv   = Colors.white;
  static const textPrimary  = Color(0xFF1A1A2E);
  static const textSecond   = Color(0xFF8696A0);
  static const recordRed    = Color(0xFFFF3B30);
  static const systemBg     = Color(0x99FFFFFF);
}

// ╔══════════════════════════════════════════════════════════════════════════════
// ChatPage
// ╚══════════════════════════════════════════════════════════════════════════════
class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    final logic = Get.find<ChatLogic>();
    return Scaffold(
      backgroundColor: _C.bg,
      appBar: _ChatAppBar(logic: logic),
      body: Column(children: [
        Expanded(
          child: Stack(children: [
            // subtle tinted wallpaper
            Positioned.fill(
              child: CustomPaint(painter: _WallpaperPainter(context.primary)),
            ),
            _MessageList(logic: logic),
          ]),
        ),
        _InputBar(logic: logic),
      ]),
    );
  }
}

// ── AppBar ────────────────────────────────────────────────────────────────────

class _ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final ChatLogic logic;
  const _ChatAppBar({required this.logic});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final primary = context.primary;
    return AppBar(
      backgroundColor: primary,
      elevation: 0,
      titleSpacing: 0,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.light,
      ),
      leading: BounceTap(
        pressScale: 0.82,
        onTap: () => Get.back(),
        child: const Icon(Icons.arrow_back_ios_new_rounded,
            color: Colors.white, size: 20),
      ),
      title: Obx(() {
        final name   = logic.state.conversationName.value;
        final avatar = logic.state.peerAvatar.value;
        return Row(children: [
          // Avatar with white ring
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2),
            ),
            child: ClipOval(
              child: avatar.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: avatar, width: 36, height: 36, fit: BoxFit.cover,
                      errorWidget: (_, __, ___) =>
                          _InitialsAvatar(name: name, radius: 18, primary: primary),
                    )
                  : _InitialsAvatar(name: name, radius: 18, primary: primary),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white, fontSize: 15.5, fontWeight: FontWeight.w700),
                ),
                Text(context.l10n.imOnline,
                  style: const TextStyle(
                    color: Color(0xCCFFFFFF), fontSize: 11.5,
                    fontWeight: FontWeight.w400)),
              ],
            ),
          ),
        ]);
      }),
      actions: [
        // Video call icon (outline, like WhatsApp)
        IconButton(
          icon: const Icon(Icons.videocam_outlined, color: Colors.white, size: 26),
          onPressed: () {},   // TODO: video call
          tooltip: '',
        ),
        // Voice call icon (outline)
        IconButton(
          icon: const Icon(Icons.call_outlined, color: Colors.white, size: 24),
          onPressed: logic.startVoiceCall,
          tooltip: '',
        ),
        IconButton(
          icon: const Icon(Icons.more_vert_rounded, color: Colors.white, size: 22),
          onPressed: () {},
        ),
      ],
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  final String name;
  final double radius;
  final Color  primary;
  const _InitialsAvatar({
    required this.name, required this.radius, required this.primary});

  @override
  Widget build(BuildContext context) => CircleAvatar(
    radius: radius,
    backgroundColor: Colors.white.withValues(alpha: 0.3),
    child: Text(
      name.isNotEmpty ? name[0].toUpperCase() : '?',
      style: TextStyle(
        color: Colors.white, fontSize: radius * 0.88, fontWeight: FontWeight.w700),
    ),
  );
}

// ── Wallpaper ─────────────────────────────────────────────────────────────────
// Subtle dot grid + tiny leaf silhouettes tinted with the app's primary color.
// shouldRepaint = false → never triggers redraws.

class _WallpaperPainter extends CustomPainter {
  final Color primary;
  const _WallpaperPainter(this.primary);

  static const _seed = 137;

  @override
  void paint(Canvas canvas, Size size) {
    // fill
    canvas.drawRect(Offset.zero & size, Paint()..color = _C.bg);

    final rng = math.Random(_seed);

    // leaf silhouettes
    final leafPaint = Paint()
      ..color = primary.withValues(alpha: 0.05)
      ..style  = PaintingStyle.fill;

    for (int i = 0; i < 80; i++) {
      final x     = rng.nextDouble() * size.width;
      final y     = rng.nextDouble() * size.height;
      final scale = 7.0 + rng.nextDouble() * 12;
      final angle = rng.nextDouble() * math.pi * 2;
      _drawLeaf(canvas, leafPaint, x, y, scale, angle);
    }

    // fine dot grid
    final dotPaint = Paint()
      ..color = primary.withValues(alpha: 0.055)
      ..style  = PaintingStyle.fill;

    const gap = 26.0;
    for (double x = gap / 2; x < size.width; x += gap) {
      for (double y = gap / 2; y < size.height; y += gap) {
        canvas.drawCircle(Offset(x, y), 1.2, dotPaint);
      }
    }
  }

  void _drawLeaf(Canvas canvas, Paint p, double cx, double cy,
      double scale, double angle) {
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(angle);
    final path = Path()
      ..moveTo(0, -scale)
      ..cubicTo(scale * 0.6, -scale * 0.6, scale * 0.6, scale * 0.6, 0, scale)
      ..cubicTo(-scale * 0.6, scale * 0.6, -scale * 0.6, -scale * 0.6, 0, -scale)
      ..close();
    canvas.drawPath(path, p);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_WallpaperPainter o) => o.primary != primary;
}

// ── Message List (StatefulWidget with sticky floating date header) ────────────

class _MessageList extends StatefulWidget {
  final ChatLogic logic;
  const _MessageList({required this.logic});

  @override
  State<_MessageList> createState() => _MessageListState();
}

class _MessageListState extends State<_MessageList> {
  String _floatingDate = '';
  bool   _showFloating = false;
  Timer? _hideTimer;

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _onScroll() {
    final msgs = widget.logic.state.messages;
    if (msgs.isEmpty) return;

    // Estimate first visible message index from scroll offset
    const approxItemH = 62.0;
    final offset = widget.logic.scrollCtrl.hasClients
        ? widget.logic.scrollCtrl.offset : 0.0;
    final idx = (offset / approxItemH).floor().clamp(0, msgs.length - 1);
    final date = _DatePill.format(msgs[idx].time, context);

    _hideTimer?.cancel();
    if (!mounted) return;
    setState(() { _floatingDate = date; _showFloating = true; });
    _hideTimer = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _showFloating = false);
    });
  }

  @override
  void initState() {
    super.initState();
    widget.logic.scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    widget.logic.scrollCtrl.removeListener(_onScroll);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Obx(() {
      final msgs = widget.logic.state.messages;
      if (msgs.isEmpty) {
        return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.chat_bubble_outline_rounded,
                color: _C.textSecond.withValues(alpha: 0.4), size: 56),
          ),
          const SizedBox(height: 14),
          Text(l.imNoMessages,
            style: TextStyle(
              color: _C.textSecond.withValues(alpha: 0.7),
              fontSize: 14, fontWeight: FontWeight.w500)),
        ]));
      }

      final peerAvatar = widget.logic.state.peerAvatar.value;
      final peerName   = widget.logic.state.conversationName.value;

      return Stack(children: [
        NotificationListener<ScrollNotification>(
          onNotification: (n) {
            if (n is ScrollEndNotification && n.metrics.pixels < 120) {
              widget.logic.loadMore();
            }
            return false;
          },
          child: ListView.builder(
            controller: widget.logic.scrollCtrl,
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
            itemCount: msgs.length,
            itemBuilder: (_, i) {
              final msg  = msgs[i];
              final prev = i > 0 ? msgs[i - 1] : null;
              final next = i < msgs.length - 1 ? msgs[i + 1] : null;
              final showDate    = prev == null || !_sameDay(prev.time, msg.time);
              final isLastGroup = next == null || next.isMe != msg.isMe;
              final showAvatar  = isLastGroup && !msg.isMe &&
                  msg.type != MessageType.system;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (showDate) _DatePill(time: msg.time),
                  _BubbleRow(
                    msg:        msg,
                    showTail:   isLastGroup && msg.type != MessageType.system,
                    showAvatar: showAvatar,
                    peerAvatar: peerAvatar,
                    peerName:   peerName,
                  ),
                ],
              );
            },
          ),
        ),

        // ── Floating sticky date label (WhatsApp-style) ──────────────────
        AnimatedPositioned(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          top: _showFloating ? 8 : -40,
          left: 0, right: 0,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: _showFloating ? 1.0 : 0.0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  _floatingDate,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 11.5,
                      fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ),
        ),
      ]);
    });
  }
}

// ── Date Pill ─────────────────────────────────────────────────────────────────

class _DatePill extends StatelessWidget {
  final DateTime time;
  const _DatePill({required this.time});

  /// Format a date as WhatsApp does:
  ///  • Today / Yesterday
  ///  • Mon / Tue / … (within 6 days)
  ///  • "5 Jan" / "12 Mar" (older)
  static String format(DateTime time, BuildContext context) {
    final l    = context.l10n;
    final now  = DateTime.now();
    final diff = DateTime(now.year, now.month, now.day)
        .difference(DateTime(time.year, time.month, time.day)).inDays;
    if (diff == 0) return l.imToday;
    if (diff == 1) return l.imYesterday;
    if (diff < 7) {
      const wd = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return wd[time.weekday - 1];
    }
    const mo = ['Jan','Feb','Mar','Apr','May','Jun',
                 'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${time.day} ${mo[time.month - 1]}';
  }

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        format(time, context),
        style: const TextStyle(
          color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w500),
      ),
    ),
  );
}

// ── Bubble Row ────────────────────────────────────────────────────────────────

class _BubbleRow extends StatelessWidget {
  final ChatMessageModel msg;
  final bool             showTail;
  final bool             showAvatar;
  final String           peerAvatar;
  final String           peerName;
  const _BubbleRow({
    required this.msg,
    required this.showTail,
    this.showAvatar  = false,
    this.peerAvatar  = '',
    this.peerName    = '',
  });

  @override
  Widget build(BuildContext context) {
    if (msg.type == MessageType.system) return _SystemChip(content: msg.content);

    final isMine  = msg.isMe;
    final primary = context.primary;

    final radius = BorderRadius.only(
      topLeft:     const Radius.circular(18),
      topRight:    const Radius.circular(18),
      bottomLeft:  Radius.circular(isMine ? 18 : (showTail ? 4 : 18)),
      bottomRight: Radius.circular(isMine ? (showTail ? 4 : 18) : 18),
    );

    Widget bubble = ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.68,
        minWidth: 80,
      ),
      child: switch (msg.type) {
        MessageType.image    => _ImageBubble(msg: msg, radius: radius, primary: primary, isMine: isMine),
        MessageType.voice    => _VoiceBubble(msg: msg, isMine: isMine, primary: primary, radius: radius),
        MessageType.location => _LocationBubble(msg: msg, isMine: isMine, primary: primary, radius: radius),
        _                    => _TextBubble(msg: msg, isMine: isMine, primary: primary, radius: radius),
      },
    );

    // Tail triangle
    if (showTail) {
      bubble = Stack(
        clipBehavior: Clip.none,
        children: [
          bubble,
          if (isMine)
            Positioned(
              bottom: 0, right: -6,
              child: CustomPaint(
                size: const Size(9, 11),
                painter: _TailPainter(isMe: true, color: primary),
              ),
            )
          else
            const Positioned(
              bottom: 0, left: -6,
              child: CustomPaint(
                size: Size(9, 11),
                painter: _TailPainter(isMe: false, color: _C.bubbleRecv),
              ),
            ),
        ],
      );
    }

    // Avatar placeholder width keeps alignment consistent even when hidden
    const double avatarSize = 34;
    const double avatarGap  = 6;

    return Padding(
      padding: EdgeInsets.only(
        top:    2,
        bottom: showTail ? 8 : 2,
        left:   isMine ? 56 : 8,
        right:  isMine ? 8 : 56,
      ),
      child: Row(
        mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // ── Received side: avatar + bubble ───────────────────────────────
          if (!isMine) ...[
            SizedBox(
              width: avatarSize,
              child: showAvatar
                  ? _MiniAvatar(name: peerName, url: peerAvatar, size: avatarSize, primary: primary)
                  : const SizedBox.shrink(),
            ),
            const SizedBox(width: avatarGap),
          ],
          // ── Bubble ────────────────────────────────────────────────────────
          bubble,
        ],
      ),
    );
  }
}

/// Small circular avatar shown next to received messages.
class _MiniAvatar extends StatelessWidget {
  final String name;
  final String url;
  final double size;
  final Color  primary;
  const _MiniAvatar({
    required this.name, required this.url,
    required this.size, required this.primary});

  @override
  Widget build(BuildContext context) {
    if (url.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: url, width: size, height: size, fit: BoxFit.cover,
          errorWidget: (_, __, ___) => _fallback(),
        ),
      );
    }
    return _fallback();
  }

  Widget _fallback() => CircleAvatar(
    radius: size / 2,
    backgroundColor: primary.withValues(alpha: 0.85),
    child: Text(
      name.isNotEmpty ? name[0].toUpperCase() : '?',
      style: TextStyle(
        color: Colors.white,
        fontSize: size * 0.42,
        fontWeight: FontWeight.w700),
    ),
  );
}

// ── Bubble Tail ───────────────────────────────────────────────────────────────

class _TailPainter extends CustomPainter {
  final bool  isMe;
  final Color color;
  const _TailPainter({required this.isMe, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    if (isMe) {
      path.moveTo(0, 0);
      path.lineTo(size.width, size.height * 0.6);
      path.lineTo(0, size.height);
    } else {
      path.moveTo(size.width, 0);
      path.lineTo(0, size.height * 0.6);
      path.lineTo(size.width, size.height);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color ..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(_TailPainter o) => o.isMe != isMe || o.color != color;
}

class _SystemChip extends StatelessWidget {
  final String content;
  const _SystemChip({required this.content});
  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: _C.systemBg,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 3)],
      ),
      child: Text(content,
          style: const TextStyle(color: _C.textSecond, fontSize: 12)),
    ),
  );
}

// ── Text Bubble ───────────────────────────────────────────────────────────────

class _TextBubble extends StatelessWidget {
  final ChatMessageModel msg;
  final bool        isMine;
  final Color       primary;
  final BorderRadius radius;
  const _TextBubble({
    required this.msg, required this.isMine,
    required this.primary,  required this.radius});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
    decoration: BoxDecoration(
      color: isMine ? primary : _C.bubbleRecv,
      borderRadius: radius,
      boxShadow: [
        BoxShadow(color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 6, offset: const Offset(0, 2)),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,   // text left-aligned
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(msg.content,
          style: TextStyle(
            color: isMine ? Colors.white : _C.textPrimary,
            fontSize: 15, height: 1.4, letterSpacing: 0.1)),
        const SizedBox(height: 2),
        // Time at bottom-right corner (WhatsApp style)
        Align(
          alignment: Alignment.centerRight,
          child: _TimeRow(msg: msg, isMine: isMine),
        ),
      ],
    ),
  );
}

// ── Location Bubble ───────────────────────────────────────────────────────────

class _LocationBubble extends StatelessWidget {
  final ChatMessageModel msg;
  final bool             isMine;
  final Color            primary;
  final BorderRadius     radius;
  const _LocationBubble({
    required this.msg, required this.isMine,
    required this.primary, required this.radius});

  @override
  Widget build(BuildContext context) {
    // Parse JSON content
    Map<String, dynamic> loc = {};
    try { loc = jsonDecode(msg.content) as Map<String, dynamic>; } catch (_) {}
    final lat     = (loc['lat'] as num?)?.toDouble() ?? 0.0;
    final lng     = (loc['lng'] as num?)?.toDouble() ?? 0.0;
    final address = loc['address'] as String? ?? 'Location';

    return GestureDetector(
      onTap: () => _openMap(context, lat, lng, address),
      child: Container(
        width: 230,
        decoration: BoxDecoration(
          color: isMine ? primary : _C.bubbleRecv,
          borderRadius: radius,
          boxShadow: [BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Mini static map preview
              SizedBox(
                height: 130,
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: LatLng(lat, lng),
                    initialZoom:   15,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.none),  // static
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.cambook.partner',
                    ),
                    MarkerLayer(markers: [
                      Marker(
                        point: LatLng(lat, lng),
                        width: 28, height: 28,
                        child: Icon(Icons.location_on,
                            color: isMine ? Colors.white : primary, size: 28),
                      ),
                    ]),
                  ],
                ),
              ),
              // Address + time row
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(Icons.location_on_outlined,
                          size: 14, color: isMine ? Colors.white70 : primary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(address,
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: isMine ? Colors.white : _C.textPrimary,
                              fontSize: 13, fontWeight: FontWeight.w500)),
                      ),
                    ]),
                    const SizedBox(height: 2),
                    Align(
                      alignment: Alignment.centerRight,
                      child: _TimeRow(msg: msg, isMine: isMine),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openMap(BuildContext ctx, double lat, double lng, String address) {
    showDialog(
      context: ctx,
      builder: (_) => _MapViewDialog(lat: lat, lng: lng, address: address),
    );
  }
}

// ── Image Bubble ──────────────────────────────────────────────────────────────

class _ImageBubble extends StatelessWidget {
  final ChatMessageModel msg;
  final BorderRadius     radius;
  final Color            primary;
  final bool             isMine;
  const _ImageBubble({
    required this.msg, required this.radius,
    required this.primary, required this.isMine});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => _fullScreen(context),
    child: ClipRRect(
      borderRadius: radius,
      child: Stack(children: [
        Hero(
          tag: 'img_${msg.id}',
          child: CachedNetworkImage(
            imageUrl: msg.content,
            width: 210, height: 210, fit: BoxFit.cover,
            placeholder: (_, __) => Container(
              width: 210, height: 210,
              color: isMine ? primary.withValues(alpha: 0.3) : const Color(0xFFEEEEEE),
              child: Center(child: CircularProgressIndicator(
                  strokeWidth: 2, color: isMine ? Colors.white : primary)),
            ),
            errorWidget: (_, __, ___) => Container(
              width: 210, height: 210,
              color: isMine ? primary.withValues(alpha: 0.2) : const Color(0xFFEEEEEE),
              child: Icon(Icons.broken_image_outlined,
                  size: 44, color: isMine ? Colors.white70 : _C.textSecond),
            ),
          ),
        ),
        Positioned(bottom: 6, right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.50),
              borderRadius: BorderRadius.circular(10),
            ),
            child: _TimeRow(msg: msg, isMine: msg.isMe, overlay: true),
          ),
        ),
      ]),
    ),
  );

  void _fullScreen(BuildContext ctx) => showDialog(
    context: ctx,
    barrierColor: Colors.black.withValues(alpha: 0.95),
    builder: (_) => GestureDetector(
      onTap: () => Navigator.pop(ctx),
      child: Center(
        child: Hero(
          tag: 'img_${msg.id}',
          child: InteractiveViewer(
            minScale: 0.5, maxScale: 6,
            child: CachedNetworkImage(imageUrl: msg.content),
          ),
        ),
      ),
    ),
  );
}

// ── Voice Bubble ──────────────────────────────────────────────────────────────

class _VoiceBubble extends StatefulWidget {
  final ChatMessageModel msg;
  final bool             isMine;
  final Color            primary;
  final BorderRadius     radius;
  const _VoiceBubble({
    required this.msg, required this.isMine,
    required this.primary,  required this.radius});
  @override
  State<_VoiceBubble> createState() => _VoiceBubbleState();
}

class _VoiceBubbleState extends State<_VoiceBubble>
    with SingleTickerProviderStateMixin {
  final _player = AudioPlayer();
  bool   _playing  = false;
  double _progress = 0;
  late AnimationController _waveCtrl;

  @override
  void initState() {
    super.initState();
    _waveCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
    _player.onPositionChanged.listen((pos) {
      final dur = widget.msg.voiceDurSec ?? 1;
      if (mounted) setState(() => _progress = (pos.inSeconds / dur).clamp(0.0, 1.0));
    });
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() { _playing = false; _progress = 0; });
      _waveCtrl.stop();
    });
    _player.onLog.listen((msg) => debugPrint('[AudioPlayer] $msg'));
    _player.onPlayerStateChanged.listen((state) {
      if (state == PlayerState.stopped && _playing) {
        if (mounted) setState(() { _playing = false; _progress = 0; });
        _waveCtrl.stop();
      }
    });
  }

  @override
  void dispose() { _player.dispose(); _waveCtrl.dispose(); super.dispose(); }

  Future<void> _toggle() async {
    final url = widget.msg.voiceUrl ?? widget.msg.content;
    if (_playing) {
      await _player.pause();
      _waveCtrl.stop();
      setState(() => _playing = false);
    } else {
      try {
        await _player.play(UrlSource(url));
        _waveCtrl.repeat(reverse: true);
        setState(() => _playing = true);
      } catch (e) {
        debugPrint('[VoiceBubble] play error: $e  url=$url');
      }
    }
  }

  String _fmt(int s) {
    final m = s ~/ 60, sec = s % 60;
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final dur     = widget.msg.voiceDurSec ?? 0;
    final isMine  = widget.isMine;
    final primary = widget.primary;
    final bubbleBg = isMine ? primary : _C.bubbleRecv;
    final iconFg   = isMine ? Colors.white : primary;
    final iconBg   = isMine
        ? Colors.white.withValues(alpha: 0.2)
        : primary.withValues(alpha: 0.12);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      constraints: const BoxConstraints(minWidth: 190),
      decoration: BoxDecoration(
        color: bubbleBg,
        borderRadius: widget.radius,
        boxShadow: [BoxShadow(
          color: Colors.black.withValues(alpha: 0.10),
          blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        GestureDetector(
          onTap: _toggle,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 40, height: 40,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(
              _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: iconFg, size: 24),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _WaveformBar(
                progress: _progress, playing: _playing,
                anim: _waveCtrl, isMine: isMine, primary: primary),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_fmt(dur),
                    style: TextStyle(
                      color: isMine
                          ? Colors.white.withValues(alpha: 0.75)
                          : _C.textSecond,
                      fontSize: 11)),
                  _TimeRow(msg: widget.msg, isMine: isMine),
                ],
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

class _WaveformBar extends StatelessWidget {
  final double progress;
  final bool   playing;
  final AnimationController anim;
  final bool   isMine;
  final Color  primary;
  const _WaveformBar({
    required this.progress, required this.playing,
    required this.anim,     required this.isMine,
    required this.primary});

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: anim,
    builder: (_, __) => SizedBox(
      height: 26, width: 140,
      child: CustomPaint(
        painter: _WavePainter(
          progress:      progress,
          animValue:     playing ? anim.value : 0,
          activeColor:   isMine ? Colors.white : primary,
          inactiveColor: (isMine ? Colors.white : _C.textSecond)
              .withValues(alpha: 0.35),
        ),
      ),
    ),
  );
}

class _WavePainter extends CustomPainter {
  final double progress, animValue;
  final Color  activeColor, inactiveColor;
  const _WavePainter({
    required this.progress,     required this.animValue,
    required this.activeColor,  required this.inactiveColor});

  static const _h = [
    0.3, 0.5, 0.7, 0.5, 1.0, 0.6, 0.4, 0.9, 0.7, 0.5,
    0.8, 0.4, 0.6, 0.5, 0.3, 0.7, 0.9, 0.4, 0.8, 0.5,
    0.7, 0.4, 0.6, 0.3, 0.5, 0.8, 0.6, 0.4, 0.7, 0.5,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final bars    = _h.length;
    final bw      = size.width / bars;
    final centerY = size.height / 2;
    for (int i = 0; i < bars; i++) {
      final frac   = i / bars;
      final active = frac <= progress;
      var h = _h[i] * size.height * 0.92;
      if (active && animValue > 0) {
        h *= 0.82 + 0.18 * math.sin(animValue * math.pi + i * 0.5);
      }
      canvas.drawRRect(
        RRect.fromLTRBR(
          bw * i + 1,       centerY - h / 2,
          bw * (i + 1) - 1, centerY + h / 2,
          const Radius.circular(2),
        ),
        Paint()
          ..color = active ? activeColor : inactiveColor
          ..style  = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(_WavePainter o) =>
      o.progress != progress || o.animValue != animValue;
}

// ── Time Row ──────────────────────────────────────────────────────────────────

class _TimeRow extends StatelessWidget {
  final ChatMessageModel msg;
  final bool isMine;
  final bool overlay;
  const _TimeRow({required this.msg, required this.isMine, this.overlay = false});

  @override
  Widget build(BuildContext context) {
    final timeColor = overlay
        ? Colors.white70
        : isMine
            ? Colors.white.withValues(alpha: 0.75)
            : _C.textSecond;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Text(DateUtil.timeOnly(msg.time),
          style: TextStyle(color: timeColor, fontSize: 10.5)),
      if (isMine) ...[
        const SizedBox(width: 3),
        _Ticks(status: msg.status, isMine: isMine, overlay: overlay),
      ],
    ]);
  }
}

class _Ticks extends StatelessWidget {
  final int  status;
  final bool isMine;
  final bool overlay;
  const _Ticks({required this.status, required this.isMine, required this.overlay});

  @override
  Widget build(BuildContext context) {
    Color color;
    if (status == 3) {
      color = overlay ? Colors.lightBlueAccent : const Color(0xFF53BDEB);
    } else {
      color = overlay
          ? Colors.white70
          : isMine
              ? Colors.white.withValues(alpha: 0.80)
              : _C.textSecond;
    }
    return Icon(
      status >= 2 ? Icons.done_all_rounded : Icons.check_rounded,
      color: color, size: 14,
    );
  }
}

// ╔══════════════════════════════════════════════════════════════════════════════
// Input Bar — pixel-accurate WhatsApp layout
//
// No text:  [😊] [────── 消息... ──────] [📎] [●mic]
// Has text: [😊] [────── typed ────────]     [●▶]
//
// Key rules that match WhatsApp exactly:
//  • Emoji + attachment: plain icons, bottom-padded 8 px so they sit level
//    with the pill's bottom when the pill is single-line
//  • Pill: light-gray background, NO border, radius 22, grows vertically
//  • Mic / Send: 44 px green circle, 2 px bottom margin to optically centre
// ╚══════════════════════════════════════════════════════════════════════════════

class _InputBar extends StatelessWidget {
  final ChatLogic logic;
  const _InputBar({required this.logic});

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return ColoredBox(
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Hairline top divider (WhatsApp style)
          Container(height: 0.5, color: Colors.black.withValues(alpha: 0.08)),
          Padding(
            padding: EdgeInsets.fromLTRB(8, 8, 8, 8 + bottom),
            child: Obx(() => logic.state.recording.value
                ? _RecordingBar(logic: logic)
                : _NormalBar(logic: logic)),
          ),
        ],
      ),
    );
  }
}

class _NormalBar extends StatelessWidget {
  final ChatLogic logic;
  const _NormalBar({required this.logic});

  @override
  Widget build(BuildContext context) {
    final l       = context.l10n;
    final primary = context.primary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // ── Emoji (flat icon) — opens emoji picker ───────────────────────────
        GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
            _EmojiPicker.show(context, logic);
          },
          child: const Padding(
            padding: EdgeInsets.fromLTRB(4, 0, 4, 9),
            child: Icon(Icons.emoji_emotions_outlined,
                color: _C.textSecond, size: 26),
          ),
        ),

        const SizedBox(width: 2),

        // ── Pill input (no border in any state) ──────────────────────────────
        Expanded(
          child: Container(
            constraints: const BoxConstraints(maxHeight: 130),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color:        _C.inputFieldBg,
              borderRadius: BorderRadius.circular(22),
            ),
            child: TextField(
              controller:      logic.inputCtrl,
              maxLines:        null,
              textInputAction: TextInputAction.newline,
              style: const TextStyle(
                  color: _C.textPrimary, fontSize: 16, height: 1.4),
              decoration: InputDecoration(
                hintText:       l.imInputHint,
                hintStyle:      const TextStyle(
                    color: _C.textSecond, fontSize: 16),
                border:         InputBorder.none,
                enabledBorder:  InputBorder.none,
                focusedBorder:  InputBorder.none,
                errorBorder:    InputBorder.none,
                disabledBorder: InputBorder.none,
                isDense:        true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ),

        const SizedBox(width: 4),

        // ── Right actions ────────────────────────────────────────────────────
        Obx(() {
          final hasText   = logic.state.inputHasText.value;
          final uploading = logic.state.uploadingMedia.value;

          if (hasText) {
            return _CircleBtn(
              color: primary,
              onTap: logic.send,
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 21),
            );
          }

          return Row(mainAxisSize: MainAxisSize.min, children: [
            // ① Camera icon (outlined) — tap opens camera
            if (uploading)
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 9),
                child: SizedBox(
                  width: 22, height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: primary)),
              )
            else
              GestureDetector(
                onTap: () async {
                  final xfile = await ImagePicker()
                      .pickImage(source: ImageSource.camera, imageQuality: 85);
                  if (xfile == null) return;
                  logic.state.uploadingMedia.value = true;
                  try {
                    await Get.find<MessageService>()
                        .sendImage(logic.state.conversationId.value, xfile.path);
                    logic.reload();
                  } finally {
                    logic.state.uploadingMedia.value = false;
                  }
                },
                child: const Padding(
                  padding: EdgeInsets.fromLTRB(4, 0, 4, 9),
                  child: Icon(Icons.camera_alt_outlined,
                      color: _C.textSecond, size: 25),
                ),
              ),

            // ② Mic — plain outline icon, NO circle background (WhatsApp style)
            //    tap starts recording; long-press = hold-to-record
            GestureDetector(
              onTap:            logic.startRecording,
              onLongPressStart: (_) => logic.startRecording(),
              onLongPressEnd:   (_) => logic.stopRecording(),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 2, 9),
                child: Icon(Icons.mic_none_rounded,
                    color: primary, size: 28),
              ),
            ),

            // ③ "+" button — opens attachment bottom sheet
            GestureDetector(
              onTap: () => _AttachmentSheet.show(context, logic),
              child: const Padding(
                padding: EdgeInsets.fromLTRB(4, 0, 4, 9),
                child: Icon(Icons.add_circle_outline_rounded,
                    color: _C.textSecond, size: 28),
              ),
            ),
          ]);
        }),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
/// Lightweight emoji picker bottom sheet.
// ─────────────────────────────────────────────────────────────────────────────
class _EmojiPicker {
  static const _rows = [
    ['😀','😂','🥰','😍','😎','🤩','😊','😇'],
    ['😢','😭','😡','🤬','😱','🤯','🥳','🤗'],
    ['👍','👎','❤️','🔥','🎉','✅','💯','⭐'],
    ['👋','🙏','💪','🤝','👏','🫶','💔','😴'],
    ['🍕','🍔','🍜','🍣','🍩','🎂','🍺','☕'],
    ['🌸','🌈','⚡','🎵','🎯','💡','🛡️','🚀'],
    ['🐶','🐱','🐼','🦁','🦋','🐝','🌺','🌴'],
    ['😏','🙄','😒','😌','🥺','😋','🤤','🫠'],
  ];

  static void show(BuildContext ctx, ChatLogic logic) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _EmojiSheet(logic: logic),
    );
  }
}

class _EmojiSheet extends StatelessWidget {
  final ChatLogic logic;
  const _EmojiSheet({required this.logic});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 280,
      decoration: const BoxDecoration(
        color: Color(0xFFF9F9F9),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(width: 36, height: 4,
              decoration: BoxDecoration(color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 8),
          Expanded(
            child: GridView.count(
              crossAxisCount: 8,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              childAspectRatio: 1,
              children: [
                for (final row in _EmojiPicker._rows)
                  for (final e in row)
                    GestureDetector(
                      onTap: () {
                        logic.inputCtrl.text += e;
                        logic.inputCtrl.selection = TextSelection.fromPosition(
                            TextPosition(offset: logic.inputCtrl.text.length));
                        logic.state.inputHasText.value = logic.inputCtrl.text.trim().isNotEmpty;
                        Navigator.of(context).pop();
                      },
                      child: Center(
                        child: Text(e, style: const TextStyle(fontSize: 26)),
                      ),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Circle button — filled or outlined (hollow) variant.
class _CircleBtn extends StatelessWidget {
  final Color        color;
  final VoidCallback onTap;
  final Widget       child;
  const _CircleBtn({
    required this.color, required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 44, height: 44,
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color:  color,
        shape:  BoxShape.circle,
        boxShadow: [BoxShadow(
            color:      color.withValues(alpha: 0.35),
            blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Center(child: child),
    ),
  );
}

// ╔══════════════════════════════════════════════════════════════════════════════
// Attachment Bottom Sheet  (WhatsApp-style grid of action icons)
// ╚══════════════════════════════════════════════════════════════════════════════

class _AttachmentSheet extends StatelessWidget {
  final ChatLogic logic;
  const _AttachmentSheet({required this.logic});

  static void show(BuildContext ctx, ChatLogic logic) =>
      showModalBottomSheet(
        context:         ctx,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _AttachmentSheet(logic: logic),
      );

  @override
  Widget build(BuildContext context) {
    final primary = context.primary;
    final l       = context.l10n;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, 16 + MediaQuery.of(context).padding.bottom),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Drag handle
        Container(
          width: 36, height: 4,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(height: 12),

        // Header row: Cancel + title
        Row(children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Text(l.cancel,
              style: TextStyle(color: primary, fontSize: 16,
                  fontWeight: FontWeight.w500)),
          ),
          const Spacer(),
          Text(l.imShare,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                color: _C.textPrimary)),
          const Spacer(),
          const SizedBox(width: 52),  // balance for cancel btn
        ]),
        const SizedBox(height: 20),

        // Action grid
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 8,
          children: [
            _SheetItem(
              icon: Icons.photo_library_outlined,
              color: const Color(0xFF5B9BD5),
              label: l.imAttachPhotos,
              onTap: () async {
                Navigator.pop(context);
                final xfile = await ImagePicker()
                    .pickImage(source: ImageSource.gallery, imageQuality: 85);
                if (xfile == null) return;
                logic.state.uploadingMedia.value = true;
                try {
                  await Get.find<MessageService>()
                      .sendImage(logic.state.conversationId.value, xfile.path);
                  logic.reload();
                } finally {
                  logic.state.uploadingMedia.value = false;
                }
              },
            ),
            _SheetItem(
              icon: Icons.camera_alt_outlined,
              color: const Color(0xFF4CAF50),
              label: l.imAttachCamera,
              onTap: () async {
                Navigator.pop(context);
                final xfile = await ImagePicker()
                    .pickImage(source: ImageSource.camera, imageQuality: 85);
                if (xfile == null) return;
                logic.state.uploadingMedia.value = true;
                try {
                  await Get.find<MessageService>()
                      .sendImage(logic.state.conversationId.value, xfile.path);
                  logic.reload();
                } finally {
                  logic.state.uploadingMedia.value = false;
                }
              },
            ),
            _SheetItem(
              icon: Icons.location_on_outlined,
              color: const Color(0xFFE53935),
              label: l.imAttachLocation,
              onTap: () {
                Navigator.pop(context);
                _LocationPicker.show(context, logic);
              },
            ),
            _SheetItem(
              icon: Icons.poll_outlined,
              color: const Color(0xFF9C27B0),
              label: l.imAttachPoll,
              onTap: () {
                Navigator.pop(context);
                Get.snackbar(l.comingSoon, '',
                    snackPosition: SnackPosition.BOTTOM,
                    duration: const Duration(seconds: 2));
              },
            ),
            _SheetItem(
              icon: Icons.event_outlined,
              color: const Color(0xFFFF7043),
              label: l.imAttachEvent,
              onTap: () {
                Navigator.pop(context);
                Get.snackbar(l.comingSoon, '',
                    snackPosition: SnackPosition.BOTTOM,
                    duration: const Duration(seconds: 2));
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
      ]),
    );
  }
}

class _SheetItem extends StatelessWidget {
  final IconData     icon;
  final Color        color;
  final String       label;
  final VoidCallback onTap;
  const _SheetItem({
    required this.icon, required this.color,
    required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 58, height: 58,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 28),
      ),
      const SizedBox(height: 8),
      Text(label,
        style: const TextStyle(
            color: _C.textPrimary, fontSize: 12, fontWeight: FontWeight.w500),
        textAlign: TextAlign.center),
    ]),
  );
}

// ╔══════════════════════════════════════════════════════════════════════════════
// Location Picker — flutter_map + geolocator + Nominatim search
// ╚══════════════════════════════════════════════════════════════════════════════

class _LocationPicker extends StatefulWidget {
  final ChatLogic logic;
  const _LocationPicker({required this.logic});

  static void show(BuildContext ctx, ChatLogic logic) => showDialog(
    context: ctx,
    builder: (_) => _LocationPicker(logic: logic),
  );

  @override
  State<_LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<_LocationPicker> {
  final _mapCtrl    = MapController();
  final _searchCtrl = TextEditingController();
  LatLng _center    = const LatLng(11.5564, 104.9282);  // default: Phnom Penh
  String _address   = '';
  bool   _loading   = true;

  @override
  void initState() {
    super.initState();
    _fetchCurrentLocation();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchCurrentLocation() async {
    try {
      bool svc = await Geolocator.isLocationServiceEnabled();
      if (!svc) { setState(() => _loading = false); return; }

      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        setState(() => _loading = false);
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high));
      final ll = LatLng(pos.latitude, pos.longitude);
      final addr = await _reverseGeocode(pos.latitude, pos.longitude);

      if (!mounted) return;
      _mapCtrl.move(ll, 16);
      setState(() { _center = ll; _address = addr; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Use a local Dio instance — NOT Get.find<Dio> which is never registered
  final dio.Dio _http = dio.Dio(dio.BaseOptions(
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 8),
  ));

  Future<String> _reverseGeocode(double lat, double lng) async {
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
        'lat': '$lat', 'lon': '$lng', 'format': 'json'
      });
      final resp = await _http.getUri(uri,
          options: dio.Options(headers: {'User-Agent': 'CamBook/1.0'}));
      return (resp.data as Map<String, dynamic>)['display_name'] as String? ?? '';
    } catch (_) { return '$lat, $lng'; }
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) return;
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'q': query, 'format': 'json', 'limit': '5'
      });
      final resp = await _http.getUri(uri,
          options: dio.Options(headers: {'User-Agent': 'CamBook/1.0'}));
      final list = resp.data as List;
      if (list.isEmpty) return;
      final first = list.first as Map<String, dynamic>;
      final lat   = double.parse(first['lat'] as String);
      final lng   = double.parse(first['lon'] as String);
      final ll    = LatLng(lat, lng);
      _mapCtrl.move(ll, 16);
      setState(() {
        _center  = ll;
        _address = first['display_name'] as String? ?? query;
      });
    } catch (_) {}
  }

  Future<void> _send() async {
    Navigator.pop(context);
    await widget.logic.sendLocation(_center.latitude, _center.longitude, _address);
  }

  @override
  Widget build(BuildContext context) {
    final primary = context.primary;
    final l       = context.l10n;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.65,
        child: Column(children: [

          // ── Header ────────────────────────────────────────────────────────
          Container(
            color: primary,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller:   _searchCtrl,
                  onSubmitted:  _search,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText:       l.imLocationSearch,
                    hintStyle: const TextStyle(
                        color: Colors.white60, fontSize: 14),
                    border:        InputBorder.none,
                    isDense:       true,
                    contentPadding: EdgeInsets.zero,
                    prefixIcon:    const Icon(Icons.search_rounded,
                        color: Colors.white70, size: 20),
                  ),
                ),
              ),
              // Refresh / current location
              GestureDetector(
                onTap: _fetchCurrentLocation,
                child: const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(Icons.my_location_rounded,
                      color: Colors.white, size: 22),
                ),
              ),
            ]),
          ),

          // ── Map ───────────────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? Center(child: CircularProgressIndicator(color: primary))
                : FlutterMap(
                    mapController: _mapCtrl,
                    options: MapOptions(
                      initialCenter: _center,
                      initialZoom:   16,
                      onPositionChanged: (pos, _) {
                        setState(() => _center = pos.center);
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.cambook.partner',
                      ),
                      MarkerLayer(markers: [
                        Marker(
                          point: _center,
                          width: 36, height: 36,
                          child: Icon(Icons.location_on,
                              color: primary, size: 36),
                        ),
                      ]),
                    ],
                  ),
          ),

          // ── Address + Send ────────────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Row(children: [
              Icon(Icons.location_on_outlined, color: primary, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _address.isNotEmpty ? _address : l.imLocationNone,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: _C.textPrimary, fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _send,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 10),
                ),
                child: Text(l.imSendLocation),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ── Map View Dialog (view a received location) ────────────────────────────────

class _MapViewDialog extends StatelessWidget {
  final double lat, lng;
  final String address;
  const _MapViewDialog({required this.lat, required this.lng, required this.address});

  @override
  Widget build(BuildContext context) {
    final primary = context.primary;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.55,
        child: Column(children: [
          Container(
            color: primary,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(address,
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 14,
                      fontWeight: FontWeight.w600)),
              ),
            ]),
          ),
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(lat, lng),
                initialZoom:   16,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.cambook.partner',
                ),
                MarkerLayer(markers: [
                  Marker(
                    point: LatLng(lat, lng),
                    width: 36, height: 36,
                    child: Icon(Icons.location_on, color: primary, size: 36),
                  ),
                ]),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Recording Bar ─────────────────────────────────────────────────────────────

class _RecordingBar extends StatelessWidget {
  final ChatLogic logic;
  const _RecordingBar({required this.logic});

  String _fmt(int s) {
    final m = s ~/ 60, sec = s % 60;
    return '${m.toString().padLeft(2,'0')}:${sec.toString().padLeft(2,'0')}';
  }

  @override
  Widget build(BuildContext context) {
    final l       = context.l10n;
    final primary = context.primary;
    return Row(children: [
      GestureDetector(
        onTap: logic.cancelRecording,
        child: const Icon(Icons.delete_outline_rounded,
            color: _C.recordRed, size: 28),
      ),
      const SizedBox(width: 10),
      Expanded(child: Row(children: [
        _PulsingDot(),
        const SizedBox(width: 6),
        Obx(() => Text(_fmt(logic.state.recSeconds.value),
          style: const TextStyle(
            color: _C.textPrimary, fontSize: 14, fontWeight: FontWeight.w600))),
        const SizedBox(width: 10),
        Flexible(child: Text(l.imReleaseToSend,
          style: const TextStyle(color: _C.textSecond, fontSize: 12),
          overflow: TextOverflow.ellipsis)),
      ])),
      GestureDetector(
        onTap: logic.stopRecording,
        child: Container(
          width: 46, height: 46,
          decoration: BoxDecoration(color: primary, shape: BoxShape.circle),
          child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
        ),
      ),
    ]);
  }
}

class _PulsingDot extends StatefulWidget {
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700))
      ..repeat(reverse: true);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _ctrl,
    builder: (_, __) => Container(
      width: 10, height: 10,
      decoration: BoxDecoration(
        color: _C.recordRed.withValues(alpha: 0.5 + 0.5 * _ctrl.value),
        shape: BoxShape.circle,
      ),
    ),
  );
}
