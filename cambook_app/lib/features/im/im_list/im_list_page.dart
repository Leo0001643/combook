import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';

/// IM 聊天列表页 — 全部 i18n
class ImListPage extends StatelessWidget {
  const ImListPage({super.key});

  // nameKey: 'service' / 'system' => resolve via l; others are real names from backend
  static const _sessions = [
    {'id': '1', 'nameKey': null, 'name': 'Chen Xiuling', 'lastMsg': 'Ok I will be there on time', 'timeKey': null, 'time': '14:32', 'unread': 2, 'type': 'tech'},
    {'id': '2', 'nameKey': 'service', 'name': '', 'lastMsg': 'Your order has been accepted', 'timeKey': null, 'time': '10:05', 'unread': 0, 'type': 'service'},
    {'id': '3', 'nameKey': null, 'name': 'Cai Qing', 'lastMsg': 'I will be there on time', 'timeKey': 'yesterday', 'time': '', 'unread': 0, 'type': 'tech'},
    {'id': '4', 'nameKey': 'system', 'name': '', 'lastMsg': 'Welcome to CamBook!', 'timeKey': 'yesterday', 'time': '', 'unread': 1, 'type': 'system'},
  ];

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        title: Text(l.messages, style: const TextStyle(color: AppTheme.gray900, fontWeight: FontWeight.w700)),
        centerTitle: true,
        actions: [IconButton(icon: const Icon(Icons.edit_outlined, color: AppTheme.gray600), onPressed: () {})],
      ),
      body: ListView.separated(
        itemCount: _sessions.length,
        separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
        itemBuilder: (_, i) => _buildSessionTile(context, l, _sessions[i]),
      ),
    );
  }

  Widget _buildSessionTile(BuildContext context, AppLocalizations l, Map<String, dynamic> session) {
    final isService = session['type'] == 'service';
    final isSystem = session['type'] == 'system';
    final unread = session['unread'] as int;
    final displayName = session['nameKey'] == 'service'
        ? l.customerService
        : session['nameKey'] == 'system'
            ? l.sysNotifTitle
            : session['name'] as String;
    final displayTime = session['timeKey'] == 'yesterday'
        ? l.yesterday
        : session['time'] as String;

    return ListTile(
      onTap: () => Get.toNamed('/im/chat/${session['id']}'),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Stack(
        children: [
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: isSystem
                  ? LinearGradient(colors: [Colors.grey.shade300, Colors.grey.shade200])
                  : isService
                      ? const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)])
                      : LinearGradient(colors: [AppTheme.primaryColor.withOpacity(0.7), AppTheme.primaryColor]),
            ),
            child: Center(child: Icon(
              isSystem ? Icons.notifications_outlined : isService ? Icons.support_agent : Icons.person,
              color: Colors.white, size: 24,
            )),
          ),
          if (unread > 0)
            Positioned(
              right: 0, top: 0,
              child: Container(
                width: 18, height: 18,
                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                child: Center(child: Text('$unread', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700))),
              ),
            ),
        ],
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(displayName, style: TextStyle(fontSize: 15, fontWeight: unread > 0 ? FontWeight.w700 : FontWeight.w500, color: AppTheme.gray900)),
          Text(displayTime, style: TextStyle(fontSize: 11, color: unread > 0 ? AppTheme.primaryColor : AppTheme.gray400)),
        ],
      ),
      subtitle: Text(
        session['lastMsg'] as String,
        style: TextStyle(fontSize: 13, color: unread > 0 ? AppTheme.gray700 : AppTheme.gray400, fontWeight: unread > 0 ? FontWeight.w500 : FontWeight.normal),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
