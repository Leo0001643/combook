import 'package:get/get.dart';
import '../models/models.dart';
import '../mock/mock_data.dart';
import '../events/app_events.dart';
import '../utils/event_bus_util.dart';

/// 消息服务 —— 会话 & 聊天（全局单例）
class MessageService extends GetxService {
  final RxList<ConversationModel>             conversations = <ConversationModel>[].obs;
  final RxMap<String, List<ChatMessageModel>> messages     = <String, List<ChatMessageModel>>{}.obs;

  Future<MessageService> init() async {
    conversations.assignAll(MockData.conversations);
    messages.assignAll(MockData.chatMessages);
    return this;
  }

  int get totalUnread => conversations.fold(0, (s, c) => s + c.unread);

  void markRead(String id) {
    final i = conversations.indexWhere((c) => c.id == id);
    if (i >= 0) conversations[i] = conversations[i].copyWithUnread(0);
  }

  List<ChatMessageModel> getMessages(String id) => messages[id] ?? [];

  /// 技师发送消息
  void sendMessage(String convId, String content) {
    _addMessage(convId, content, isMe: true);
  }

  /// 模拟收到对方消息（正式版替换为 WebSocket 回调）
  void receiveMessage(String convId, String senderName, String content, {ConversationType type = ConversationType.customer}) {
    _addMessage(convId, content, isMe: false);

    // 更新未读计数
    final i = conversations.indexWhere((c) => c.id == convId);
    if (i >= 0) {
      final c = conversations[i];
      conversations[i] = ConversationModel(
        id: c.id, type: c.type, name: c.name, avatar: c.avatar,
        lastMessage: content, lastTime: DateTime.now(),
        unread: c.unread + 1, customerId: c.customerId,
      );
    }

    // 广播新消息事件 → 其他模块（如 Home 徽章）可响应
    EventBusUtil.fire(NewMessageEvent(convId, senderName, content, type));
  }

  void _addMessage(String convId, String content, {required bool isMe}) {
    final msg = ChatMessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      conversationId: convId, isMe: isMe,
      content: content, type: MessageType.text, time: DateTime.now(),
    );
    final list = List<ChatMessageModel>.from(messages[convId] ?? [])..add(msg);
    messages[convId] = list;

    // 更新会话最后一条消息（仅发送方更新，接收方已在 receiveMessage 处理）
    if (isMe) {
      final i = conversations.indexWhere((c) => c.id == convId);
      if (i >= 0) {
        final c = conversations[i];
        conversations[i] = ConversationModel(
          id: c.id, type: c.type, name: c.name, avatar: c.avatar,
          lastMessage: content, lastTime: DateTime.now(),
          unread: 0, customerId: c.customerId,
        );
      }
    }
  }
}
