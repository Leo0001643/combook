// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => 'CamBook 技师端';

  @override
  String get navHome => '首页';

  @override
  String get navOrders => '订单';

  @override
  String get navMessages => '消息';

  @override
  String get navIncome => '收入';

  @override
  String get navProfile => '我的';

  @override
  String get ok => '确定';

  @override
  String get cancel => '取消';

  @override
  String get confirm => '确认';

  @override
  String get save => '保存';

  @override
  String get edit => '编辑';

  @override
  String get delete => '删除';

  @override
  String get back => '返回';

  @override
  String get loading => '加载中…';

  @override
  String get noData => '暂无数据';

  @override
  String get noMore => '没有更多订单了';

  @override
  String get error => '加载失败';

  @override
  String get retry => '重试';

  @override
  String get close => '关闭';

  @override
  String get send => '发送';

  @override
  String get call => '拨打电话';

  @override
  String get navigate => '导航';

  @override
  String get copy => '复制';

  @override
  String get justNow => '刚刚';

  @override
  String minutesAgo(int n) {
    return '$n 分钟前';
  }

  @override
  String hoursAgo(int n) {
    return '$n 小时前';
  }

  @override
  String daysAgo(int n) {
    return '$n 天前';
  }

  @override
  String get success => '操作成功';

  @override
  String get failed => '操作失败';

  @override
  String get submitting => '提交中…';

  @override
  String get statusOnline => '在线';

  @override
  String get statusBusy => '忙碌';

  @override
  String get statusRest => '休息';

  @override
  String get statusOnlineDesc => '可接单';

  @override
  String get statusBusyDesc => '服务中';

  @override
  String get statusRestDesc => '休息中';

  @override
  String get statusSwitchTitle => '切换状态';

  @override
  String get statusSwitchDesc => '切换后将影响接单状态';

  @override
  String get greetingMorning => '早上好';

  @override
  String get greetingAfternoon => '下午好';

  @override
  String get greetingEvening => '晚上好';

  @override
  String get techNo => '技师编号';

  @override
  String get todayStats => '今日数据';

  @override
  String get todayOrders => '今日订单';

  @override
  String get todayIncome => '今日收入';

  @override
  String get todayRating => '今日评分';

  @override
  String get quickActions => '快捷操作';

  @override
  String get startAccepting => '开始接单';

  @override
  String get appointments => '预约管理';

  @override
  String get viewSchedule => '查看排班';

  @override
  String get recentOrders => '最近订单';

  @override
  String get viewAll => '查看全部';

  @override
  String get noOrdersToday => '今日暂无订单';

  @override
  String get newOrderTitle => '新订单请求';

  @override
  String get newOrderDesc => '有新的服务订单待接单';

  @override
  String get acceptOrder => '立即接单';

  @override
  String get rejectOrder => '拒单';

  @override
  String autoReject(int s) {
    return '$s 秒后自动拒单';
  }

  @override
  String get refreshed => '已刷新';

  @override
  String get ordersTitle => '订单管理';

  @override
  String get tabPending => '待接单';

  @override
  String get tabAccepted => '已接单';

  @override
  String get statusReception => '接待中';

  @override
  String get tabInService => '服务中';

  @override
  String get tabCompleted => '已完成';

  @override
  String get tabCancelled => '已取消';

  @override
  String get orderNo => '订单号';

  @override
  String get serviceType => '服务类型';

  @override
  String get homeService => '上门服务';

  @override
  String get storeService => '到店服务';

  @override
  String get amount => '金额';

  @override
  String get appointTime => '预约时间';

  @override
  String get distance => '距离';

  @override
  String get remark => '备注';

  @override
  String get btnAccept => '接单';

  @override
  String get btnReject => '拒单';

  @override
  String get btnArrive => '到达';

  @override
  String get btnStartService => '开始服务';

  @override
  String get btnComplete => '完成订单';

  @override
  String get btnContact => '联系客户';

  @override
  String get btnDetail => '查看详情';

  @override
  String get rejectReason => '拒单原因';

  @override
  String get rejectReasonHint => '请输入拒单原因（可选）';

  @override
  String get acceptConfirm => '确定接受此订单？';

  @override
  String get completeConfirm => '确定完成服务？';

  @override
  String get rejectConfirm => '确定拒绝此订单？';

  @override
  String get noOrders => '暂无订单';

  @override
  String get duration => '时长';

  @override
  String get unitMin => '分钟';

  @override
  String get orderDetailTitle => '订单详情';

  @override
  String get customerInfo => '客户信息';

  @override
  String get orderInfo => '订单信息';

  @override
  String get serviceItems => '服务项目';

  @override
  String get totalAmount => '总金额';

  @override
  String get orderTime => '下单时间';

  @override
  String get serviceAddress => '服务地址';

  @override
  String get customerNotes => '客户备注';

  @override
  String get serviceProgress => '服务进度';

  @override
  String get stepPending => '待接单';

  @override
  String get stepAccepted => '已接单';

  @override
  String get stepArrived => '已到达';

  @override
  String get stepInService => '服务中';

  @override
  String get stepCompleted => '已完成';

  @override
  String get confirmArrival => '确认到达';

  @override
  String get serviceActiveTitle => '服务中';

  @override
  String get elapsed => '已服务';

  @override
  String get remaining => '剩余';

  @override
  String get pause => '暂停';

  @override
  String get resume => '继续';

  @override
  String get endService => '结束服务';

  @override
  String get endServiceConfirm => '确定结束服务？完成后将进入待评价状态。';

  @override
  String get pauseConfirm => '确定暂停服务吗？';

  @override
  String get focusMode => '专注模式';

  @override
  String get messagesTitle => '消息';

  @override
  String get systemNotice => '系统通知';

  @override
  String get noMessages => '暂无消息';

  @override
  String get markAllRead => '全部已读';

  @override
  String get unread => '未读';

  @override
  String get chatPlaceholder => '输入消息…';

  @override
  String get quickReplies => '快捷回复';

  @override
  String get sendLocation => '发送位置';

  @override
  String get noChatMessages => '开始聊天吧';

  @override
  String get qr1 => '好的，我马上出发';

  @override
  String get qr2 => '请问您在哪里？';

  @override
  String get qr3 => '我已到达服务地点';

  @override
  String get qr4 => '服务已开始';

  @override
  String get qr5 => '稍等一下';

  @override
  String get qr6 => '感谢您的惠顾';

  @override
  String get incomeTitle => '收入';

  @override
  String get incomeOverview => '收入概览';

  @override
  String get periodToday => '今日';

  @override
  String get periodWeek => '本周';

  @override
  String get periodMonth => '本月';

  @override
  String get periodTotal => '累计';

  @override
  String get todayIncomeLabel => '今日收入';

  @override
  String get weekIncomeLabel => '本周收入';

  @override
  String get monthIncomeLabel => '本月收入';

  @override
  String get totalIncomeLabel => '累计收入';

  @override
  String get incomeTrend => '收入趋势';

  @override
  String get incomeRecords => '收入明细';

  @override
  String get noRecords => '暂无收入记录';

  @override
  String get incomeOrder => '订单收入';

  @override
  String get incomeBonus => '奖励';

  @override
  String get incomeDeduction => '扣除';

  @override
  String get withdraw => '申请提现';

  @override
  String get availableBalance => '可提现余额';

  @override
  String get withdrawAmount => '提现金额';

  @override
  String get withdrawMethod => '提现方式';

  @override
  String get bankCard => '银行卡';

  @override
  String get usdtLabel => 'USDT';

  @override
  String get withdrawMin => '最低提现 100 元';

  @override
  String get withdrawConfirm => '确认提现';

  @override
  String get withdrawSuccess => '提现申请已提交，预计 1-3 个工作日到账';

  @override
  String get inputAmount => '请输入提现金额';

  @override
  String get profileTitle => '我的';

  @override
  String get levelNormal => '普通技师';

  @override
  String get levelSenior => '高级技师';

  @override
  String get levelGold => '金牌技师';

  @override
  String get levelTop => '顶级技师';

  @override
  String get completedOrders => '完成订单';

  @override
  String get skillsMenu => '技能管理';

  @override
  String get reviewsMenu => '客户评价';

  @override
  String get scheduleMenu => '我的排班';

  @override
  String get settingsMenu => '设置';

  @override
  String get helpMenu => '帮助中心';

  @override
  String get aboutMenu => '关于我们';

  @override
  String get logout => '退出登录';

  @override
  String get logoutConfirm => '确定要退出登录吗？';

  @override
  String get editProfile => '编辑资料';

  @override
  String get memberSince => '入职时间';

  @override
  String get settingsTitle => '设置';

  @override
  String get accountSection => '账号设置';

  @override
  String get changePassword => '修改密码';

  @override
  String get notifySection => '通知设置';

  @override
  String get orderNotify => '订单通知';

  @override
  String get messageNotify => '消息通知';

  @override
  String get systemNotify => '系统通知';

  @override
  String get langSection => '语言设置';

  @override
  String get currentLanguage => '当前语言';

  @override
  String get aboutSection => '关于';

  @override
  String get version => '版本';

  @override
  String get privacyPolicy => '隐私政策';

  @override
  String get terms => '用户协议';

  @override
  String get savedSuccess => '保存成功';

  @override
  String get scheduleTitle => '排班管理';

  @override
  String get calendarTab => '日历';

  @override
  String get appointmentsTab => '预约';

  @override
  String get setAvailable => '设为可用';

  @override
  String get setUnavailable => '设为休息';

  @override
  String get workHours => '工作时间';

  @override
  String get addTimeSlot => '添加时间段';

  @override
  String get noAppointments => '暂无预约';

  @override
  String get upcoming => '即将到来';

  @override
  String get confirmScheduleChange => '确认修改排班？';

  @override
  String get weekdayMon => '一';

  @override
  String get weekdayTue => '二';

  @override
  String get weekdayWed => '三';

  @override
  String get weekdayThu => '四';

  @override
  String get weekdayFri => '五';

  @override
  String get weekdaySat => '六';

  @override
  String get weekdaySun => '日';

  @override
  String get langZh => '中文';

  @override
  String get langEn => 'English';

  @override
  String get langVi => 'Tiếng Việt';

  @override
  String get langKm => 'ភាសាខ្មែរ';

  @override
  String get langKo => '한국어';

  @override
  String get langJa => '日本語';

  @override
  String get langTitle => '语言设置';

  @override
  String get loginTitle => '技师端登录';

  @override
  String get loginSubtitle => '欢迎回来，请登录您的账号';

  @override
  String get phone => '手机号';

  @override
  String get phoneHint => '请输入手机号';

  @override
  String get password => '密码';

  @override
  String get passwordHint => '请输入密码';

  @override
  String get loginBtn => '登录';

  @override
  String get forgotPassword => '忘记密码？';

  @override
  String get loginSuccess => '登录成功';

  @override
  String get loginFailed => '手机号或密码错误';

  @override
  String get phoneRequired => '请输入手机号';

  @override
  String get passwordRequired => '请输入密码';

  @override
  String get skillsTitle => '技能管理';

  @override
  String get reviewsTitle => '客户评价';

  @override
  String get noReviews => '暂无评价';

  @override
  String get avgRating => '平均评分';

  @override
  String totalReviews(int n) {
    return '$n 条评价';
  }

  @override
  String get loginTabPhone => '手机号登录';

  @override
  String get loginTabTechId => '技师编号登录';

  @override
  String get fieldTechId => '技师编号';

  @override
  String get techIdHint => '请输入您的技师编号';

  @override
  String get techIdRequired => '请输入技师编号';

  @override
  String get noAccount => '还没有账号？';

  @override
  String get goRegister => '立即注册';

  @override
  String get haveAccount => '已有账号？';

  @override
  String get goLogin => '去登录';

  @override
  String get registerTitle => '注册技师账号';

  @override
  String registerSubtitle(String merchant) {
    return '加入 $merchant，开始您的服务之旅';
  }

  @override
  String get fieldFullName => '姓名';

  @override
  String get fullNameHint => '请输入您的真实姓名';

  @override
  String get fullNameRequired => '请输入姓名';

  @override
  String get fieldEmail => '邮箱';

  @override
  String get emailHint => '请输入邮箱地址';

  @override
  String get fieldConfirmPassword => '确认密码';

  @override
  String get confirmPasswordHint => '请再次输入密码';

  @override
  String get passwordMismatch => '两次密码不一致';

  @override
  String get passwordTooShort => '密码至少 6 位';

  @override
  String get fieldTelegram => 'Telegram 账号';

  @override
  String get telegramHint => '@username（选填）';

  @override
  String get fieldFacebook => 'Facebook';

  @override
  String get facebookHint => '用户名或主页链接（选填）';

  @override
  String get fieldMerchantCode => '商户代码';

  @override
  String get merchantCodeHint => '请输入商户邀请码';

  @override
  String get merchantCodeRequired => '请输入商户代码';

  @override
  String get selectCountry => '选择国家/地区';

  @override
  String get registerBtn => '立即注册';

  @override
  String get registerSuccess => '注册成功！请等待商户审核';

  @override
  String get registerFailed => '注册失败，请重试';

  @override
  String get invalidPhone => '手机号格式不正确';

  @override
  String get invalidEmail => '邮箱格式不正确';

  @override
  String get optionalField => '选填';

  @override
  String get myMerchant => '所属商户';

  @override
  String get merchantVerified => '已认证';

  @override
  String get merchantPending => '审核中';

  @override
  String get forgotPasswordTitle => '找回密码';

  @override
  String get forgotPasswordDesc => '请输入注册手机号，我们将发送验证码';

  @override
  String get sendOtp => '发送验证码';

  @override
  String otpSent(String phone) {
    return '验证码已发送至 $phone';
  }

  @override
  String get comingSoon => '该功能即将上线，敬请期待';

  @override
  String get arrivalNotice => '技师已到达，请确认后开始服务';

  @override
  String get launchingApp => '正在跳转...';

  @override
  String get statusSwitchedTo => '状态已切换为';

  @override
  String get customerMessage => '客户消息';

  @override
  String get systemMessage => '系统消息';

  @override
  String get serviceCompleted => '服务完成';

  @override
  String get grabExpired => '抢单超时，订单已失效';

  @override
  String get newOrder => '新订单';

  @override
  String get newOrderGrab => '新订单抢单';

  @override
  String get distanceFrom => '距您';

  @override
  String get ignore => '忽略';

  @override
  String get grabOrder => '立即接单';

  @override
  String get announcements => '公告消息';

  @override
  String get helpAndSupport => '帮助与支持';

  @override
  String get rateApp => '评价应用';

  @override
  String get exitApp => '退出应用';

  @override
  String get exitAppConfirm => '确定退出应用程序？';

  @override
  String get todaySchedule => '今日安排';

  @override
  String get allOrders => '全部订单';

  @override
  String get orderStatusPending => '待确认';

  @override
  String get orderStatusAccepted => '已接单';

  @override
  String get orderStatusInProgress => '服务中';

  @override
  String get orderStatusCompleted => '已完成';

  @override
  String get orderStatusCancelled => '已取消';

  @override
  String get noScheduleToday => '今日暂无预约';

  @override
  String get keepOnlineHint => '保持在线，随时迎接新订单 ✨';

  @override
  String get myStats => '我的数据';

  @override
  String get totalOrders => '累计接单';

  @override
  String get overallRating => '综合评分';

  @override
  String get currentBalance => '当前余额';

  @override
  String get statTodayAppointments => '今日预约';

  @override
  String get statTodayCompleted => '今日完成';

  @override
  String get statTodayCancelled => '今日取消';

  @override
  String schedOrderCount(int n) {
    return '$n单';
  }

  @override
  String get schedInService => '进行中';

  @override
  String get schedPending => '待服务';

  @override
  String get totalDuration => '总时长';

  @override
  String scheduleProgress(int completed, int total) {
    return '$completed / $total 单完成';
  }

  @override
  String get statusOnWay => '前往中';

  @override
  String get statusCancelling => '取消中';

  @override
  String get statusRefunding => '退款中';

  @override
  String get statusRefunded => '已退款';

  @override
  String schedEndTime(String time, String duration) {
    return '结束 $time · ${duration}min';
  }

  @override
  String get serviceInProgress => '服务进行中';

  @override
  String estimatedIncome(String amount) {
    return '预计 $amount';
  }

  @override
  String get sessionExpiredTitle => '登出提醒';

  @override
  String get sessionExpiredMessage => '您已经登出，请重新登录后继续操作';

  @override
  String get goToLogin => '前往登录';

  @override
  String get networkTimeout => '网络超时，请检查网络连接';

  @override
  String get networkUnavailable => '网络不可用，请检查连接';

  @override
  String get networkError => '网络请求失败，请稍后重试';

  @override
  String get orderTypeOnline => '在线预约';

  @override
  String get orderTypeWalkin => '门店散客';

  @override
  String get walkinGuest => '散客';

  @override
  String get sessionNo => '接待单';

  @override
  String get walkinOrderTip => '门店订单由前台管理，技师按服务项操作即可。';

  @override
  String get notificationSound => '提示音';

  @override
  String get vibration => '震动';

  @override
  String get rating => '评分';

  @override
  String get myOrders => '我的订单';

  @override
  String get reviews => '我的评价';

  @override
  String get langHint => '选择您偏好的显示语言';
}
