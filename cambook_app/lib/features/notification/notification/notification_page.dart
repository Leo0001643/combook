import 'package:get/get.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';

/// 单条通知数据模型（本地 Mock）
class _NotificationItem {
  const _NotificationItem({
    required this.id,
    required this.icon,
    required this.title,
    required this.content,
    required this.time,
    required this.read,
  });

  final String id;
  final IconData icon;
  final String title;
  final String content;
  final String time;
  final bool read;
}

/// 消息通知中心 — 系统 / 订单 / 活动 三类 Tab
class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  /// 三类通知 Mock 数据
  late List<_NotificationItem> _system;
  late List<_NotificationItem> _order;
  late List<_NotificationItem> _promo;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _system = [
      const _NotificationItem(
        id: 's1',
        icon: Icons.system_update_rounded,
        title: '版本更新',
        content: 'CamBook v1.0.1 已发布，优化预约流程与地图定位体验。',
        time: '今天 09:12',
        read: false,
      ),
      const _NotificationItem(
        id: 's2',
        icon: Icons.security_rounded,
        title: '安全提醒',
        content: '请勿向他人透露验证码与支付密码，官方不会索要您的私钥。',
        time: '昨天 18:40',
        read: false,
      ),
      const _NotificationItem(
        id: 's3',
        icon: Icons.campaign_outlined,
        title: '系统维护',
        content: '本周三 02:00–04:00 将进行例行维护，期间可能短暂无法下单。',
        time: '周一 10:00',
        read: true,
      ),
      const _NotificationItem(
        id: 's4',
        icon: Icons.verified_user_outlined,
        title: '实名认证通过',
        content: '您的账号已完成实名认证，可正常使用全部功能。',
        time: '3月28日',
        read: true,
      ),
    ];
    _order = [
      const _NotificationItem(
        id: 'o1',
        icon: Icons.receipt_long_rounded,
        title: '订单已接单',
        content: '技师 林悦 已接受您的预约，预计 14:30 到达。',
        time: '今天 13:05',
        read: false,
      ),
      const _NotificationItem(
        id: 'o2',
        icon: Icons.local_shipping_outlined,
        title: '技师正在赶来',
        content: '订单 #CB8821 技师已出发，可在地图中查看实时位置。',
        time: '今天 12:48',
        read: false,
      ),
      const _NotificationItem(
        id: 'o3',
        icon: Icons.check_circle_outline,
        title: '服务已完成',
        content: '感谢您的使用，欢迎对本次服务进行评价。',
        time: '昨天 20:15',
        read: true,
      ),
      const _NotificationItem(
        id: 'o4',
        icon: Icons.payment_rounded,
        title: '退款已到账',
        content: '订单退款已原路退回，请注意查收。',
        time: '昨天 11:22',
        read: true,
      ),
    ];
    _promo = [
      const _NotificationItem(
        id: 'p1',
        icon: Icons.local_offer_rounded,
        title: '限时立减',
        content: '周末专享：下单满 299 立减 50，名额有限先到先得。',
        time: '今天 08:00',
        read: false,
      ),
      const _NotificationItem(
        id: 'p2',
        icon: Icons.card_giftcard_rounded,
        title: '新客礼包',
        content: '您有一张 8 折优惠券即将过期，快去使用吧。',
        time: '昨天 09:30',
        read: false,
      ),
      const _NotificationItem(
        id: 'p3',
        icon: Icons.spa_rounded,
        title: '春季 SPA 专场',
        content: '精选芳香理疗套餐上线，预约即赠热敷眼罩一份。',
        time: '3月30日',
        read: true,
      ),
      const _NotificationItem(
        id: 'p4',
        icon: Icons.groups_2_outlined,
        title: '邀请有礼',
        content: '成功邀请好友完成首单，双方各得 20 元余额奖励。',
        time: '3月25日',
        read: true,
      ),
    ];
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _markAllRead() {
    setState(() {
      _system = _system.map((e) => _NotificationItem(
            id: e.id,
            icon: e.icon,
            title: e.title,
            content: e.content,
            time: e.time,
            read: true,
          )).toList();
      _order = _order.map((e) => _NotificationItem(
            id: e.id,
            icon: e.icon,
            title: e.title,
            content: e.content,
            time: e.time,
            read: true,
          )).toList();
      _promo = _promo.map((e) => _NotificationItem(
            id: e.id,
            icon: e.icon,
            title: e.title,
            content: e.content,
            time: e.time,
            read: true,
          )).toList();
    });
    final l = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l.operationSuccess), behavior: SnackBarBehavior.floating),
    );
  }

  void _onTapItem(List<_NotificationItem> list, int index) {
    final item = list[index];
    if (!item.read) {
      setState(() {
        list[index] = _NotificationItem(
          id: item.id,
          icon: item.icon,
          title: item.title,
          content: item.content,
          time: item.time,
          read: true,
        );
      });
    }
    if (!mounted) return;
    final l = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(item.read ? l.notifAlreadyRead : l.notifMarkedRead),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppTheme.gray900),
          onPressed: () => Get.back(),
        ),
        title: Text(
          l.messages,
          style: const TextStyle(
            color: AppTheme.gray900,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _markAllRead,
            child: Text(
              l.markAllRead,
              style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.gray500,
          indicatorColor: AppTheme.primaryColor,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          tabs: [
            Tab(text: l.notifTabSystem),
            Tab(text: l.notifTabOrder),
            Tab(text: l.notifTabPromo),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTabList(_system, 0),
          _buildTabList(_order, 1),
          _buildTabList(_promo, 2),
        ],
      ),
    );
  }

  /// 单个 Tab 下的列表或空状态
  Widget _buildTabList(List<_NotificationItem> items, int tabIndex) {
    final l = AppLocalizations.of(context);
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none_rounded, size: 64, color: AppTheme.gray300),
            const SizedBox(height: 12),
            Text(l.noData, style: const TextStyle(color: AppTheme.gray500, fontSize: 15)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final n = items[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
                final list = tabIndex == 0 ? _system : tabIndex == 1 ? _order : _promo;
                _onTapItem(list, i);
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(n.icon, color: AppTheme.primaryColor, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!n.read)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6, right: 6),
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: AppTheme.infoColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              Expanded(
                                child: Text(
                                  n.title,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: n.read ? FontWeight.w500 : FontWeight.w700,
                                    color: AppTheme.gray900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            n.content,
                            style: const TextStyle(fontSize: 13, color: AppTheme.gray600, height: 1.45),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            n.time,
                            style: const TextStyle(fontSize: 12, color: AppTheme.gray400),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
