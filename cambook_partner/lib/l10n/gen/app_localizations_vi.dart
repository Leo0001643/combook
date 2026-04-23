// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appName => 'CamBook Partner';

  @override
  String get navHome => 'Trang chủ';

  @override
  String get navOrders => 'Đơn hàng';

  @override
  String get navMessages => 'Tin nhắn';

  @override
  String get navIncome => 'Thu nhập';

  @override
  String get navProfile => 'Tôi';

  @override
  String get ok => 'Đồng ý';

  @override
  String get cancel => 'Hủy';

  @override
  String get confirm => 'Xác nhận';

  @override
  String get save => 'Lưu';

  @override
  String get edit => 'Sửa';

  @override
  String get delete => 'Xóa';

  @override
  String get back => 'Quay lại';

  @override
  String get loading => 'Đang tải…';

  @override
  String get noData => 'Không có dữ liệu';

  @override
  String get noMore => 'Không còn đơn nữa';

  @override
  String get error => 'Tải thất bại';

  @override
  String get retry => 'Thử lại';

  @override
  String get close => 'Đóng';

  @override
  String get send => 'Gửi';

  @override
  String get call => 'Gọi điện';

  @override
  String get navigate => 'Dẫn đường';

  @override
  String get copy => 'Sao chép';

  @override
  String get justNow => 'Vừa xong';

  @override
  String minutesAgo(int n) {
    return '$n phút trước';
  }

  @override
  String hoursAgo(int n) {
    return '$n giờ trước';
  }

  @override
  String daysAgo(int n) {
    return '$n ngày trước';
  }

  @override
  String get success => 'Thành công';

  @override
  String get failed => 'Thất bại';

  @override
  String get submitting => 'Đang gửi…';

  @override
  String get statusOnline => 'Trực tuyến';

  @override
  String get statusBusy => 'Bận';

  @override
  String get statusRest => 'Nghỉ';

  @override
  String get statusOnlineDesc => 'Nhận đơn';

  @override
  String get statusBusyDesc => 'Đang phục vụ';

  @override
  String get statusRestDesc => 'Đang nghỉ';

  @override
  String get statusSwitchTitle => 'Chuyển trạng thái';

  @override
  String get statusSwitchDesc => 'Sẽ ảnh hưởng đến việc nhận đơn';

  @override
  String get greetingMorning => 'Chào buổi sáng';

  @override
  String get greetingAfternoon => 'Chào buổi chiều';

  @override
  String get greetingEvening => 'Chào buổi tối';

  @override
  String get techNo => 'Mã KTV';

  @override
  String get todayStats => 'Thống kê hôm nay';

  @override
  String get todayOrders => 'Đơn hàng';

  @override
  String get todayIncome => 'Thu nhập';

  @override
  String get todayRating => 'Đánh giá';

  @override
  String get quickActions => 'Thao tác nhanh';

  @override
  String get startAccepting => 'Bắt đầu nhận đơn';

  @override
  String get appointments => 'Lịch hẹn';

  @override
  String get viewSchedule => 'Lịch làm việc';

  @override
  String get recentOrders => 'Đơn gần đây';

  @override
  String get viewAll => 'Xem tất cả';

  @override
  String get noOrdersToday => 'Chưa có đơn hôm nay';

  @override
  String get newOrderTitle => 'Đơn mới';

  @override
  String get newOrderDesc => 'Có yêu cầu dịch vụ mới';

  @override
  String get acceptOrder => 'Nhận đơn';

  @override
  String get rejectOrder => 'Từ chối';

  @override
  String autoReject(int s) {
    return 'Tự từ chối sau ${s}s';
  }

  @override
  String get refreshed => 'Đã làm mới';

  @override
  String get ordersTitle => 'Quản lý đơn';

  @override
  String get tabPending => 'Chờ nhận';

  @override
  String get tabAccepted => 'Đã nhận';

  @override
  String get tabInService => 'Đang phục vụ';

  @override
  String get tabCompleted => 'Hoàn thành';

  @override
  String get tabCancelled => 'Đã hủy';

  @override
  String get orderNo => 'Mã đơn';

  @override
  String get serviceType => 'Loại dịch vụ';

  @override
  String get homeService => 'Dịch vụ tại nhà';

  @override
  String get storeService => 'Dịch vụ tại cửa hàng';

  @override
  String get amount => 'Số tiền';

  @override
  String get appointTime => 'Giờ hẹn';

  @override
  String get distance => 'Khoảng cách';

  @override
  String get remark => 'Ghi chú';

  @override
  String get btnAccept => 'Nhận đơn';

  @override
  String get btnReject => 'Từ chối';

  @override
  String get btnArrive => 'Đã đến';

  @override
  String get btnStartService => 'Bắt đầu';

  @override
  String get btnComplete => 'Hoàn thành';

  @override
  String get btnContact => 'Liên hệ';

  @override
  String get btnDetail => 'Chi tiết';

  @override
  String get rejectReason => 'Lý do';

  @override
  String get rejectReasonHint => 'Nhập lý do (không bắt buộc)';

  @override
  String get acceptConfirm => 'Nhận đơn này?';

  @override
  String get completeConfirm => 'Hoàn thành dịch vụ?';

  @override
  String get rejectConfirm => 'Từ chối đơn này?';

  @override
  String get noOrders => 'Không có đơn';

  @override
  String get duration => 'Thời gian';

  @override
  String get unitMin => 'phút';

  @override
  String get orderDetailTitle => 'Chi tiết đơn';

  @override
  String get customerInfo => 'Khách hàng';

  @override
  String get orderInfo => 'Thông tin đơn';

  @override
  String get serviceItems => 'Dịch vụ';

  @override
  String get totalAmount => 'Tổng tiền';

  @override
  String get orderTime => 'Giờ đặt';

  @override
  String get serviceAddress => 'Địa chỉ';

  @override
  String get customerNotes => 'Ghi chú';

  @override
  String get serviceProgress => 'Tiến độ';

  @override
  String get stepPending => 'Chờ nhận';

  @override
  String get stepAccepted => 'Đã nhận';

  @override
  String get stepArrived => 'Đã đến';

  @override
  String get stepInService => 'Đang phục vụ';

  @override
  String get stepCompleted => 'Hoàn thành';

  @override
  String get confirmArrival => 'Xác nhận đã đến';

  @override
  String get serviceActiveTitle => 'Đang phục vụ';

  @override
  String get elapsed => 'Đã phục vụ';

  @override
  String get remaining => 'Còn lại';

  @override
  String get pause => 'Tạm dừng';

  @override
  String get resume => 'Tiếp tục';

  @override
  String get endService => 'Kết thúc';

  @override
  String get endServiceConfirm => 'Kết thúc dịch vụ? Khách sẽ được mời đánh giá.';

  @override
  String get pauseConfirm => 'Tạm dừng dịch vụ?';

  @override
  String get focusMode => 'Chế độ tập trung';

  @override
  String get messagesTitle => 'Tin nhắn';

  @override
  String get systemNotice => 'Hệ thống';

  @override
  String get noMessages => 'Chưa có tin nhắn';

  @override
  String get markAllRead => 'Đánh dấu đã đọc';

  @override
  String get unread => 'chưa đọc';

  @override
  String get chatPlaceholder => 'Nhập tin nhắn…';

  @override
  String get quickReplies => 'Phản hồi nhanh';

  @override
  String get sendLocation => 'Vị trí';

  @override
  String get noChatMessages => 'Hãy bắt đầu trò chuyện';

  @override
  String get qr1 => 'Tôi đang trên đường';

  @override
  String get qr2 => 'Bạn đang ở đâu?';

  @override
  String get qr3 => 'Tôi đã đến nơi';

  @override
  String get qr4 => 'Dịch vụ đã bắt đầu';

  @override
  String get qr5 => 'Đợi một chút';

  @override
  String get qr6 => 'Cảm ơn bạn đã sử dụng dịch vụ';

  @override
  String get incomeTitle => 'Thu nhập';

  @override
  String get incomeOverview => 'Tổng quan';

  @override
  String get periodToday => 'Hôm nay';

  @override
  String get periodWeek => 'Tuần';

  @override
  String get periodMonth => 'Tháng';

  @override
  String get periodTotal => 'Tổng';

  @override
  String get todayIncomeLabel => 'Hôm nay';

  @override
  String get weekIncomeLabel => 'Tuần này';

  @override
  String get monthIncomeLabel => 'Tháng này';

  @override
  String get totalIncomeLabel => 'Tổng thu nhập';

  @override
  String get incomeTrend => 'Xu hướng';

  @override
  String get incomeRecords => 'Lịch sử';

  @override
  String get noRecords => 'Chưa có giao dịch';

  @override
  String get incomeOrder => 'Đơn hàng';

  @override
  String get incomeBonus => 'Thưởng';

  @override
  String get incomeDeduction => 'Khấu trừ';

  @override
  String get withdraw => 'Rút tiền';

  @override
  String get availableBalance => 'Số dư';

  @override
  String get withdrawAmount => 'Số tiền';

  @override
  String get withdrawMethod => 'Phương thức';

  @override
  String get bankCard => 'Thẻ ngân hàng';

  @override
  String get usdtLabel => 'USDT';

  @override
  String get withdrawMin => 'Rút tối thiểu 10\$';

  @override
  String get withdrawConfirm => 'Xác nhận';

  @override
  String get withdrawSuccess => 'Đã gửi yêu cầu rút tiền';

  @override
  String get inputAmount => 'Nhập số tiền';

  @override
  String get profileTitle => 'Hồ sơ';

  @override
  String get levelNormal => 'Tiêu chuẩn';

  @override
  String get levelSenior => 'Cao cấp';

  @override
  String get levelGold => 'Vàng';

  @override
  String get levelTop => 'Đỉnh';

  @override
  String get completedOrders => 'Đã hoàn thành';

  @override
  String get skillsMenu => 'Kỹ năng';

  @override
  String get reviewsMenu => 'Đánh giá';

  @override
  String get scheduleMenu => 'Lịch làm việc';

  @override
  String get settingsMenu => 'Cài đặt';

  @override
  String get helpMenu => 'Trợ giúp';

  @override
  String get aboutMenu => 'Về chúng tôi';

  @override
  String get logout => 'Đăng xuất';

  @override
  String get logoutConfirm => 'Xác nhận đăng xuất?';

  @override
  String get editProfile => 'Chỉnh sửa';

  @override
  String get memberSince => 'Ngày gia nhập';

  @override
  String get settingsTitle => 'Cài đặt';

  @override
  String get accountSection => 'Tài khoản';

  @override
  String get changePassword => 'Đổi mật khẩu';

  @override
  String get notifySection => 'Thông báo';

  @override
  String get orderNotify => 'Thông báo đơn';

  @override
  String get messageNotify => 'Thông báo tin nhắn';

  @override
  String get systemNotify => 'Thông báo hệ thống';

  @override
  String get langSection => 'Ngôn ngữ';

  @override
  String get currentLanguage => 'Ngôn ngữ';

  @override
  String get aboutSection => 'Về ứng dụng';

  @override
  String get version => 'Phiên bản';

  @override
  String get privacyPolicy => 'Chính sách bảo mật';

  @override
  String get terms => 'Điều khoản';

  @override
  String get savedSuccess => 'Đã lưu';

  @override
  String get scheduleTitle => 'Lịch làm việc';

  @override
  String get calendarTab => 'Lịch';

  @override
  String get appointmentsTab => 'Lịch hẹn';

  @override
  String get setAvailable => 'Đặt sẵn sàng';

  @override
  String get setUnavailable => 'Đặt nghỉ';

  @override
  String get workHours => 'Giờ làm việc';

  @override
  String get addTimeSlot => 'Thêm khung giờ';

  @override
  String get noAppointments => 'Chưa có lịch hẹn';

  @override
  String get upcoming => 'Sắp tới';

  @override
  String get confirmScheduleChange => 'Xác nhận thay đổi lịch?';

  @override
  String get weekdayMon => 'T2';

  @override
  String get weekdayTue => 'T3';

  @override
  String get weekdayWed => 'T4';

  @override
  String get weekdayThu => 'T5';

  @override
  String get weekdayFri => 'T6';

  @override
  String get weekdaySat => 'T7';

  @override
  String get weekdaySun => 'CN';

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
  String get langTitle => 'Ngôn ngữ';

  @override
  String get loginTitle => 'Đăng nhập KTV';

  @override
  String get loginSubtitle => 'Chào mừng trở lại';

  @override
  String get phone => 'Số điện thoại';

  @override
  String get phoneHint => 'Nhập số điện thoại';

  @override
  String get password => 'Mật khẩu';

  @override
  String get passwordHint => 'Nhập mật khẩu';

  @override
  String get loginBtn => 'Đăng nhập';

  @override
  String get forgotPassword => 'Quên mật khẩu?';

  @override
  String get loginSuccess => 'Đăng nhập thành công';

  @override
  String get loginFailed => 'Thông tin sai';

  @override
  String get phoneRequired => 'Nhập số điện thoại';

  @override
  String get passwordRequired => 'Nhập mật khẩu';

  @override
  String get skillsTitle => 'Kỹ năng';

  @override
  String get reviewsTitle => 'Đánh giá';

  @override
  String get noReviews => 'Chưa có đánh giá';

  @override
  String get avgRating => 'Trung bình';

  @override
  String totalReviews(int n) {
    return '$n đánh giá';
  }

  @override
  String get loginTabPhone => 'Đăng nhập SĐT';

  @override
  String get loginTabTechId => 'Đăng nhập Mã KT';

  @override
  String get fieldTechId => 'Mã kỹ thuật viên';

  @override
  String get techIdHint => 'Nhập mã kỹ thuật viên';

  @override
  String get techIdRequired => 'Vui lòng nhập mã KTV';

  @override
  String get noAccount => 'Chưa có tài khoản?';

  @override
  String get goRegister => 'Đăng ký ngay';

  @override
  String get haveAccount => 'Đã có tài khoản?';

  @override
  String get goLogin => 'Đăng nhập';

  @override
  String get registerTitle => 'Tạo tài khoản KTV';

  @override
  String registerSubtitle(String merchant) {
    return 'Tham gia $merchant để bắt đầu';
  }

  @override
  String get fieldFullName => 'Họ và tên';

  @override
  String get fullNameHint => 'Nhập họ và tên';

  @override
  String get fullNameRequired => 'Vui lòng nhập họ tên';

  @override
  String get fieldEmail => 'Email';

  @override
  String get emailHint => 'Nhập địa chỉ email';

  @override
  String get fieldConfirmPassword => 'Xác nhận mật khẩu';

  @override
  String get confirmPasswordHint => 'Nhập lại mật khẩu';

  @override
  String get passwordMismatch => 'Mật khẩu không khớp';

  @override
  String get passwordTooShort => 'Mật khẩu ít nhất 6 ký tự';

  @override
  String get fieldTelegram => 'Telegram';

  @override
  String get telegramHint => '@username (tùy chọn)';

  @override
  String get fieldFacebook => 'Facebook';

  @override
  String get facebookHint => 'Tên người dùng hoặc URL (tùy chọn)';

  @override
  String get fieldMerchantCode => 'Mã thương nhân';

  @override
  String get merchantCodeHint => 'Nhập mã mời thương nhân';

  @override
  String get merchantCodeRequired => 'Vui lòng nhập mã thương nhân';

  @override
  String get selectCountry => 'Chọn quốc gia';

  @override
  String get registerBtn => 'Đăng ký ngay';

  @override
  String get registerSuccess => 'Đăng ký thành công! Chờ xét duyệt';

  @override
  String get registerFailed => 'Đăng ký thất bại, thử lại';

  @override
  String get invalidPhone => 'Số điện thoại không hợp lệ';

  @override
  String get invalidEmail => 'Email không hợp lệ';

  @override
  String get optionalField => 'Tùy chọn';

  @override
  String get myMerchant => 'Thương nhân của tôi';

  @override
  String get merchantVerified => 'Đã xác minh';

  @override
  String get merchantPending => 'Đang chờ duyệt';

  @override
  String get forgotPasswordTitle => 'Quên mật khẩu';

  @override
  String get forgotPasswordDesc => 'Nhập số điện thoại đã đăng ký để nhận OTP';

  @override
  String get sendOtp => 'Gửi OTP';

  @override
  String otpSent(String phone) {
    return 'OTP đã gửi tới $phone';
  }

  @override
  String get comingSoon => 'Sắp ra mắt';

  @override
  String get arrivalNotice => 'Kỹ thuật viên đã đến, vui lòng xác nhận để bắt đầu dịch vụ';

  @override
  String get launchingApp => 'Đang mở ứng dụng...';

  @override
  String get statusSwitchedTo => 'Trạng thái đã chuyển sang';

  @override
  String get customerMessage => 'Tin nhắn khách hàng';

  @override
  String get systemMessage => 'Thông báo hệ thống';

  @override
  String get serviceCompleted => 'Dịch vụ hoàn thành';

  @override
  String get grabExpired => 'Hết thời gian nhận đơn';

  @override
  String get newOrder => 'Đơn mới';

  @override
  String get newOrderGrab => 'Đơn mới — Nhận ngay';

  @override
  String get distanceFrom => 'Khoảng cách:';

  @override
  String get ignore => 'Bỏ qua';

  @override
  String get grabOrder => 'Nhận ngay';

  @override
  String get announcements => 'Thông báo';

  @override
  String get helpAndSupport => 'Trợ giúp & Hỗ trợ';

  @override
  String get rateApp => 'Đánh giá ứng dụng';

  @override
  String get exitApp => 'Thoát ứng dụng';

  @override
  String get exitAppConfirm => 'Thoát khỏi ứng dụng?';

  @override
  String get todaySchedule => 'Lịch hôm nay';

  @override
  String get allOrders => 'Tất cả đơn hàng';

  @override
  String get orderStatusPending => 'Chờ xác nhận';

  @override
  String get orderStatusAccepted => 'Đã nhận';

  @override
  String get orderStatusInProgress => 'Đang phục vụ';

  @override
  String get orderStatusCompleted => 'Hoàn thành';

  @override
  String get orderStatusCancelled => 'Đã hủy';

  @override
  String get noScheduleToday => 'Hôm nay không có lịch hẹn';

  @override
  String get keepOnlineHint => 'Duy trì trực tuyến để nhận đơn mới ✨';

  @override
  String get myStats => 'Dữ liệu của tôi';

  @override
  String get totalOrders => 'Tổng đơn hàng';

  @override
  String get overallRating => 'Đánh giá tổng thể';

  @override
  String get currentBalance => 'Số dư hiện tại';

  @override
  String get statTodayAppointments => 'Đặt lịch hôm nay';

  @override
  String get statTodayCompleted => 'Hoàn thành hôm nay';

  @override
  String get statTodayCancelled => 'Huỷ hôm nay';

  @override
  String schedOrderCount(int n) {
    return '$n đơn';
  }

  @override
  String get schedInService => 'Đang phục vụ';

  @override
  String get schedPending => 'Chờ phục vụ';

  @override
  String get totalDuration => 'Tổng thời gian';

  @override
  String scheduleProgress(int completed, int total) {
    return '$completed / $total hoàn thành';
  }

  @override
  String get statusOnWay => 'Đang đến';

  @override
  String get statusCancelling => 'Đang huỷ';

  @override
  String get statusRefunding => 'Đang hoàn tiền';

  @override
  String get statusRefunded => 'Đã hoàn tiền';

  @override
  String schedEndTime(String time, String duration) {
    return 'Kết thúc $time · ${duration}ph';
  }

  @override
  String get serviceInProgress => 'Đang phục vụ';

  @override
  String estimatedIncome(String amount) {
    return 'Dự tính $amount';
  }
}
