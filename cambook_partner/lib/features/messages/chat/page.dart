import 'package:flutter/material.dart';
import '../../../core/widgets/app_dialog.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/i18n/l10n_ext.dart';
import '../../../core/models/models.dart';
import '../../../core/utils/date_util.dart';
import '../../../core/widgets/common_widgets.dart';
import 'logic.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  List<String> _quickReplyTexts(BuildContext context) {
    final l = context.l10n;
    return [l.qr1, l.qr2, l.qr3, l.qr4, l.qr5, l.qr6];
  }

  void _callCustomer(BuildContext context, ChatLogic logic) {
    final l = context.l10n;
    final phone = logic.state.customerPhone.value;
    if (phone.isEmpty) { AppToast.info(l.noData); return; }
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          CircleAvatar(radius: 28, backgroundColor: AppColors.success.withValues(alpha: 0.12),
              child: const Icon(Icons.phone_rounded, color: AppColors.success, size: 28)),
          const SizedBox(height: 12),
          Text(phone, style: AppTextStyles.h2),
          const SizedBox(height: 6),
          Text(logic.state.conversationName.value, style: AppTextStyles.body3),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Get.back();
                AppToast.success(phone);
              },
              icon: const Icon(Icons.phone_rounded),
              label: Text(l.call, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                minimumSize: const Size(0, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  void _pickImage(BuildContext context) {
    final l = context.l10n;
    AppToast.info(l.comingSoon);
  }

  @override
  Widget build(BuildContext context) {
    final logic = Get.find<ChatLogic>();
    final state = logic.state;
    final l = context.l10n;
    final quickReplies = _quickReplyTexts(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Obx(() => Text(state.conversationName.value)),
        leading: BounceTap(
          pressScale: 0.78,
          onTap: () => Get.back(),
          child: const Padding(
            padding: EdgeInsets.fromLTRB(12, 8, 8, 8),
            child: Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          ),
        ),
        actions: [
          BounceTap(
            pressScale: 0.78,
            onTap: () => _callCustomer(context, logic),
            child: const Padding(padding: EdgeInsets.all(10), child: Icon(Icons.phone_rounded, color: Colors.white, size: 24)),
          ),
          BounceTap(
            pressScale: 0.78,
            onTap: logic.mockReceive,
            child: const Padding(padding: EdgeInsets.all(10), child: Icon(Icons.reply_rounded, color: Colors.white, size: 24)),
          ),
          const MainAppBarActions(),
        ],
      ),
      body: Column(children: [
        Expanded(
          child: Obx(() {
            final msgs = state.messages;
            if (msgs.isEmpty) {
              return EmptyView(
                message: l.noChatMessages,
                iconWidget: WeChatBubbleIcon(color: AppColors.textHint, size: 64));
            }
            return ListView.builder(
              controller: logic.scrollCtrl,
              padding: const EdgeInsets.all(AppSizes.pagePadding),
              itemCount: msgs.length,
              itemBuilder: (_, i) => _MessageBubble(msg: msgs[i]),
            );
          }),
        ),

        Container(
          height: 40,
          color: Colors.white,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: quickReplies.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) => Center(
              child: BounceTap(
                onTap: () => logic.sendQuickReply(quickReplies[i]),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Text(quickReplies[i],
                      style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500)),
                ),
              ),
            ),
          ),
        ),

        Container(
          padding: EdgeInsets.fromLTRB(12, 8, 12, MediaQuery.of(context).padding.bottom + 8),
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, -2))],
          ),
          child: Row(children: [
            BounceTap(
              pressScale: 0.80,
              onTap: () => logic.sendQuickReply(l.sendLocation),
              child: const Padding(padding: EdgeInsets.all(8), child: Icon(Icons.location_on_rounded, color: AppColors.info, size: 22)),
            ),
            BounceTap(
              pressScale: 0.80,
              onTap: () => _pickImage(context),
              child: const Padding(padding: EdgeInsets.all(8), child: Icon(Icons.image_rounded, color: AppColors.textHint, size: 22)),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: TextField(
                  controller: logic.inputCtrl,
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => logic.send(),
                  decoration: InputDecoration(
                    hintText: l.chatPlaceholder,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            BounceTap(
              pressScale: 0.82,
              onTap: logic.send,
              child: Container(
                width: 40, height: 40,
                decoration: const BoxDecoration(
                  gradient: AppColors.gradientPrimary, shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessageModel msg;
  const _MessageBubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    final isMe = msg.isMe;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(radius: 14, backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                child: const Icon(Icons.person_rounded, size: 16, color: AppColors.primary)),
            const SizedBox(width: 6),
          ],
          Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.65),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isMe ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16), topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isMe ? 16 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 16),
                  ),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
                ),
                child: Text(msg.content,
                    style: TextStyle(color: isMe ? Colors.white : AppColors.textPrimary, fontSize: 14)),
              ),
              const SizedBox(height: 2),
              Text(DateUtil.timeOnly(msg.time), style: AppTextStyles.caption),
            ],
          ),
          if (isMe) ...[
            const SizedBox(width: 6),
            CircleAvatar(radius: 14, backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                child: const Icon(Icons.person_rounded, size: 16, color: AppColors.primary)),
          ],
        ],
      ),
    );
  }
}
