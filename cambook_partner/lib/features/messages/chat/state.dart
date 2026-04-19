import 'package:get/get.dart';
import '../../../core/models/models.dart';

class ChatState {
  final RxList<ChatMessageModel> messages       = <ChatMessageModel>[].obs;
  final RxBool                   sending        = false.obs;
  final RxString                 conversationId   = ''.obs;
  final RxString                 conversationName = ''.obs;
  final RxString                 customerPhone    = ''.obs;
  final RxString                 customerId       = ''.obs;
}
