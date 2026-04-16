import 'package:get/get.dart';
import 'notification_logic.dart';

class NotificationBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<NotificationLogic>(() => NotificationLogic());
  }
}
