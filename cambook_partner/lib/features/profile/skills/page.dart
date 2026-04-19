import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/i18n/l10n_ext.dart';
import '../../../core/widgets/common_widgets.dart';
import 'logic.dart';

class SkillsPage extends StatelessWidget {
  const SkillsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final logic = Get.find<SkillsLogic>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: MainAppBar(title: l.skillsTitle, showBack: true),
      body: Obx(() {
        final skills = logic.state.skills;
        if (skills.isEmpty) return EmptyView(message: l.noData);
        return ListView.separated(
          padding: const EdgeInsets.all(AppSizes.pagePadding),
          itemCount: skills.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final s = skills[i];
            return AppCard(
              child: Row(children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: (s.enabled ? AppColors.secondary : AppColors.textHint).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  ),
                  child: Icon(Icons.spa_rounded,
                      color: s.enabled ? AppColors.secondary : AppColors.textHint, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(s.name, style: AppTextStyles.label2),
                  Text(s.enabled ? l.statusOnline : l.statusRest,
                      style: TextStyle(fontSize: 12, color: s.enabled ? AppColors.success : AppColors.textHint)),
                ])),
                Switch(
                  value: s.enabled,
                  onChanged: (_) => logic.toggle(s.id),
                  activeColor: AppColors.secondary,
                ),
              ]),
            );
          },
        );
      }),
    );
  }
}
