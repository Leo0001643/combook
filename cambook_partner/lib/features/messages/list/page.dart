import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/extensions/theme_ext.dart';
import '../../../core/i18n/l10n_ext.dart';
import '../../../core/models/models.dart';
import '../../../core/theme/app_theme_controller.dart';
import '../../../core/utils/date_util.dart';
import '../../../core/widgets/common_widgets.dart';
import 'logic.dart';

class MessageListPage extends StatelessWidget {
  const MessageListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l     = context.l10n;
    final logic = Get.find<MessageListLogic>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: MainAppBar(title: l.messagesTitle),
      body: Obx(() {
        final convs = logic.conversations;
        if (convs.isEmpty) {
          return EmptyView(
              message: l.noMessages,
              iconWidget: const WeChatBubbleIcon(color: AppColors.textHint, size: 64));
        }
        return RefreshIndicator(
          color: context.primary,
          onRefresh: logic.refresh,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: convs.length,
            itemBuilder: (_, i) => _ConvTile(conv: convs[i], logic: logic),
          ),
        );
      }),
    );
  }
}

class _ConvTile extends StatelessWidget {
  final ConversationModel conv;
  final MessageListLogic logic;
  const _ConvTile({required this.conv, required this.logic});

  @override
  Widget build(BuildContext context) {
    final hasUnread = conv.unread > 0;
    final avatarColor = _avatarColor(conv.type);
    return BounceTap(
      onTap: () => logic.openChat(conv),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: hasUnread
              ? context.primary.withValues(alpha: 0.03)
              : Colors.transparent,
          border: const Border(
            bottom: BorderSide(color: Color(0xFFF3F4F6)),
          ),
        ),
        child: Row(children: [
          // Avatar with optional badge
          Stack(children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    avatarColor,
                    avatarColor.withValues(alpha: 0.7),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(
                  color: avatarColor.withValues(alpha: 0.30),
                  blurRadius: 8, offset: const Offset(0, 3),
                )],
              ),
              child: conv.type == ConversationType.customer
                  ? Center(child: Text(
                      conv.name.isNotEmpty ? conv.name[0].toUpperCase() : '?',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 20,
                          fontWeight: FontWeight.w800),
                    ))
                  : Icon(_avatarIcon(conv.type), color: Colors.white, size: 22),
            ),
            if (hasUnread)
              Positioned(right: 0, top: 0, child: Container(
                width: 18, height: 18,
                decoration: BoxDecoration(
                  color: AppColors.danger,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Center(child: Text(
                  conv.unread > 9 ? '9+' : '${conv.unread}',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 9,
                      fontWeight: FontWeight.w800),
                )),
              )),
          ]),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(child: Text(conv.name,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w600,
                        color: const Color(0xFF111827)))),
                Text(DateUtil.relative(conv.lastTime),
                    style: TextStyle(
                        fontSize: 11,
                        color: hasUnread ? context.primary : AppColors.textHint,
                        fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w400)),
              ]),
              const SizedBox(height: 4),
              Text(conv.lastMessage,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: hasUnread ? FontWeight.w500 : FontWeight.w400,
                      color: hasUnread
                          ? const Color(0xFF374151)
                          : AppColors.textSecond),
                  overflow: TextOverflow.ellipsis, maxLines: 1),
            ],
          )),
        ]),
      ),
    );
  }

  Color _avatarColor(ConversationType t) => switch (t) {
    ConversationType.system   => AppColors.info,
    ConversationType.customer => AppThemeController.to.primary,
    ConversationType.order    => AppColors.success,
  };

  IconData _avatarIcon(ConversationType t) => switch (t) {
    ConversationType.system   => Icons.notifications_rounded,
    ConversationType.customer => Icons.person_rounded,
    ConversationType.order    => Icons.receipt_long_rounded,
  };
}
