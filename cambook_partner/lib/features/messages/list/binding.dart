import 'package:get/get.dart';
import 'logic.dart';

class MessageListBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MessageListLogic>(() => MessageListLogic());
  }
}
