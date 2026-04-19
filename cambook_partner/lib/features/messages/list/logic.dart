import 'package:get/get.dart';
import '../../../core/models/models.dart';
import '../../../core/services/message_service.dart';
import '../../../core/routes/app_routes.dart';
import 'state.dart';

class MessageListLogic extends GetxController {
  final MessageListState state = MessageListState();

  MessageService get _svc => Get.find<MessageService>();

  List<ConversationModel> get conversations => _svc.conversations;
  int get totalUnread => _svc.totalUnread;

  void openChat(ConversationModel c) {
    _svc.markRead(c.id);
    Get.toNamed(AppRoutes.chat, arguments: {'id': c.id, 'name': c.name, 'customerId': c.customerId});
  }

@override
  Future<void> refresh() => Future.delayed(const Duration(milliseconds: 600));
}
