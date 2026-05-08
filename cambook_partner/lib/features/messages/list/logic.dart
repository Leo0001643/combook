import 'package:get/get.dart';
import '../../../core/models/models.dart';
import '../../../core/services/message_service.dart';
import '../../../core/routes/app_routes.dart';
import '../../shell/shell_controller.dart';
import 'state.dart';

/// 消息列表控制器
///
/// 实时性完全由 WS 驱动（零 HTTP 轮询）：
///   1. 上线时 → Netty 推送 CONV_LIST → MessageService 全量替换 conversations
///   2. 新消息时 → Netty 推送 CONV_UPDATE → MessageService 单条更新 conversations
///   3. 上述两路均通过 conversations.refresh() 触发 Obx 即时重绘
///   4. MessageService._convRefreshTimer（60s）— WS 全断时的最后兜底
///
/// 此层不再维护任何定时器，避免重复 HTTP 流量。
class MessageListLogic extends GetxController {
  final MessageListState state = MessageListState();

  MessageService  get _svc   => Get.find<MessageService>();
  ShellController get _shell => Get.find<ShellController>();

  List<ConversationModel> get conversations => _svc.conversations;
  int get totalUnread => _svc.totalUnread;

  @override
  void onInit() {
    super.onInit();
    // MessageService.init() already fetched conversations before this page mounts.
    // Only register the tab-switch callback so switching back refreshes on demand.
    _shell.registerRefresh(ShellController.tabMessages, () => _svc.refresh());
  }

  @override
  void onClose() {
    _shell.unregisterRefresh(ShellController.tabMessages);
    super.onClose();
  }

  void openChat(ConversationModel c) {
    _svc.markRead(c.id);
    Get.toNamed(AppRoutes.chat, arguments: {
      'id':         c.id,
      'name':       c.name,
      'customerId': c.customerId,
      'peerType':   c.peerType ?? 'member',
      'peerId':     c.peerId ?? c.customerId ?? 0,
    });
  }

  /// 标记已读（本地 + 服务端）
  void markRead(String convId) => _svc.markRead(convId);

  /// 清空本地消息记录（不调后端）
  void clearLocalMessages(String convId) => _svc.clearLocalMessages(convId);

  /// 从本地列表中删除会话（不调后端）
  void deleteLocalConversation(String convId) =>
      _svc.deleteLocalConversation(convId);

  @override
  Future<void> refresh() => _svc.refresh();
}
