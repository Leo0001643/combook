import 'package:get/get.dart';
import 'im_chat_logic.dart';

class ImChatBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ImChatLogic>(() => ImChatLogic());
  }
}
