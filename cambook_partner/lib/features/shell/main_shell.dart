import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:badges/badges.dart' as bdg;
import '../../core/constants/app_colors.dart';
import '../../core/i18n/l10n_ext.dart';
import '../../core/services/message_service.dart';
import '../../core/widgets/common_widgets.dart';
import '../home/page.dart';
import '../orders/list/page.dart';
import '../messages/list/page.dart';
import '../income/page.dart';
import '../profile/index/page.dart';
import 'shell_controller.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key});

  static const _pages = [
    HomePage(), OrderListPage(), MessageListPage(), IncomePage(), ProfileIndexPage(),
  ];
  static const _icons = [
    Icons.home_rounded, Icons.receipt_long_rounded,
    Icons.chat_bubble_rounded, Icons.account_balance_wallet_rounded, Icons.person_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final ctrl   = Get.find<ShellController>();
    final labels = [
      context.l10n.navHome, context.l10n.navOrders,
      context.l10n.navMessages, context.l10n.navIncome, context.l10n.navProfile,
    ];
    return Obx(() {
      final idx = ctrl.currentIdx.value;
      return Scaffold(
        body: IndexedStack(index: idx, children: _pages),
        bottomNavigationBar: _BottomNav(currentIdx: idx, labels: labels, onTap: ctrl.switchTab),
      );
    });
  }
}

class _BottomNav extends StatelessWidget {
  final int currentIdx;
  final List<String> labels;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.currentIdx, required this.labels, required this.onTap});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 12, offset: const Offset(0, -2))],
    ),
    child: SafeArea(
      child: SizedBox(
        height: 58,
        child: Row(children: List.generate(5, (i) {
          final active = currentIdx == i;
          final color  = active ? AppColors.primary : AppColors.textHint;
          return Expanded(child: BounceTap(
            pressScale: 0.82,
            onTap: () => onTap(i),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              _buildIcon(i, color),
              const SizedBox(height: 3),
              Text(labels[i], style: TextStyle(
                color: color, fontSize: 11,
                fontWeight: active ? FontWeight.w700 : FontWeight.w400,
              )),
            ]),
          ));
        })),
      ),
    ),
  );

  Widget _buildIcon(int i, Color color) {
    final icon = Icon(MainShell._icons[i], color: color, size: 24);
    if (i == 2) {
      return Obx(() {
        final unread = Get.find<MessageService>().totalUnread;
        return bdg.Badge(
          showBadge: unread > 0,
          badgeContent: Text(
            '${unread > 9 ? '9+' : unread}',
            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
          ),
          badgeStyle: const bdg.BadgeStyle(badgeColor: AppColors.danger, padding: EdgeInsets.all(3)),
          child: icon,
        );
      });
    }
    return icon;
  }
}
