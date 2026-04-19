import 'package:get/get.dart';

/// 主 Shell 全局控制器 —— 允许任意模块跳转到指定底部导航 Tab
/// 用法：Get.find<ShellController>().switchTab(1) → 切换到订单页
class ShellController extends GetxController {
  static const int tabHome     = 0;
  static const int tabOrders   = 1;
  static const int tabMessages = 2;
  static const int tabIncome   = 3;
  static const int tabProfile  = 4;

  final currentIdx = 0.obs;

  void switchTab(int idx) => currentIdx.value = idx;
}
