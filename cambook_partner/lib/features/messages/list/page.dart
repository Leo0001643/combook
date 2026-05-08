import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/extensions/theme_ext.dart';
import '../../../core/i18n/l10n_ext.dart';
import '../../../core/models/models.dart';
import '../../../core/services/message_service.dart';
import '../../../core/utils/date_util.dart';
import '../../../core/widgets/common_widgets.dart';
import 'logic.dart';

// ╔══════════════════════════════════════════════════════════════════════════════
// MessageListPage
// ╚══════════════════════════════════════════════════════════════════════════════
class MessageListPage extends StatelessWidget {
  const MessageListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l       = context.l10n;
    final logic   = Get.find<MessageListLogic>();
    final primary = context.primary;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _ListAppBar(l: l, primary: primary),
      body: Obx(() {
        final convs    = logic.conversations;
        final contacts = Get.find<MessageService>().contacts;

        return RefreshIndicator(
          color:           primary,
          backgroundColor: AppColors.surface,
          onRefresh:       logic.refresh,
          child: CustomScrollView(
            slivers: [
              // ── Contacts (operations / marketing staff) ──────────────────
              SliverToBoxAdapter(
                child: _ContactsSection(
                  contacts: contacts,
                  primary:  primary,
                  l:        l,
                  logic:    logic,
                ),
              ),

              // ── Section header ────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Text(
                    l.messagesTitle,
                    style: const TextStyle(
                      color:      AppColors.textSecond,
                      fontSize:   12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ),

              if (convs.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyState(l: l, primary: primary),
                )
              else
                SliverList.separated(
                  itemCount: convs.length,
                  separatorBuilder: (_, __) => const Divider(
                    height: 0, thickness: 0.6,
                    indent: 82, endIndent: 16,
                    color: AppColors.divider,
                  ),
                  itemBuilder: (_, i) => _ConvTile(
                    conv:    convs[i],
                    logic:   logic,
                    primary: primary,
                  ),
                ),

              const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
            ],
          ),
        );
      }),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primary,
        elevation: 3,
        onPressed: () {},
        child: const Icon(Icons.edit_rounded, color: Colors.white, size: 22),
      ),
    );
  }
}

// ── Contacts section (operations/marketing staff) ─────────────────────────────

class _ContactsSection extends StatelessWidget {
  final List<ImContactModel> contacts;
  final Color                primary;
  final dynamic              l;
  final MessageListLogic     logic;

  const _ContactsSection({
    required this.contacts,
    required this.primary,
    required this.l,
    required this.logic,
  });

  @override
  Widget build(BuildContext context) {
    // Always visible header; items hidden when empty (shows placeholder dot row)
    return Container(
      color:  AppColors.surface,
      margin: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(children: [
              Icon(Icons.people_alt_rounded,
                  size: 16, color: primary.withValues(alpha: 0.85)),
              const SizedBox(width: 6),
              Text(
                l.imContacts,
                style: TextStyle(
                  color:      primary,
                  fontSize:   13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ]),
          ),
          SizedBox(
            height: 88,
            child: contacts.isEmpty
                ? _ContactPlaceholder(primary: primary)
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: contacts.length,
                    itemBuilder: (_, i) =>
                        _ContactChip(contact: contacts[i], primary: primary),
                  ),
          ),
          const Divider(height: 0, thickness: 0.6, color: AppColors.divider),
        ],
      ),
    );
  }
}

class _ContactChip extends StatelessWidget {
  final ImContactModel contact;
  final Color          primary;
  const _ContactChip({required this.contact, required this.primary});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {/* TODO: start chat with contact */},
      child: Container(
        width: 66,
        margin: const EdgeInsets.symmetric(horizontal: 5),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: primary.withValues(alpha: 0.12),
                  backgroundImage: contact.avatar != null && contact.avatar!.isNotEmpty
                      ? NetworkImage(contact.avatar!) as ImageProvider
                      : null,
                  child: (contact.avatar == null || contact.avatar!.isEmpty)
                      ? Text(
                          contact.name.isNotEmpty
                              ? contact.name[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color:      primary,
                            fontSize:   20,
                            fontWeight: FontWeight.w700),
                        )
                      : null,
                ),
                // online dot
                Positioned(
                  right: 2, bottom: 2,
                  child: Container(
                    width: 11, height: 11,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              contact.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11, color: AppColors.textPrimary,
                fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

/// Placeholder shown when contacts list is empty — shows a soft hint row.
class _ContactPlaceholder extends StatelessWidget {
  final Color primary;
  const _ContactPlaceholder({required this.primary});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.person_add_alt_1_rounded,
            size: 28, color: primary.withValues(alpha: 0.30)),
        const SizedBox(height: 4),
        Text(
          context.l10n.imNoContacts,
          style: TextStyle(
            color:    AppColors.textSecond.withValues(alpha: 0.6),
            fontSize: 12),
        ),
      ],
    ),
  );
}

// ── Empty conversation state ───────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final dynamic l;
  final Color   primary;
  const _EmptyState({required this.l, required this.primary});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: primary.withValues(alpha: 0.08),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.chat_bubble_outline_rounded,
            color: primary.withValues(alpha: 0.55), size: 56),
      ),
      const SizedBox(height: 16),
      Text(l.noMessages,
        style: const TextStyle(
          color: AppColors.textSecond, fontSize: 15,
          fontWeight: FontWeight.w500)),
    ]),
  );
}

// ── App Bar ───────────────────────────────────────────────────────────────────

class _ListAppBar extends StatelessWidget implements PreferredSizeWidget {
  final dynamic l;
  final Color   primary;
  const _ListAppBar({required this.l, required this.primary});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) => AppBar(
    backgroundColor: primary,
    elevation: 0,
    automaticallyImplyLeading: false,
    title: Text(l.messagesTitle,
      style: const TextStyle(
        color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
    actions: [
      IconButton(
        icon: const Icon(Icons.search_rounded, color: Colors.white, size: 22),
        onPressed: () {},
      ),
      PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, color: Colors.white, size: 22),
        color: AppColors.surface,
        onSelected: (_) {},
        itemBuilder: (_) => [
          PopupMenuItem(
            value: 'mark_read',
            child: Text(l.imMarkAllRead,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 14)),
          ),
        ],
      ),
    ],
  );
}

// ── Conversation Tile (with swipe actions) ────────────────────────────────────

class _ConvTile extends StatelessWidget {
  final ConversationModel conv;
  final MessageListLogic  logic;
  final Color             primary;
  const _ConvTile({
    required this.conv, required this.logic, required this.primary});

  @override
  Widget build(BuildContext context) {
    final l         = context.l10n;
    final hasUnread = conv.unread > 0;

    return Slidable(
      key:         ValueKey(conv.id),
      endActionPane: ActionPane(
        motion:         const DrawerMotion(),
        extentRatio:    0.68,
        dismissible:    null,
        children: [
          // ── Mark read ────────────────────────────────────────────────────
          SlidableAction(
            onPressed: (_) => logic.markRead(conv.id),
            backgroundColor: const Color(0xFF2196F3),
            foregroundColor: Colors.white,
            icon:  Icons.done_all_rounded,
            label: l.imMarkRead,
            borderRadius: BorderRadius.zero,
          ),
          // ── Clear messages (local only) ───────────────────────────────────
          SlidableAction(
            onPressed: (_) => _confirmClear(context, l),
            backgroundColor: const Color(0xFFFF9800),
            foregroundColor: Colors.white,
            icon:  Icons.clear_all_rounded,
            label: l.imClearMessages,
            borderRadius: BorderRadius.zero,
          ),
          // ── Delete conversation (local only) ─────────────────────────────
          SlidableAction(
            onPressed: (_) => _confirmDelete(context, l),
            backgroundColor: AppColors.danger,
            foregroundColor: Colors.white,
            icon:  Icons.delete_rounded,
            label: l.imDelete,
            borderRadius: BorderRadius.zero,
          ),
        ],
      ),
      child: BounceTap(
        onTap: () => logic.openChat(conv),
        child: Container(
          color: AppColors.surface,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: Row(children: [
            // Avatar with unread badge on top-right
            _ConvAvatar(conv: conv, primary: primary),
            const SizedBox(width: 14),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + timestamp row
                Row(children: [
                  Expanded(
                    child: Text(conv.name,
                      style: TextStyle(
                        color:      AppColors.textPrimary,
                        fontSize:   15.5,
                        fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w500,
                        letterSpacing: 0.1,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(DateUtil.relative(conv.lastTime),
                    style: TextStyle(
                      fontSize:   11.5,
                      color:      hasUnread ? primary : AppColors.textSecond,
                      fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ]),
                const SizedBox(height: 4),

                // Preview row (no badge here — moved to avatar)
                Row(children: [
                  if (!hasUnread) ...[
                    const Icon(Icons.done_all_rounded,
                        size: 14, color: Color(0xFF53BDEB)),
                    const SizedBox(width: 3),
                  ],
                  if (_previewIcon(conv.lastMessage) != null) ...[
                    Icon(_previewIcon(conv.lastMessage)!,
                        size: 14, color: AppColors.textSecond),
                    const SizedBox(width: 4),
                  ],
                  Expanded(
                    child: Text(conv.lastMessage,
                      style: TextStyle(
                        fontSize:   13.5,
                        color:      hasUnread
                            ? AppColors.textSecond
                            : AppColors.textSecond.withValues(alpha: 0.75),
                        fontWeight: hasUnread ? FontWeight.w500 : FontWeight.w400,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ]),
              ],
            )),
          ]),
        ),
      ),
    );
  }

  IconData? _previewIcon(String msg) {
    if (msg.startsWith('[Image]') || msg.startsWith('📷')) return Icons.camera_alt_rounded;
    if (msg.startsWith('[Voice]') || msg.startsWith('🎤')) return Icons.mic_rounded;
    if (msg.startsWith('[Video]') || msg.startsWith('📹')) return Icons.videocam_rounded;
    return null;
  }

  Future<void> _confirmClear(BuildContext ctx, dynamic l) async {
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: Text(l.imClearMessages),
        content: Text(l.imClearConfirm),
        actions: [
          TextButton(onPressed: () => Get.back(result: false),
              child: Text(l.cancel)),
          TextButton(onPressed: () => Get.back(result: true),
              child: Text(l.confirm,
                  style: const TextStyle(color: AppColors.danger))),
        ],
      ),
    );
    if (ok == true) logic.clearLocalMessages(conv.id);
  }

  Future<void> _confirmDelete(BuildContext ctx, dynamic l) async {
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: Text(l.imDelete),
        content: Text(l.imDeleteConfirm),
        actions: [
          TextButton(onPressed: () => Get.back(result: false),
              child: Text(l.cancel)),
          TextButton(onPressed: () => Get.back(result: true),
              child: Text(l.confirm,
                  style: const TextStyle(color: AppColors.danger))),
        ],
      ),
    );
    if (ok == true) logic.deleteLocalConversation(conv.id);
  }
}

// ── Conversation Avatar (with unread badge on top-right) ─────────────────────

class _ConvAvatar extends StatelessWidget {
  final ConversationModel conv;
  final Color             primary;
  const _ConvAvatar({required this.conv, required this.primary});

  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    children: [
      // ── Main avatar circle ───────────────────────────────────────────────
      Container(
        width: 54, height: 54,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _bgColor(conv.type, primary),
          boxShadow: [BoxShadow(
            color: _bgColor(conv.type, primary).withValues(alpha: 0.25),
            blurRadius: 6, offset: const Offset(0, 2),
          )],
        ),
        clipBehavior: Clip.hardEdge,
        child: _avatarContent(),
      ),

      // ── Online indicator (bottom-right, only for customer) ────────────────
      if (conv.type == ConversationType.customer)
        Positioned(
          right: 0, bottom: 0,
          child: Container(
            width: 14, height: 14,
            decoration: BoxDecoration(
              color:  const Color(0xFF4CAF50),
              shape:  BoxShape.circle,
              border: Border.all(color: AppColors.surface, width: 2),
            ),
          ),
        ),

      // ── Unread badge (top-right, shown when unread > 0) ──────────────────
      if (conv.unread > 0)
        Positioned(
          top: -3, right: -3,
          child: Container(
            constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color:         AppColors.danger,
              borderRadius:  BorderRadius.circular(10),
              border:        Border.all(color: Colors.white, width: 1.8),
              boxShadow: [BoxShadow(
                color:       AppColors.danger.withValues(alpha: 0.4),
                blurRadius:  4, offset: const Offset(0, 1),
              )],
            ),
            alignment: Alignment.center,
            child: Text(
              conv.unread > 99 ? '99+' : '${conv.unread}',
              style: const TextStyle(
                color: Colors.white, fontSize: 10,
                fontWeight: FontWeight.w800, height: 1.1),
            ),
          ),
        ),
    ],
  );

  Widget _avatarContent() {
    if (conv.avatar != null && conv.avatar!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: conv.avatar!,
        width: 54, height: 54, fit: BoxFit.cover,
        errorWidget: (_, __, ___) => _Initials(name: conv.name),
      );
    }
    return conv.type == ConversationType.customer
        ? _Initials(name: conv.name)
        : Icon(_typeIcon(conv.type), color: Colors.white, size: 24);
  }

  Color _bgColor(ConversationType t, Color primary) => switch (t) {
    ConversationType.customer => primary,
    ConversationType.order    => const Color(0xFF5C8A6E),
    ConversationType.system   => const Color(0xFF7986CB),
  };

  IconData _typeIcon(ConversationType t) => switch (t) {
    ConversationType.system   => Icons.notifications_active_rounded,
    ConversationType.order    => Icons.receipt_long_rounded,
    ConversationType.customer => Icons.person_rounded,
  };
}

class _Initials extends StatelessWidget {
  final String name;
  const _Initials({required this.name});

  @override
  Widget build(BuildContext context) => Center(
    child: Text(
      name.isNotEmpty ? name[0].toUpperCase() : '?',
      style: const TextStyle(
          color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
  );
}
