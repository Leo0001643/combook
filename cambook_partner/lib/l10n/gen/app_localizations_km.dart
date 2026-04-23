// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Khmer Central Khmer (`km`).
class AppLocalizationsKm extends AppLocalizations {
  AppLocalizationsKm([String locale = 'km']) : super(locale);

  @override
  String get appName => 'CamBook Partner';

  @override
  String get navHome => 'ទំព័រដើម';

  @override
  String get navOrders => 'បញ្ជាទិញ';

  @override
  String get navMessages => 'សារ';

  @override
  String get navIncome => 'ចំណូល';

  @override
  String get navProfile => 'ខ្ញុំ';

  @override
  String get ok => 'យល់ព្រម';

  @override
  String get cancel => 'បោះបង់';

  @override
  String get confirm => 'បញ្ជាក់';

  @override
  String get save => 'រក្សាទុក';

  @override
  String get edit => 'កែប្រែ';

  @override
  String get delete => 'លុប';

  @override
  String get back => 'ត្រឡប់';

  @override
  String get loading => 'កំពុងផ្ទុក…';

  @override
  String get noData => 'គ្មានទិន្នន័យ';

  @override
  String get noMore => 'គ្មានការបញ្ជាទៀតទេ';

  @override
  String get error => 'ផ្ទុកបរាជ័យ';

  @override
  String get retry => 'ព្យាយាមម្តងទៀត';

  @override
  String get close => 'បិទ';

  @override
  String get send => 'ផ្ញើ';

  @override
  String get call => 'ហៅទូរស័ព្ទ';

  @override
  String get navigate => 'រុករក';

  @override
  String get copy => 'ចម្លង';

  @override
  String get justNow => 'ថ្មីៗ';

  @override
  String minutesAgo(int n) {
    return '$n នាទីមុន';
  }

  @override
  String hoursAgo(int n) {
    return '$n ម៉ោងមុន';
  }

  @override
  String daysAgo(int n) {
    return '$n ថ្ងៃមុន';
  }

  @override
  String get success => 'ជោគជ័យ';

  @override
  String get failed => 'បរាជ័យ';

  @override
  String get submitting => 'កំពុងដាក់ស្នើ…';

  @override
  String get statusOnline => 'អនឡាញ';

  @override
  String get statusBusy => 'រវល់';

  @override
  String get statusRest => 'សម្រាក';

  @override
  String get statusOnlineDesc => 'ទទួលការបញ្ជាទិញ';

  @override
  String get statusBusyDesc => 'កំពុងបម្រើ';

  @override
  String get statusRestDesc => 'សម្រាក';

  @override
  String get statusSwitchTitle => 'ប្តូរស្ថានភាព';

  @override
  String get statusSwitchDesc => 'នឹងប៉ះពាល់ដល់ការទទួលការបញ្ជា';

  @override
  String get greetingMorning => 'អរុណសួស្តី';

  @override
  String get greetingAfternoon => 'រាប្រសើរ';

  @override
  String get greetingEvening => 'សាយណ្ហសួស្តី';

  @override
  String get techNo => 'លេខបច្ចេកទេស';

  @override
  String get todayStats => 'ស្ថិតិថ្ងៃនេះ';

  @override
  String get todayOrders => 'ការបញ្ជា';

  @override
  String get todayIncome => 'ចំណូល';

  @override
  String get todayRating => 'ការវាយតម្លៃ';

  @override
  String get quickActions => 'សកម្មភាពរហ័ស';

  @override
  String get startAccepting => 'ចាប់ផ្តើមទទួលការបញ្ជា';

  @override
  String get appointments => 'ការណាត់ជួប';

  @override
  String get viewSchedule => 'ម៉ោងធ្វើការ';

  @override
  String get recentOrders => 'ការបញ្ជាថ្មីៗ';

  @override
  String get viewAll => 'មើលទាំងអស់';

  @override
  String get noOrdersToday => 'គ្មានការបញ្ជាថ្ងៃនេះ';

  @override
  String get newOrderTitle => 'ការបញ្ជាថ្មី';

  @override
  String get newOrderDesc => 'មានសំណើសេវាថ្មី';

  @override
  String get acceptOrder => 'ទទួល';

  @override
  String get rejectOrder => 'បដិសេធ';

  @override
  String autoReject(int s) {
    return 'បដិសេធដោយស្វ័យប្រវត្តិក្នុង $s វិ.';
  }

  @override
  String get refreshed => 'បានធ្វើឱ្យស្រស់';

  @override
  String get ordersTitle => 'ការគ្រប់គ្រងការបញ្ជា';

  @override
  String get tabPending => 'រង់ចាំ';

  @override
  String get tabAccepted => 'ទទួលហើយ';

  @override
  String get tabInService => 'កំពុងបម្រើ';

  @override
  String get tabCompleted => 'បញ្ចប់';

  @override
  String get tabCancelled => 'បោះបង់';

  @override
  String get orderNo => 'លេខការបញ្ជា';

  @override
  String get serviceType => 'ប្រភេទសេវា';

  @override
  String get homeService => 'សេវាផ្ទះ';

  @override
  String get storeService => 'សេវាហាង';

  @override
  String get amount => 'ចំនួនទឹកប្រាក់';

  @override
  String get appointTime => 'ពេលណាត់';

  @override
  String get distance => 'ចម្ងាយ';

  @override
  String get remark => 'កំណត់ចំណាំ';

  @override
  String get btnAccept => 'ទទួល';

  @override
  String get btnReject => 'បដិសេធ';

  @override
  String get btnArrive => 'បានមកដល់';

  @override
  String get btnStartService => 'ចាប់ផ្តើម';

  @override
  String get btnComplete => 'បញ្ចប់';

  @override
  String get btnContact => 'ទំនាក់ទំនង';

  @override
  String get btnDetail => 'ព័ត៌មានលម្អិត';

  @override
  String get rejectReason => 'ហេតុផល';

  @override
  String get rejectReasonHint => 'បញ្ចូលហេតុផល (ស្រេចចិត្ត)';

  @override
  String get acceptConfirm => 'ទទួលការបញ្ជានេះ?';

  @override
  String get completeConfirm => 'បញ្ចប់សេវា?';

  @override
  String get rejectConfirm => 'បដិសេធការបញ្ជានេះ?';

  @override
  String get noOrders => 'គ្មានការបញ្ជា';

  @override
  String get duration => 'រយៈពេល';

  @override
  String get unitMin => 'នាទី';

  @override
  String get orderDetailTitle => 'ព័ត៌មានលម្អិត';

  @override
  String get customerInfo => 'អតិថិជន';

  @override
  String get orderInfo => 'ព័ត៌មានការបញ្ជា';

  @override
  String get serviceItems => 'សេវា';

  @override
  String get totalAmount => 'សរុប';

  @override
  String get orderTime => 'ពេលបញ្ជា';

  @override
  String get serviceAddress => 'អាសយដ្ឋាន';

  @override
  String get customerNotes => 'កំណត់ចំណាំ';

  @override
  String get serviceProgress => 'វឌ្ឍនភាព';

  @override
  String get stepPending => 'រង់ចាំ';

  @override
  String get stepAccepted => 'ទទួលហើយ';

  @override
  String get stepArrived => 'មកដល់';

  @override
  String get stepInService => 'កំពុងបម្រើ';

  @override
  String get stepCompleted => 'បញ្ចប់';

  @override
  String get confirmArrival => 'បញ្ជាក់ការមកដល់';

  @override
  String get serviceActiveTitle => 'កំពុងបម្រើ';

  @override
  String get elapsed => 'បានកន្លង';

  @override
  String get remaining => 'នៅសល់';

  @override
  String get pause => 'ផ្អាក';

  @override
  String get resume => 'បន្ត';

  @override
  String get endService => 'បញ្ចប់សេវា';

  @override
  String get endServiceConfirm => 'បញ្ចប់សេវា?';

  @override
  String get pauseConfirm => 'ផ្អាកសេវា?';

  @override
  String get focusMode => 'របៀបផ្តោត';

  @override
  String get messagesTitle => 'សារ';

  @override
  String get systemNotice => 'ប្រព័ន្ធ';

  @override
  String get noMessages => 'គ្មានសារ';

  @override
  String get markAllRead => 'សម្គាល់ថាបានអាន';

  @override
  String get unread => 'មិនទាន់អាន';

  @override
  String get chatPlaceholder => 'វាយសារ…';

  @override
  String get quickReplies => 'ឆ្លើយរហ័ស';

  @override
  String get sendLocation => 'ទីតាំង';

  @override
  String get noChatMessages => 'ចាប់ផ្តើមជជែក';

  @override
  String get qr1 => 'ខ្ញុំកំពុងមក';

  @override
  String get qr2 => 'អ្នកនៅទីណា?';

  @override
  String get qr3 => 'ខ្ញុំបានមកដល់';

  @override
  String get qr4 => 'សេវាបានចាប់ផ្តើម';

  @override
  String get qr5 => 'សូមមួយភ្លែត';

  @override
  String get qr6 => 'អរគុណចំពោះការប្រើប្រាស់';

  @override
  String get incomeTitle => 'ចំណូល';

  @override
  String get incomeOverview => 'ទិដ្ឋភាពទូទៅ';

  @override
  String get periodToday => 'ថ្ងៃនេះ';

  @override
  String get periodWeek => 'សប្តាហ៍';

  @override
  String get periodMonth => 'ខែ';

  @override
  String get periodTotal => 'សរុប';

  @override
  String get todayIncomeLabel => 'ថ្ងៃនេះ';

  @override
  String get weekIncomeLabel => 'សប្តាហ៍នេះ';

  @override
  String get monthIncomeLabel => 'ខែនេះ';

  @override
  String get totalIncomeLabel => 'ចំណូលសរុប';

  @override
  String get incomeTrend => 'និន្នាការ';

  @override
  String get incomeRecords => 'កំណត់ត្រា';

  @override
  String get noRecords => 'គ្មានកំណត់ត្រា';

  @override
  String get incomeOrder => 'ការបញ្ជា';

  @override
  String get incomeBonus => 'រង្វាន់';

  @override
  String get incomeDeduction => 'កាត់ចេញ';

  @override
  String get withdraw => 'ដក';

  @override
  String get availableBalance => 'សមតុល្យ';

  @override
  String get withdrawAmount => 'ចំនួន';

  @override
  String get withdrawMethod => 'វិធីសាស្ត្រ';

  @override
  String get bankCard => 'កាតធនាគារ';

  @override
  String get usdtLabel => 'USDT';

  @override
  String get withdrawMin => 'ដករយ: \$10';

  @override
  String get withdrawConfirm => 'បញ្ជាក់';

  @override
  String get withdrawSuccess => 'ស្នើសុំដកបានដាក់ស្នើ';

  @override
  String get inputAmount => 'បញ្ចូលចំនួន';

  @override
  String get profileTitle => 'ខ្ញុំ';

  @override
  String get levelNormal => 'ស្តង់ដារ';

  @override
  String get levelSenior => 'ជាន់ខ្ពស់';

  @override
  String get levelGold => 'មាស';

  @override
  String get levelTop => 'កំពូល';

  @override
  String get completedOrders => 'បានបញ្ចប់';

  @override
  String get skillsMenu => 'ជំនាញ';

  @override
  String get reviewsMenu => 'ការវាយតម្លៃ';

  @override
  String get scheduleMenu => 'កាលវិភាគ';

  @override
  String get settingsMenu => 'ការកំណត់';

  @override
  String get helpMenu => 'ជំនួយ';

  @override
  String get aboutMenu => 'អំពីយើង';

  @override
  String get logout => 'ចេញ';

  @override
  String get logoutConfirm => 'បញ្ជាក់ការចេញ?';

  @override
  String get editProfile => 'កែប្រែ';

  @override
  String get memberSince => 'ថ្ងៃចូលជា';

  @override
  String get settingsTitle => 'ការកំណត់';

  @override
  String get accountSection => 'គណនី';

  @override
  String get changePassword => 'ប្តូរពាក្យសម្ងាត់';

  @override
  String get notifySection => 'ការជូនដំណឹង';

  @override
  String get orderNotify => 'ការបញ្ជា';

  @override
  String get messageNotify => 'សារ';

  @override
  String get systemNotify => 'ប្រព័ន្ធ';

  @override
  String get langSection => 'ភាសា';

  @override
  String get currentLanguage => 'ភាសា';

  @override
  String get aboutSection => 'អំពី';

  @override
  String get version => 'កំណែ';

  @override
  String get privacyPolicy => 'គោលការណ៍';

  @override
  String get terms => 'លក្ខខណ្ឌ';

  @override
  String get savedSuccess => 'រក្សាទុកហើយ';

  @override
  String get scheduleTitle => 'កាលវិភាគ';

  @override
  String get calendarTab => 'ប្រតិទិន';

  @override
  String get appointmentsTab => 'ការណាត់ជួប';

  @override
  String get setAvailable => 'កំណត់ថាទំនេរ';

  @override
  String get setUnavailable => 'កំណត់ថាសម្រាក';

  @override
  String get workHours => 'ម៉ោងធ្វើការ';

  @override
  String get addTimeSlot => 'បន្ថែមពេលវេលា';

  @override
  String get noAppointments => 'គ្មានការណាត់ជួប';

  @override
  String get upcoming => 'ខាងមុខ';

  @override
  String get confirmScheduleChange => 'បញ្ជាក់ការផ្លាស់ប្តូរ?';

  @override
  String get weekdayMon => 'ច';

  @override
  String get weekdayTue => 'អ';

  @override
  String get weekdayWed => 'ព';

  @override
  String get weekdayThu => 'ព្';

  @override
  String get weekdayFri => 'សុ';

  @override
  String get weekdaySat => 'ស';

  @override
  String get weekdaySun => 'អា';

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
  String get langTitle => 'ភាសា';

  @override
  String get loginTitle => 'ចូលប្រព័ន្ធ';

  @override
  String get loginSubtitle => 'សូមស្វាគមន៍';

  @override
  String get phone => 'ទូរស័ព្ទ';

  @override
  String get phoneHint => 'បញ្ចូលលេខទូរស័ព្ទ';

  @override
  String get password => 'ពាក្យសម្ងាត់';

  @override
  String get passwordHint => 'បញ្ចូលពាក្យសម្ងាត់';

  @override
  String get loginBtn => 'ចូល';

  @override
  String get forgotPassword => 'ភ្លេចពាក្យសម្ងាត់?';

  @override
  String get loginSuccess => 'ចូលបានជោគជ័យ';

  @override
  String get loginFailed => 'ព័ត៌មានមិនត្រឹមត្រូវ';

  @override
  String get phoneRequired => 'ត្រូវការទូរស័ព្ទ';

  @override
  String get passwordRequired => 'ត្រូវការពាក្យសម្ងាត់';

  @override
  String get skillsTitle => 'ជំនាញ';

  @override
  String get reviewsTitle => 'ការវាយតម្លៃ';

  @override
  String get noReviews => 'មិនទាន់មានការវាយតម្លៃ';

  @override
  String get avgRating => 'មធ្យម';

  @override
  String totalReviews(int n) {
    return '$n ការវាយតម្លៃ';
  }

  @override
  String get loginTabPhone => 'ចូលដោយលេខទូរស័ព្ទ';

  @override
  String get loginTabTechId => 'ចូលដោយលេខខ';

  @override
  String get fieldTechId => 'លេខខ';

  @override
  String get techIdHint => 'បញ្ចូលលេខខ';

  @override
  String get techIdRequired => 'សូមបញ្ចូលលេខខ';

  @override
  String get noAccount => 'មិនទាន់មានគណនី?';

  @override
  String get goRegister => 'ចុះឈ្មោះឥឡូវ';

  @override
  String get haveAccount => 'មានគណនីរួចហើយ?';

  @override
  String get goLogin => 'ចូល';

  @override
  String get registerTitle => 'បង្កើតគណនីជាង';

  @override
  String registerSubtitle(String merchant) {
    return 'ចូលរួម $merchant ដើម្បីចាប់ផ្ដើម';
  }

  @override
  String get fieldFullName => 'ឈ្មោះពេញ';

  @override
  String get fullNameHint => 'បញ្ចូលឈ្មោះពេញ';

  @override
  String get fullNameRequired => 'សូមបញ្ចូលឈ្មោះ';

  @override
  String get fieldEmail => 'អ៊ីម៉ែល';

  @override
  String get emailHint => 'បញ្ចូលអ៊ីម៉ែល';

  @override
  String get fieldConfirmPassword => 'បញ្ជាក់ពាក្យសម្ងាត់';

  @override
  String get confirmPasswordHint => 'បញ្ចូលពាក្យសម្ងាត់ម្ដងទៀត';

  @override
  String get passwordMismatch => 'ពាក្យសម្ងាត់មិនត្រូវគ្នា';

  @override
  String get passwordTooShort => 'ពាក្យសម្ងាត់យ៉ាងតិច 6 តួ';

  @override
  String get fieldTelegram => 'Telegram';

  @override
  String get telegramHint => '@username (ស្រេចចិត្ត)';

  @override
  String get fieldFacebook => 'Facebook';

  @override
  String get facebookHint => 'ឈ្មោះអ្នកប្រើ ឬ URL (ស្រេចចិត្ត)';

  @override
  String get fieldMerchantCode => 'លេខកូដអ្នកជំនួញ';

  @override
  String get merchantCodeHint => 'បញ្ចូលលេខកូដអញ្ជើញ';

  @override
  String get merchantCodeRequired => 'សូមបញ្ចូលលេខកូដអ្នកជំនួញ';

  @override
  String get selectCountry => 'ជ្រើសប្រទេស';

  @override
  String get registerBtn => 'ចុះឈ្មោះឥឡូវ';

  @override
  String get registerSuccess => 'ចុះឈ្មោះបានជោគជ័យ! កំពុងរង់ចាំការអនុម័ត';

  @override
  String get registerFailed => 'ការចុះឈ្មោះបរាជ័យ សូមព្យាយាមម្ដងទៀត';

  @override
  String get invalidPhone => 'លេខទូរស័ព្ទមិនត្រឹមត្រូវ';

  @override
  String get invalidEmail => 'អ៊ីម៉ែលមិនត្រឹមត្រូវ';

  @override
  String get optionalField => 'ស្រេចចិត្ត';

  @override
  String get myMerchant => 'អ្នកជំនួញរបស់ខ្ញុំ';

  @override
  String get merchantVerified => 'បានផ្ទៀងផ្ទាត់';

  @override
  String get merchantPending => 'កំពុងរង់ចាំ';

  @override
  String get forgotPasswordTitle => 'ភ្លេចពាក្យសម្ងាត់';

  @override
  String get forgotPasswordDesc => 'បញ្ចូលលេខទូរស័ព្ទដើម្បីទទួល OTP';

  @override
  String get sendOtp => 'ផ្ញើ OTP';

  @override
  String otpSent(String phone) {
    return 'OTP បានផ្ញើទៅ $phone';
  }

  @override
  String get comingSoon => 'មកដល់ឆាប់ៗ';

  @override
  String get arrivalNotice => 'ช่างបានមកដល់ហើយ សូមបញ្ជាក់ដើម្បីចាប់ផ្ដើម';

  @override
  String get launchingApp => 'កំពុងបើក...';

  @override
  String get statusSwitchedTo => 'ស្ថានភាពបានផ្លាស់ប្តូរទៅ';

  @override
  String get customerMessage => 'សារអតិថិជន';

  @override
  String get systemMessage => 'សារប្រព័ន្ធ';

  @override
  String get serviceCompleted => 'សេវាកម្មបានបញ្ចប់';

  @override
  String get grabExpired => 'ផុតពេលទទួលការងារ';

  @override
  String get newOrder => 'ការបញ្ជាទិញថ្មី';

  @override
  String get newOrderGrab => 'ការបញ្ជាទិញថ្មី — ទទួលឥឡូវ';

  @override
  String get distanceFrom => 'ចម្ងាយ:';

  @override
  String get ignore => 'មិនអើពើ';

  @override
  String get grabOrder => 'ទទួលឥឡូវ';

  @override
  String get announcements => 'សេចក្ដីជូនដំណឹង';

  @override
  String get helpAndSupport => 'ជំនួយ និង ការគាំទ្រ';

  @override
  String get rateApp => 'វាយតម្លៃ App';

  @override
  String get exitApp => 'ចេញពី App';

  @override
  String get exitAppConfirm => 'ចង់ចេញពីកម្មវិធីមែនទេ?';

  @override
  String get todaySchedule => 'កម្មវិធីថ្ងៃនេះ';

  @override
  String get allOrders => 'ការបញ្ជាទិញទាំងអស់';

  @override
  String get orderStatusPending => 'រង់ចាំ';

  @override
  String get orderStatusAccepted => 'បានទទួល';

  @override
  String get orderStatusInProgress => 'កំពុងបម្រើ';

  @override
  String get orderStatusCompleted => 'បានបញ្ចប់';

  @override
  String get orderStatusCancelled => 'បានបោះបង់';

  @override
  String get noScheduleToday => 'គ្មានការណាត់ថ្ងៃនេះ';

  @override
  String get keepOnlineHint => 'បន្តអនឡាញ ដើម្បីទទួលការបញ្ជាទិញថ្មី ✨';

  @override
  String get myStats => 'ទិន្នន័យរបស់ខ្ញុំ';

  @override
  String get totalOrders => 'ការបញ្ជាទិញសរុប';

  @override
  String get overallRating => 'ការវាយតម្លៃទូទៅ';

  @override
  String get currentBalance => 'សមតុល្យបច្ចុប្បន្ន';

  @override
  String get statTodayAppointments => 'ការណាត់ថ្ងៃនេះ';

  @override
  String get statTodayCompleted => 'បានបញ្ចប់ថ្ងៃនេះ';

  @override
  String get statTodayCancelled => 'បានលុបថ្ងៃនេះ';

  @override
  String schedOrderCount(int n) {
    return '$n ការបញ្ជាទិញ';
  }

  @override
  String get schedInService => 'កំពុងបម្រើ';

  @override
  String get schedPending => 'រង់ចាំ';

  @override
  String get totalDuration => 'រយៈពេលសរុប';

  @override
  String scheduleProgress(int completed, int total) {
    return '$completed / $total បានបញ្ចប់';
  }

  @override
  String get statusOnWay => 'កំពុងទៅ';

  @override
  String get statusCancelling => 'កំពុងលុប';

  @override
  String get statusRefunding => 'កំពុងសងប្រាក់';

  @override
  String get statusRefunded => 'បានសងប្រាក់';

  @override
  String schedEndTime(String time, String duration) {
    return 'ចប់ $time · $durationនាទី';
  }

  @override
  String get serviceInProgress => 'កំពុងបម្រើ';

  @override
  String estimatedIncome(String amount) {
    return 'ប្រហាក់ $amount';
  }
}
