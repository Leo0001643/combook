import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

/// 主 Shell 全局控制器 —— 允许任意模块跳转到指定底部导航 Tab
/// 用法：Get.find<ShellController>().switchTab(1) → 切换到订单页
class ShellController extends GetxController {
  static const int tabHome     = 0;
  static const int tabMessages = 1;  // 消息移至第2位
  static const int tabOrders   = 2;  // 订单居中（浮动按钮）
  static const int tabIncome   = 3;
  static const int tabProfile  = 4;

  final currentIdx = 0.obs;

  /// 待执行预约订单数（用于底部导航 FAB 角标）
  final orderBadgeCount = 0.obs;

  // 各 Tab 的静默刷新回调（切换时自动触发，不显示 toast）
  final _refreshCallbacks = <int, VoidCallback>{};

  /// 注册 Tab 切换时的刷新回调（在对应 Logic.onInit 中调用）
  void registerRefresh(int tabIdx, VoidCallback callback) {
    _refreshCallbacks[tabIdx] = callback;
  }

  /// 取消注册（在对应 Logic.onClose 中调用）
  void unregisterRefresh(int tabIdx) {
    _refreshCallbacks.remove(tabIdx);
  }

  /// 切换 Tab：同时触发目标 Tab 的刷新
  void switchTab(int idx) {
    currentIdx.value = idx;
    _refreshCallbacks[idx]?.call();
  }

  /// 更新待执行订单角标数量（由 HomeLogic 在拉取数据时调用）
  void updateOrderBadge(int count) {
    orderBadgeCount.value = count;
  }
}
