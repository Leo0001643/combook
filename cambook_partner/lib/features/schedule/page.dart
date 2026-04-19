import 'package:flutter/material.dart';
import '../../../core/widgets/app_dialog.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/i18n/l10n_ext.dart';
import '../../../core/models/models.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/order_service.dart';
import '../../../core/utils/date_util.dart';
import '../../../core/widgets/common_widgets.dart';
import 'logic.dart';

class SchedulePage extends StatelessWidget {
  const SchedulePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final logic = Get.find<ScheduleLogic>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: MainAppBar(title: l.scheduleTitle, showBack: true),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.pagePadding),
        children: [
          _WorkDayCard(logic: logic),
          const SizedBox(height: 20),
          SectionTitle(title: l.upcoming),
          const SizedBox(height: 12),
          if (logic.appointments.isEmpty)
            EmptyView(message: l.noAppointments, icon: Icons.event_available_rounded)
          else
            ...logic.appointments.map((a) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _AppointmentCard(apt: a),
            )),
        ],
      ),
    );
  }
}

// ── 工作日 / 工作时间设置卡片 ────────────────────────────────────────────────────
class _WorkDayCard extends StatelessWidget {
  final ScheduleLogic logic;
  const _WorkDayCard({required this.logic});

  Future<void> _pickWorkTime(BuildContext context) async {
    final l = context.l10n;
    final startParts = logic.state.workStart.value.split(':');
    final initStart  = TimeOfDay(hour: int.parse(startParts[0]), minute: int.parse(startParts[1]));
    final start = await showTimePicker(
      context: context, initialTime: initStart,
      helpText: l.workHours,
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (start == null) return;

    final endParts = logic.state.workEnd.value.split(':');
    final initEnd  = TimeOfDay(hour: int.parse(endParts[0]), minute: int.parse(endParts[1]));
    if (!context.mounted) return;
    final end = await showTimePicker(
      context: context, initialTime: initEnd,
      helpText: l.workHours,
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (end == null) return;

    logic.setWorkTime(
      '${start.hour.toString().padLeft(2,'0')}:${start.minute.toString().padLeft(2,'0')}',
      '${end.hour.toString().padLeft(2,'0')}:${end.minute.toString().padLeft(2,'0')}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l.scheduleTitle, style: AppTextStyles.label1),
        const SizedBox(height: 4),
        Text(l.confirmScheduleChange, style: AppTextStyles.body3),
        const SizedBox(height: 14),
        Row(
          children: List.generate(7, (i) {
            final day    = i + 1;
            final active = logic.isWorkDay(day);
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: BounceTap(
                  onTap: () => logic.toggleWorkDay(day),
                  child: Column(children: [
                    Text(logic.dayName(day).substring(1),
                        style: TextStyle(fontSize: 11, color: active ? AppColors.primary : AppColors.textHint)),
                    const SizedBox(height: 4),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: active ? AppColors.primary : AppColors.background,
                        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                        border: Border.all(color: active ? AppColors.primary : AppColors.border),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        active ? Icons.check_rounded : Icons.bedtime_rounded,
                        color: active ? Colors.white : AppColors.textHint, size: 16,
                      ),
                    ),
                  ]),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        const Divider(),
        const SizedBox(height: 8),
        Obx(() => Row(children: [
          const Icon(Icons.access_time_rounded, size: 16, color: AppColors.textSecond),
          const SizedBox(width: 6),
          Text('${l.workHours}：', style: AppTextStyles.body3),
          Text(
            '${logic.state.workStart.value} ~ ${logic.state.workEnd.value}',
            style: AppTextStyles.label3,
          ),
          const Spacer(),
          BounceTap(
            onTap: () => _pickWorkTime(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(l.edit, style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600)),
            ),
          ),
        ])),
      ]),
    );
  }
}

// ── 预约卡片 ─────────────────────────────────────────────────────────────────
class _AppointmentCard extends StatelessWidget {
  final AppointmentModel apt;
  const _AppointmentCard({required this.apt});

  void _navigateToOrder(BuildContext context) {
    final l = context.l10n;
    final order = Get.find<OrderService>().getByOrderNo(apt.orderNo);
    if (order != null) {
      Get.toNamed(AppRoutes.orderDetail, arguments: {'id': order.id});
    } else {
      AppToast.info(l.noData);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final isToday    = DateUtil.sameDay(apt.appointTime, DateTime.now());
    final isTomorrow = DateUtil.sameDay(apt.appointTime, DateTime.now().add(const Duration(days: 1)));
    final tag = isToday ? l.periodToday : isTomorrow ? l.upcoming : DateUtil.dateOnly(apt.appointTime);

    return AppCard(
      child: Row(children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            gradient: isToday ? AppColors.gradientPrimary : const LinearGradient(colors: [Color(0xFFF0F0F0), Color(0xFFE8E8E8)]),
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
          alignment: Alignment.center,
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(tag, style: TextStyle(
              color: isToday ? Colors.white : AppColors.textSecond,
              fontSize: 10, fontWeight: FontWeight.w600,
            )),
            Text(DateUtil.timeOnly(apt.appointTime), style: TextStyle(
              color: isToday ? Colors.white : AppColors.textPrimary,
              fontSize: 13, fontWeight: FontWeight.w800,
            )),
          ]),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(apt.customerName, style: AppTextStyles.label2),
          const SizedBox(height: 2),
          Text(apt.serviceNames.join(' · '), style: AppTextStyles.body3, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Row(children: [
            ServiceModeTag(
              mode: apt.serviceMode,
              label: apt.serviceMode == ServiceMode.home ? l.homeService : l.storeService,
            ),
            const SizedBox(width: 6),
            const Icon(Icons.timelapse_rounded, size: 12, color: AppColors.textSecond),
            const SizedBox(width: 3),
            Text('${apt.totalDuration}${l.unitMin}', style: AppTextStyles.caption),
          ]),
        ])),
        Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: BounceTap(
              pressScale: 0.80,
              onTap: () => _navigateToOrder(context),
              child: const Padding(
                padding: EdgeInsets.all(10),
                child: Icon(Icons.arrow_forward_ios_rounded, color: AppColors.primary, size: 15),
              ),
            ),
          ),
          if (apt.address != null) ...[
            const SizedBox(height: 4),
            Container(
              decoration: BoxDecoration(color: AppColors.info.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: BounceTap(
                pressScale: 0.80,
                onTap: () { AppToast.info(apt.address ?? ''); },
                child: const Padding(
                  padding: EdgeInsets.all(10),
                  child: Icon(Icons.navigation_rounded, color: AppColors.info, size: 15),
                ),
              ),
            ),
          ],
        ]),
      ]),
    );
  }
}
