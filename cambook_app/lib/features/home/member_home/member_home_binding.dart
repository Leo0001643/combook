import 'package:get/get.dart';
import 'member_home_logic.dart';

class MemberHomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MemberHomeLogic>(() => MemberHomeLogic());
  }
}
