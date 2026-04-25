import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../l10n/gen/app_localizations.dart';
import '../constants/app_colors.dart';
import '../i18n/l10n_ext.dart';
import '../routes/app_routes.dart';
import 'user_service.dart';

/// 认证守卫服务
///
/// 监听 [UserService.isSessionExpired]。当技师被强制登出时（服务端 401 /
/// token 过期），显示不可关闭的模态弹窗。弹窗期间任何导航操作均被拦截，
/// 技师确认后才跳转到登录页。
///
/// 与 [AuthMiddleware] 协同工作：
///   - AuthMiddleware   → 路由级拦截（未登录的命名路由跳转）
///   - AuthGuardService → 状态级拦截（已在页面时的被动登出提示）
class AuthGuardService extends GetxService {
  Future<AuthGuardService> init() async {
    ever(Get.find<UserService>().isSessionExpired, _onChanged);
    return this;
  }

  void _onChanged(bool expired) {
    if (!expired) return;
    // 防止重复弹窗（多个并发 401 同时到达时）
    if (Get.isDialogOpen ?? false) return;
    Get.dialog(
      const _SessionExpiredDialog(),
      barrierDismissible: false,
      useSafeArea: true,
    );
  }
}

// ── 已登出提示弹窗 ────────────────────────────────────────────────────────────

class _SessionExpiredDialog extends StatefulWidget {
  const _SessionExpiredDialog();

  @override
  State<_SessionExpiredDialog> createState() => _SessionExpiredDialogState();
}

class _SessionExpiredDialogState extends State<_SessionExpiredDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack);
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(
        scale: _scale,
        alignment: Alignment.center,
        child: _buildContent(context),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final l10n = context.l10n;

    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryDark.withValues(alpha: 0.25),
                blurRadius: 40,
                spreadRadius: 0,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.hardEdge,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(l10n),
              _buildBody(l10n),
            ],
          ),
        ),
      ),
    );
  }

  // ── 深色渐变顶部区域 ────────────────────────────────────────────────────────
  Widget _buildHeader(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 28),
      decoration: const BoxDecoration(gradient: AppColors.gradientDark),
      child: Column(
        children: [
          const _GlowIcon(),
          const SizedBox(height: 16),
          Text(
            l10n.sessionExpiredTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── 白色内容区域 ────────────────────────────────────────────────────────────
  Widget _buildBody(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 28),
      child: Column(
        children: [
          Text(
            l10n.sessionExpiredMessage,
            style: const TextStyle(
              color: AppColors.textSecond,
              fontSize: 14,
              height: 1.65,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          _GradientButton(
            label: l10n.goToLogin,
            onTap: () {
              Get.find<UserService>().clearSessionExpired();
              Get.offAllNamed(AppRoutes.login);
            },
          ),
        ],
      ),
    );
  }
}

// ── 三层光晕图标 ───────────────────────────────────────────────────────────────

class _GlowIcon extends StatelessWidget {
  const _GlowIcon();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // 最外层：大光晕
        Container(
          width: 90, height: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.07),
          ),
        ),
        // 中间层
        Container(
          width: 70, height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.12),
          ),
        ),
        // 内核：图标容器
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.22),
          ),
          child: const Icon(
            Icons.lock_person_rounded,
            color: Colors.white,
            size: 26,
          ),
        ),
      ],
    );
  }
}

// ── 渐变按钮（含阴影） ─────────────────────────────────────────────────────────

class _GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _GradientButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        gradient: AppColors.gradientPrimary,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.40),
            blurRadius: 16,
            spreadRadius: 0,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          splashColor: Colors.white.withValues(alpha: 0.15),
          highlightColor: Colors.white.withValues(alpha: 0.08),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
