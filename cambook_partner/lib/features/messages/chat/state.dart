import 'package:get/get.dart';
import '../../../core/models/models.dart';

class ChatState {
  final RxList<ChatMessageModel> messages         = <ChatMessageModel>[].obs;
  final RxBool                   uploadingMedia   = false.obs;  // image & voice uploads
  final RxBool                   recording        = false.obs;
  final RxInt                    recSeconds       = 0.obs;
  final RxBool                   inputHasText     = false.obs;
  final RxString                 conversationId   = ''.obs;
  final RxString                 conversationName = ''.obs;
  final RxString                 peerAvatar       = ''.obs;
  final RxString                 customerPhone    = ''.obs;
  final RxString                 customerId       = ''.obs;
  final RxString                 peerType         = 'member'.obs;
  final RxInt                    peerId           = 0.obs;
}
