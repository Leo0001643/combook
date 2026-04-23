import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Toast 类型
// ──────────────────────────────────────────────────────────────────────────────
enum ToastType { success, error, warning, info }

// ──────────────────────────────────────────────────────────────────────────────
// Dialog 类型
// ──────────────────────────────────────────────────────────────────────────────
enum DialogType { info, success, warning, danger, confirm }

// ──────────────────────────────────────────────────────────────────────────────
// AppToast — 浮动顶部通知，完全自定义动画与外观
// ──────────────────────────────────────────────────────────────────────────────
abstract class AppToast {
  static OverlayEntry? _entry;
  static Timer? _timer;

  static void success(String msg) => _show(msg, ToastType.success);
  static void error(String msg)   => _show(msg, ToastType.error);
  static void warning(String msg) => _show(msg, ToastType.warning);
  static void info(String msg)    => _show(msg, ToastType.info);

  static void _show(String msg, ToastType type, {Duration duration = const Duration(milliseconds: 2800)}) {
    _timer?.cancel();
    _entry?.remove();
    _entry = null;

    final ctx = Get.overlayContext;
    if (ctx == null) return;

    _entry = OverlayEntry(
      builder: (_) => _ToastOverlay(message: msg, type: type, onDismiss: _dismiss),
    );
    Overlay.of(ctx).insert(_entry!);
    _timer = Timer(duration, _dismiss);
  }

  static void _dismiss() {
    _timer?.cancel();
    _timer = null;
    _entry?.remove();
    _entry = null;
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// _ToastOverlay — 带进出动画的 Toast 展示层
// ──────────────────────────────────────────────────────────────────────────────
class _ToastOverlay extends StatefulWidget {
  final String message;
  final ToastType type;
  final VoidCallback onDismiss;
  const _ToastOverlay({required this.message, required this.type, required this.onDismiss});

  @override
  State<_ToastOverlay> createState() => _ToastOverlayState();
}

class _ToastOverlayState extends State<_ToastOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl    = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _scale   = Tween<double>(begin: 0.82, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final cfg = _toastConfig(widget.type);
    return IgnorePointer(
      child: Material(
        color: Colors.transparent,
        child: Center(
          child: FadeTransition(
            opacity: _opacity,
            child: ScaleTransition(
              scale: _scale,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xCC3D3D3D),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.center, children: [
                  // ── 渐变图标圆 ────────────────────────────────────
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                        colors: [cfg.color, cfg.color.withValues(alpha: 0.70)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(
                        color: cfg.color.withValues(alpha: 0.35),
                        blurRadius: 8, offset: const Offset(0, 3),
                      )],
                    ),
                    child: Icon(cfg.icon, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 8),
                  // ── 消息文字 ──────────────────────────────────────
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 220),
                    child: Text(
                      widget.message,
                      style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600,
                        color: Colors.white, height: 1.35,
                      ),
                    ),
                  ),
                  const SizedBox(width: 2),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  _ToastCfg _toastConfig(ToastType t) => switch (t) {
    ToastType.success => const _ToastCfg(AppColors.success, Icons.check_circle_rounded),
    ToastType.error   => const _ToastCfg(AppColors.danger,  Icons.cancel_rounded),
    ToastType.warning => const _ToastCfg(AppColors.warning, Icons.warning_rounded),
    ToastType.info    => const _ToastCfg(AppColors.info,    Icons.info_rounded),
  };
}

class _ToastCfg {
  final Color color; final IconData icon;
  const _ToastCfg(this.color, this.icon);
}

// ──────────────────────────────────────────────────────────────────────────────
// AppDialog — 美观弹窗，支持 confirm / info / success / warning / danger
// ──────────────────────────────────────────────────────────────────────────────
abstract class AppDialog {
  // ── 确认弹窗（返回 true=确认, false=取消）────────────────────────
  static Future<bool> confirm({
    required String title,
    required String content,
    String? confirmText,
    String? cancelText,
    DialogType type = DialogType.warning,
    bool barrierDismissible = true,
  }) async {
    final result = await _push<bool>(_AppDialogWidget(
      title: title, content: content,
      confirmText: confirmText, cancelText: cancelText,
      type: type, showCancel: true,
      barrierDismissible: barrierDismissible,
    ));
    return result == true;
  }

  // ── 纯信息弹窗 ────────────────────────────────────────────────────
  static Future<void> show({
    required String title,
    required String content,
    String? confirmText,
    DialogType type = DialogType.info,
  }) => _push<void>(_AppDialogWidget(
    title: title, content: content,
    confirmText: confirmText,
    type: type, showCancel: false,
    barrierDismissible: true,
  ));

  // ── 成功弹窗 ──────────────────────────────────────────────────────
  static Future<void> success({
    required String title,
    String content = '',
    String? confirmText,
  }) => show(title: title, content: content, confirmText: confirmText, type: DialogType.success);

  static Future<T?> _push<T>(Widget dialog) => showGeneralDialog<T>(
    context: Get.overlayContext!,
    barrierDismissible: false,
    barrierLabel: '',
    barrierColor: Colors.black.withValues(alpha: 0.55),
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (_, __, ___) => dialog,
    transitionBuilder: (_, anim, __, child) => ScaleTransition(
      scale: Tween<double>(begin: 0.88, end: 1.0).animate(
          CurvedAnimation(parent: anim, curve: Curves.easeOut)),
      child: FadeTransition(opacity: anim, child: child),
    ),
  );
}

// ──────────────────────────────────────────────────────────────────────────────
// _AppDialogWidget — 弹窗视图
// ──────────────────────────────────────────────────────────────────────────────
class _AppDialogWidget extends StatelessWidget {
  final String title, content;
  final String? confirmText, cancelText;
  final DialogType type;
  final bool showCancel, barrierDismissible;

  const _AppDialogWidget({
    required this.title, required this.content,
    this.confirmText, this.cancelText,
    required this.type, required this.showCancel,
    required this.barrierDismissible,
  });

  @override
  Widget build(BuildContext context) {
    final cfg = _dialogConfig(type);

    return GestureDetector(
      onTap: barrierDismissible ? () => Navigator.of(context).pop() : null,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: GestureDetector(
          onTap: () {}, // Absorb taps on the card itself
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            constraints: const BoxConstraints(maxWidth: 380),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 40, spreadRadius: 0, offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              // ── 顶部图标区域 ────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                decoration: BoxDecoration(
                  gradient: cfg.gradient,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(children: [
                  Container(
                    width: 68, height: 68,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(cfg.icon, color: Colors.white, size: 34),
                  ),
                  const SizedBox(height: 14),
                  Text(title, style: const TextStyle(
                    color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800,
                    height: 1.2,
                  ), textAlign: TextAlign.center),
                ]),
              ),

              // ── 内容区域 ──────────────────────────────────────────────
              if (content.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 4),
                  child: Text(content, style: const TextStyle(
                    fontSize: 14, color: AppColors.textSecond, height: 1.6,
                  ), textAlign: TextAlign.center),
                ),

              // ── 按钮区域 ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                child: showCancel
                    ? Row(children: [
                        Expanded(child: _CancelBtn(
                          label: cancelText ?? 'cancel'.tr,
                          onTap: () => Navigator.of(context).pop(false),
                        )),
                        const SizedBox(width: 12),
                        Expanded(child: _ConfirmBtn(
                          label: confirmText ?? 'confirm'.tr,
                          gradient: cfg.gradient,
                          onTap: () => Navigator.of(context).pop(true),
                        )),
                      ])
                    : _ConfirmBtn(
                        label: confirmText ?? 'confirm'.tr,
                        gradient: cfg.gradient,
                        onTap: () => Navigator.of(context).pop(),
                      ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  _DialogCfg _dialogConfig(DialogType t) => switch (t) {
    DialogType.success => const _DialogCfg(
        Icons.check_circle_rounded,
        LinearGradient(colors: [Color(0xFF059669), Color(0xFF10B981)],
            begin: Alignment.topLeft, end: Alignment.bottomRight)),
    DialogType.warning => const _DialogCfg(
        Icons.warning_amber_rounded,
        LinearGradient(colors: [Color(0xFFD97706), Color(0xFFF59E0B)],
            begin: Alignment.topLeft, end: Alignment.bottomRight)),
    DialogType.danger  => const _DialogCfg(
        Icons.error_rounded,
        LinearGradient(colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
            begin: Alignment.topLeft, end: Alignment.bottomRight)),
    DialogType.confirm => const _DialogCfg(
        Icons.help_rounded,
        LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
            begin: Alignment.topLeft, end: Alignment.bottomRight)),
    DialogType.info    => const _DialogCfg(
        Icons.info_rounded,
        LinearGradient(colors: [Color(0xFF0284C7), Color(0xFF0EA5E9)],
            begin: Alignment.topLeft, end: Alignment.bottomRight)),
  };
}

class _DialogCfg {
  final IconData icon; final LinearGradient gradient;
  const _DialogCfg(this.icon, this.gradient);
}

class _ConfirmBtn extends StatelessWidget {
  final String label; final LinearGradient gradient; final VoidCallback onTap;
  const _ConfirmBtn({required this.label, required this.gradient, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 48,
      decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(12)),
      alignment: Alignment.center,
      child: Text(label, style: const TextStyle(
        color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
    ),
  );
}

class _CancelBtn extends StatelessWidget {
  final String label; final VoidCallback onTap;
  const _CancelBtn({required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.background, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      alignment: Alignment.center,
      child: Text(label, style: const TextStyle(
        fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textSecond)),
    ),
  );
}

// ──────────────────────────────────────────────────────────────────────────────
// AppSheet — 精美底部弹出面板（统一圆角 + handle bar）
// ──────────────────────────────────────────────────────────────────────────────
abstract class AppSheet {
  /// 展示自定义内容的底部面板
  static Future<T?> show<T>({
    required Widget child,
    String? title,
    bool isDismissible = true,
    bool isScrollControlled = false,
    Color backgroundColor = Colors.white,
  }) {
    return Get.bottomSheet<T>(
      _AppSheetWrapper(title: title, child: child),
      backgroundColor: backgroundColor,
      isScrollControlled: isScrollControlled,
      isDismissible: isDismissible,
      enableDrag: isDismissible,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    );
  }

  /// 展示可滚动内容的底部面板
  static Future<T?> showScrollable<T>({
    required Widget child,
    String? title,
    bool isDismissible = true,
    Color backgroundColor = Colors.white,
  }) =>
      show<T>(
        child: child, title: title,
        isDismissible: isDismissible, backgroundColor: backgroundColor,
        isScrollControlled: true,
      );
}

class _AppSheetWrapper extends StatelessWidget {
  final Widget child;
  final String? title;
  const _AppSheetWrapper({required this.child, this.title});

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      // ── Handle bar ────────────────────────────────────────────────
      Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 8),
        child: Container(
          width: 40, height: 4,
          decoration: BoxDecoration(
            color: AppColors.border, borderRadius: BorderRadius.circular(2)),
        ),
      ),
      // ── 标题 ──────────────────────────────────────────────────────
      if (title != null) ...[
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
          child: Row(children: [
            Expanded(child: Text(title!,
                style: AppTextStyles.h3, overflow: TextOverflow.ellipsis)),
            IconButton(
              onPressed: () => Get.back(),
              icon: const Icon(Icons.close_rounded, color: AppColors.textHint),
              padding: EdgeInsets.zero, constraints: const BoxConstraints(),
            ),
          ]),
        ),
        const Divider(height: 1),
      ],
      // ── 内容 ──────────────────────────────────────────────────────
      child,
    ]);
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// AppStatusToast — 屏幕居中状态切换精品提示（图标 + 文字，全局封装）
// ──────────────────────────────────────────────────────────────────────────────
abstract class AppStatusToast {
  static OverlayEntry? _entry;
  static Timer?        _timer;

  /// 显示居中状态提示。[icon]、[color]、[label] 对应各状态。
  static void show({
    required IconData icon,
    required Color    color,
    required String   label,
    Duration duration = const Duration(milliseconds: 1800),
  }) {
    _timer?.cancel();
    _entry?.remove();
    _entry = null;

    final ctx = Get.overlayContext;
    if (ctx == null) return;

    _entry = OverlayEntry(
      builder: (_) => _StatusToastOverlay(
        icon: icon, color: color, label: label, onDismiss: _dismiss,
      ),
    );
    Overlay.of(ctx).insert(_entry!);
    _timer = Timer(duration, _dismiss);
  }

  static void _dismiss() {
    _timer?.cancel();
    _timer = null;
    _entry?.remove();
    _entry = null;
  }
}

class _StatusToastOverlay extends StatefulWidget {
  final IconData icon;
  final Color    color;
  final String   label;
  final VoidCallback onDismiss;
  const _StatusToastOverlay({
    required this.icon, required this.color,
    required this.label, required this.onDismiss,
  });
  @override
  State<_StatusToastOverlay> createState() => _StatusToastOverlayState();
}

class _StatusToastOverlayState extends State<_StatusToastOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _scale;
  late Animation<double>   _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
    _scale = Tween<double>(begin: 0.88, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color;
    return IgnorePointer(
      child: Material(
        color: Colors.transparent,
        child: Center(
          child: FadeTransition(
            opacity: _opacity,
            child: ScaleTransition(
              scale: _scale,
              child: Container(
                width: 152,
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.28),
                      blurRadius: 40, spreadRadius: 0,
                      offset: const Offset(0, 14),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12, spreadRadius: 0,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  // ── 渐变图标圆 ─────────────────────────────────────
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          color,
                          color.withValues(alpha: 0.72),
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(
                        color: color.withValues(alpha: 0.45),
                        blurRadius: 20, offset: const Offset(0, 6),
                      )],
                    ),
                    child: Icon(widget.icon, color: Colors.white, size: 36),
                  ),
                  const SizedBox(height: 16),
                  // ── 状态名文字 ─────────────────────────────────────
                  Text(
                    widget.label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: color,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // ── 装饰短横线 ─────────────────────────────────────
                  Container(
                    width: 32, height: 3,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.30),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}


abstract class AppBanner {
  static OverlayEntry? _entry;
  static Timer? _timer;

  static void show({
    required String title,
    required String subtitle,
    required String actionLabel,
    required VoidCallback onAction,
    Duration duration = const Duration(seconds: 5),
    Color accentColor = AppColors.primary,
  }) {
    _timer?.cancel();
    _entry?.remove();
    _entry = null;

    final ctx = Get.overlayContext;
    if (ctx == null) return;

    _entry = OverlayEntry(builder: (_) => _BannerOverlay(
      title: title, subtitle: subtitle,
      actionLabel: actionLabel, onAction: () { _dismiss(); onAction(); },
      onDismiss: _dismiss, accentColor: accentColor,
    ));
    Overlay.of(ctx).insert(_entry!);
    _timer = Timer(duration, _dismiss);
  }

  static void _dismiss() {
    _timer?.cancel(); _timer = null;
    _entry?.remove(); _entry = null;
  }
}

class _BannerOverlay extends StatefulWidget {
  final String title, subtitle, actionLabel;
  final VoidCallback onAction, onDismiss;
  final Color accentColor;
  const _BannerOverlay({
    required this.title, required this.subtitle,
    required this.actionLabel, required this.onAction,
    required this.onDismiss, required this.accentColor,
  });
  @override State<_BannerOverlay> createState() => _BannerOverlayState();
}

class _BannerOverlayState extends State<_BannerOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 220));
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide   = Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Positioned(
      top: topPad + 10, left: 12, right: 12,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _opacity,
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [
                    widget.accentColor, widget.accentColor.withValues(alpha: 0.82),
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: widget.accentColor.withValues(alpha: 0.4),
                    blurRadius: 20, offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(children: [
                // Icon
                Container(
                  width: 54, height: 54,
                  margin: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.notifications_active_rounded,
                      color: Colors.white, size: 26),
                ),
                // Text
                Expanded(child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(widget.title, style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(widget.subtitle, style: const TextStyle(
                      color: Colors.white70, fontSize: 12), maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  ]),
                )),
                // Action button
                GestureDetector(
                  onTap: widget.onAction,
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(0, 12, 12, 12),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(widget.actionLabel, style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                ),
                // Close
                GestureDetector(
                  onTap: widget.onDismiss,
                  child: const Padding(
                    padding: EdgeInsets.fromLTRB(0, 12, 10, 12),
                    child: Icon(Icons.close_rounded, color: Colors.white60, size: 18),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// AppLoading — 精美全屏加载弹窗
// ──────────────────────────────────────────────────────────────────────────────
abstract class AppLoading {
  static bool _showing = false;

  static void show([String? msg]) {
    if (_showing) return;
    _showing = true;
    Get.dialog(
      _LoadingWidget(msg: msg),
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.4),
    );
  }

  static void hide() {
    if (!_showing) return;
    _showing = false;
    if (Get.isDialogOpen == true) Get.back();
  }
}

class _LoadingWidget extends StatelessWidget {
  final String? msg;
  const _LoadingWidget({this.msg});

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 30, offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(
          width: 48, height: 48,
          child: CircularProgressIndicator(
            strokeWidth: 3.5,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
        if (msg != null) ...[
          const SizedBox(height: 16),
          Text(msg!, style: AppTextStyles.body2),
        ],
      ]),
    ),
  );
}
