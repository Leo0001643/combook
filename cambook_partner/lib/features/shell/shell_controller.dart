import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/user_service.dart';

/// 主 Shell 全局控制器 —— 允许任意模块跳转到指定底部导航 Tab
/// 用法：Get.find<ShellController>().switchTab(1) → 切换到订单页
///
/// ⚠️ IndexedStack 的 Tab 切换不经过 GetX 路由层，因此 AuthMiddleware
///    不会被触发。登录态校验必须在此处显式执行。
class ShellController extends GetxController {
  static const int tabHome     = 0;
  static const int tabMessages = 1;
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
  ///
  /// 切换前校验登录状态 —— IndexedStack 内部切换不经过路由层，
  /// 必须在此处手动拦截，否则 AuthMiddleware 无法覆盖到 Tab 导航。
  void switchTab(int idx) {
    if (!_requireLogin()) return;
    currentIdx.value = idx;
    _refreshCallbacks[idx]?.call();
  }

  /// 更新待执行订单角标数量（由 HomeLogic 在拉取数据时调用）
  void updateOrderBadge(int count) {
    orderBadgeCount.value = count;
  }

  // ── 私有 ──────────────────────────────────────────────────────────────────

  /// 校验登录态。
  /// - 已登录 → 返回 true，正常放行。
  /// - 已登出但弹窗正在展示 → 返回 false，让弹窗自行完成跳转，避免导航冲突。
  /// - 未登录 → 清空路由栈并跳转登录页，返回 false。
  bool _requireLogin() {
    final user = Get.find<UserService>();
    if (user.isLoggedIn) return true;
    // 会话过期弹窗已在处理跳转，不重复导航
    if (user.isSessionExpired.value && (Get.isDialogOpen ?? false)) return false;
    Get.offAllNamed(AppRoutes.login);
    return false;
  }
}
