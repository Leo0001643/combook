import 'package:get/get.dart';

class MemberHomeState {
  /// 底部导航当前 Tab 索引
  final currentTab = 0.obs;

  /// Banner 当前页码
  final bannerPage = 0.obs;

  /// 技师区 Tab（推荐/附近/新人/特惠）
  final selectedTab = 0.obs;

  MemberHomeState();
}
