import '../widgets/app_dialog.dart';

/// 统一 Toast / Dialog / Loading 工具 — 代理到 AppToast / AppDialog / AppLoading
/// 所有页面和 Logic 调用此类，UI 实现集中在 app_dialog.dart
abstract class ToastUtil {
  // ── Toast ──────────────────────────────────────────────────────────
  static void success(String msg) => AppToast.success(msg);
  static void error(String msg)   => AppToast.error(msg);
  static void info(String msg)    => AppToast.info(msg);
  static void warning(String msg) => AppToast.warning(msg);

  // ── Confirm Dialog ─────────────────────────────────────────────────
  static Future<bool> confirm(String title, String content, {String? okText}) =>
      AppDialog.confirm(title: title, content: content, confirmText: okText);

  // ── Loading ────────────────────────────────────────────────────────
  static void showLoading([String? msg]) => AppLoading.show(msg);
  static void hideLoading()              => AppLoading.hide();
}
