// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'CamBook Partner';

  @override
  String get navHome => 'Home';

  @override
  String get navOrders => 'Orders';

  @override
  String get navMessages => 'Messages';

  @override
  String get navIncome => 'Income';

  @override
  String get navProfile => 'Me';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get save => 'Save';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get back => 'Back';

  @override
  String get loading => 'Loading…';

  @override
  String get noData => 'No data';

  @override
  String get noMore => 'No more orders';

  @override
  String get error => 'Failed';

  @override
  String get retry => 'Retry';

  @override
  String get close => 'Close';

  @override
  String get send => 'Send';

  @override
  String get call => 'Call';

  @override
  String get navigate => 'Navigate';

  @override
  String get copy => 'Copy';

  @override
  String get justNow => 'Just now';

  @override
  String minutesAgo(int n) {
    return '${n}m ago';
  }

  @override
  String hoursAgo(int n) {
    return '${n}h ago';
  }

  @override
  String daysAgo(int n) {
    return '${n}d ago';
  }

  @override
  String get success => 'Success';

  @override
  String get failed => 'Failed';

  @override
  String get submitting => 'Submitting…';

  @override
  String get statusOnline => 'Online';

  @override
  String get statusBusy => 'Busy';

  @override
  String get statusRest => 'Rest';

  @override
  String get statusOnlineDesc => 'Accepting orders';

  @override
  String get statusBusyDesc => 'In service';

  @override
  String get statusRestDesc => 'Resting';

  @override
  String get statusSwitchTitle => 'Switch Status';

  @override
  String get statusSwitchDesc => 'This will affect order acceptance';

  @override
  String get greetingMorning => 'Good morning';

  @override
  String get greetingAfternoon => 'Good afternoon';

  @override
  String get greetingEvening => 'Good evening';

  @override
  String get techNo => 'Tech ID';

  @override
  String get todayStats => 'Today\'s Stats';

  @override
  String get todayOrders => 'Orders';

  @override
  String get todayIncome => 'Income';

  @override
  String get todayRating => 'Rating';

  @override
  String get quickActions => 'Quick Actions';

  @override
  String get startAccepting => 'Accept Orders';

  @override
  String get appointments => 'Appointments';

  @override
  String get viewSchedule => 'My Schedule';

  @override
  String get recentOrders => 'Recent Orders';

  @override
  String get viewAll => 'View All';

  @override
  String get noOrdersToday => 'No orders today';

  @override
  String get newOrderTitle => 'New Order';

  @override
  String get newOrderDesc => 'New service request pending';

  @override
  String get acceptOrder => 'Accept';

  @override
  String get rejectOrder => 'Decline';

  @override
  String autoReject(int s) {
    return 'Auto-reject in ${s}s';
  }

  @override
  String get refreshed => 'Refreshed';

  @override
  String get ordersTitle => 'Orders';

  @override
  String get tabPending => 'Pending';

  @override
  String get tabAccepted => 'Accepted';

  @override
  String get statusReception => 'Welcoming';

  @override
  String get tabInService => 'In Service';

  @override
  String get tabCompleted => 'Completed';

  @override
  String get tabCancelled => 'Cancelled';

  @override
  String get orderNo => 'Order #';

  @override
  String get serviceType => 'Type';

  @override
  String get homeService => 'Home Service';

  @override
  String get storeService => 'In-store Service';

  @override
  String get amount => 'Amount';

  @override
  String get appointTime => 'Appt. Time';

  @override
  String get distance => 'Distance';

  @override
  String get remark => 'Note';

  @override
  String get btnAccept => 'Accept';

  @override
  String get btnReject => 'Decline';

  @override
  String get btnArrive => 'Arrived';

  @override
  String get btnStartService => 'Start';

  @override
  String get btnComplete => 'Complete';

  @override
  String get btnContact => 'Contact';

  @override
  String get btnDetail => 'Details';

  @override
  String get rejectReason => 'Reason';

  @override
  String get rejectReasonHint => 'Enter reason (optional)';

  @override
  String get acceptConfirm => 'Accept this order?';

  @override
  String get completeConfirm => 'Mark as complete?';

  @override
  String get rejectConfirm => 'Reject this order?';

  @override
  String get noOrders => 'No orders';

  @override
  String get duration => 'Duration';

  @override
  String get unitMin => 'min';

  @override
  String get orderDetailTitle => 'Order Detail';

  @override
  String get customerInfo => 'Customer';

  @override
  String get orderInfo => 'Order Info';

  @override
  String get serviceItems => 'Services';

  @override
  String get totalAmount => 'Total';

  @override
  String get orderTime => 'Order Time';

  @override
  String get serviceAddress => 'Address';

  @override
  String get customerNotes => 'Notes';

  @override
  String get serviceProgress => 'Progress';

  @override
  String get stepPending => 'Pending';

  @override
  String get stepAccepted => 'Accepted';

  @override
  String get stepArrived => 'Arrived';

  @override
  String get stepInService => 'In Service';

  @override
  String get stepCompleted => 'Completed';

  @override
  String get confirmArrival => 'Confirm Arrival';

  @override
  String get serviceActiveTitle => 'In Service';

  @override
  String get elapsed => 'Elapsed';

  @override
  String get remaining => 'Remaining';

  @override
  String get pause => 'Pause';

  @override
  String get resume => 'Resume';

  @override
  String get endService => 'End Service';

  @override
  String get endServiceConfirm => 'End service? Customer will be asked to review.';

  @override
  String get pauseConfirm => 'Pause service?';

  @override
  String get focusMode => 'Focus Mode';

  @override
  String get messagesTitle => 'Messages';

  @override
  String get systemNotice => 'System';

  @override
  String get noMessages => 'No messages';

  @override
  String get markAllRead => 'Mark all read';

  @override
  String get unread => 'unread';

  @override
  String get chatPlaceholder => 'Type a message…';

  @override
  String get quickReplies => 'Quick Reply';

  @override
  String get sendLocation => 'Location';

  @override
  String get noChatMessages => 'Start chatting';

  @override
  String get qr1 => 'On my way!';

  @override
  String get qr2 => 'Where are you?';

  @override
  String get qr3 => 'I have arrived';

  @override
  String get qr4 => 'Service started';

  @override
  String get qr5 => 'One moment please';

  @override
  String get qr6 => 'Thank you for your business';

  @override
  String get incomeTitle => 'Income';

  @override
  String get incomeOverview => 'Overview';

  @override
  String get periodToday => 'Today';

  @override
  String get periodWeek => 'Week';

  @override
  String get periodMonth => 'Month';

  @override
  String get periodTotal => 'Total';

  @override
  String get todayIncomeLabel => 'Today';

  @override
  String get weekIncomeLabel => 'This Week';

  @override
  String get monthIncomeLabel => 'This Month';

  @override
  String get totalIncomeLabel => 'Total';

  @override
  String get incomeTrend => 'Trend';

  @override
  String get incomeRecords => 'Transactions';

  @override
  String get noRecords => 'No records';

  @override
  String get incomeOrder => 'Order';

  @override
  String get incomeBonus => 'Bonus';

  @override
  String get incomeDeduction => 'Deduction';

  @override
  String get withdraw => 'Withdraw';

  @override
  String get availableBalance => 'Available';

  @override
  String get withdrawAmount => 'Amount';

  @override
  String get withdrawMethod => 'Method';

  @override
  String get bankCard => 'Bank Card';

  @override
  String get usdtLabel => 'USDT';

  @override
  String get withdrawMin => 'Min. withdrawal \$10';

  @override
  String get withdrawConfirm => 'Confirm';

  @override
  String get withdrawSuccess => 'Submitted, ETA 1-3 business days';

  @override
  String get inputAmount => 'Enter amount';

  @override
  String get profileTitle => 'Me';

  @override
  String get levelNormal => 'Standard';

  @override
  String get levelSenior => 'Senior';

  @override
  String get levelGold => 'Gold';

  @override
  String get levelTop => 'Top';

  @override
  String get completedOrders => 'Completed';

  @override
  String get skillsMenu => 'Skills';

  @override
  String get reviewsMenu => 'Reviews';

  @override
  String get scheduleMenu => 'Schedule';

  @override
  String get settingsMenu => 'Settings';

  @override
  String get helpMenu => 'Help';

  @override
  String get aboutMenu => 'About';

  @override
  String get logout => 'Logout';

  @override
  String get logoutConfirm => 'Confirm logout?';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get memberSince => 'Member Since';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get accountSection => 'Account';

  @override
  String get changePassword => 'Change Password';

  @override
  String get notifySection => 'Notifications';

  @override
  String get orderNotify => 'Order Alerts';

  @override
  String get messageNotify => 'Message Alerts';

  @override
  String get systemNotify => 'System Alerts';

  @override
  String get langSection => 'Language';

  @override
  String get currentLanguage => 'Language';

  @override
  String get aboutSection => 'About';

  @override
  String get version => 'Version';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get terms => 'Terms';

  @override
  String get savedSuccess => 'Saved';

  @override
  String get scheduleTitle => 'Schedule';

  @override
  String get calendarTab => 'Calendar';

  @override
  String get appointmentsTab => 'Appointments';

  @override
  String get setAvailable => 'Set Available';

  @override
  String get setUnavailable => 'Set Rest';

  @override
  String get workHours => 'Work Hours';

  @override
  String get addTimeSlot => 'Add Slot';

  @override
  String get noAppointments => 'No appointments';

  @override
  String get upcoming => 'Upcoming';

  @override
  String get confirmScheduleChange => 'Confirm schedule change?';

  @override
  String get weekdayMon => 'Mo';

  @override
  String get weekdayTue => 'Tu';

  @override
  String get weekdayWed => 'We';

  @override
  String get weekdayThu => 'Th';

  @override
  String get weekdayFri => 'Fr';

  @override
  String get weekdaySat => 'Sa';

  @override
  String get weekdaySun => 'Su';

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
  String get langTitle => 'Language';

  @override
  String get loginTitle => 'Partner Login';

  @override
  String get loginSubtitle => 'Welcome back';

  @override
  String get phone => 'Phone';

  @override
  String get phoneHint => 'Enter phone number';

  @override
  String get password => 'Password';

  @override
  String get passwordHint => 'Enter password';

  @override
  String get loginBtn => 'Sign In';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get loginSuccess => 'Welcome back!';

  @override
  String get loginFailed => 'Invalid credentials';

  @override
  String get phoneRequired => 'Phone required';

  @override
  String get passwordRequired => 'Password required';

  @override
  String get skillsTitle => 'Skills';

  @override
  String get reviewsTitle => 'Reviews';

  @override
  String get noReviews => 'No reviews yet';

  @override
  String get avgRating => 'Avg. Rating';

  @override
  String totalReviews(int n) {
    return '$n reviews';
  }

  @override
  String get loginTabPhone => 'Phone Login';

  @override
  String get loginTabTechId => 'Tech ID Login';

  @override
  String get fieldTechId => 'Technician ID';

  @override
  String get techIdHint => 'Enter your technician ID';

  @override
  String get techIdRequired => 'Technician ID required';

  @override
  String get noAccount => 'No account yet?';

  @override
  String get goRegister => 'Register Now';

  @override
  String get haveAccount => 'Already have account?';

  @override
  String get goLogin => 'Go Login';

  @override
  String get registerTitle => 'Create Tech Account';

  @override
  String registerSubtitle(String merchant) {
    return 'Join $merchant and start serving';
  }

  @override
  String get fieldFullName => 'Full Name';

  @override
  String get fullNameHint => 'Enter your full name';

  @override
  String get fullNameRequired => 'Name is required';

  @override
  String get fieldEmail => 'Email';

  @override
  String get emailHint => 'Enter email address';

  @override
  String get fieldConfirmPassword => 'Confirm Password';

  @override
  String get confirmPasswordHint => 'Re-enter your password';

  @override
  String get passwordMismatch => 'Passwords do not match';

  @override
  String get passwordTooShort => 'Password must be at least 6 characters';

  @override
  String get fieldTelegram => 'Telegram';

  @override
  String get telegramHint => '@username (optional)';

  @override
  String get fieldFacebook => 'Facebook';

  @override
  String get facebookHint => 'Username or page URL (optional)';

  @override
  String get fieldMerchantCode => 'Merchant Code';

  @override
  String get merchantCodeHint => 'Enter merchant invite code';

  @override
  String get merchantCodeRequired => 'Merchant code is required';

  @override
  String get selectCountry => 'Select Country';

  @override
  String get registerBtn => 'Register Now';

  @override
  String get registerSuccess => 'Registered! Awaiting merchant approval';

  @override
  String get registerFailed => 'Registration failed, please retry';

  @override
  String get invalidPhone => 'Invalid phone number';

  @override
  String get invalidEmail => 'Invalid email address';

  @override
  String get optionalField => 'Optional';

  @override
  String get myMerchant => 'My Merchant';

  @override
  String get merchantVerified => 'Verified';

  @override
  String get merchantPending => 'Pending Approval';

  @override
  String get forgotPasswordTitle => 'Forgot Password';

  @override
  String get forgotPasswordDesc => 'Enter your registered phone to receive OTP';

  @override
  String get sendOtp => 'Send OTP';

  @override
  String otpSent(String phone) {
    return 'OTP sent to $phone';
  }

  @override
  String get comingSoon => 'Coming Soon';

  @override
  String get arrivalNotice => 'Technician has arrived, please confirm to start service';

  @override
  String get launchingApp => 'Opening app...';

  @override
  String get statusSwitchedTo => 'Status switched to';

  @override
  String get customerMessage => 'Customer Message';

  @override
  String get systemMessage => 'System Message';

  @override
  String get serviceCompleted => 'Service completed';

  @override
  String get grabExpired => 'Grab order timed out, order has expired';

  @override
  String get newOrder => 'New Order';

  @override
  String get newOrderGrab => 'New Order — Grab Now';

  @override
  String get distanceFrom => 'Distance:';

  @override
  String get ignore => 'Ignore';

  @override
  String get grabOrder => 'Accept Now';

  @override
  String get announcements => 'Announcements';

  @override
  String get helpAndSupport => 'Help & Support';

  @override
  String get rateApp => 'Rate App';

  @override
  String get exitApp => 'Exit App';

  @override
  String get exitAppConfirm => 'Exit the application?';

  @override
  String get todaySchedule => 'Today\'s Schedule';

  @override
  String get allOrders => 'All Orders';

  @override
  String get orderStatusPending => 'Pending';

  @override
  String get orderStatusAccepted => 'Accepted';

  @override
  String get orderStatusInProgress => 'In Service';

  @override
  String get orderStatusCompleted => 'Completed';

  @override
  String get orderStatusCancelled => 'Cancelled';

  @override
  String get noScheduleToday => 'No appointments today';

  @override
  String get keepOnlineHint => 'Stay online to receive new orders ✨';

  @override
  String get myStats => 'My Stats';

  @override
  String get totalOrders => 'Total Orders';

  @override
  String get overallRating => 'Overall Rating';

  @override
  String get currentBalance => 'Current Balance';

  @override
  String get statTodayAppointments => 'Today\'s Appts';

  @override
  String get statTodayCompleted => 'Completed';

  @override
  String get statTodayCancelled => 'Cancelled';

  @override
  String schedOrderCount(int n) {
    return '$n Orders';
  }

  @override
  String get schedInService => 'In Service';

  @override
  String get schedPending => 'Pending';

  @override
  String get totalDuration => 'Total Time';

  @override
  String scheduleProgress(int completed, int total) {
    return '$completed / $total done';
  }

  @override
  String get statusOnWay => 'On Way';

  @override
  String get statusCancelling => 'Cancelling';

  @override
  String get statusRefunding => 'Refunding';

  @override
  String get statusRefunded => 'Refunded';

  @override
  String schedEndTime(String time, String duration) {
    return 'End $time · ${duration}min';
  }

  @override
  String get serviceInProgress => 'In Service';

  @override
  String estimatedIncome(String amount) {
    return 'Est. $amount';
  }

  @override
  String get sessionExpiredTitle => 'Session Expired';

  @override
  String get sessionExpiredMessage => 'You have been logged out. Please sign in again to continue.';

  @override
  String get goToLogin => 'Go to Login';

  @override
  String get networkTimeout => 'Request timed out. Please check your connection.';

  @override
  String get networkUnavailable => 'Network unavailable. Please check your connection.';

  @override
  String get networkError => 'Request failed. Please try again later.';

  @override
  String get orderTypeOnline => 'Online Appt.';

  @override
  String get orderTypeWalkin => 'Walk-in';

  @override
  String get walkinGuest => 'Walk-in Guest';

  @override
  String get sessionNo => 'Session';

  @override
  String get walkinOrderTip => 'Walk-in order is managed at the front desk.';

  @override
  String get notificationSound => 'Notification Sound';

  @override
  String get vibration => 'Vibration';

  @override
  String get rating => 'Rating';

  @override
  String get myOrders => 'My Orders';

  @override
  String get reviews => 'Reviews';

  @override
  String get langHint => 'Select your preferred display language';
}
