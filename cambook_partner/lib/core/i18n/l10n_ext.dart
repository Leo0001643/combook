import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../l10n/gen/app_localizations.dart';

/// BuildContext 扩展 —— 免去每次写 AppLocalizations.of(context)
/// 用法：context.l10n.navHome
extension L10nExt on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// 全局无 context 访问 l10n（用于 Logic/Service 层）
/// 用法：gL10n.confirmTitle
AppLocalizations get gL10n => AppLocalizations.of(Get.context!);
