import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_km.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_vi.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
    Locale('km'),
    Locale('ko'),
    Locale('vi'),
    Locale('zh')
  ];

  /// No description provided for @appName.
  ///
  /// In zh, this message translates to:
  /// **'CamBook 技师端'**
  String get appName;

  /// No description provided for @navHome.
  ///
  /// In zh, this message translates to:
  /// **'首页'**
  String get navHome;

  /// No description provided for @navOrders.
  ///
  /// In zh, this message translates to:
  /// **'订单'**
  String get navOrders;

  /// No description provided for @navMessages.
  ///
  /// In zh, this message translates to:
  /// **'消息'**
  String get navMessages;

  /// No description provided for @navIncome.
  ///
  /// In zh, this message translates to:
  /// **'收入'**
  String get navIncome;

  /// No description provided for @navProfile.
  ///
  /// In zh, this message translates to:
  /// **'我的'**
  String get navProfile;

  /// No description provided for @ok.
  ///
  /// In zh, this message translates to:
  /// **'确定'**
  String get ok;

  /// No description provided for @cancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In zh, this message translates to:
  /// **'确认'**
  String get confirm;

  /// No description provided for @save.
  ///
  /// In zh, this message translates to:
  /// **'保存'**
  String get save;

  /// No description provided for @edit.
  ///
  /// In zh, this message translates to:
  /// **'编辑'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In zh, this message translates to:
  /// **'删除'**
  String get delete;

  /// No description provided for @back.
  ///
  /// In zh, this message translates to:
  /// **'返回'**
  String get back;

  /// No description provided for @loading.
  ///
  /// In zh, this message translates to:
  /// **'加载中…'**
  String get loading;

  /// No description provided for @noData.
  ///
  /// In zh, this message translates to:
  /// **'暂无数据'**
  String get noData;

  /// No description provided for @noMore.
  ///
  /// In zh, this message translates to:
  /// **'没有更多订单了'**
  String get noMore;

  /// No description provided for @error.
  ///
  /// In zh, this message translates to:
  /// **'加载失败'**
  String get error;

  /// No description provided for @retry.
  ///
  /// In zh, this message translates to:
  /// **'重试'**
  String get retry;

  /// No description provided for @close.
  ///
  /// In zh, this message translates to:
  /// **'关闭'**
  String get close;

  /// No description provided for @send.
  ///
  /// In zh, this message translates to:
  /// **'发送'**
  String get send;

  /// No description provided for @call.
  ///
  /// In zh, this message translates to:
  /// **'拨打电话'**
  String get call;

  /// No description provided for @navigate.
  ///
  /// In zh, this message translates to:
  /// **'导航'**
  String get navigate;

  /// No description provided for @copy.
  ///
  /// In zh, this message translates to:
  /// **'复制'**
  String get copy;

  /// No description provided for @justNow.
  ///
  /// In zh, this message translates to:
  /// **'刚刚'**
  String get justNow;

  /// No description provided for @minutesAgo.
  ///
  /// In zh, this message translates to:
  /// **'{n} 分钟前'**
  String minutesAgo(int n);

  /// No description provided for @hoursAgo.
  ///
  /// In zh, this message translates to:
  /// **'{n} 小时前'**
  String hoursAgo(int n);

  /// No description provided for @daysAgo.
  ///
  /// In zh, this message translates to:
  /// **'{n} 天前'**
  String daysAgo(int n);

  /// No description provided for @success.
  ///
  /// In zh, this message translates to:
  /// **'操作成功'**
  String get success;

  /// No description provided for @failed.
  ///
  /// In zh, this message translates to:
  /// **'操作失败'**
  String get failed;

  /// No description provided for @submitting.
  ///
  /// In zh, this message translates to:
  /// **'提交中…'**
  String get submitting;

  /// No description provided for @statusOnline.
  ///
  /// In zh, this message translates to:
  /// **'在线'**
  String get statusOnline;

  /// No description provided for @statusBusy.
  ///
  /// In zh, this message translates to:
  /// **'忙碌'**
  String get statusBusy;

  /// No description provided for @statusRest.
  ///
  /// In zh, this message translates to:
  /// **'休息'**
  String get statusRest;

  /// No description provided for @statusOnlineDesc.
  ///
  /// In zh, this message translates to:
  /// **'可接单'**
  String get statusOnlineDesc;

  /// No description provided for @statusBusyDesc.
  ///
  /// In zh, this message translates to:
  /// **'服务中'**
  String get statusBusyDesc;

  /// No description provided for @statusRestDesc.
  ///
  /// In zh, this message translates to:
  /// **'休息中'**
  String get statusRestDesc;

  /// No description provided for @statusSwitchTitle.
  ///
  /// In zh, this message translates to:
  /// **'切换状态'**
  String get statusSwitchTitle;

  /// No description provided for @statusSwitchDesc.
  ///
  /// In zh, this message translates to:
  /// **'切换后将影响接单状态'**
  String get statusSwitchDesc;

  /// No description provided for @greetingMorning.
  ///
  /// In zh, this message translates to:
  /// **'早上好'**
  String get greetingMorning;

  /// No description provided for @greetingAfternoon.
  ///
  /// In zh, this message translates to:
  /// **'下午好'**
  String get greetingAfternoon;

  /// No description provided for @greetingEvening.
  ///
  /// In zh, this message translates to:
  /// **'晚上好'**
  String get greetingEvening;

  /// No description provided for @techNo.
  ///
  /// In zh, this message translates to:
  /// **'技师编号'**
  String get techNo;

  /// No description provided for @todayStats.
  ///
  /// In zh, this message translates to:
  /// **'今日数据'**
  String get todayStats;

  /// No description provided for @todayOrders.
  ///
  /// In zh, this message translates to:
  /// **'今日订单'**
  String get todayOrders;

  /// No description provided for @todayIncome.
  ///
  /// In zh, this message translates to:
  /// **'今日收入'**
  String get todayIncome;

  /// No description provided for @todayRating.
  ///
  /// In zh, this message translates to:
  /// **'今日评分'**
  String get todayRating;

  /// No description provided for @quickActions.
  ///
  /// In zh, this message translates to:
  /// **'快捷操作'**
  String get quickActions;

  /// No description provided for @startAccepting.
  ///
  /// In zh, this message translates to:
  /// **'开始接单'**
  String get startAccepting;

  /// No description provided for @appointments.
  ///
  /// In zh, this message translates to:
  /// **'预约管理'**
  String get appointments;

  /// No description provided for @viewSchedule.
  ///
  /// In zh, this message translates to:
  /// **'查看排班'**
  String get viewSchedule;

  /// No description provided for @recentOrders.
  ///
  /// In zh, this message translates to:
  /// **'最近订单'**
  String get recentOrders;

  /// No description provided for @viewAll.
  ///
  /// In zh, this message translates to:
  /// **'查看全部'**
  String get viewAll;

  /// No description provided for @noOrdersToday.
  ///
  /// In zh, this message translates to:
  /// **'今日暂无订单'**
  String get noOrdersToday;

  /// No description provided for @newOrderTitle.
  ///
  /// In zh, this message translates to:
  /// **'新订单请求'**
  String get newOrderTitle;

  /// No description provided for @newOrderDesc.
  ///
  /// In zh, this message translates to:
  /// **'有新的服务订单待接单'**
  String get newOrderDesc;

  /// No description provided for @acceptOrder.
  ///
  /// In zh, this message translates to:
  /// **'立即接单'**
  String get acceptOrder;

  /// No description provided for @rejectOrder.
  ///
  /// In zh, this message translates to:
  /// **'拒单'**
  String get rejectOrder;

  /// No description provided for @autoReject.
  ///
  /// In zh, this message translates to:
  /// **'{s} 秒后自动拒单'**
  String autoReject(int s);

  /// No description provided for @refreshed.
  ///
  /// In zh, this message translates to:
  /// **'已刷新'**
  String get refreshed;

  /// No description provided for @ordersTitle.
  ///
  /// In zh, this message translates to:
  /// **'订单管理'**
  String get ordersTitle;

  /// No description provided for @tabPending.
  ///
  /// In zh, this message translates to:
  /// **'待接单'**
  String get tabPending;

  /// No description provided for @tabAccepted.
  ///
  /// In zh, this message translates to:
  /// **'已接单'**
  String get tabAccepted;

  /// No description provided for @tabInService.
  ///
  /// In zh, this message translates to:
  /// **'服务中'**
  String get tabInService;

  /// No description provided for @tabCompleted.
  ///
  /// In zh, this message translates to:
  /// **'已完成'**
  String get tabCompleted;

  /// No description provided for @tabCancelled.
  ///
  /// In zh, this message translates to:
  /// **'已取消'**
  String get tabCancelled;

  /// No description provided for @orderNo.
  ///
  /// In zh, this message translates to:
  /// **'订单号'**
  String get orderNo;

  /// No description provided for @serviceType.
  ///
  /// In zh, this message translates to:
  /// **'服务类型'**
  String get serviceType;

  /// No description provided for @homeService.
  ///
  /// In zh, this message translates to:
  /// **'上门服务'**
  String get homeService;

  /// No description provided for @storeService.
  ///
  /// In zh, this message translates to:
  /// **'到店服务'**
  String get storeService;

  /// No description provided for @amount.
  ///
  /// In zh, this message translates to:
  /// **'金额'**
  String get amount;

  /// No description provided for @appointTime.
  ///
  /// In zh, this message translates to:
  /// **'预约时间'**
  String get appointTime;

  /// No description provided for @distance.
  ///
  /// In zh, this message translates to:
  /// **'距离'**
  String get distance;

  /// No description provided for @remark.
  ///
  /// In zh, this message translates to:
  /// **'备注'**
  String get remark;

  /// No description provided for @btnAccept.
  ///
  /// In zh, this message translates to:
  /// **'接单'**
  String get btnAccept;

  /// No description provided for @btnReject.
  ///
  /// In zh, this message translates to:
  /// **'拒单'**
  String get btnReject;

  /// No description provided for @btnArrive.
  ///
  /// In zh, this message translates to:
  /// **'到达'**
  String get btnArrive;

  /// No description provided for @btnStartService.
  ///
  /// In zh, this message translates to:
  /// **'开始服务'**
  String get btnStartService;

  /// No description provided for @btnComplete.
  ///
  /// In zh, this message translates to:
  /// **'完成订单'**
  String get btnComplete;

  /// No description provided for @btnContact.
  ///
  /// In zh, this message translates to:
  /// **'联系客户'**
  String get btnContact;

  /// No description provided for @btnDetail.
  ///
  /// In zh, this message translates to:
  /// **'查看详情'**
  String get btnDetail;

  /// No description provided for @rejectReason.
  ///
  /// In zh, this message translates to:
  /// **'拒单原因'**
  String get rejectReason;

  /// No description provided for @rejectReasonHint.
  ///
  /// In zh, this message translates to:
  /// **'请输入拒单原因（可选）'**
  String get rejectReasonHint;

  /// No description provided for @acceptConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确定接受此订单？'**
  String get acceptConfirm;

  /// No description provided for @completeConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确定完成服务？'**
  String get completeConfirm;

  /// No description provided for @rejectConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确定拒绝此订单？'**
  String get rejectConfirm;

  /// No description provided for @noOrders.
  ///
  /// In zh, this message translates to:
  /// **'暂无订单'**
  String get noOrders;

  /// No description provided for @duration.
  ///
  /// In zh, this message translates to:
  /// **'时长'**
  String get duration;

  /// No description provided for @unitMin.
  ///
  /// In zh, this message translates to:
  /// **'分钟'**
  String get unitMin;

  /// No description provided for @orderDetailTitle.
  ///
  /// In zh, this message translates to:
  /// **'订单详情'**
  String get orderDetailTitle;

  /// No description provided for @customerInfo.
  ///
  /// In zh, this message translates to:
  /// **'客户信息'**
  String get customerInfo;

  /// No description provided for @orderInfo.
  ///
  /// In zh, this message translates to:
  /// **'订单信息'**
  String get orderInfo;

  /// No description provided for @serviceItems.
  ///
  /// In zh, this message translates to:
  /// **'服务项目'**
  String get serviceItems;

  /// No description provided for @totalAmount.
  ///
  /// In zh, this message translates to:
  /// **'总金额'**
  String get totalAmount;

  /// No description provided for @orderTime.
  ///
  /// In zh, this message translates to:
  /// **'下单时间'**
  String get orderTime;

  /// No description provided for @serviceAddress.
  ///
  /// In zh, this message translates to:
  /// **'服务地址'**
  String get serviceAddress;

  /// No description provided for @customerNotes.
  ///
  /// In zh, this message translates to:
  /// **'客户备注'**
  String get customerNotes;

  /// No description provided for @serviceProgress.
  ///
  /// In zh, this message translates to:
  /// **'服务进度'**
  String get serviceProgress;

  /// No description provided for @stepPending.
  ///
  /// In zh, this message translates to:
  /// **'待接单'**
  String get stepPending;

  /// No description provided for @stepAccepted.
  ///
  /// In zh, this message translates to:
  /// **'已接单'**
  String get stepAccepted;

  /// No description provided for @stepArrived.
  ///
  /// In zh, this message translates to:
  /// **'已到达'**
  String get stepArrived;

  /// No description provided for @stepInService.
  ///
  /// In zh, this message translates to:
  /// **'服务中'**
  String get stepInService;

  /// No description provided for @stepCompleted.
  ///
  /// In zh, this message translates to:
  /// **'已完成'**
  String get stepCompleted;

  /// No description provided for @confirmArrival.
  ///
  /// In zh, this message translates to:
  /// **'确认到达'**
  String get confirmArrival;

  /// No description provided for @serviceActiveTitle.
  ///
  /// In zh, this message translates to:
  /// **'服务中'**
  String get serviceActiveTitle;

  /// No description provided for @elapsed.
  ///
  /// In zh, this message translates to:
  /// **'已服务'**
  String get elapsed;

  /// No description provided for @remaining.
  ///
  /// In zh, this message translates to:
  /// **'剩余'**
  String get remaining;

  /// No description provided for @pause.
  ///
  /// In zh, this message translates to:
  /// **'暂停'**
  String get pause;

  /// No description provided for @resume.
  ///
  /// In zh, this message translates to:
  /// **'继续'**
  String get resume;

  /// No description provided for @endService.
  ///
  /// In zh, this message translates to:
  /// **'结束服务'**
  String get endService;

  /// No description provided for @endServiceConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确定结束服务？完成后将进入待评价状态。'**
  String get endServiceConfirm;

  /// No description provided for @pauseConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确定暂停服务吗？'**
  String get pauseConfirm;

  /// No description provided for @focusMode.
  ///
  /// In zh, this message translates to:
  /// **'专注模式'**
  String get focusMode;

  /// No description provided for @messagesTitle.
  ///
  /// In zh, this message translates to:
  /// **'消息'**
  String get messagesTitle;

  /// No description provided for @systemNotice.
  ///
  /// In zh, this message translates to:
  /// **'系统通知'**
  String get systemNotice;

  /// No description provided for @noMessages.
  ///
  /// In zh, this message translates to:
  /// **'暂无消息'**
  String get noMessages;

  /// No description provided for @markAllRead.
  ///
  /// In zh, this message translates to:
  /// **'全部已读'**
  String get markAllRead;

  /// No description provided for @unread.
  ///
  /// In zh, this message translates to:
  /// **'未读'**
  String get unread;

  /// No description provided for @chatPlaceholder.
  ///
  /// In zh, this message translates to:
  /// **'输入消息…'**
  String get chatPlaceholder;

  /// No description provided for @quickReplies.
  ///
  /// In zh, this message translates to:
  /// **'快捷回复'**
  String get quickReplies;

  /// No description provided for @sendLocation.
  ///
  /// In zh, this message translates to:
  /// **'发送位置'**
  String get sendLocation;

  /// No description provided for @noChatMessages.
  ///
  /// In zh, this message translates to:
  /// **'开始聊天吧'**
  String get noChatMessages;

  /// No description provided for @qr1.
  ///
  /// In zh, this message translates to:
  /// **'好的，我马上出发'**
  String get qr1;

  /// No description provided for @qr2.
  ///
  /// In zh, this message translates to:
  /// **'请问您在哪里？'**
  String get qr2;

  /// No description provided for @qr3.
  ///
  /// In zh, this message translates to:
  /// **'我已到达服务地点'**
  String get qr3;

  /// No description provided for @qr4.
  ///
  /// In zh, this message translates to:
  /// **'服务已开始'**
  String get qr4;

  /// No description provided for @qr5.
  ///
  /// In zh, this message translates to:
  /// **'稍等一下'**
  String get qr5;

  /// No description provided for @qr6.
  ///
  /// In zh, this message translates to:
  /// **'感谢您的惠顾'**
  String get qr6;

  /// No description provided for @incomeTitle.
  ///
  /// In zh, this message translates to:
  /// **'收入'**
  String get incomeTitle;

  /// No description provided for @incomeOverview.
  ///
  /// In zh, this message translates to:
  /// **'收入概览'**
  String get incomeOverview;

  /// No description provided for @periodToday.
  ///
  /// In zh, this message translates to:
  /// **'今日'**
  String get periodToday;

  /// No description provided for @periodWeek.
  ///
  /// In zh, this message translates to:
  /// **'本周'**
  String get periodWeek;

  /// No description provided for @periodMonth.
  ///
  /// In zh, this message translates to:
  /// **'本月'**
  String get periodMonth;

  /// No description provided for @periodTotal.
  ///
  /// In zh, this message translates to:
  /// **'累计'**
  String get periodTotal;

  /// No description provided for @todayIncomeLabel.
  ///
  /// In zh, this message translates to:
  /// **'今日收入'**
  String get todayIncomeLabel;

  /// No description provided for @weekIncomeLabel.
  ///
  /// In zh, this message translates to:
  /// **'本周收入'**
  String get weekIncomeLabel;

  /// No description provided for @monthIncomeLabel.
  ///
  /// In zh, this message translates to:
  /// **'本月收入'**
  String get monthIncomeLabel;

  /// No description provided for @totalIncomeLabel.
  ///
  /// In zh, this message translates to:
  /// **'累计收入'**
  String get totalIncomeLabel;

  /// No description provided for @incomeTrend.
  ///
  /// In zh, this message translates to:
  /// **'收入趋势'**
  String get incomeTrend;

  /// No description provided for @incomeRecords.
  ///
  /// In zh, this message translates to:
  /// **'收入明细'**
  String get incomeRecords;

  /// No description provided for @noRecords.
  ///
  /// In zh, this message translates to:
  /// **'暂无收入记录'**
  String get noRecords;

  /// No description provided for @incomeOrder.
  ///
  /// In zh, this message translates to:
  /// **'订单收入'**
  String get incomeOrder;

  /// No description provided for @incomeBonus.
  ///
  /// In zh, this message translates to:
  /// **'奖励'**
  String get incomeBonus;

  /// No description provided for @incomeDeduction.
  ///
  /// In zh, this message translates to:
  /// **'扣除'**
  String get incomeDeduction;

  /// No description provided for @withdraw.
  ///
  /// In zh, this message translates to:
  /// **'申请提现'**
  String get withdraw;

  /// No description provided for @availableBalance.
  ///
  /// In zh, this message translates to:
  /// **'可提现余额'**
  String get availableBalance;

  /// No description provided for @withdrawAmount.
  ///
  /// In zh, this message translates to:
  /// **'提现金额'**
  String get withdrawAmount;

  /// No description provided for @withdrawMethod.
  ///
  /// In zh, this message translates to:
  /// **'提现方式'**
  String get withdrawMethod;

  /// No description provided for @bankCard.
  ///
  /// In zh, this message translates to:
  /// **'银行卡'**
  String get bankCard;

  /// No description provided for @usdtLabel.
  ///
  /// In zh, this message translates to:
  /// **'USDT'**
  String get usdtLabel;

  /// No description provided for @withdrawMin.
  ///
  /// In zh, this message translates to:
  /// **'最低提现 100 元'**
  String get withdrawMin;

  /// No description provided for @withdrawConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确认提现'**
  String get withdrawConfirm;

  /// No description provided for @withdrawSuccess.
  ///
  /// In zh, this message translates to:
  /// **'提现申请已提交，预计 1-3 个工作日到账'**
  String get withdrawSuccess;

  /// No description provided for @inputAmount.
  ///
  /// In zh, this message translates to:
  /// **'请输入提现金额'**
  String get inputAmount;

  /// No description provided for @profileTitle.
  ///
  /// In zh, this message translates to:
  /// **'我的'**
  String get profileTitle;

  /// No description provided for @levelNormal.
  ///
  /// In zh, this message translates to:
  /// **'普通技师'**
  String get levelNormal;

  /// No description provided for @levelSenior.
  ///
  /// In zh, this message translates to:
  /// **'高级技师'**
  String get levelSenior;

  /// No description provided for @levelGold.
  ///
  /// In zh, this message translates to:
  /// **'金牌技师'**
  String get levelGold;

  /// No description provided for @levelTop.
  ///
  /// In zh, this message translates to:
  /// **'顶级技师'**
  String get levelTop;

  /// No description provided for @completedOrders.
  ///
  /// In zh, this message translates to:
  /// **'完成订单'**
  String get completedOrders;

  /// No description provided for @skillsMenu.
  ///
  /// In zh, this message translates to:
  /// **'技能管理'**
  String get skillsMenu;

  /// No description provided for @reviewsMenu.
  ///
  /// In zh, this message translates to:
  /// **'客户评价'**
  String get reviewsMenu;

  /// No description provided for @scheduleMenu.
  ///
  /// In zh, this message translates to:
  /// **'我的排班'**
  String get scheduleMenu;

  /// No description provided for @settingsMenu.
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get settingsMenu;

  /// No description provided for @helpMenu.
  ///
  /// In zh, this message translates to:
  /// **'帮助中心'**
  String get helpMenu;

  /// No description provided for @aboutMenu.
  ///
  /// In zh, this message translates to:
  /// **'关于我们'**
  String get aboutMenu;

  /// No description provided for @logout.
  ///
  /// In zh, this message translates to:
  /// **'退出登录'**
  String get logout;

  /// No description provided for @logoutConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确定要退出登录吗？'**
  String get logoutConfirm;

  /// No description provided for @editProfile.
  ///
  /// In zh, this message translates to:
  /// **'编辑资料'**
  String get editProfile;

  /// No description provided for @memberSince.
  ///
  /// In zh, this message translates to:
  /// **'入职时间'**
  String get memberSince;

  /// No description provided for @settingsTitle.
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get settingsTitle;

  /// No description provided for @accountSection.
  ///
  /// In zh, this message translates to:
  /// **'账号设置'**
  String get accountSection;

  /// No description provided for @changePassword.
  ///
  /// In zh, this message translates to:
  /// **'修改密码'**
  String get changePassword;

  /// No description provided for @notifySection.
  ///
  /// In zh, this message translates to:
  /// **'通知设置'**
  String get notifySection;

  /// No description provided for @orderNotify.
  ///
  /// In zh, this message translates to:
  /// **'订单通知'**
  String get orderNotify;

  /// No description provided for @messageNotify.
  ///
  /// In zh, this message translates to:
  /// **'消息通知'**
  String get messageNotify;

  /// No description provided for @systemNotify.
  ///
  /// In zh, this message translates to:
  /// **'系统通知'**
  String get systemNotify;

  /// No description provided for @langSection.
  ///
  /// In zh, this message translates to:
  /// **'语言设置'**
  String get langSection;

  /// No description provided for @currentLanguage.
  ///
  /// In zh, this message translates to:
  /// **'当前语言'**
  String get currentLanguage;

  /// No description provided for @aboutSection.
  ///
  /// In zh, this message translates to:
  /// **'关于'**
  String get aboutSection;

  /// No description provided for @version.
  ///
  /// In zh, this message translates to:
  /// **'版本'**
  String get version;

  /// No description provided for @privacyPolicy.
  ///
  /// In zh, this message translates to:
  /// **'隐私政策'**
  String get privacyPolicy;

  /// No description provided for @terms.
  ///
  /// In zh, this message translates to:
  /// **'用户协议'**
  String get terms;

  /// No description provided for @savedSuccess.
  ///
  /// In zh, this message translates to:
  /// **'保存成功'**
  String get savedSuccess;

  /// No description provided for @scheduleTitle.
  ///
  /// In zh, this message translates to:
  /// **'排班管理'**
  String get scheduleTitle;

  /// No description provided for @calendarTab.
  ///
  /// In zh, this message translates to:
  /// **'日历'**
  String get calendarTab;

  /// No description provided for @appointmentsTab.
  ///
  /// In zh, this message translates to:
  /// **'预约'**
  String get appointmentsTab;

  /// No description provided for @setAvailable.
  ///
  /// In zh, this message translates to:
  /// **'设为可用'**
  String get setAvailable;

  /// No description provided for @setUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'设为休息'**
  String get setUnavailable;

  /// No description provided for @workHours.
  ///
  /// In zh, this message translates to:
  /// **'工作时间'**
  String get workHours;

  /// No description provided for @addTimeSlot.
  ///
  /// In zh, this message translates to:
  /// **'添加时间段'**
  String get addTimeSlot;

  /// No description provided for @noAppointments.
  ///
  /// In zh, this message translates to:
  /// **'暂无预约'**
  String get noAppointments;

  /// No description provided for @upcoming.
  ///
  /// In zh, this message translates to:
  /// **'即将到来'**
  String get upcoming;

  /// No description provided for @confirmScheduleChange.
  ///
  /// In zh, this message translates to:
  /// **'确认修改排班？'**
  String get confirmScheduleChange;

  /// No description provided for @weekdayMon.
  ///
  /// In zh, this message translates to:
  /// **'一'**
  String get weekdayMon;

  /// No description provided for @weekdayTue.
  ///
  /// In zh, this message translates to:
  /// **'二'**
  String get weekdayTue;

  /// No description provided for @weekdayWed.
  ///
  /// In zh, this message translates to:
  /// **'三'**
  String get weekdayWed;

  /// No description provided for @weekdayThu.
  ///
  /// In zh, this message translates to:
  /// **'四'**
  String get weekdayThu;

  /// No description provided for @weekdayFri.
  ///
  /// In zh, this message translates to:
  /// **'五'**
  String get weekdayFri;

  /// No description provided for @weekdaySat.
  ///
  /// In zh, this message translates to:
  /// **'六'**
  String get weekdaySat;

  /// No description provided for @weekdaySun.
  ///
  /// In zh, this message translates to:
  /// **'日'**
  String get weekdaySun;

  /// No description provided for @langZh.
  ///
  /// In zh, this message translates to:
  /// **'中文'**
  String get langZh;

  /// No description provided for @langEn.
  ///
  /// In zh, this message translates to:
  /// **'English'**
  String get langEn;

  /// No description provided for @langVi.
  ///
  /// In zh, this message translates to:
  /// **'Tiếng Việt'**
  String get langVi;

  /// No description provided for @langKm.
  ///
  /// In zh, this message translates to:
  /// **'ភាសាខ្មែរ'**
  String get langKm;

  /// No description provided for @langKo.
  ///
  /// In zh, this message translates to:
  /// **'한국어'**
  String get langKo;

  /// No description provided for @langJa.
  ///
  /// In zh, this message translates to:
  /// **'日本語'**
  String get langJa;

  /// No description provided for @langTitle.
  ///
  /// In zh, this message translates to:
  /// **'语言设置'**
  String get langTitle;

  /// No description provided for @loginTitle.
  ///
  /// In zh, this message translates to:
  /// **'技师端登录'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'欢迎回来，请登录您的账号'**
  String get loginSubtitle;

  /// No description provided for @phone.
  ///
  /// In zh, this message translates to:
  /// **'手机号'**
  String get phone;

  /// No description provided for @phoneHint.
  ///
  /// In zh, this message translates to:
  /// **'请输入手机号'**
  String get phoneHint;

  /// No description provided for @password.
  ///
  /// In zh, this message translates to:
  /// **'密码'**
  String get password;

  /// No description provided for @passwordHint.
  ///
  /// In zh, this message translates to:
  /// **'请输入密码'**
  String get passwordHint;

  /// No description provided for @loginBtn.
  ///
  /// In zh, this message translates to:
  /// **'登录'**
  String get loginBtn;

  /// No description provided for @forgotPassword.
  ///
  /// In zh, this message translates to:
  /// **'忘记密码？'**
  String get forgotPassword;

  /// No description provided for @loginSuccess.
  ///
  /// In zh, this message translates to:
  /// **'登录成功'**
  String get loginSuccess;

  /// No description provided for @loginFailed.
  ///
  /// In zh, this message translates to:
  /// **'手机号或密码错误'**
  String get loginFailed;

  /// No description provided for @phoneRequired.
  ///
  /// In zh, this message translates to:
  /// **'请输入手机号'**
  String get phoneRequired;

  /// No description provided for @passwordRequired.
  ///
  /// In zh, this message translates to:
  /// **'请输入密码'**
  String get passwordRequired;

  /// No description provided for @skillsTitle.
  ///
  /// In zh, this message translates to:
  /// **'技能管理'**
  String get skillsTitle;

  /// No description provided for @reviewsTitle.
  ///
  /// In zh, this message translates to:
  /// **'客户评价'**
  String get reviewsTitle;

  /// No description provided for @noReviews.
  ///
  /// In zh, this message translates to:
  /// **'暂无评价'**
  String get noReviews;

  /// No description provided for @avgRating.
  ///
  /// In zh, this message translates to:
  /// **'平均评分'**
  String get avgRating;

  /// No description provided for @totalReviews.
  ///
  /// In zh, this message translates to:
  /// **'{n} 条评价'**
  String totalReviews(int n);

  /// No description provided for @loginTabPhone.
  ///
  /// In zh, this message translates to:
  /// **'手机号登录'**
  String get loginTabPhone;

  /// No description provided for @loginTabTechId.
  ///
  /// In zh, this message translates to:
  /// **'技师编号登录'**
  String get loginTabTechId;

  /// No description provided for @fieldTechId.
  ///
  /// In zh, this message translates to:
  /// **'技师编号'**
  String get fieldTechId;

  /// No description provided for @techIdHint.
  ///
  /// In zh, this message translates to:
  /// **'请输入您的技师编号'**
  String get techIdHint;

  /// No description provided for @techIdRequired.
  ///
  /// In zh, this message translates to:
  /// **'请输入技师编号'**
  String get techIdRequired;

  /// No description provided for @noAccount.
  ///
  /// In zh, this message translates to:
  /// **'还没有账号？'**
  String get noAccount;

  /// No description provided for @goRegister.
  ///
  /// In zh, this message translates to:
  /// **'立即注册'**
  String get goRegister;

  /// No description provided for @haveAccount.
  ///
  /// In zh, this message translates to:
  /// **'已有账号？'**
  String get haveAccount;

  /// No description provided for @goLogin.
  ///
  /// In zh, this message translates to:
  /// **'去登录'**
  String get goLogin;

  /// No description provided for @registerTitle.
  ///
  /// In zh, this message translates to:
  /// **'注册技师账号'**
  String get registerTitle;

  /// No description provided for @registerSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'加入 {merchant}，开始您的服务之旅'**
  String registerSubtitle(String merchant);

  /// No description provided for @fieldFullName.
  ///
  /// In zh, this message translates to:
  /// **'姓名'**
  String get fieldFullName;

  /// No description provided for @fullNameHint.
  ///
  /// In zh, this message translates to:
  /// **'请输入您的真实姓名'**
  String get fullNameHint;

  /// No description provided for @fullNameRequired.
  ///
  /// In zh, this message translates to:
  /// **'请输入姓名'**
  String get fullNameRequired;

  /// No description provided for @fieldEmail.
  ///
  /// In zh, this message translates to:
  /// **'邮箱'**
  String get fieldEmail;

  /// No description provided for @emailHint.
  ///
  /// In zh, this message translates to:
  /// **'请输入邮箱地址'**
  String get emailHint;

  /// No description provided for @fieldConfirmPassword.
  ///
  /// In zh, this message translates to:
  /// **'确认密码'**
  String get fieldConfirmPassword;

  /// No description provided for @confirmPasswordHint.
  ///
  /// In zh, this message translates to:
  /// **'请再次输入密码'**
  String get confirmPasswordHint;

  /// No description provided for @passwordMismatch.
  ///
  /// In zh, this message translates to:
  /// **'两次密码不一致'**
  String get passwordMismatch;

  /// No description provided for @passwordTooShort.
  ///
  /// In zh, this message translates to:
  /// **'密码至少 6 位'**
  String get passwordTooShort;

  /// No description provided for @fieldTelegram.
  ///
  /// In zh, this message translates to:
  /// **'Telegram 账号'**
  String get fieldTelegram;

  /// No description provided for @telegramHint.
  ///
  /// In zh, this message translates to:
  /// **'@username（选填）'**
  String get telegramHint;

  /// No description provided for @fieldFacebook.
  ///
  /// In zh, this message translates to:
  /// **'Facebook'**
  String get fieldFacebook;

  /// No description provided for @facebookHint.
  ///
  /// In zh, this message translates to:
  /// **'用户名或主页链接（选填）'**
  String get facebookHint;

  /// No description provided for @fieldMerchantCode.
  ///
  /// In zh, this message translates to:
  /// **'商户代码'**
  String get fieldMerchantCode;

  /// No description provided for @merchantCodeHint.
  ///
  /// In zh, this message translates to:
  /// **'请输入商户邀请码'**
  String get merchantCodeHint;

  /// No description provided for @merchantCodeRequired.
  ///
  /// In zh, this message translates to:
  /// **'请输入商户代码'**
  String get merchantCodeRequired;

  /// No description provided for @selectCountry.
  ///
  /// In zh, this message translates to:
  /// **'选择国家/地区'**
  String get selectCountry;

  /// No description provided for @registerBtn.
  ///
  /// In zh, this message translates to:
  /// **'立即注册'**
  String get registerBtn;

  /// No description provided for @registerSuccess.
  ///
  /// In zh, this message translates to:
  /// **'注册成功！请等待商户审核'**
  String get registerSuccess;

  /// No description provided for @registerFailed.
  ///
  /// In zh, this message translates to:
  /// **'注册失败，请重试'**
  String get registerFailed;

  /// No description provided for @invalidPhone.
  ///
  /// In zh, this message translates to:
  /// **'手机号格式不正确'**
  String get invalidPhone;

  /// No description provided for @invalidEmail.
  ///
  /// In zh, this message translates to:
  /// **'邮箱格式不正确'**
  String get invalidEmail;

  /// No description provided for @optionalField.
  ///
  /// In zh, this message translates to:
  /// **'选填'**
  String get optionalField;

  /// No description provided for @myMerchant.
  ///
  /// In zh, this message translates to:
  /// **'所属商户'**
  String get myMerchant;

  /// No description provided for @merchantVerified.
  ///
  /// In zh, this message translates to:
  /// **'已认证'**
  String get merchantVerified;

  /// No description provided for @merchantPending.
  ///
  /// In zh, this message translates to:
  /// **'审核中'**
  String get merchantPending;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In zh, this message translates to:
  /// **'找回密码'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordDesc.
  ///
  /// In zh, this message translates to:
  /// **'请输入注册手机号，我们将发送验证码'**
  String get forgotPasswordDesc;

  /// No description provided for @sendOtp.
  ///
  /// In zh, this message translates to:
  /// **'发送验证码'**
  String get sendOtp;

  /// No description provided for @otpSent.
  ///
  /// In zh, this message translates to:
  /// **'验证码已发送至 {phone}'**
  String otpSent(String phone);

  /// No description provided for @comingSoon.
  ///
  /// In zh, this message translates to:
  /// **'该功能即将上线，敬请期待'**
  String get comingSoon;

  /// No description provided for @arrivalNotice.
  ///
  /// In zh, this message translates to:
  /// **'技师已到达，请确认后开始服务'**
  String get arrivalNotice;

  /// No description provided for @launchingApp.
  ///
  /// In zh, this message translates to:
  /// **'正在跳转...'**
  String get launchingApp;

  /// No description provided for @statusSwitchedTo.
  ///
  /// In zh, this message translates to:
  /// **'状态已切换为'**
  String get statusSwitchedTo;

  /// No description provided for @customerMessage.
  ///
  /// In zh, this message translates to:
  /// **'客户消息'**
  String get customerMessage;

  /// No description provided for @systemMessage.
  ///
  /// In zh, this message translates to:
  /// **'系统消息'**
  String get systemMessage;

  /// No description provided for @serviceCompleted.
  ///
  /// In zh, this message translates to:
  /// **'服务完成'**
  String get serviceCompleted;

  /// No description provided for @grabExpired.
  ///
  /// In zh, this message translates to:
  /// **'抢单超时，订单已失效'**
  String get grabExpired;

  /// No description provided for @newOrder.
  ///
  /// In zh, this message translates to:
  /// **'新订单'**
  String get newOrder;

  /// No description provided for @newOrderGrab.
  ///
  /// In zh, this message translates to:
  /// **'新订单抢单'**
  String get newOrderGrab;

  /// No description provided for @distanceFrom.
  ///
  /// In zh, this message translates to:
  /// **'距您'**
  String get distanceFrom;

  /// No description provided for @ignore.
  ///
  /// In zh, this message translates to:
  /// **'忽略'**
  String get ignore;

  /// No description provided for @grabOrder.
  ///
  /// In zh, this message translates to:
  /// **'立即接单'**
  String get grabOrder;

  /// No description provided for @announcements.
  ///
  /// In zh, this message translates to:
  /// **'公告消息'**
  String get announcements;

  /// No description provided for @helpAndSupport.
  ///
  /// In zh, this message translates to:
  /// **'帮助与支持'**
  String get helpAndSupport;

  /// No description provided for @rateApp.
  ///
  /// In zh, this message translates to:
  /// **'评价应用'**
  String get rateApp;

  /// No description provided for @exitApp.
  ///
  /// In zh, this message translates to:
  /// **'退出应用'**
  String get exitApp;

  /// No description provided for @exitAppConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确定退出应用程序？'**
  String get exitAppConfirm;

  /// No description provided for @todaySchedule.
  ///
  /// In zh, this message translates to:
  /// **'今日安排'**
  String get todaySchedule;

  /// No description provided for @allOrders.
  ///
  /// In zh, this message translates to:
  /// **'全部订单'**
  String get allOrders;

  /// No description provided for @orderStatusPending.
  ///
  /// In zh, this message translates to:
  /// **'待确认'**
  String get orderStatusPending;

  /// No description provided for @orderStatusAccepted.
  ///
  /// In zh, this message translates to:
  /// **'已接单'**
  String get orderStatusAccepted;

  /// No description provided for @orderStatusInProgress.
  ///
  /// In zh, this message translates to:
  /// **'服务中'**
  String get orderStatusInProgress;

  /// No description provided for @orderStatusCompleted.
  ///
  /// In zh, this message translates to:
  /// **'已完成'**
  String get orderStatusCompleted;

  /// No description provided for @orderStatusCancelled.
  ///
  /// In zh, this message translates to:
  /// **'已取消'**
  String get orderStatusCancelled;

  /// No description provided for @noScheduleToday.
  ///
  /// In zh, this message translates to:
  /// **'今日暂无预约'**
  String get noScheduleToday;

  /// No description provided for @keepOnlineHint.
  ///
  /// In zh, this message translates to:
  /// **'保持在线，随时迎接新订单 ✨'**
  String get keepOnlineHint;

  /// No description provided for @myStats.
  ///
  /// In zh, this message translates to:
  /// **'我的数据'**
  String get myStats;

  /// No description provided for @totalOrders.
  ///
  /// In zh, this message translates to:
  /// **'累计接单'**
  String get totalOrders;

  /// No description provided for @overallRating.
  ///
  /// In zh, this message translates to:
  /// **'综合评分'**
  String get overallRating;

  /// No description provided for @currentBalance.
  ///
  /// In zh, this message translates to:
  /// **'当前余额'**
  String get currentBalance;

  /// No description provided for @statTodayAppointments.
  ///
  /// In zh, this message translates to:
  /// **'今日预约'**
  String get statTodayAppointments;

  /// No description provided for @statTodayCompleted.
  ///
  /// In zh, this message translates to:
  /// **'今日完成'**
  String get statTodayCompleted;

  /// No description provided for @statTodayCancelled.
  ///
  /// In zh, this message translates to:
  /// **'今日取消'**
  String get statTodayCancelled;

  /// No description provided for @schedOrderCount.
  ///
  /// In zh, this message translates to:
  /// **'{n}单'**
  String schedOrderCount(int n);

  /// No description provided for @schedInService.
  ///
  /// In zh, this message translates to:
  /// **'进行中'**
  String get schedInService;

  /// No description provided for @schedPending.
  ///
  /// In zh, this message translates to:
  /// **'待服务'**
  String get schedPending;

  /// No description provided for @totalDuration.
  ///
  /// In zh, this message translates to:
  /// **'总时长'**
  String get totalDuration;

  /// No description provided for @scheduleProgress.
  ///
  /// In zh, this message translates to:
  /// **'{completed} / {total} 单完成'**
  String scheduleProgress(int completed, int total);

  /// No description provided for @statusOnWay.
  ///
  /// In zh, this message translates to:
  /// **'前往中'**
  String get statusOnWay;

  /// No description provided for @statusCancelling.
  ///
  /// In zh, this message translates to:
  /// **'取消中'**
  String get statusCancelling;

  /// No description provided for @statusRefunding.
  ///
  /// In zh, this message translates to:
  /// **'退款中'**
  String get statusRefunding;

  /// No description provided for @statusRefunded.
  ///
  /// In zh, this message translates to:
  /// **'已退款'**
  String get statusRefunded;

  /// No description provided for @schedEndTime.
  ///
  /// In zh, this message translates to:
  /// **'结束 {time} · {duration}min'**
  String schedEndTime(String time, String duration);

  /// No description provided for @serviceInProgress.
  ///
  /// In zh, this message translates to:
  /// **'服务进行中'**
  String get serviceInProgress;

  /// No description provided for @estimatedIncome.
  ///
  /// In zh, this message translates to:
  /// **'预计 {amount}'**
  String estimatedIncome(String amount);
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'ja', 'km', 'ko', 'vi', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'ja': return AppLocalizationsJa();
    case 'km': return AppLocalizationsKm();
    case 'ko': return AppLocalizationsKo();
    case 'vi': return AppLocalizationsVi();
    case 'zh': return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
