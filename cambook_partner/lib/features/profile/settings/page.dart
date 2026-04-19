import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/i18n/l10n_ext.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../l10n/gen/app_localizations.dart';
import 'logic.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  static List<(String, String Function(AppLocalizations l))> _langs() => [
    ('zh', (l) => l.langZh), ('en', (l) => l.langEn), ('vi', (l) => l.langVi),
    ('km', (l) => l.langKm), ('ko', (l) => l.langKo), ('ja', (l) => l.langJa),
  ];

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final logic = Get.find<SettingsLogic>();
    final langs = _langs();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: MainAppBar(title: l.settingsTitle, showBack: true),
      body: Obx(() => ListView(
        padding: const EdgeInsets.all(AppSizes.pagePadding),
        children: [
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(children: [
              _SectionHeader(l.notifySection),
              _SwitchTile(l.orderNotify, Icons.receipt_long_rounded, AppColors.primary,
                  logic.state.notifyOrder.value, (v) => logic.toggleNotify('order', v)),
              const Divider(indent: 58, height: 1),
              _SwitchTile(l.messageNotify, Icons.chat_bubble_rounded, AppColors.info,
                  logic.state.notifyMessage.value, (v) => logic.toggleNotify('message', v)),
              const Divider(indent: 58, height: 1),
              _SwitchTile(l.systemNotify, Icons.notifications_rounded, AppColors.success,
                  logic.state.notifySystem.value, (v) => logic.toggleNotify('system', v)),
            ]),
          ),
          const SizedBox(height: 16),

          AppCard(
            padding: EdgeInsets.zero,
            child: Column(children: [
              _SectionHeader(l.langTitle),
              ...langs.asMap().entries.map((e) {
                final lang = e.value;
                final active = logic.state.locale.value == lang.$1;
                return Column(children: [
                  BounceTap(
                    onTap: () => logic.changeLocale(lang.$1),
                    child: ListTile(
                      title: Text(lang.$2(l), style: AppTextStyles.body2),
                      trailing: active
                          ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
                          : null,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                    ),
                  ),
                  if (e.key < langs.length - 1) const Divider(height: 1),
                ]);
              }),
            ]),
          ),
          const SizedBox(height: 16),

          AppCard(
            padding: EdgeInsets.zero,
            child: Column(children: [
              _SectionHeader(l.accountSection),
              _ArrowTile(l.changePassword, Icons.lock_rounded, AppColors.secondary,
                  () => _showChangePasswordDialog(context, logic)),
              const Divider(indent: 58, height: 1),
              _ArrowTile(l.editProfile, Icons.edit_rounded, AppColors.info,
                  () => _showEditProfileDialog(context, logic)),
            ]),
          ),
          const SizedBox(height: 16),

          AppCard(
            padding: EdgeInsets.zero,
            child: Column(children: [
              _SectionHeader(l.aboutSection),
              _ArrowTile('${l.version} 1.0.0', Icons.info_outline_rounded, AppColors.textSecond,
                  () => _showAbout(context)),
              const Divider(indent: 58, height: 1),
              _ArrowTile(l.terms, Icons.description_rounded, AppColors.textSecond,
                  () => AppToast.info(l.comingSoon)),
              const Divider(indent: 58, height: 1),
              _ArrowTile(l.privacyPolicy, Icons.privacy_tip_rounded, AppColors.textSecond,
                  () => AppToast.info(l.comingSoon)),
            ]),
          ),
        ],
      )),
    );
  }

  void _showChangePasswordDialog(BuildContext ctx, SettingsLogic logic) {
    final loc      = AppLocalizations.of(ctx);
    final oldCtrl  = TextEditingController();
    final newCtrl  = TextEditingController();
    final confCtrl = TextEditingController();
    AppSheet.show(
      title: loc.changePassword,
      isScrollControlled: true,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 8, 20,
            MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          _PassField(loc.password, oldCtrl),
          const SizedBox(height: 12),
          _PassField(loc.passwordHint, newCtrl),
          const SizedBox(height: 12),
          _PassField(loc.fieldConfirmPassword, confCtrl),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: BounceTap(child: OutlinedButton(
              onPressed: () { oldCtrl.dispose(); newCtrl.dispose(); confCtrl.dispose(); Get.back(); },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(loc.cancel),
            ))),
            const SizedBox(width: 12),
            Expanded(child: BounceTap(child: ElevatedButton(
              onPressed: () {
                if (newCtrl.text != confCtrl.text) {
                  AppToast.warning(loc.passwordMismatch);
                  return;
                }
                final newPass = newCtrl.text;
                oldCtrl.dispose(); newCtrl.dispose(); confCtrl.dispose();
                Get.back();
                logic.changePassword(newPass);
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(loc.save),
            ))),
          ]),
        ]),
      ),
    );
  }

  void _showEditProfileDialog(BuildContext ctx, SettingsLogic logic) {
    final loc      = AppLocalizations.of(ctx);
    final nameCtrl  = TextEditingController(text: logic.state.nickname.value);
    final phoneCtrl = TextEditingController(text: logic.state.phone.value);
    AppSheet.show(
      title: loc.editProfile,
      isScrollControlled: true,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 8, 20,
            MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: nameCtrl,
            decoration: InputDecoration(
              labelText: loc.fieldFullName,
              prefixIcon: const Icon(Icons.person_rounded, size: 18),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: loc.phone,
              prefixIcon: const Icon(Icons.phone_rounded, size: 18),
            ),
          ),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: BounceTap(child: OutlinedButton(
              onPressed: () { nameCtrl.dispose(); phoneCtrl.dispose(); Get.back(); },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(loc.cancel),
            ))),
            const SizedBox(width: 12),
            Expanded(child: BounceTap(child: ElevatedButton(
              onPressed: () {
                logic.saveProfile(nameCtrl.text.trim(), phoneCtrl.text.trim());
                nameCtrl.dispose(); phoneCtrl.dispose();
                Get.back();
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(loc.save),
            ))),
          ]),
        ]),
      ),
    );
  }

  void _showAbout(BuildContext ctx) {
    final loc = AppLocalizations.of(ctx);
    AppSheet.show(
      title: loc.aboutSection,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 80, height: 80,
            decoration: const BoxDecoration(
              gradient: AppColors.gradientPrimary, shape: BoxShape.circle,
            ),
            child: const Icon(Icons.spa_rounded, color: Colors.white, size: 42),
          ),
          const SizedBox(height: 16),
          Text(loc.appName, style: AppTextStyles.h2),
          const SizedBox(height: 4),
          const Text('v 1.0.0', style: TextStyle(color: AppColors.textSecond, fontSize: 13)),
          const SizedBox(height: 8),
          Text(loc.aboutMenu,
              style: const TextStyle(color: AppColors.textHint, fontSize: 12),
              textAlign: TextAlign.center),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Get.back(),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(loc.ok),
            ),
          ),
        ]),
      ),
    );
  }
}

// ── 私有子组件 ─────────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
    child: Text(title, style: const TextStyle(
      fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textHint, letterSpacing: 0.5,
    )),
  );
}

class _SwitchTile extends StatelessWidget {
  final String label; final IconData icon; final Color color;
  final bool value; final ValueChanged<bool> onChanged;
  const _SwitchTile(this.label, this.icon, this.color, this.value, this.onChanged);
  @override
  Widget build(BuildContext context) => ListTile(
    leading: Container(width: 34, height: 34,
        decoration: BoxDecoration(color: color.withValues(alpha:0.1), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: color, size: 18)),
    title: Text(label, style: AppTextStyles.body2),
    trailing: Switch(value: value, onChanged: onChanged, activeColor: AppColors.primary),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
  );
}

class _ArrowTile extends StatelessWidget {
  final String label; final IconData icon; final Color color; final VoidCallback onTap;
  const _ArrowTile(this.label, this.icon, this.color, this.onTap);
  @override
  Widget build(BuildContext context) => BounceTap(
    onTap: onTap,
    child: ListTile(
      leading: Container(width: 34, height: 34,
          decoration: BoxDecoration(color: color.withValues(alpha:0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 18)),
      title: Text(label, style: AppTextStyles.body2),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    ),
  );
}

class _PassField extends StatefulWidget {
  final String hint; final TextEditingController ctrl;
  const _PassField(this.hint, this.ctrl);
  @override
  State<_PassField> createState() => _PassFieldState();
}

class _PassFieldState extends State<_PassField> {
  bool _obs = true;
  @override
  Widget build(BuildContext context) => TextField(
    controller: widget.ctrl, obscureText: _obs,
    decoration: InputDecoration(
      labelText: widget.hint,
      prefixIcon: const Icon(Icons.lock_rounded, size: 18),
      suffixIcon: IconButton(
        icon: Icon(_obs ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 18),
        onPressed: () => setState(() => _obs = !_obs),
      ),
    ),
  );
}
