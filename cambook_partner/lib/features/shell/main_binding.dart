import 'package:get/get.dart';
import 'shell_controller.dart';
import '../home/binding.dart';
import '../orders/list/binding.dart';
import '../messages/list/binding.dart';
import '../income/binding.dart';
import '../profile/index/binding.dart';

/// 主 Shell Binding —— 一次性注入所有 Tab 页面 Controller
class MainBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ShellController>(() => ShellController(), fenix: true);
    HomeBinding().dependencies();
    OrderListBinding().dependencies();
    MessageListBinding().dependencies();
    IncomeBinding().dependencies();
    ProfileIndexBinding().dependencies();
  }
}
