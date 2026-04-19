import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/services/message_service.dart';
import '../../../core/utils/event_bus_util.dart';
import '../../../core/events/app_events.dart';
import 'state.dart';

class ChatLogic extends GetxController with EventBusMixin {
  final ChatState state = ChatState();
  final inputCtrl  = TextEditingController();
  final scrollCtrl = ScrollController();

  @override
  void onInit() {
    super.onInit();
    state.conversationId.value   = Get.arguments?['id'] ?? '';
    state.conversationName.value = Get.arguments?['name'] ?? '';
    state.customerId.value       = Get.arguments?['customerId']?.toString() ?? '';
    // 从 MessageService 拿到联系人电话
    final conv = Get.find<MessageService>().conversations
        .where((c) => c.id == state.conversationId.value)
        .firstOrNull;
    state.customerPhone.value = conv?.phone ?? '';
    _loadMessages();

    // 订阅新消息事件 → 如果是当前会话的消息则自动刷新
    subscribe<NewMessageEvent>((e) {
      if (e.conversationId == state.conversationId.value) {
        _loadMessages();
        _scrollToBottom();
      }
    });
  }

  @override
  void onClose() {
    inputCtrl.dispose();
    scrollCtrl.dispose();
    cancelAllSubscriptions();
    super.onClose();
  }

  void _loadMessages() {
    state.messages.assignAll(
      Get.find<MessageService>().getMessages(state.conversationId.value),
    );
  }

  void send() {
    final text = inputCtrl.text.trim();
    if (text.isEmpty) return;
    Get.find<MessageService>().sendMessage(state.conversationId.value, text);
    _loadMessages();
    inputCtrl.clear();
    _scrollToBottom();
  }

  void sendQuickReply(String text) {
    Get.find<MessageService>().sendMessage(state.conversationId.value, text);
    _loadMessages();
    _scrollToBottom();
  }

  /// 模拟对方回复（正式版替换为 WebSocket 回调）
  void mockReceive() {
    final convId = state.conversationId.value;
    Get.find<MessageService>().receiveMessage(
      convId, state.conversationName.value,
      'Thanks for the quick response! 😊',
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollCtrl.hasClients) {
        scrollCtrl.animateTo(scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }
}
