import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/services/im_service.dart';
import '../../../core/routes/app_routes.dart';
import '../models/im_models.dart';
import 'im_list_logic.dart';
import '../_shared/im_theme.dart';
import '../_shared/im_avatar.dart';
import '../_shared/im_time_util.dart';

/// IM 会话列表页 — WhatsApp 暗色风格
class ImListPage extends StatelessWidget {
  const ImListPage({super.key});

  @override
  Widget build(BuildContext context) {
    Get.find<ImListLogic>();
    return Scaffold(
      backgroundColor: ImTheme.bg,
      appBar: _buildAppBar(context),
      body: Obx(() {
        final list = ImService.to.conversations;
        if (list.isEmpty) return _buildEmpty();
        return ListView.builder(
          itemCount: list.length,
          itemBuilder: (_, i) => _ConvTile(conv: list[i]),
        );
      }),
      floatingActionButton: FloatingActionButton(
        backgroundColor: ImTheme.accent,
        onPressed: () {},   // TODO: 新建会话（通讯录）
        child: const Icon(Icons.chat_bubble_outline, color: Colors.white),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) => AppBar(
    backgroundColor: ImTheme.header,
    elevation: 0,
    title: const Text('消息', style: TextStyle(color: ImTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 18)),
    actions: [
      IconButton(
        icon: const Icon(Icons.search, color: ImTheme.textSub),
        onPressed: () {},
      ),
      IconButton(
        icon: const Icon(Icons.more_vert, color: ImTheme.textSub),
        onPressed: () {},
      ),
    ],
  );

  Widget _buildEmpty() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.chat_bubble_outline, size: 64, color: ImTheme.textMuted.withValues(alpha: 0.4)),
        const SizedBox(height: 16),
        const Text('暂无消息', style: TextStyle(color: ImTheme.textMuted, fontSize: 15)),
      ],
    ),
  );
}

// ── 会话列表项 ─────────────────────────────────────────────────────────────

class _ConvTile extends StatelessWidget {
  final ImConversation conv;
  const _ConvTile({required this.conv});

  @override
  Widget build(BuildContext context) {
    final hasUnread = conv.unreadCount > 0;
    return InkWell(
      onTap: () => Get.toNamed(AppRoutes.imChat, arguments: {
        'conversationId': conv.conversationId,
        'peerName':       conv.peerName ?? '未知',
        'peerType':       conv.peerType ?? 'member',
        'peerId':         conv.peerId ?? 0,
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: ImTheme.divider, width: 0.5)),
        ),
        child: Row(children: [
          ImAvatar(
            name:   conv.peerName ?? '?',
            url:    conv.peerAvatar,
            size:   50,
            userId: conv.peerId,
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(
                    conv.peerName ?? '未知',
                    style: TextStyle(
                      color: ImTheme.textPrimary,
                      fontSize: 15,
                      fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  )),
                  Text(
                    ImTimeUtil.fmtConvTime(conv.lastMsgTime),
                    style: TextStyle(
                      fontSize: 11,
                      color: hasUnread ? ImTheme.accent : ImTheme.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Row(children: [
                Expanded(child: Text(
                  conv.lastMsgPreview ?? '暂无消息',
                  style: TextStyle(
                    fontSize: 13,
                    color: hasUnread ? ImTheme.textSub : ImTheme.textMuted,
                    fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )),
                if (hasUnread) ...[
                  const SizedBox(width: 6),
                  _UnreadBadge(count: conv.unreadCount),
                ],
              ]),
            ],
          )),
        ]),
      ),
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  final int count;
  const _UnreadBadge({required this.count});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: ImTheme.accent,
      borderRadius: BorderRadius.circular(12),
    ),
    constraints: const BoxConstraints(minWidth: 20),
    child: Text(
      count > 99 ? '99+' : '$count',
      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
      textAlign: TextAlign.center,
    ),
  );
}
