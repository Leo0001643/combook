import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';

/// IM 聊天详情页 — 完整聊天 UI，全部 i18n
class ImChatPage extends StatefulWidget {
  final String targetUserId;
  const ImChatPage({super.key, required this.targetUserId});

  @override
  State<ImChatPage> createState() => _ImChatPageState();
}

class _ImChatPageState extends State<ImChatPage> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _isComposing = false;

  final _messages = [
    {'id': '1', 'text': '您好，我是陈秀玲技师，请问您预约的是60分钟全身推拿？', 'isMine': false, 'time': '14:00'},
    {'id': '2', 'text': 'Yes, that is correct. Can you please confirm the address?', 'isMine': true, 'time': '14:01'},
    {'id': '3', 'text': 'Of course! Your address is Room 201, Building 5, Sunrise Garden. I will arrive on time.', 'isMine': false, 'time': '14:02'},
    {'id': '4', 'text': 'Great, thank you! 谢谢', 'isMine': true, 'time': '14:03'},
    {'id': '5', 'text': 'I am on my way now, will arrive in about 15 minutes.', 'isMine': false, 'time': '14:30'},
  ];

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: AppTheme.gray900), onPressed: () => Navigator.pop(context)),
        title: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [AppTheme.primaryColor, AppTheme.accentColor])),
            child: const Center(child: Icon(Icons.person, color: Colors.white, size: 20)),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('陈秀玲', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.gray900)),
              Row(children: [
                Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                const SizedBox(width: 4),
                Text(l.onlineNow, style: const TextStyle(fontSize: 11, color: Colors.green)),
              ]),
            ],
          ),
        ]),
        actions: [
          IconButton(icon: const Icon(Icons.phone_outlined, color: AppTheme.gray600), onPressed: () {}),
          IconButton(icon: const Icon(Icons.more_vert, color: AppTheme.gray600), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (_, i) => _buildMessage(_messages[i]),
            ),
          ),
          _buildInputBar(l),
        ],
      ),
    );
  }

  Widget _buildMessage(Map<String, dynamic> msg) {
    final isMine = msg['isMine'] as bool;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine) ...[
            Container(
              width: 32, height: 32,
              decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [AppTheme.primaryColor, AppTheme.accentColor])),
              child: const Center(child: Icon(Icons.person, color: Colors.white, size: 18)),
            ),
            const SizedBox(width: 8),
          ],
          Column(
            crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.65),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isMine ? AppTheme.primaryColor : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isMine ? 18 : 4),
                    bottomRight: Radius.circular(isMine ? 4 : 18),
                  ),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4)],
                ),
                child: Text(
                  msg['text'] as String,
                  style: TextStyle(fontSize: 14, color: isMine ? Colors.white : AppTheme.gray900, height: 1.4),
                ),
              ),
              const SizedBox(height: 4),
              Text(msg['time'] as String, style: const TextStyle(fontSize: 10, color: AppTheme.gray400)),
            ],
          ),
          if (isMine) ...[
            const SizedBox(width: 8),
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.gray200),
              child: const Center(child: Icon(Icons.person, color: AppTheme.gray500, size: 18)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputBar(AppLocalizations l) {
    return Container(
      padding: EdgeInsets.fromLTRB(12, 8, 12, MediaQuery.of(context).padding.bottom + 8),
      decoration: const BoxDecoration(color: Colors.white),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.add_circle_outline, color: AppTheme.gray500, size: 24), onPressed: () {}),
          IconButton(icon: const Icon(Icons.image_outlined, color: AppTheme.gray500, size: 24), onPressed: () {}),
          Expanded(
            child: Container(
              decoration: BoxDecoration(color: AppTheme.gray100, borderRadius: BorderRadius.circular(20)),
              child: TextField(
                controller: _inputCtrl,
                onChanged: (v) => setState(() => _isComposing = v.trim().isNotEmpty),
                decoration: InputDecoration(
                  hintText: l.typeMessage,
                  hintStyle: const TextStyle(color: AppTheme.gray400, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                maxLines: null,
                textInputAction: TextInputAction.newline,
              ),
            ),
          ),
          const SizedBox(width: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: _isComposing ? 40 : 0,
            height: 40,
            child: _isComposing
                ? GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      width: 40, height: 40,
                      decoration: const BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle),
                      child: const Icon(Icons.send, color: Colors.white, size: 18),
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    if (_inputCtrl.text.trim().isEmpty) return;
    // TODO: 发送 WebSocket 消息
    setState(() {
      _messages.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'text': _inputCtrl.text.trim(),
        'isMine': true,
        'time': AppLocalizations.of(context).timeNow,
      });
      _inputCtrl.clear();
      _isComposing = false;
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    });
  }
}
