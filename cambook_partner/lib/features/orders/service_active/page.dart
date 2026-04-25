import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/i18n/l10n_ext.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/utils/date_util.dart';
import '../../../core/utils/format_util.dart';
import '../../../core/widgets/common_widgets.dart';
import 'logic.dart';

class ServiceActivePage extends StatelessWidget {
  const ServiceActivePage({super.key});

  void _showMoreOptions(BuildContext context, ServiceActiveLogic logic) {
    final l = context.l10n;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          BounceTap(
            onTap: () {
              Get.back();
              final id = logic.state.order.value?.id;
              if (id != null) Get.toNamed(AppRoutes.orderDetail, arguments: {'id': id});
            },
            child: ListTile(
              leading: const Icon(Icons.info_outline_rounded, color: AppColors.primary),
              title: Text(l.btnDetail),
            ),
          ),
          BounceTap(
            onTap: () { Get.back(); logic.complete(); },
            child: ListTile(
              leading: const Icon(Icons.stop_circle_outlined, color: AppColors.danger),
              title: Text(l.endService, style: const TextStyle(color: AppColors.danger)),
            ),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final logic = Get.find<ServiceActiveLogic>();
    final state = logic.state;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.gradientDark),
        child: SafeArea(
          child: Obx(() {
            final l = context.l10n;
            final order   = state.order.value;

            if (order == null) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.hourglass_empty_rounded, color: Colors.white38, size: 64),
                  const SizedBox(height: 16),
                  Text(l.noOrders, style: const TextStyle(color: Colors.white54, fontSize: 16)),
                  const SizedBox(height: 24),
                  TextButton.icon(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white70),
                    label: Text(l.back, style: const TextStyle(color: Colors.white70)),
                  ),
                ],
              );
            }

            final elapsed   = state.elapsedSec;
            final paused    = state.paused.value;
            final total     = order.totalDuration * 60;
            final remaining = max(0, total - elapsed);
            final progress  = total > 0 ? elapsed / total : 0.0;

            return Column(children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(children: [
                  BounceTap(
                    pressScale: 0.78,
                    onTap: () => Get.back(),
                    child: const Padding(
                      padding: EdgeInsets.all(10),
                      child: Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.secondary.withValues(alpha: 0.5)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Text(l.focusMode, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                  const Spacer(),
                  BounceTap(
                    pressScale: 0.78,
                    onTap: () => _showMoreOptions(context, logic),
                    child: const Padding(
                      padding: EdgeInsets.all(10),
                      child: Icon(Icons.more_vert_rounded, color: Colors.white, size: 22),
                    ),
                  ),
                ]),
              ),

              Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 顶部：客户信息 + 总金额
                      Row(children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.white24,
                          child: Text(
                              order.customer.nickname.isNotEmpty
                                  ? order.customer.nickname[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            order.customer.nickname.isNotEmpty ? order.customer.nickname : '-',
                            style: AppTextStyles.whiteMd,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(FormatUtil.money(order.totalAmount),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20)),
                      ]),
                      // 服务项明细列表
                      if (order.services.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        const Divider(color: Colors.white24, height: 1),
                        const SizedBox(height: 8),
                        ...order.services.asMap().entries.map((e) {
                          final idx = e.key;
                          final svc = e.value;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(children: [
                              Container(
                                width: 20, height: 20,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text('${idx + 1}',
                                    style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 8),
                              Expanded(child: Text(svc.name,
                                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500))),
                              if (svc.duration > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text('${svc.duration}min',
                                      style: const TextStyle(color: Colors.white60, fontSize: 11)),
                                ),
                            ]),
                          );
                        }),
                      ],
                    ],
                  ),
                ),

              const Spacer(),

              _TimerCircle(elapsed: elapsed, remaining: remaining, total: total, progress: progress, paused: paused),

              const SizedBox(height: 16),
              Text(paused ? l.pause : l.stepInService,
                  style: TextStyle(color: paused ? Colors.amber : Colors.white70, fontSize: 14, letterSpacing: 1.5)),

              const Spacer(),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _CircleBtn(
                      icon: paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                      label: paused ? l.resume : l.pause,
                      color: AppColors.warning,
                      onTap: logic.togglePause,
                    ),
                    _CircleBtn(
                      icon: Icons.check_rounded,
                      label: l.btnComplete,
                      color: AppColors.success,
                      onTap: logic.complete,
                      large: true,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
            ]);
          }),
        ),
      ),
    );
  }
}

class _TimerCircle extends StatelessWidget {
  final int elapsed, remaining, total;
  final double progress;
  final bool paused;
  const _TimerCircle({required this.elapsed, required this.remaining, required this.total, required this.progress, required this.paused});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return SizedBox(
      width: 220, height: 220,
      child: Stack(alignment: Alignment.center, children: [
        Container(
          width: 220, height: 220,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.05),
            border: Border.all(color: Colors.white12, width: 3),
          ),
        ),
        SizedBox(
          width: 200, height: 200,
          child: CircularProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            strokeWidth: 10,
            backgroundColor: Colors.white12,
            valueColor: AlwaysStoppedAnimation(
              paused ? Colors.amber : AppColors.success,
            ),
          ),
        ),
        Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(l.elapsed, style: const TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 1)),
          const SizedBox(height: 4),
          Text(DateUtil.timer(elapsed),
              style: const TextStyle(color: Colors.white, fontSize: 44, fontWeight: FontWeight.w800, fontFeatures: [FontFeature.tabularFigures()])),
          const SizedBox(height: 4),
          Text('${l.remaining} ${DateUtil.timer(remaining)}',
              style: TextStyle(color: paused ? Colors.amber : Colors.white60, fontSize: 14)),
        ]),
      ]),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool large;

  const _CircleBtn({required this.icon, required this.label, required this.color, required this.onTap, this.large = false});

  @override
  Widget build(BuildContext context) {
    final size = large ? 64.0 : 54.0;
    return BounceTap(
      onTap: onTap,
      child: Column(children: [
        Container(
          width: size, height: size,
          decoration: BoxDecoration(
            color: color.withValues(alpha: large ? 0.9 : 0.25),
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
            boxShadow: large ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 16)] : null,
          ),
          child: Icon(icon, color: Colors.white, size: large ? 30 : 24),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
      ]),
    );
  }
}
