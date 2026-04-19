// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appName => 'CamBook 파트너';

  @override
  String get navHome => '홈';

  @override
  String get navOrders => '주문';

  @override
  String get navMessages => '메시지';

  @override
  String get navIncome => '수입';

  @override
  String get navProfile => '내 정보';

  @override
  String get ok => '확인';

  @override
  String get cancel => '취소';

  @override
  String get confirm => '확인';

  @override
  String get save => '저장';

  @override
  String get edit => '편집';

  @override
  String get delete => '삭제';

  @override
  String get back => '뒤로';

  @override
  String get loading => '로딩 중…';

  @override
  String get noData => '데이터 없음';

  @override
  String get noMore => '더 이상 주문 없음';

  @override
  String get error => '로드 실패';

  @override
  String get retry => '재시도';

  @override
  String get close => '닫기';

  @override
  String get send => '보내기';

  @override
  String get call => '전화';

  @override
  String get navigate => '길 안내';

  @override
  String get copy => '복사';

  @override
  String get justNow => '방금';

  @override
  String minutesAgo(int n) {
    return '$n분 전';
  }

  @override
  String hoursAgo(int n) {
    return '$n시간 전';
  }

  @override
  String daysAgo(int n) {
    return '$n일 전';
  }

  @override
  String get success => '성공';

  @override
  String get failed => '실패';

  @override
  String get submitting => '제출 중…';

  @override
  String get statusOnline => '온라인';

  @override
  String get statusBusy => '바쁨';

  @override
  String get statusRest => '휴식';

  @override
  String get statusOnlineDesc => '주문 수락 중';

  @override
  String get statusBusyDesc => '서비스 중';

  @override
  String get statusRestDesc => '휴식 중';

  @override
  String get statusSwitchTitle => '상태 변경';

  @override
  String get statusSwitchDesc => '주문 수락에 영향을 미칩니다';

  @override
  String get greetingMorning => '좋은 아침이에요';

  @override
  String get greetingAfternoon => '좋은 오후에요';

  @override
  String get greetingEvening => '좋은 저녁이에요';

  @override
  String get techNo => '기사 번호';

  @override
  String get todayStats => '오늘 통계';

  @override
  String get todayOrders => '주문 수';

  @override
  String get todayIncome => '수입';

  @override
  String get todayRating => '평점';

  @override
  String get quickActions => '빠른 작업';

  @override
  String get startAccepting => '주문 받기';

  @override
  String get appointments => '예약 관리';

  @override
  String get viewSchedule => '스케줄 보기';

  @override
  String get recentOrders => '최근 주문';

  @override
  String get viewAll => '전체 보기';

  @override
  String get noOrdersToday => '오늘 주문 없음';

  @override
  String get newOrderTitle => '새 주문';

  @override
  String get newOrderDesc => '새 서비스 요청';

  @override
  String get acceptOrder => '수락';

  @override
  String get rejectOrder => '거절';

  @override
  String autoReject(int s) {
    return '$s초 후 자동 거절';
  }

  @override
  String get refreshed => '새로고침 완료';

  @override
  String get ordersTitle => '주문 관리';

  @override
  String get tabPending => '대기 중';

  @override
  String get tabAccepted => '수락됨';

  @override
  String get tabInService => '서비스 중';

  @override
  String get tabCompleted => '완료';

  @override
  String get tabCancelled => '취소됨';

  @override
  String get orderNo => '주문 번호';

  @override
  String get serviceType => '서비스 유형';

  @override
  String get homeService => '방문 서비스';

  @override
  String get storeService => '매장 서비스';

  @override
  String get amount => '금액';

  @override
  String get appointTime => '예약 시간';

  @override
  String get distance => '거리';

  @override
  String get remark => '메모';

  @override
  String get btnAccept => '수락';

  @override
  String get btnReject => '거절';

  @override
  String get btnArrive => '도착';

  @override
  String get btnStartService => '서비스 시작';

  @override
  String get btnComplete => '완료';

  @override
  String get btnContact => '고객 연락';

  @override
  String get btnDetail => '상세 보기';

  @override
  String get rejectReason => '거절 사유';

  @override
  String get rejectReasonHint => '사유 입력 (선택)';

  @override
  String get acceptConfirm => '이 주문을 수락하시겠습니까?';

  @override
  String get completeConfirm => '서비스를 완료하시겠습니까?';

  @override
  String get rejectConfirm => '이 주문을 거절하시겠습니까?';

  @override
  String get noOrders => '주문 없음';

  @override
  String get duration => '소요 시간';

  @override
  String get unitMin => '분';

  @override
  String get orderDetailTitle => '주문 상세';

  @override
  String get customerInfo => '고객 정보';

  @override
  String get orderInfo => '주문 정보';

  @override
  String get serviceItems => '서비스 항목';

  @override
  String get totalAmount => '합계';

  @override
  String get orderTime => '주문 시간';

  @override
  String get serviceAddress => '서비스 주소';

  @override
  String get customerNotes => '고객 메모';

  @override
  String get serviceProgress => '진행 상황';

  @override
  String get stepPending => '대기 중';

  @override
  String get stepAccepted => '수락됨';

  @override
  String get stepArrived => '도착';

  @override
  String get stepInService => '서비스 중';

  @override
  String get stepCompleted => '완료';

  @override
  String get confirmArrival => '도착 확인';

  @override
  String get serviceActiveTitle => '서비스 중';

  @override
  String get elapsed => '경과 시간';

  @override
  String get remaining => '남은 시간';

  @override
  String get pause => '일시 중지';

  @override
  String get resume => '재개';

  @override
  String get endService => '서비스 종료';

  @override
  String get endServiceConfirm => '서비스를 종료하시겠습니까?';

  @override
  String get pauseConfirm => '일시 중지하시겠습니까?';

  @override
  String get focusMode => '집중 모드';

  @override
  String get messagesTitle => '메시지';

  @override
  String get systemNotice => '시스템';

  @override
  String get noMessages => '메시지 없음';

  @override
  String get markAllRead => '모두 읽음 표시';

  @override
  String get unread => '읽지 않음';

  @override
  String get chatPlaceholder => '메시지 입력…';

  @override
  String get quickReplies => '빠른 답장';

  @override
  String get sendLocation => '위치 전송';

  @override
  String get noChatMessages => '채팅을 시작하세요';

  @override
  String get qr1 => '가고 있어요';

  @override
  String get qr2 => '어디 계세요?';

  @override
  String get qr3 => '도착했어요';

  @override
  String get qr4 => '서비스 시작했습니다';

  @override
  String get qr5 => '잠깐만요';

  @override
  String get qr6 => '이용해 주셔서 감사합니다';

  @override
  String get incomeTitle => '수입';

  @override
  String get incomeOverview => '개요';

  @override
  String get periodToday => '오늘';

  @override
  String get periodWeek => '이번 주';

  @override
  String get periodMonth => '이번 달';

  @override
  String get periodTotal => '합계';

  @override
  String get todayIncomeLabel => '오늘 수입';

  @override
  String get weekIncomeLabel => '이번 주 수입';

  @override
  String get monthIncomeLabel => '이번 달 수입';

  @override
  String get totalIncomeLabel => '총 수입';

  @override
  String get incomeTrend => '수입 추세';

  @override
  String get incomeRecords => '거래 내역';

  @override
  String get noRecords => '내역 없음';

  @override
  String get incomeOrder => '주문';

  @override
  String get incomeBonus => '보너스';

  @override
  String get incomeDeduction => '공제';

  @override
  String get withdraw => '출금';

  @override
  String get availableBalance => '출금 가능 잔액';

  @override
  String get withdrawAmount => '출금 금액';

  @override
  String get withdrawMethod => '출금 방법';

  @override
  String get bankCard => '은행 카드';

  @override
  String get usdtLabel => 'USDT';

  @override
  String get withdrawMin => '최소 출금 \$10';

  @override
  String get withdrawConfirm => '출금 확인';

  @override
  String get withdrawSuccess => '출금 신청 완료';

  @override
  String get inputAmount => '금액 입력';

  @override
  String get profileTitle => '내 정보';

  @override
  String get levelNormal => '일반';

  @override
  String get levelSenior => '시니어';

  @override
  String get levelGold => '골드';

  @override
  String get levelTop => '최고';

  @override
  String get completedOrders => '완료 주문';

  @override
  String get skillsMenu => '스킬 관리';

  @override
  String get reviewsMenu => '고객 리뷰';

  @override
  String get scheduleMenu => '스케줄';

  @override
  String get settingsMenu => '설정';

  @override
  String get helpMenu => '도움말';

  @override
  String get aboutMenu => '소개';

  @override
  String get logout => '로그아웃';

  @override
  String get logoutConfirm => '로그아웃 하시겠습니까?';

  @override
  String get editProfile => '프로필 수정';

  @override
  String get memberSince => '가입일';

  @override
  String get settingsTitle => '설정';

  @override
  String get accountSection => '계정';

  @override
  String get changePassword => '비밀번호 변경';

  @override
  String get notifySection => '알림';

  @override
  String get orderNotify => '주문 알림';

  @override
  String get messageNotify => '메시지 알림';

  @override
  String get systemNotify => '시스템 알림';

  @override
  String get langSection => '언어';

  @override
  String get currentLanguage => '현재 언어';

  @override
  String get aboutSection => '정보';

  @override
  String get version => '버전';

  @override
  String get privacyPolicy => '개인정보 처리방침';

  @override
  String get terms => '이용약관';

  @override
  String get savedSuccess => '저장됨';

  @override
  String get scheduleTitle => '스케줄 관리';

  @override
  String get calendarTab => '달력';

  @override
  String get appointmentsTab => '예약';

  @override
  String get setAvailable => '가능으로 설정';

  @override
  String get setUnavailable => '휴식으로 설정';

  @override
  String get workHours => '근무 시간';

  @override
  String get addTimeSlot => '시간대 추가';

  @override
  String get noAppointments => '예약 없음';

  @override
  String get upcoming => '예정';

  @override
  String get confirmScheduleChange => '스케줄 변경 확인?';

  @override
  String get weekdayMon => '월';

  @override
  String get weekdayTue => '화';

  @override
  String get weekdayWed => '수';

  @override
  String get weekdayThu => '목';

  @override
  String get weekdayFri => '금';

  @override
  String get weekdaySat => '토';

  @override
  String get weekdaySun => '일';

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
  String get langTitle => '언어 설정';

  @override
  String get loginTitle => '파트너 로그인';

  @override
  String get loginSubtitle => '다시 오신 것을 환영합니다';

  @override
  String get phone => '전화번호';

  @override
  String get phoneHint => '전화번호 입력';

  @override
  String get password => '비밀번호';

  @override
  String get passwordHint => '비밀번호 입력';

  @override
  String get loginBtn => '로그인';

  @override
  String get forgotPassword => '비밀번호 찾기';

  @override
  String get loginSuccess => '로그인 성공';

  @override
  String get loginFailed => '잘못된 정보';

  @override
  String get phoneRequired => '전화번호 필수';

  @override
  String get passwordRequired => '비밀번호 필수';

  @override
  String get skillsTitle => '스킬';

  @override
  String get reviewsTitle => '리뷰';

  @override
  String get noReviews => '리뷰 없음';

  @override
  String get avgRating => '평균 평점';

  @override
  String totalReviews(int n) {
    return '$n개 리뷰';
  }

  @override
  String get loginTabPhone => '전화번호 로그인';

  @override
  String get loginTabTechId => '기술자 ID 로그인';

  @override
  String get fieldTechId => '기술자 ID';

  @override
  String get techIdHint => '기술자 ID를 입력하세요';

  @override
  String get techIdRequired => '기술자 ID를 입력하세요';

  @override
  String get noAccount => '계정이 없으신가요?';

  @override
  String get goRegister => '지금 등록';

  @override
  String get haveAccount => '이미 계정이 있으신가요?';

  @override
  String get goLogin => '로그인';

  @override
  String get registerTitle => '기술자 계정 만들기';

  @override
  String registerSubtitle(String merchant) {
    return '$merchant에 가입하여 시작하세요';
  }

  @override
  String get fieldFullName => '이름';

  @override
  String get fullNameHint => '이름을 입력하세요';

  @override
  String get fullNameRequired => '이름을 입력하세요';

  @override
  String get fieldEmail => '이메일';

  @override
  String get emailHint => '이메일 주소를 입력하세요';

  @override
  String get fieldConfirmPassword => '비밀번호 확인';

  @override
  String get confirmPasswordHint => '비밀번호를 다시 입력하세요';

  @override
  String get passwordMismatch => '비밀번호가 일치하지 않습니다';

  @override
  String get passwordTooShort => '비밀번호는 최소 6자 이상이어야 합니다';

  @override
  String get fieldTelegram => '텔레그램';

  @override
  String get telegramHint => '@username (선택)';

  @override
  String get fieldFacebook => '페이스북';

  @override
  String get facebookHint => '사용자 이름 또는 URL (선택)';

  @override
  String get fieldMerchantCode => '가맹점 코드';

  @override
  String get merchantCodeHint => '가맹점 초대 코드를 입력하세요';

  @override
  String get merchantCodeRequired => '가맹점 코드를 입력하세요';

  @override
  String get selectCountry => '국가 선택';

  @override
  String get registerBtn => '지금 등록';

  @override
  String get registerSuccess => '등록 완료! 가맹점 승인을 기다려 주세요';

  @override
  String get registerFailed => '등록 실패, 다시 시도해 주세요';

  @override
  String get invalidPhone => '잘못된 전화번호';

  @override
  String get invalidEmail => '잘못된 이메일 주소';

  @override
  String get optionalField => '선택사항';

  @override
  String get myMerchant => '내 가맹점';

  @override
  String get merchantVerified => '인증됨';

  @override
  String get merchantPending => '승인 대기 중';

  @override
  String get forgotPasswordTitle => '비밀번호 찾기';

  @override
  String get forgotPasswordDesc => '등록된 전화번호를 입력하면 OTP를 전송합니다';

  @override
  String get sendOtp => 'OTP 전송';

  @override
  String otpSent(String phone) {
    return '$phone으로 OTP 전송됨';
  }

  @override
  String get comingSoon => '곧 출시됩니다';

  @override
  String get arrivalNotice => '기술자가 도착했습니다. 서비스 시작을 확인해 주세요';

  @override
  String get launchingApp => '앱을 여는 중...';

  @override
  String get statusSwitchedTo => '상태가 변경되었습니다';

  @override
  String get customerMessage => '고객 메시지';

  @override
  String get systemMessage => '시스템 메시지';

  @override
  String get serviceCompleted => '서비스 완료';

  @override
  String get grabExpired => '주문 수락 시간 초과';

  @override
  String get newOrder => '새 주문';

  @override
  String get newOrderGrab => '새 주문 — 지금 수락';

  @override
  String get distanceFrom => '거리:';

  @override
  String get ignore => '무시';

  @override
  String get grabOrder => '즉시 수락';

  @override
  String get announcements => '공지사항';

  @override
  String get helpAndSupport => '도움말 & 지원';

  @override
  String get rateApp => '앱 평가하기';

  @override
  String get exitApp => '앱 종료';

  @override
  String get exitAppConfirm => '앱을 종료하시겠습니까?';
}
