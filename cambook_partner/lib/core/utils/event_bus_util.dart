import 'dart:async';
import 'package:event_bus/event_bus.dart';
import 'log_util.dart';

/// 全局事件总线 —— 解耦模块间通信
///
/// 发布：EventBusUtil.fire(NewOrderEvent(order))
/// 订阅：EventBusUtil.on<NewOrderEvent>().listen((e) { ... })
/// 取消：subscription.cancel()  ← 务必在 onClose() 中调用
abstract class EventBusUtil {
  static final EventBus _bus = EventBus();

  // ── 发布事件 ─────────────────────────────────────────────────────────────
  static void fire(Object event) {
    LogUtil.d('[EventBus] 🔥 ${event.runtimeType}');
    _bus.fire(event);
  }

  // ── 订阅事件 ─────────────────────────────────────────────────────────────
  static Stream<T> on<T>() => _bus.on<T>();

  // ── 便捷订阅（自动注册到 cancelList，统一 onClose 取消）──────────────────
  static StreamSubscription<T> listen<T>(
    void Function(T) handler, {
    List<StreamSubscription>? cancelList,
  }) {
    final sub = _bus.on<T>().listen(handler);
    cancelList?.add(sub);
    return sub;
  }

  // ── 销毁（仅应用关闭时调用）──────────────────────────────────────────────
  static void dispose() => _bus.destroy();
}

/// GetxController 扩展 Mixin —— 简化订阅管理
/// 用法：class MyLogic extends GetxController with EventBusMixin { ... }
mixin EventBusMixin {
  final List<StreamSubscription> _subs = [];

  /// 订阅事件（自动注册，onClose 统一取消）
  void subscribe<T>(void Function(T) handler) {
    _subs.add(EventBusUtil.listen<T>(handler, cancelList: _subs));
  }

  /// 必须在 GetxController.onClose() 中调用 super.onClose() 以触发取消
  void cancelAllSubscriptions() {
    for (final sub in _subs) {
      sub.cancel();
    }
    _subs.clear();
  }
}
