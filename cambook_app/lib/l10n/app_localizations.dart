/// 多语言资源代理（完整版）
/// 覆盖全部页面所有文本，零硬编码
/// 支持：中文(zh-CN) / English(en) / Tiếng Việt(vi) / ភាសាខ្មែរ(km)
library;

import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)
        ?? AppLocalizations(const Locale('zh'));
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  // ==================== 通用 ====================
  String get appName => 'CamBook';
  String get ok => _t(zh: '确定', en: 'OK', vi: 'Xác nhận', km: 'យល់ព្រម');
  String get hint => _t(zh: '提示', en: 'Notice', vi: 'Thông báo', km: 'សេចក្ដីជូនដំណឹង');
  String get cancel => _t(zh: '取消', en: 'Cancel', vi: 'Hủy', km: 'បោះបង់');
  String get confirm => _t(zh: '确认', en: 'Confirm', vi: 'Xác nhận', km: 'បញ្ជាក់');
  String get save => _t(zh: '保存', en: 'Save', vi: 'Lưu', km: 'រក្សាទុក');
  String get edit => _t(zh: '编辑', en: 'Edit', vi: 'Chỉnh sửa', km: 'កែប្រែ');
  String get delete => _t(zh: '删除', en: 'Delete', vi: 'Xóa', km: 'លុប');
  String get search => _t(zh: '搜索', en: 'Search', vi: 'Tìm kiếm', km: 'ស្វែងរក');
  String get loading => _t(zh: '加载中...', en: 'Loading...', vi: 'Đang tải...', km: 'កំពុងផ្ទុក...');
  String get retry => _t(zh: '重试', en: 'Retry', vi: 'Thử lại', km: 'ព្យាយាមម្ដងទៀត');
  String get noData => _t(zh: '暂无数据', en: 'No Data', vi: 'Không có dữ liệu', km: 'គ្មានទិន្នន័យ');
  String get networkError => _t(zh: '网络错误，请稍后重试', en: 'Network error, please try again', vi: 'Lỗi mạng, thử lại', km: 'បណ្ដាញមានបញ្ហា');
  String get submit => _t(zh: '提交', en: 'Submit', vi: 'Gửi', km: 'ដាក់ស្នើ');
  String get back => _t(zh: '返回', en: 'Back', vi: 'Quay lại', km: 'ត្រឡប់');
  String get next => _t(zh: '下一步', en: 'Next', vi: 'Tiếp theo', km: 'បន្ទាប់');
  String get skip => _t(zh: '跳过', en: 'Skip', vi: 'Bỏ qua', km: 'រំលង');
  String get done => _t(zh: '完成', en: 'Done', vi: 'Xong', km: 'រួចរាល់');
  String get copy => _t(zh: '复制', en: 'Copy', vi: 'Sao chép', km: 'ចម្លង');
  String get share => _t(zh: '分享', en: 'Share', vi: 'Chia sẻ', km: 'ចែករំលែក');
  String get more => _t(zh: '更多', en: 'More', vi: 'Thêm', km: 'បន្ថែម');
  String get all => _t(zh: '全部', en: 'All', vi: 'Tất cả', km: 'ទាំងអស់');
  String get yes => _t(zh: '是', en: 'Yes', vi: 'Có', km: 'បាទ/ចាស');
  String get no => _t(zh: '否', en: 'No', vi: 'Không', km: 'ទេ');

  // ==================== 底部导航 ====================
  String get navHome => _t(zh: '柬单约', en: 'Home', vi: 'Trang chủ', km: 'ទំព័រដើម');
  String get navTechnician => _t(zh: '技师', en: 'Therapist', vi: 'Kỹ thuật viên', km: 'អ្នកបច្ចេកទេស');
  String get navDiscover => _t(zh: '发现', en: 'Discover', vi: 'Khám phá', km: 'រកឃើញ');
  String get navOrder => _t(zh: '订单', en: 'Orders', vi: 'Đơn hàng', km: 'ការបញ្ជាទិញ');
  String get navProfile => _t(zh: '我的', en: 'Profile', vi: 'Hồ sơ', km: 'គណនី');

  // ==================== 认证 ====================
  String get login => _t(zh: '登录', en: 'Login', vi: 'Đăng nhập', km: 'ចូល');
  String get logout => _t(zh: '退出登录', en: 'Logout', vi: 'Đăng xuất', km: 'ចេញ');
  String get register => _t(zh: '注册', en: 'Register', vi: 'Đăng ký', km: 'ចុះឈ្មោះ');
  String get forgotPassword => _t(zh: '忘记密码?', en: 'Forgot Password?', vi: 'Quên mật khẩu?', km: 'ភ្លេចពាក្យសម្ងាត់?');
  String get loginByPassword => _t(zh: '密码登录', en: 'Password Login', vi: 'Đăng nhập mật khẩu', km: 'ចូលដោយពាក្យសម្ងាត់');
  String get loginBySms => _t(zh: '验证码登录', en: 'SMS Login', vi: 'Đăng nhập mã OTP', km: 'ចូលដោយ OTP');
  String get welcomeBack => _t(zh: '欢迎回来', en: 'Welcome Back', vi: 'Chào mừng trở lại', km: 'សូមស្វាគមន៍');
  String get loginSubtitle => _t(zh: '登录您的 CamBook 账号', en: 'Sign in to your CamBook account', vi: 'Đăng nhập tài khoản CamBook', km: 'ចូលក្នុងគណនី CamBook');
  String get noAccount => _t(zh: '还没有账号? ', en: "Don't have an account? ", vi: 'Chưa có tài khoản? ', km: 'មិនមានគណនី? ');
  String get registerNow => _t(zh: '立即注册', en: 'Register Now', vi: 'Đăng ký ngay', km: 'ចុះឈ្មោះឥឡូវ');
  String get hasAccount => _t(zh: '已有账号？立即登录', en: 'Already have an account? Login', vi: 'Đã có tài khoản? Đăng nhập', km: 'មានគណនីហើយ? ចូល');
  String get memberLogin => _t(zh: '会员登录', en: 'Member Login', vi: 'Đăng nhập thành viên', km: 'ចូលជាសមាជិក');
  String get technicianLogin => _t(zh: '技师登录', en: 'Therapist Login', vi: 'Đăng nhập KTV', km: 'ចូលជាអ្នកបច្ចេកទេស');
  String get merchantLogin => _t(zh: '商户登录', en: 'Merchant Login', vi: 'Đăng nhập thương nhân', km: 'ចូលជាអ្នកលក់');
  String get userType => _t(zh: '用户类型', en: 'User Type', vi: 'Loại tài khoản', km: 'ប្រភេទគណនី');
  String get phone => _t(zh: '手机号', en: 'Phone Number', vi: 'Số điện thoại', km: 'លេខទូរស័ព្ទ');
  String get phonePlaceholder => _t(zh: '请输入手机号', en: 'Enter phone number', vi: 'Nhập số điện thoại', km: 'បញ្ចូលលេខទូរស័ព្ទ');
  String get password => _t(zh: '密码', en: 'Password', vi: 'Mật khẩu', km: 'ពាក្យសម្ងាត់');
  String get passwordPlaceholder => _t(zh: '请输入密码', en: 'Enter password', vi: 'Nhập mật khẩu', km: 'បញ្ចូលពាក្យសម្ងាត់');
  String get newPassword => _t(zh: '新密码', en: 'New Password', vi: 'Mật khẩu mới', km: 'ពាក្យសម្ងាត់ថ្មី');
  String get confirmPassword => _t(zh: '确认密码', en: 'Confirm Password', vi: 'Xác nhận mật khẩu', km: 'បញ្ជាក់ពាក្យសម្ងាត់');
  String get verifyCode => _t(zh: '验证码', en: 'Verification Code', vi: 'Mã xác minh', km: 'លេខកូដផ្ទៀងផ្ទាត់');
  String get verifyCodePlaceholder => _t(zh: '请输入验证码', en: 'Enter verification code', vi: 'Nhập mã xác minh', km: 'បញ្ចូលលេខកូដ');
  String get sendCode => _t(zh: '获取验证码', en: 'Send Code', vi: 'Gửi mã', km: 'ផ្ញើលេខកូដ');
  String resendCountdown(int s) => _t(zh: '${s}s后重发', en: 'Resend in ${s}s', vi: 'Gửi lại sau ${s}s', km: 'ផ្ញើឡើងវិញក្នុង ${s}s');
  String get countryCode => _t(zh: '国际区号', en: 'Country Code', vi: 'Mã quốc gia', km: 'លេខកូដប្រទេស');
  String get selectCountry => _t(zh: '选择国家/地区', en: 'Select Country/Region', vi: 'Chọn quốc gia', km: 'ជ្រើសរើសប្រទេស');
  String get agreeTerms => _t(zh: '我已阅读并同意', en: 'I agree to', vi: 'Tôi đồng ý với', km: 'ខ្ញុំយល់ព្រម');
  String get userAgreement => _t(zh: '《用户协议》', en: 'Terms of Service', vi: 'Điều khoản dịch vụ', km: 'លក្ខខណ្ឌ');
  String get privacyPolicy => _t(zh: '《隐私政策》', en: 'Privacy Policy', vi: 'Chính sách bảo mật', km: 'គោលការណ៍ឯកជនភាព');
  String get and => _t(zh: '和', en: 'and', vi: 'và', km: 'និង');
  String get inviteCode => _t(zh: '邀请码（选填）', en: 'Invite Code (Optional)', vi: 'Mã mời (Tùy chọn)', km: 'លេខកូដអញ្ជើញ');
  String get autoRegisterHint => _t(zh: '，未注册手机号将自动创建账号', en: ', unregistered phone will create an account', vi: ', SĐT chưa đăng ký sẽ tự tạo tài khoản', km: ', លេខទូរស័ព្ទថ្មីនឹងបង្កើតគណនីស្វ័យប្រវត្តិ');
  String get appTagline => _t(zh: '专业上门按摩 · SPA服务', en: 'Professional Home Massage · SPA', vi: 'Massage & SPA tại nhà chuyên nghiệp', km: 'ម៉ាស្សា · SPA ជំនាញ');
  String get welcomeToCamBook => _t(zh: '欢迎来到 CamBook', en: 'Welcome to CamBook', vi: 'Chào mừng đến CamBook', km: 'សូមស្វាគមន៍មកកាន់ CamBook');
  String get appTaglineLong => _t(zh: '专业上门按摩 · SPA 服务平台', en: 'Professional Home Massage & SPA Platform', vi: 'Nền tảng Massage · SPA tại nhà', km: 'វេទិកា Massage · SPA ជំនាញ');
  // 欢迎页角色卡片
  String get roleMember => _t(zh: '会员', en: 'Member', vi: 'Thành viên', km: 'សមាជិក');
  String get roleTechnicianTitle => _t(zh: '技师', en: 'Therapist', vi: 'Kỹ thuật viên', km: 'អ្នកបច្ចេកទេស');
  String get roleMerchantTitle => _t(zh: '商户', en: 'Merchant', vi: 'Thương nhân', km: 'អ្នកលក់');
  String get roleMemberSubtitle => _t(zh: '浏览技师，预约专属上门按摩 SPA 服务', en: 'Browse therapists and book home massage & SPA services', vi: 'Duyệt KTV và đặt dịch vụ massage SPA tại nhà', km: 'ស្វែងរក KTV ហើយកក់ Massage SPA ផ្ទះ');
  String get roleTechnicianSubtitle => _t(zh: '展示技能，灵活接单，轻松增收', en: 'Showcase your skills, accept orders flexibly, boost income', vi: 'Trình bày kỹ năng, nhận đơn linh hoạt, tăng thu nhập', km: 'បង្ហាញជំនាញ ទទួលការបញ្ជាទិញ បង្កើនចំណូល');
  String get roleMerchantSubtitle => _t(zh: '开设门店，引流拓客，拓展业务版图', en: 'Open your store, attract customers, expand your business', vi: 'Mở cửa hàng, thu hút khách hàng, mở rộng kinh doanh', km: 'បើកហាង ទាក់ទាញអតិថិជន ពង្រីកអាជីវកម្ម');

  // ==================== 引导页 ====================
  String get onboarding1Title => _t(zh: '专业技师上门服务', en: 'Professional Home Service', vi: 'Dịch vụ tại nhà chuyên nghiệp', km: 'សេវាជំនាញផ្ទះ');
  String get onboarding1Subtitle => _t(zh: '数百名认证技师，随时为您提供专业按摩、SPA服务，足不出户享受高品质放松体验', en: 'Hundreds of certified therapists ready to provide professional massage and SPA services at your doorstep', vi: 'Hàng trăm kỹ thuật viên được chứng nhận sẵn sàng phục vụ tại nhà bạn', km: 'ជ្រើសរើសពីអ្នកបច្ចេកទេសដែលមានការបញ្ជាក់ ហើយទទួលសេវា SPA នៅផ្ទះ');
  String get onboarding2Title => _t(zh: '便捷预约，实时追踪', en: 'Easy Booking, Real-time Tracking', vi: 'Đặt lịch dễ dàng, theo dõi thời gian thực', km: 'ការកក់ងាយស្រួល តាមដានពេលវេលាជាក់ស្ដែង');
  String get onboarding2Subtitle => _t(zh: '一键预约心仪技师，Google Maps实时查看技师位置，让服务透明可信', en: 'Book your favorite therapist with one tap, track their location in real-time with Google Maps', vi: 'Đặt lịch kỹ thuật viên yêu thích chỉ với một chạm, theo dõi vị trí thời gian thực', km: 'កក់ KTV ដែលអ្នកចូលចិត្ត ហើយតាមដានទីតាំងតាម Google Maps');
  String get onboarding3Title => _t(zh: '多种支付，安全保障', en: 'Multiple Payments, Secure Guarantee', vi: 'Nhiều phương thức thanh toán, bảo đảm an toàn', km: 'ការទូទាត់ច្រើនប្រភេទ សុវត្ថិភាព');
  String get onboarding3Subtitle => _t(zh: '支持USDT加密货币、ABA网银转账等多种支付方式，全程加密保障资金安全', en: 'Support USDT cryptocurrency, ABA bank transfer and more. Your funds are fully encrypted and protected', vi: 'Hỗ trợ USDT, chuyển khoản ABA và nhiều hình thức khác. Tất cả được mã hóa và bảo vệ', km: 'គាំទ្រ USDT, ABA Bank និងច្រើនទៀត ។ សុវត្ថិភាពពេញ');
  String get getStarted => _t(zh: '立即注册', en: 'Get Started', vi: 'Bắt đầu ngay', km: 'ចាប់ផ្ដើម');

  // ==================== 首页 ====================
  String get newUserZone => _t(zh: '新客专区', en: 'New User Zone', vi: 'Khu vực người dùng mới', km: 'តំបន់អ្នកប្រើថ្មី');
  String get newUserDiscount => _t(zh: '下单立减200元！', en: 'Save \$20 on first order!', vi: 'Giảm 200k đơn đầu!', km: 'បញ្ចុះ \$20 លើការបញ្ជាទិញដំបូង!');
  String get useNow => _t(zh: '立即使用', en: 'Use Now', vi: 'Dùng ngay', km: 'ប្រើឥឡូវ');
  String get explore => _t(zh: '探索', en: 'Explore', vi: 'Khám phá', km: 'ស្វែងរក');
  String get nearby => _t(zh: '附近', en: 'Nearby', vi: 'Gần đây', km: 'ជិតៗ');
  String get newUser => _t(zh: '新人', en: 'New', vi: 'Mới', km: 'ថ្មី');
  String get specialOffer => _t(zh: '特惠', en: 'Special', vi: 'Ưu đãi', km: 'ពិសេស');
  String get returnCustomerRank => _t(zh: '往约回头客榜', en: 'Top Repeat Clients', vi: 'Bảng khách quay lại', km: 'ចំណាត់ថ្នាក់ភ្ញៀវវិលមកវិញ');
  String get viewNow => _t(zh: '立即查看', en: 'View Now', vi: 'Xem ngay', km: 'មើលឥឡូវ');
  String get selectedPackage => _t(zh: '甄选套餐', en: 'Selected Packages', vi: 'Gói dịch vụ chọn lọc', km: 'កញ្ចប់ដែលបានជ្រើស');
  String get hotPackage => _t(zh: '热门套餐', en: 'Popular Packages', vi: 'Gói phổ biến', km: 'កញ្ចប់ពេញនិយម');
  String get everyoneLoves => _t(zh: '大家都爱约', en: 'Everyone Loves', vi: 'Mọi người yêu thích', km: 'គ្រប់គ្នាចូលចិត្ត');
  String get memberPrice => _t(zh: '会员价格', en: 'Member Price', vi: 'Giá hội viên', km: 'តម្លៃសមាជិក');
  String get bookService => _t(zh: '预约服务', en: 'Book Service', vi: 'Đặt lịch', km: 'កក់សេវា');
  String get locationCity => _t(zh: '定位城市', en: 'Current City', vi: 'Thành phố', km: 'ទីក្រុង');
  String get locationFailed => _t(zh: '定位失败', en: 'Location Failed', vi: 'Định vị thất bại', km: 'ការកំណត់ទីតាំងបានបរាជ័យ');

  // ==================== 首页内容 ====================
  String get searchHint => _t(zh: '搜索技师、服务…', en: 'Search therapists, services…', vi: 'Tìm KTV, dịch vụ…', km: 'ស្វែងរក KTV, សេវា…');
  String get featuredTech => _t(zh: '精选技师', en: 'Featured Therapists', vi: 'KTV Nổi Bật', km: 'អ្នកបច្ចេកទេសដែលបានជ្រើស');
  String get viewAll => _t(zh: '查看全部', en: 'View All', vi: 'Xem tất cả', km: 'មើលទាំងអស់');
  String get allPackages => _t(zh: '全部套餐', en: 'All Packages', vi: 'Tất cả gói', km: 'គ្រប់កញ្ចប់');
  String get book => _t(zh: '预约', en: 'Book', vi: 'Đặt lịch', km: 'កក់');
  String servedTimes(int n) => _t(zh: '已服务 $n 次', en: '$n sessions', vi: '$n lần phục vụ', km: 'បម្រើ $n ដង');
  String get newUserExclusive => _t(zh: '🎁 新人专享', en: '🎁 New User Exclusive', vi: '🎁 Độc quyền người mới', km: '🎁 ផ្តាច់មុខអ្នកថ្មី');
  String get newUserRegisterOffer => _t(zh: '注册立享首单优惠', en: 'Register & save on your first order', vi: 'Đăng ký để được ưu đãi đơn đầu', km: 'ចុះឈ្មោះ សន្សំលើការបញ្ជាទិញដំបូង');
  String get unlockFeaturesDiscount => _t(zh: '解锁全部功能 + 专属折扣券', en: 'Unlock all features + exclusive discount', vi: 'Mở khóa tính năng + mã giảm giá độc quyền', km: 'ដោះសោមុខងារ + ការបញ្ចុះតម្លៃ');
  String get registerNowArrow => _t(zh: '立即注册  →', en: 'Register Now  →', vi: 'Đăng ký ngay  →', km: 'ចុះឈ្មោះឥឡូវ  →');
  // 服务分类
  String get catFullBodyMassage => _t(zh: '全身按摩', en: 'Full Body', vi: 'Toàn thân', km: 'ខ្លួនទាំងមូល');
  String get catOilSpa => _t(zh: '精油 SPA', en: 'Oil SPA', vi: 'SPA tinh dầu', km: 'SPA ប្រេង');
  String get catFootMassage => _t(zh: '足底按摩', en: 'Foot Massage', vi: 'Massage chân', km: 'ម៉ាស្សាជើង');
  String get catPostnatalCare => _t(zh: '产后护理', en: 'Postnatal', vi: 'Hậu sản', km: 'ក្រោយសម្រាល');
  String get catMerchantPartner => _t(zh: '商户合作', en: 'Partner', vi: 'Đối tác', km: 'ដៃគូ');
  // Banner 内容
  String get banner1Title => _t(zh: '专业上门按摩', en: 'Professional Home Massage', vi: 'Massage Tại Nhà', km: 'ម៉ាស្សាផ្ទះជំនាញ');
  String get banner1Sub => _t(zh: '5000+ 认证技师 · 随时上门服务', en: '5000+ certified therapists · On-demand', vi: '5000+ KTV chứng nhận · Phục vụ tận nơi', km: 'KTV ជាង 5000 · សេវាចល័ត');
  String get banner1Cta => _t(zh: '立即预约', en: 'Book Now', vi: 'Đặt Ngay', km: 'កក់ឥឡូវ');
  String get banner2Title => _t(zh: '精油 SPA 特惠', en: 'Oil SPA Special', vi: 'Ưu Đãi SPA Tinh Dầu', km: 'ការផ្ដល់ជូន SPA ប្រេង');
  String get banner2Sub => _t(zh: '芳香疗愈 · 深层放松 · 焕活身心', en: 'Aromatherapy · Deep relax · Revitalize', vi: 'Hương thơm · Thư giãn sâu · Hồi sinh', km: 'ព្យាបាលក្លិន · ស្ងប់ស្ងាត់ · ស្រស់ស្រាយ');
  String get banner2Cta => _t(zh: '查看活动', en: 'View Offers', vi: 'Xem Ưu Đãi', km: 'មើលការផ្ដល់ជូន');
  String get banner3Title => _t(zh: '新人首单折扣', en: 'New User Discount', vi: 'Giảm Giá Đơn Đầu', km: 'បញ្ចុះតម្លៃដំបូង');
  String get banner3Sub => _t(zh: '注册立享 8 折 + 专属优惠券', en: 'Register: 20% off + exclusive coupons', vi: 'Đăng ký: giảm 20% + phiếu ưu đãi', km: 'ចុះឈ្មោះ: បញ្ចុះ 20% + គូប៉ុង');
  String get banner3Cta => _t(zh: '立即领取', en: 'Claim Now', vi: 'Nhận Ngay', km: 'ទទួលឥឡូវ');
  // 技师标签
  String get tagFavoriteReturner => _t(zh: '回头客最爱', en: 'Top Returning', vi: 'Khách quay lại nhiều', km: 'ចំណូលចិត្តត្រឡប់');
  String get tagNewRecommended => _t(zh: '新人推荐', en: 'New & Recommended', vi: 'Mới & Đề xuất', km: 'ថ្មី & ណែនាំ');
  String get tagQualityService => _t(zh: '优质服务', en: 'Quality Service', vi: 'Dịch vụ chất lượng', km: 'សេវាល្អ');
  // 套餐
  String get pkg1Name => _t(zh: '香薰精油全身按摩', en: 'Aroma Oil Full Body', vi: 'Toàn thân tinh dầu hương thơm', km: 'ម៉ាស្សាទាំងខ្លួនប្រេងក្លិន');
  String get pkg1Desc => _t(zh: '90分钟 · 专业精油 · 深层放松', en: '90 mins · Pro oil · Deep relax', vi: '90 phút · Tinh dầu · Thư giãn sâu', km: '90 នាទី · ប្រេងឯកទេស · ស្ងប់ស្ងាត់');
  String get pkg2Name => _t(zh: '全身经络疏通', en: 'Full Body Meridian', vi: 'Thông kinh lạc toàn thân', km: 'ច្រកម៉េរីឌានទាំងខ្លួន');
  String get pkg2Desc => _t(zh: '60分钟 · 经络调理 · 缓解疲劳', en: '60 mins · Meridian · Fatigue relief', vi: '60 phút · Kinh lạc · Giảm mệt mỏi', km: '60 នាទី · ម៉េរីឌាន · ស្រោចស្រាល');
  // ==================== 设置页 ====================
  String get langAndLanguage => _t(zh: '语言 / Language', en: 'Language', vi: 'Ngôn ngữ', km: 'ភាសា');
  String get notifSettings => _t(zh: '通知设置', en: 'Notifications', vi: 'Cài đặt thông báo', km: 'ការកំណត់ការជូនដំណឹង');
  String get orderNotifTitle => _t(zh: '订单通知', en: 'Order Notifications', vi: 'Thông báo đơn hàng', km: 'ការជូនដំណឹងការបញ្ជាទិញ');
  String get orderNotifSubtitle => _t(zh: '接单、派单、完成等状态更新', en: 'Order accepted, dispatched & completed updates', vi: 'Cập nhật trạng thái đơn hàng', km: 'ការធ្វើបច្ចុប្បន្នភាពស្ថានភាព');
  String get promoNotifTitle => _t(zh: '优惠活动', en: 'Promotions', vi: 'Khuyến mãi', km: 'ការផ្ដល់ជូន');
  String get promoNotifSubtitle => _t(zh: '优惠券、限时特惠推送', en: 'Coupons and limited-time offers', vi: 'Phiếu ưu đãi và ưu đãi giới hạn', km: 'គូប៉ុងនិងការផ្ដល់ជូនតាមពេលវេលា');
  String get sysNotifTitle => _t(zh: '系统消息', en: 'System Messages', vi: 'Tin nhắn hệ thống', km: 'សារប្រព័ន្ធ');
  String get sysNotifSubtitle => _t(zh: '版本更新、安全提醒', en: 'App updates and security alerts', vi: 'Cập nhật ứng dụng và cảnh báo bảo mật', km: 'ការអាប់ដេតកម្មវិធី');
  String get biometric => _t(zh: '生物识别', en: 'Biometrics', vi: 'Sinh trắc học', km: 'ជីវមាត្រ');
  String get rateUs => _t(zh: '评价我们', en: 'Rate Us', vi: 'Đánh giá chúng tôi', km: 'វាយតម្លៃយើង');
  String get confirmLogout => _t(zh: '确认退出登录吗？', en: 'Are you sure you want to logout?', vi: 'Bạn có chắc muốn đăng xuất?', km: 'តើអ្នកប្រាកដចង់ចេញ?');

  // ==================== 技师相关 ====================
  String get technicianList => _t(zh: '技师列表', en: 'Therapist List', vi: 'Danh sách KTV', km: 'បញ្ជីអ្នកបច្ចេកទេស');
  String get technicianDetail => _t(zh: '技师详情', en: 'Therapist Profile', vi: 'Hồ sơ KTV', km: 'ព័ត៌មានលម្អិតអ្នកបច្ចេកទេស');
  String get smartSort => _t(zh: '智能排序', en: 'Smart Sort', vi: 'Sắp xếp thông minh', km: 'តម្រៀបឆ្លាត');
  String get serviceTime => _t(zh: '服务时段', en: 'Service Hours', vi: 'Giờ phục vụ', km: 'ម៉ោងសេវា');
  String get allFilters => _t(zh: '全部筛选', en: 'All Filters', vi: 'Tất cả bộ lọc', km: 'តម្រងទាំងអស់');
  String get listView => _t(zh: '列表', en: 'List', vi: 'Danh sách', km: 'បញ្ជី');
  String get mapView => _t(zh: '地图', en: 'Map', vi: 'Bản đồ', km: 'ផែនទី');
  String get skillFirst => _t(zh: '手法优先', en: 'Skill First', vi: 'Ưu tiên kỹ năng', km: 'ជំនាញមុនគេ');
  String get freeTransport => _t(zh: '免车费', en: 'Free Transport', vi: 'Miễn phí xe', km: 'ដំណើរចរណ៍ឥតគិតថ្លៃ');
  String get godCoupon => _t(zh: '神券技师', en: 'Coupon Therapist', vi: 'KTV phiếu ưu đãi', km: 'អ្នកបច្ចេកទេសកូប៉ុង');
  String get bookNow => _t(zh: '立即预订', en: 'Book Now', vi: 'Đặt ngay', km: 'កក់ឥឡូវ');
  String alreadyBooked(int n) => _t(zh: '已有${n}人预约', en: '$n people booked', vi: '$n người đã đặt', km: '$n នាក់បានកក់');
  String get onlineNow => _t(zh: '在线', en: 'Online', vi: 'Trực tuyến', km: 'អនឡាញ');
  String get offlineNow => _t(zh: '离线', en: 'Offline', vi: 'Ngoại tuyến', km: 'ក្រៅបណ្ដាញ');
  String get inService => _t(zh: '服务中', en: 'In Service', vi: 'Đang phục vụ', km: 'កំពុងសេវា');
  String get newArrival => _t(zh: '新到', en: 'New', vi: 'Mới', km: 'ថ្មី');
  String get returnCustomer => _t(zh: '超多回头客', en: 'Top Repeat Clients', vi: 'Khách quay lại nhiều', km: 'អតិថិជនវិលមកវិញ');
  String distance(String d) => _t(zh: '直线${d}km', en: '${d}km away', vi: 'Cách ${d}km', km: '${d}km');
  String get rating => _t(zh: '评分', en: 'Rating', vi: 'Đánh giá', km: 'ការវាយតម្លៃ');
  String goodReviews(int n) => _t(zh: '好评$n', en: '$n reviews', vi: '$n đánh giá tốt', km: 'ការវាយតម្លៃល្អ $n');
  String orders(int n) => _t(zh: '接单$n', en: '$n orders', vi: '$n đơn', km: 'ការបញ្ជាទិញ $n');
  String get services => _t(zh: '服务项目', en: 'Services', vi: 'Dịch vụ', km: 'សេវា');
  String get album => _t(zh: '相册', en: 'Album', vi: 'Album ảnh', km: 'អាល់ប៊ុម');
  String get reviews => _t(zh: '评价', en: 'Reviews', vi: 'Đánh giá', km: 'ការវាយតម្លៃ');
  String get favorite => _t(zh: '收藏', en: 'Favorite', vi: 'Yêu thích', km: 'ចូលចិត្ត');
  String get unfavorite => _t(zh: '已收藏', en: 'Unfavorite', vi: 'Đã yêu thích', km: 'បានចូលចិត្ត');
  String get introduction => _t(zh: '技师简介', en: 'Introduction', vi: 'Giới thiệu', km: 'ការណែនាំ');
  String get certification => _t(zh: '资质认证', en: 'Certification', vi: 'Chứng nhận', km: 'វិញ្ញាបនប័ត្រ');
  String get availableTime => _t(zh: '可预约时间', en: 'Available Time', vi: 'Thời gian có thể đặt', km: 'ម៉ោងអាចកក់');
  String get tomorrowAvailable => _t(zh: '明 00:30 可约', en: 'Tomorrow 00:30', vi: 'Ngày mai 00:30', km: 'ថ្ងៃស្អែក 00:30');

  // ==================== 套餐/服务 ====================
  String get servicePackage => _t(zh: '服务套餐', en: 'Service Package', vi: 'Gói dịch vụ', km: 'កញ្ចប់សេវា');
  String get serviceName => _t(zh: '服务名称', en: 'Service Name', vi: 'Tên dịch vụ', km: 'ឈ្មោះសេវា');
  String duration(int min) => _t(zh: '${min}分钟', en: '${min} mins', vi: '${min} phút', km: '${min} នាទី');
  String get originalPrice => _t(zh: '原价', en: 'Original Price', vi: 'Giá gốc', km: 'តម្លៃដើម');
  String get memberPriceLabel => _t(zh: '会员价', en: 'Member Price', vi: 'Giá hội viên', km: 'តម្លៃសមាជិក');
  String get selectPackage => _t(zh: '选择套餐', en: 'Select Package', vi: 'Chọn gói', km: 'ជ្រើសកញ្ចប់');

  // ==================== 下单/预约 ====================
  String get createOrder => _t(zh: '下单预约', en: 'Book Appointment', vi: 'Đặt lịch hẹn', km: 'ធ្វើការណាត់ជួប');
  String get selectService => _t(zh: '选择服务', en: 'Select Service', vi: 'Chọn dịch vụ', km: 'ជ្រើសរើសសេវា');
  String get selectDateTime => _t(zh: '选择时间', en: 'Select Date & Time', vi: 'Chọn ngày giờ', km: 'ជ្រើសរើសថ្ងៃ និងម៉ោង');
  String get selectAddress => _t(zh: '选择服务地址', en: 'Select Service Address', vi: 'Chọn địa chỉ', km: 'ជ្រើសរើសអាសយដ្ឋានសេវា');
  String get remarks => _t(zh: '备注（选填）', en: 'Remarks (Optional)', vi: 'Ghi chú (Tùy chọn)', km: 'ចំណាំ (ស្រេចចិត្ត)');
  String get selectCoupon => _t(zh: '选择优惠券', en: 'Select Coupon', vi: 'Chọn phiếu ưu đãi', km: 'ជ្រើស​គូប៉ុង');
  String get noCoupon => _t(zh: '暂不使用优惠券', en: 'No Coupon', vi: 'Không dùng phiếu', km: 'មិនប្រើគូប៉ុង');
  String get priceDetail => _t(zh: '价格明细', en: 'Price Details', vi: 'Chi tiết giá', km: 'ព័ត៌មានតម្លៃ');
  String get totalAmount => _t(zh: '合计', en: 'Total', vi: 'Tổng cộng', km: 'សរុប');
  String get discountAmount => _t(zh: '优惠减免', en: 'Discount', vi: 'Giảm giá', km: 'បញ្ចុះតម្លៃ');
  String get payAmount => _t(zh: '实付金额', en: 'Amount Due', vi: 'Số tiền phải trả', km: 'ចំនួនត្រូវបង់');
  String get submitOrder => _t(zh: '提交订单', en: 'Place Order', vi: 'Đặt đơn', km: 'ដាក់ការបញ្ជាទិញ');

  // ==================== 订单 ====================
  String get myOrders => _t(zh: '我的订单', en: 'My Orders', vi: 'Đơn hàng của tôi', km: 'ការបញ្ជាទិញរបស់ខ្ញុំ');
  String get orderDetail => _t(zh: '订单详情', en: 'Order Details', vi: 'Chi tiết đơn hàng', km: 'ព័ត៌មានលម្អិតការបញ្ជាទិញ');
  String get orderNo => _t(zh: '订单编号', en: 'Order No.', vi: 'Mã đơn hàng', km: 'លេខសម្គាល់ការបញ្ជាទិញ');
  String get orderStatusLabel => _t(zh: '订单状态', en: 'Order status', vi: 'Trạng thái đơn', km: 'ស្ថានភាពការបញ្ជាទិញ');
  String get orderPendingPay => _t(zh: '待支付', en: 'Pending Payment', vi: 'Chờ thanh toán', km: 'រង់ចាំការទូទាត់');
  String get orderPaid => _t(zh: '待服务', en: 'Waiting Service', vi: 'Chờ phục vụ', km: 'រង់ចាំសេវា');
  String get orderAccepted => _t(zh: '已接单', en: 'Accepted', vi: 'Đã nhận đơn', km: 'បានទទួល');
  String get orderInService => _t(zh: '服务中', en: 'In Progress', vi: 'Đang phục vụ', km: 'កំពុងបម្រើ');
  String get orderCompleted => _t(zh: '已完成', en: 'Completed', vi: 'Hoàn thành', km: 'បានបញ្ចប់');
  String get orderCancelled => _t(zh: '已取消', en: 'Cancelled', vi: 'Đã hủy', km: 'បានលុបចោល');
  String get orderRefunding => _t(zh: '退款中', en: 'Refunding', vi: 'Đang hoàn tiền', km: 'កំពុងដំណើរការការសង');
  String get orderRefunded => _t(zh: '已退款', en: 'Refunded', vi: 'Đã hoàn tiền', km: 'បានសងប្រាក់');
  String get cancelOrder => _t(zh: '取消订单', en: 'Cancel Order', vi: 'Hủy đơn', km: 'លុបចោលការបញ្ជាទិញ');
  String get confirmComplete => _t(zh: '确认完成', en: 'Confirm Complete', vi: 'Xác nhận hoàn thành', km: 'បញ្ជាក់ការបញ្ចប់');
  String get applyRefund => _t(zh: '申请退款', en: 'Apply Refund', vi: 'Yêu cầu hoàn tiền', km: 'ស្នើសុំការសង');
  String get trackLocation => _t(zh: '实时追踪', en: 'Track Location', vi: 'Theo dõi vị trí', km: 'តាមដានទីតាំង');
  String get contactTech => _t(zh: '联系技师', en: 'Contact Therapist', vi: 'Liên hệ KTV', km: 'ទំនាក់ទំនង KTV');
  String get reviewOrder => _t(zh: '评价', en: 'Review', vi: 'Đánh giá', km: 'វាយតម្លៃ');
  String get payBeforeExpiry => _t(zh: '请在15分钟内完成支付', en: 'Please pay within 15 minutes', vi: 'Vui lòng thanh toán trong 15 phút', km: 'សូមទូទាត់ក្នុងរយៈពេល 15 នាទី');
  String get serviceDatetime => _t(zh: '服务时间', en: 'Service Time', vi: 'Thời gian phục vụ', km: 'ម៉ោងសេវា');
  String get serviceAddressLabel => _t(zh: '服务地址', en: 'Service Address', vi: 'Địa chỉ phục vụ', km: 'អាសយដ្ឋានសេវា');
  String get technicianInfo => _t(zh: '技师信息', en: 'Therapist Info', vi: 'Thông tin KTV', km: 'ព័ត៌មានអ្នកបច្ចេកទេស');

  // ==================== 支付 ====================
  String get selectPayMethod => _t(zh: '选择支付方式', en: 'Select Payment', vi: 'Chọn phương thức thanh toán', km: 'ជ្រើសរើសវិធីបង់ប្រាក់');
  String get payWithUsdt => _t(zh: 'USDT 加密货币支付', en: 'USDT Crypto Payment', vi: 'Thanh toán USDT', km: 'ការទូទាត់ USDT');
  String get payWithAba => _t(zh: 'ABA 网银转账', en: 'ABA Bank Transfer', vi: 'Chuyển khoản ABA', km: 'ការផ្ទេរប្រាក់ ABA');
  String get payWithBalance => _t(zh: '余额支付', en: 'Pay with Balance', vi: 'Thanh toán số dư', km: 'បង់ដោយសមតុល្យ');
  String get payConfirm => _t(zh: '确认支付', en: 'Confirm Payment', vi: 'Xác nhận thanh toán', km: 'បញ្ជាក់ការទូទាត់');
  String get paySuccess => _t(zh: '支付成功！', en: 'Payment Successful!', vi: 'Thanh toán thành công!', km: 'ការទូទាត់ជោគជ័យ!');
  String get payFailed => _t(zh: '支付失败', en: 'Payment Failed', vi: 'Thanh toán thất bại', km: 'ការទូទាត់បានបរាជ័យ');
  String get payTimeout => _t(zh: '支付已超时', en: 'Payment Timeout', vi: 'Hết thời gian thanh toán', km: 'ការទូទាត់ផុតកំណត់');
  String get usdtAddress => _t(zh: '收款地址', en: 'Receive Address', vi: 'Địa chỉ nhận tiền', km: 'អាសយដ្ឋានទទួល');
  String get usdtNetwork => _t(zh: '转账网络', en: 'Network', vi: 'Mạng lưới', km: 'បណ្ដាញ');
  String get usdtAmount => _t(zh: 'USDT 金额', en: 'USDT Amount', vi: 'Số lượng USDT', km: 'ចំនួន USDT');
  String get usdtTips => _t(zh: '转账时请备注订单号', en: 'Include order no. in memo', vi: 'Ghi mã đơn trong ghi chú', km: 'សូមរួមបញ្ចូលលេខបញ្ជាទិញ');
  String get copyAddress => _t(zh: '复制地址', en: 'Copy Address', vi: 'Sao chép địa chỉ', km: 'ចម្លងអាសយដ្ឋាន');
  String get abaAccountName => _t(zh: '收款账户名', en: 'Account Name', vi: 'Tên tài khoản', km: 'ឈ្មោះគណនី');
  String get abaAccountNo => _t(zh: '账户号', en: 'Account No.', vi: 'Số tài khoản', km: 'លេខគណនី');
  String get abaPhone => _t(zh: '收款手机号', en: 'ABA Phone', vi: 'Số điện thoại ABA', km: 'លេខទូរស័ព្ទ ABA');
  String get uploadProof => _t(zh: '上传转账截图', en: 'Upload Transfer Proof', vi: 'Tải ảnh chứng minh', km: 'ផ្ទុករូបភាពការផ្ទេរប្រាក់');
  String get iHavePaid => _t(zh: '我已完成转账', en: 'I Have Transferred', vi: 'Tôi đã chuyển khoản', km: 'ខ្ញុំបានផ្ទេរប្រាក់ហើយ');
  String get payTimeRemaining => _t(zh: '支付剩余时间', en: 'Time Remaining', vi: 'Thời gian còn lại', km: 'ពេលវេលានៅសល់');
  String get balanceAmount => _t(zh: '账户余额', en: 'Balance', vi: 'Số dư tài khoản', km: 'សមតុល្យគណនី');
  String get insufficientBalance => _t(zh: '余额不足，请充值', en: 'Insufficient balance, top up now', vi: 'Số dư không đủ, hãy nạp tiền', km: 'សមតុល្យមិនគ្រប់គ្រាន់');

  // ==================== 评价 ====================
  String get writeReview => _t(zh: '写评价', en: 'Write Review', vi: 'Viết đánh giá', km: 'សរសេរការពិនិត្យ');
  String get overallRating => _t(zh: '综合评分', en: 'Overall Rating', vi: 'Đánh giá tổng thể', km: 'ការវាយតម្លៃទូទៅ');
  String get techniqueScore => _t(zh: '手法评分', en: 'Technique', vi: 'Đánh giá kỹ thuật', km: 'ការវាយតម្លៃបច្ចេកទេស');
  String get attitudeScore => _t(zh: '服务态度', en: 'Attitude', vi: 'Thái độ phục vụ', km: 'ការប្រព្រឹត្ត');
  String get punctualityScore => _t(zh: '准时评分', en: 'Punctuality', vi: 'Đúng giờ', km: 'ពេលវេលា');
  String get reviewContent => _t(zh: '说说您的感受...', en: 'Share your experience...', vi: 'Chia sẻ trải nghiệm...', km: 'ចែករំលែកបទពិសោធន៍...');
  String get reviewTags => _t(zh: '评价标签', en: 'Review Tags', vi: 'Thẻ đánh giá', km: 'ស្លាកការពិនិត្យ');
  String get anonymous => _t(zh: '匿名评价', en: 'Anonymous Review', vi: 'Đánh giá ẩn danh', km: 'ការពិនិត្យអនាមិក');
  String get addPhoto => _t(zh: '添加图片', en: 'Add Photo', vi: 'Thêm ảnh', km: 'បន្ថែមរូបភាព');
  String get submitReview => _t(zh: '提交评价', en: 'Submit Review', vi: 'Gửi đánh giá', km: 'ដាក់ការពិនិត្យ');

  // ==================== 个人中心 ====================
  String get myProfile => _t(zh: '个人中心', en: 'My Profile', vi: 'Hồ sơ cá nhân', km: 'គណនីរបស់ខ្ញុំ');
  String get editProfile => _t(zh: '编辑资料', en: 'Edit Profile', vi: 'Chỉnh sửa hồ sơ', km: 'កែប្រែព័ត៌មានផ្ទាល់ខ្លួន');
  String get nickname => _t(zh: '昵称', en: 'Nickname', vi: 'Biệt danh', km: 'ឈ្មោះហៅ');
  String get birthday => _t(zh: '生日', en: 'Birthday', vi: 'Sinh nhật', km: 'ខួបកំណើត');
  String get gender => _t(zh: '性别', en: 'Gender', vi: 'Giới tính', km: 'ភេទ');
  String get male => _t(zh: '男', en: 'Male', vi: 'Nam', km: 'ប្រុស');
  String get female => _t(zh: '女', en: 'Female', vi: 'Nữ', km: 'ស្រី');
  String get myFavorites => _t(zh: '我的收藏', en: 'My Favorites', vi: 'Yêu thích', km: 'ចំណូលចិត្តរបស់ខ្ញុំ');
  String get myReviews => _t(zh: '我的评价', en: 'My Reviews', vi: 'Đánh giá của tôi', km: 'ការពិនិត្យរបស់ខ្ញុំ');
  String get addressManage => _t(zh: '地址管理', en: 'Address Management', vi: 'Quản lý địa chỉ', km: 'ការគ្រប់គ្រងអាសយដ្ឋាន');
  String get inviteFriends => _t(zh: '邀请好友', en: 'Invite Friends', vi: 'Mời bạn bè', km: 'អញ្ជើញមិត្តភ័ក្ត');
  String get accountSecurity => _t(zh: '账号安全', en: 'Account Security', vi: 'Bảo mật tài khoản', km: 'សុវត្ថិភាពគណនី');
  String get changePhone => _t(zh: '绑定手机', en: 'Bind Phone', vi: 'Liên kết số điện thoại', km: 'ចងភ្ជាប់ទូរស័ព្ទ');
  String get changePassword => _t(zh: '修改密码', en: 'Change Password', vi: 'Đổi mật khẩu', km: 'ប្ដូរពាក្យសម្ងាត់');
  String get language => _t(zh: '语言设置', en: 'Language', vi: 'Ngôn ngữ', km: 'ភាសា');
  String get helpCenter => _t(zh: '帮助中心', en: 'Help Center', vi: 'Trung tâm trợ giúp', km: 'មជ្ឈមណ្ឌលជំនួយ');
  String get contactUs => _t(zh: '联系客服', en: 'Contact Support', vi: 'Liên hệ hỗ trợ', km: 'ទំនាក់ទំនងការគាំទ្រ');
  String get aboutUs => _t(zh: '关于我们', en: 'About Us', vi: 'Về chúng tôi', km: 'អំពីយើង');
  String get settings => _t(zh: '设置', en: 'Settings', vi: 'Cài đặt', km: 'ការកំណត់');
  String get signIn => _t(zh: '每日签到', en: 'Daily Check-in', vi: 'Điểm danh hàng ngày', km: 'ចុះឈ្មោះប្រចាំថ្ងៃ');
  String get memberLevel => _t(zh: '会员等级', en: 'Member Level', vi: 'Cấp hội viên', km: 'កម្រិតសមាជិក');
  String get points => _t(zh: '我的积分', en: 'My Points', vi: 'Điểm của tôi', km: 'ពិន្ទុរបស់ខ្ញុំ');

  // ==================== 钱包 ====================
  String get myWallet => _t(zh: '我的钱包', en: 'My Wallet', vi: 'Ví của tôi', km: 'កាបូបរបស់ខ្ញុំ');
  String get balance => _t(zh: '可用余额', en: 'Available Balance', vi: 'Số dư khả dụng', km: 'សមតុល្យដែលអាចប្រើ');
  String get recharge => _t(zh: '充值', en: 'Top Up', vi: 'Nạp tiền', km: 'បញ្ចូលប្រាក់');
  String get withdraw => _t(zh: '提现', en: 'Withdraw', vi: 'Rút tiền', km: 'ដកប្រាក់');
  String get transactions => _t(zh: '交易记录', en: 'Transactions', vi: 'Lịch sử giao dịch', km: 'ប្រវត្តិប្រតិបត្តិការ');
  String get income => _t(zh: '收入', en: 'Income', vi: 'Thu nhập', km: 'ប្រាក់ចំណូល');
  String get expense => _t(zh: '支出', en: 'Expense', vi: 'Chi tiêu', km: 'ការចំណាយ');
  String get withdrawAmount => _t(zh: '提现金额', en: 'Withdraw Amount', vi: 'Số tiền rút', km: 'ចំនួនទឹកប្រាក់ដក');
  String get withdrawAccount => _t(zh: '提现账户', en: 'Withdraw Account', vi: 'Tài khoản rút tiền', km: 'គណនីដក');
  String get bindUsdtWallet => _t(zh: '绑定 USDT 钱包', en: 'Bind USDT Wallet', vi: 'Liên kết ví USDT', km: 'ភ្ជាប់កាបូប USDT');
  String get bindAbaAccount => _t(zh: '绑定 ABA 账户', en: 'Bind ABA Account', vi: 'Liên kết tài khoản ABA', km: 'ភ្ជាប់គណនី ABA');
  String get frozenBalance => _t(zh: '冻结金额', en: 'Frozen Balance', vi: 'Số dư bị đóng băng', km: 'សមតុល្យដែលបានបិទ');
  String get minWithdraw => _t(zh: '最低提现金额 \$10', en: 'Min. withdraw \$10', vi: 'Rút tối thiểu \$10', km: 'ដក​យ​ lowest \$10');

  // ==================== 优惠券 ====================
  String get myCoupons => _t(zh: '我的优惠券', en: 'My Coupons', vi: 'Phiếu ưu đãi của tôi', km: 'គូប៉ុងរបស់ខ្ញុំ');
  String get couponCenter => _t(zh: '领券中心', en: 'Coupon Center', vi: 'Trung tâm phiếu', km: 'មជ្ឈមណ្ឌលគូប៉ុង');
  String get unusedCoupon => _t(zh: '未使用', en: 'Unused', vi: 'Chưa dùng', km: 'មិនទាន់ប្រើ');
  String get usedCoupon => _t(zh: '已使用', en: 'Used', vi: 'Đã dùng', km: 'បានប្រើ');
  String get expiredCoupon => _t(zh: '已过期', en: 'Expired', vi: 'Hết hạn', km: 'ផុតកំណត់');
  String get getCoupon => _t(zh: '立即领取', en: 'Get Coupon', vi: 'Nhận ngay', km: 'ទទួលគូប៉ុង');
  String couponMinAmount(String amt) => _t(zh: '满${amt}可用', en: 'Min. ${amt}', vi: 'Tối thiểu ${amt}', km: 'យ​ lowest ${amt}');
  String couponExpiry(String date) => _t(zh: '有效期至 $date', en: 'Valid until $date', vi: 'Hết hạn $date', km: 'ផុតកំណត់ $date');
  String get discountCoupon => _t(zh: '折扣券', en: 'Discount', vi: 'Phiếu giảm giá', km: 'ប័ណ្ណបញ្ចុះ');
  String get cashCoupon => _t(zh: '代金券', en: 'Cash Voucher', vi: 'Phiếu tiền mặt', km: 'ប័ណ្ណសាច់ប្រាក់');
  String get freeTransportCoupon => _t(zh: '免车费券', en: 'Free Transport', vi: 'Phiếu miễn xe', km: 'ប័ណ្ណដឹកជញ្ជូនដោយឥតគិតថ្លៃ');

  // ==================== IM ====================
  String get messages => _t(zh: '消息', en: 'Messages', vi: 'Tin nhắn', km: 'សារ');
  String get typeMessage => _t(zh: '输入消息...', en: 'Type a message...', vi: 'Nhập tin nhắn...', km: 'វាយបញ្ចូលសារ...');
  String get sendImage => _t(zh: '发送图片', en: 'Send Photo', vi: 'Gửi ảnh', km: 'ផ្ញើរូបភាព');
  String get recalledMessage => _t(zh: '消息已撤回', en: 'Message recalled', vi: 'Tin nhắn đã thu hồi', km: 'សារត្រូវបានដកវិញ');
  String get onlineService => _t(zh: '在线客服', en: 'Online Support', vi: 'Hỗ trợ trực tuyến', km: 'ជំនួយអនឡាញ');

  // ==================== 发现页 ====================
  String get discoverPage => _t(zh: '发现', en: 'Discover', vi: 'Khám phá', km: 'រកឃើញ');
  String get recommended => _t(zh: '推荐', en: 'Recommended', vi: 'Đề xuất', km: 'ណែនាំ');
  String get followedPosts => _t(zh: '关注', en: 'Following', vi: 'Đang theo dõi', km: 'ការតាមដាន');
  String likes(int n) => _t(zh: '$n', en: '$n', vi: '$n', km: '$n');

  // ==================== 技师工作台 ====================
  String get workbench => _t(zh: '工作台', en: 'Dashboard', vi: 'Bảng điều khiển', km: 'ផ្ទាំងគ្រប់គ្រង');
  String get goOnline => _t(zh: '上线接单', en: 'Go Online', vi: 'Bắt đầu nhận đơn', km: 'ចាប់ផ្ដើមទទួលការបញ្ជាទិញ');
  String get goOffline => _t(zh: '下线', en: 'Go Offline', vi: 'Ngoại tuyến', km: 'ក្រៅបណ្ដាញ');
  String get todayIncome => _t(zh: '今日收入', en: "Today's Income", vi: 'Thu nhập hôm nay', km: 'ប្រាក់ចំណូលថ្ងៃនេះ');
  String get todayOrders => _t(zh: '今日接单', en: "Today's Orders", vi: 'Đơn hàng hôm nay', km: 'ការបញ្ជាទិញថ្ងៃនេះ');
  String get newOrderAlert => _t(zh: '您有新订单！', en: 'New Order!', vi: 'Đơn hàng mới!', km: 'ការបញ្ជាទិញថ្មី!');
  String get acceptOrder => _t(zh: '接单', en: 'Accept', vi: 'Nhận đơn', km: 'ទទួល');
  String get rejectOrder => _t(zh: '拒单', en: 'Reject', vi: 'Từ chối', km: 'បដិសេធ');
  String get navigate => _t(zh: '导航', en: 'Navigate', vi: 'Dẫn đường', km: 'រុករក');
  String get startService => _t(zh: '开始服务', en: 'Start Service', vi: 'Bắt đầu phục vụ', km: 'ចាប់ផ្ដើមបម្រើ');
  String get endService => _t(zh: '结束服务', en: 'End Service', vi: 'Kết thúc phục vụ', km: 'បញ្ចប់ការបម្រើ');
  String get schedule => _t(zh: '排班管理', en: 'Schedule', vi: 'Quản lý lịch', km: 'ការគ្រប់គ្រងតារាង');
  String get serviceRadius => _t(zh: '接单范围', en: 'Service Radius', vi: 'Bán kính phục vụ', km: 'ពារ៉ាម៉ែត្រសេវា');

  // ==================== 商户端 ====================
  String get merchantDashboard => _t(zh: '商户数据看板', en: 'Merchant Dashboard', vi: 'Bảng điều khiển thương nhân', km: 'ផ្ទាំងអ្នកលក់');
  String get manageTech => _t(zh: '技师管理', en: 'Manage Therapists', vi: 'Quản lý KTV', km: 'គ្រប់គ្រង KTV');
  String get financialReport => _t(zh: '财务报表', en: 'Financial Report', vi: 'Báo cáo tài chính', km: 'របាយការណ៍ហិរញ្ញវត្ថុ');
  String get totalRevenue => _t(zh: '总收入', en: 'Total Revenue', vi: 'Tổng doanh thu', km: 'ចំណូលសរុប');
  String get onlineTech => _t(zh: '在线技师', en: 'Online Therapists', vi: 'KTV trực tuyến', km: 'អ្នកបច្ចេកទេសអនឡាញ');

  // ==================== 地址 ====================
  String get addAddress => _t(zh: '添加地址', en: 'Add Address', vi: 'Thêm địa chỉ', km: 'បន្ថែមអាសយដ្ឋាន');
  String get editAddress => _t(zh: '编辑地址', en: 'Edit Address', vi: 'Sửa địa chỉ', km: 'កែប្រែអាសយដ្ឋាន');
  String get contactName => _t(zh: '联系人姓名', en: 'Contact Name', vi: 'Tên liên hệ', km: 'ឈ្មោះទំនាក់ទំនង');
  String get contactPhone => _t(zh: '联系人电话', en: 'Contact Phone', vi: 'Điện thoại liên hệ', km: 'ទូរស័ព្ទទំនាក់ទំនង');
  String get detailAddress => _t(zh: '详细地址', en: 'Detail Address', vi: 'Địa chỉ chi tiết', km: 'អាសយដ្ឋានលម្អិត');
  String get setDefault => _t(zh: '设为默认', en: 'Set Default', vi: 'Đặt mặc định', km: 'កំណត់ជាលំនាំដើម');
  String get defaultAddress => _t(zh: '默认', en: 'Default', vi: 'Mặc định', km: 'លំនាំដើម');
  String get useCurrentLocation => _t(zh: '使用当前位置', en: 'Use Current Location', vi: 'Dùng vị trí hiện tại', km: 'ប្រើទីតាំងបច្ចុប្បន្ន');

  // ==================== 邀请 ====================
  String get myInviteCode => _t(zh: '我的邀请码', en: 'My Invite Code', vi: 'Mã mời của tôi', km: 'លេខកូដអញ្ជើញរបស់ខ្ញុំ');
  String get inviteDesc => _t(zh: '邀请好友注册，双方各得优惠券', en: 'Invite friends to earn coupons for both', vi: 'Mời bạn bè, cả hai nhận phiếu ưu đãi', km: 'អញ្ជើញមិត្ត ទទួលគូប៉ុងទាំងពីរ');
  String get shareLink => _t(zh: '分享链接', en: 'Share Link', vi: 'Chia sẻ liên kết', km: 'ចែករំលែកតំណ');

  // ==================== 错误/状态 ====================
  String get loginExpired => _t(zh: '登录已过期，请重新登录', en: 'Session expired, please login again', vi: 'Phiên đăng nhập hết hạn', km: 'វគ្គផុតកំណត់');
  String get permissionDenied => _t(zh: '权限不足', en: 'Permission Denied', vi: 'Không có quyền', km: 'គ្មានការអនុញ្ញាត');
  String get locationPermissionTip => _t(zh: '需要位置权限以显示附近技师', en: 'Location permission needed to show nearby therapists', vi: 'Cần quyền vị trí', km: 'ត្រូវការការអនុញ្ញាតទីតាំង');
  String get cameraPermissionTip => _t(zh: '需要相机权限以上传图片', en: 'Camera permission needed for uploading', vi: 'Cần quyền camera', km: 'ត្រូវការការអនុញ្ញាតកាមេរ៉ា');
  String get copied => _t(zh: '已复制到剪贴板', en: 'Copied to clipboard', vi: 'Đã sao chép', km: 'បានចម្លង');
  String get operationSuccess => _t(zh: '操作成功', en: 'Operation successful', vi: 'Thao tác thành công', km: 'ប្រតិបត្តិការជោគជ័យ');
  String get operationFailed => _t(zh: '操作失败，请重试', en: 'Operation failed, please retry', vi: 'Thao tác thất bại', km: 'ប្រតិបត្តិការបានបរាជ័យ');
  String get updateAvailable => _t(zh: '发现新版本，请更新', en: 'Update available', vi: 'Có phiên bản mới', km: 'មានការអាប់ដេតថ្មី');
  String get locationUpdating => _t(zh: '正在定位...', en: 'Getting location...', vi: 'Đang định vị...', km: 'កំពុងកំណត់ទីតាំង...');

  // ==================== 忘记密码 ====================
  String get resetPasswordTitle => _t(zh: '重置密码', en: 'Reset Password', vi: 'Đặt lại mật khẩu', km: 'កំណត់ពាក្យសម្ងាត់ឡើងវិញ');
  String get resetPasswordStepVerify => _t(zh: '验证手机', en: 'Verify phone', vi: 'Xác minh SĐT', km: 'ផ្ទៀងផ្ទាត់ទូរស័ព្ទ');
  String get resetPasswordStepNewPwd => _t(zh: '新密码', en: 'New password', vi: 'Mật khẩu mới', km: 'ពាក្យសម្ងាត់ថ្មី');
  String stepIndicator(int cur, int total) =>
      _t(zh: '第 $cur/$total 步', en: 'Step $cur/$total', vi: 'Bước $cur/$total', km: 'ជំហាន $cur/$total');
  String get passwordStrengthLabel => _t(zh: '密码强度', en: 'Password strength', vi: 'Độ mạnh mật khẩu', km: 'កម្លាំងពាក្យសម្ងាត់');
  String get passwordWeak => _t(zh: '弱', en: 'Weak', vi: 'Yếu', km: 'ខ្សោយ');
  String get passwordMedium => _t(zh: '中', en: 'Medium', vi: 'Trung bình', km: 'មធ្យម');
  String get passwordStrong => _t(zh: '强', en: 'Strong', vi: 'Mạnh', km: 'ខ្លាំង');
  String get backToLogin => _t(zh: '返回登录', en: 'Back to Login', vi: 'Quay lại đăng nhập', km: 'ត្រឡប់ទៅចូល');
  String get confirmResetPassword => _t(zh: '确认重置', en: 'Confirm reset', vi: 'Xác nhận đặt lại', km: 'បញ្ជាក់កំណត់ឡើងវិញ');

  // ==================== 收藏夹 ====================
  String get removeFromFavorites => _t(zh: '取消收藏', en: 'Remove from favorites', vi: 'Bỏ yêu thích', km: 'យកចេញពីចំណូលចិត្ត');
  String removeFavoriteConfirm(String name) => _t(
        zh: '确定将「$name」从收藏中移除？',
        en: 'Remove "$name" from favorites?',
        vi: 'Bỏ "$name" khỏi yêu thích?',
        km: 'យក "$name" ចេញពីចំណូលចិត្ត?',
      );
  String get favoritesEmptyTitle => _t(zh: '暂无收藏', en: 'No favorites yet', vi: 'Chưa có mục yêu thích', km: 'មិនទាន់មានចំណូលចិត្ត');
  String get favoritesEmptySubtitle => _t(zh: '长按卡片可取消收藏', en: 'Long-press a card to remove it', vi: 'Nhấn giữ thẻ để bỏ yêu thích', km: 'ចុចឱ្យជាប់លើកាតដើម្បីយកចេញ');
  String get tagTop => _t(zh: 'TOP', en: 'TOP', vi: 'TOP', km: 'TOP');

  // ==================== 充值 ====================
  String get currentBalance => _t(zh: '当前余额', en: 'Current balance', vi: 'Số dư hiện tại', km: 'សមតុល្យបច្ចុប្បន្ន');
  String get customAmount => _t(zh: '自定义金额', en: 'Custom amount', vi: 'Số tiền tùy chỉnh', km: 'ចំនួនផ្ទាល់ខ្លួន');
  String get confirmRecharge => _t(zh: '确认充值', en: 'Confirm top-up', vi: 'Xác nhận nạp tiền', km: 'បញ្ជាក់បញ្ចូលប្រាក់');
  String get rechargeArrivalNote => _t(
        zh: '转账成功后约5分钟内到账',
        en: 'Funds credited within 5 minutes after transfer',
        vi: 'Tiền sẽ về trong khoảng 5 phút sau khi chuyển',
        km: 'ប្រាក់នឹងចូលក្នុងរយៈពេល 5 នាទីបន្ទាប់ពីផ្ទេរ',
      );
  String get usdtRechargeSubtitle => _t(zh: 'TRC20 · 低手续费', en: 'TRC20 · Low fees', vi: 'TRC20 · Phí thấp', km: 'TRC20 · ថ្លៃទាប');
  String get abaRechargeSubtitle => _t(zh: 'ABA 网银即时转账', en: 'ABA online transfer', vi: 'Chuyển khoản ABA trực tuyến', km: 'ផ្ទេរអនឡាញ ABA');

  // ==================== 提现 ====================
  String get withdrawMethod => _t(zh: '提现方式', en: 'Withdrawal method', vi: 'Phương thức rút tiền', km: 'វិធីដកប្រាក់');
  String get usdtWalletLabel => _t(zh: 'USDT 钱包', en: 'USDT wallet', vi: 'Ví USDT', km: 'កាបូប USDT');
  String get abaAccountLabel => _t(zh: 'ABA 账户', en: 'ABA account', vi: 'Tài khoản ABA', km: 'គណនី ABA');
  String get scanQrCode => _t(zh: '扫码', en: 'Scan QR', vi: 'Quét QR', km: 'ស្កេន QR');
  String get saveAccountForNextTime => _t(zh: '保存账户供下次使用', en: 'Save account for next time', vi: 'Lưu tài khoản cho lần sau', km: 'រក្សាទុកគណនីសម្រាប់ពេលក្រោយ');
  String get platformFeeOnePercent => _t(zh: '平台手续费：1%', en: 'Platform fee: 1%', vi: 'Phí nền tảng: 1%', km: 'ថ្លៃវេទិកា៖ 1%');
  String get confirmWithdraw => _t(zh: '确认提现', en: 'Confirm withdrawal', vi: 'Xác nhận rút tiền', km: 'បញ្ជាក់ដកប្រាក់');
  String get withdrawSubmitConfirmMessage => _t(
        zh: '确认提交提现申请？',
        en: 'Submit this withdrawal request?',
        vi: 'Gửi yêu cầu rút tiền?',
        km: 'ដាក់ស្នើសុំដកប្រាក់?',
      );
  String get enterWalletAddress => _t(zh: '请输入钱包地址', en: 'Enter wallet address', vi: 'Nhập địa chỉ ví', km: 'បញ្ចូលអាសយដ្ឋានកាបូប');
  String get withdrawMaxHint => _t(zh: '不超过可用余额', en: 'Cannot exceed available balance', vi: 'Không vượt số dư khả dụng', km: 'មិនអាចលើសសមតុល្យ');
  String withdrawReceiveApprox(String amt) => _t(
        zh: '预计到账约 $amt',
        en: 'Estimated to receive ~$amt',
        vi: 'Dự kiến nhận ~$amt',
        km: 'ប៉ាន់ស្មានទទួលបាន ~$amt',
      );

  // ==================== 退款 ====================
  String get orderSummary => _t(zh: '订单信息', en: 'Order summary', vi: 'Thông tin đơn', km: 'សង្ខេបការបញ្ជាទិញ');
  String get amountPaidLabel => _t(zh: '实付金额', en: 'Amount paid', vi: 'Số đã thanh toán', km: 'ចំនួនបានបង់');
  String get refundReason => _t(zh: '退款原因', en: 'Refund reason', vi: 'Lý do hoàn tiền', km: 'មូលហេតុសងប្រាក់');
  String get refundReasonNotArrived => _t(zh: '技师未到达', en: 'Therapist did not arrive', vi: 'KTV không đến', km: 'អ្នកបច្ចេកទេសមិនបានមក');
  String get refundReasonMismatch => _t(zh: '服务与描述不符', en: 'Service did not match description', vi: 'Dịch vụ không khớp mô tả', km: 'សេវាមិនត្រូវនឹងការពិពណ៌នា');
  String get refundReasonCancel => _t(zh: '临时取消', en: 'Last-minute cancellation', vi: 'Hủy đột xuất', km: 'លុបចោលភ្លាមៗ');
  String get refundReasonOther => _t(zh: '其他', en: 'Other', vi: 'Khác', km: 'ផ្សេងទៀត');
  String get refundOtherReasonHint => _t(zh: '请填写其他原因', en: 'Please describe', vi: 'Vui lòng mô tả', km: 'សូមពិពណ៌នា');
  String get estimatedRefundAmount => _t(zh: '退款金额', en: 'Refund amount', vi: 'Số tiền hoàn', km: 'ចំនួនសង');
  String get refundOriginalMethodNote => _t(
        zh: '将退回至原支付方式，预计1-3个工作日到账',
        en: 'Will be refunded to the original payment method within 1-3 business days',
        vi: 'Hoàn về phương thức thanh toán ban đầu trong 1-3 ngày làm việc',
        km: 'នឹងសងត្រឡប់ទៅវិធីបង់ប្រាក់ដើមក្នុង 1-3 ថ្ងៃធ្វើការ',
      );
  String get refundEvidenceOptional => _t(zh: '凭证照片（选填）', en: 'Photo evidence (optional)', vi: 'Ảnh minh chứng (tùy chọn)', km: 'រូបភាពភស្តុតាង (ស្រេចចិត្ត)');

  // ==================== 技师/商户端导航 ====================
  String get workspace         => _t(zh: '工作台',   en: 'Workspace',    vi: 'Bảng điều khiển',   km: 'ផ្ទាំងធ្វើការ');
  String get myShop            => _t(zh: '我的店铺',  en: 'My Store',     vi: 'Cửa hàng của tôi', km: 'ហាងរបស់ខ្ញុំ');
  String get techMgmt          => _t(zh: '技师',      en: 'Therapists',   vi: 'KTV',               km: 'អ្នកបច្ចេកទេស');
  String get orderMgmt         => _t(zh: '订单',      en: 'Orders',       vi: 'Đơn hàng',          km: 'ការបញ្ជាទិញ');

  // ==================== 状态标签 ====================
  String get online            => _t(zh: '在线',      en: 'Online',       vi: 'Trực tuyến',        km: 'អនឡាញ');
  String get offline           => _t(zh: '离线',      en: 'Offline',      vi: 'Ngoại tuyến',       km: 'គ្មានអ៊ីនធឺណិត');
  String get onlineWithTap     => _t(zh: '接单中 · 点击下线', en: 'Active · Tap to go offline',  vi: 'Đang nhận đơn · Tắt trực tuyến', km: 'កំពុងទទួល · ចុចដើម្បីចាកចេញ');
  String get offlineWithTap    => _t(zh: '已下线 · 点击上线', en: 'Offline · Tap to go online',  vi: 'Ngoại tuyến · Bật trực tuyến',  km: 'គ្មានអ៊ីនធឺណិត · ចុចដើម្បីចូលអនឡាញ');
  String get pending           => _t(zh: '待处理',    en: 'Pending',      vi: 'Chờ xử lý',         km: 'រង់ចាំ');
  String get pendingConfirm    => _t(zh: '待确认',    en: 'Pending',      vi: 'Chờ xác nhận',      km: 'រង់ចាំបញ្ជាក់');
  String get inProgress        => _t(zh: '进行中',    en: 'In Progress',  vi: 'Đang xử lý',        km: 'កំពុងដំណើរការ');
  String get completed         => _t(zh: '已完成',    en: 'Completed',    vi: 'Hoàn thành',         km: 'បានបញ្ចប់');
  String get newOrder          => _t(zh: '新订单',    en: 'New Order',    vi: 'Đơn mới',            km: 'ការបញ្ជាទិញថ្មី');
  String get serviceInProgress => _t(zh: '服务进行中', en: 'In Progress', vi: 'Đang phục vụ',      km: 'កំពុងបម្រើ');

  // ==================== 数据指标 ====================
  String get totalOrders      => _t(zh: '累计订单',   en: 'Total Orders',    vi: 'Tổng đơn',         km: 'សរុបការបញ្ជាទិញ');
  String get myIncome         => _t(zh: '我的收益',   en: 'My Income',       vi: 'Thu nhập của tôi', km: 'ប្រាក់ចំណូល');
  String get accountBalance   => _t(zh: '账户余额',   en: 'Balance',         vi: 'Số dư',             km: 'សមតុល្យ');
  String get monthIncome      => _t(zh: '本月收益',   en: 'Monthly Income',  vi: 'Thu nhập tháng',   km: 'ប្រាក់ចំណូលខែ');
  String get withdrawable     => _t(zh: '可提现',     en: 'Withdrawable',    vi: 'Có thể rút',       km: 'អាចដក');
  String get monthlyTrend     => _t(zh: '本月收益走势', en: 'Monthly Trend', vi: 'Xu hướng tháng',  km: 'និន្នាការខែ');
  String get incomeDetails    => _t(zh: '收益明细',   en: 'Income Details',  vi: 'Chi tiết thu nhập', km: 'ព័ត៌មានប្រាក់ចំណូល');
  String get todayRevenue     => _t(zh: '今日营业额', en: "Today's Revenue", vi: 'Doanh thu hôm nay', km: 'ចំណូលថ្ងៃនេះ');
  String get todayRevenueShort => _t(zh: '今日营收',  en: 'Today',           vi: 'Hôm nay',          km: 'ថ្ងៃនេះ');
  String get monthlyRevenue   => _t(zh: '本月营收',   en: 'Monthly Revenue', vi: 'Doanh thu tháng',  km: 'ចំណូលខែ');
  String get onlineTechsLabel => _t(zh: '在线技师',   en: 'Online Techs',    vi: 'KTV trực tuyến',   km: 'អ្នកបច្ចេកទេស');
  String get avgRatingLabel   => _t(zh: '综合评分',   en: 'Avg Rating',      vi: 'Đánh giá TB',      km: 'ការវាយតម្លៃ');
  String get weeklyRevenue    => _t(zh: '本周收益',   en: 'Weekly Revenue',  vi: 'Doanh thu tuần',  km: 'ចំណូលសប្ដាហ៍');
  String get dailyRanking     => _t(zh: '今日技师排行', en: "Today's Ranking", vi: 'Bảng xếp hạng',  km: 'ចំណាត់ថ្នាក់');
  String get quickEntry       => _t(zh: '快捷入口',   en: 'Quick Entry',     vi: 'Lối vào nhanh',   km: 'ចូលលឿន');
  String get noOrders         => _t(zh: '暂无订单',   en: 'No Orders',       vi: 'Không có đơn',    km: 'គ្មានការបញ្ជាទិញ');
  String nMinutes(int n)      => _t(zh: '${n}分钟',   en: '${n}min',         vi: '${n} phút',       km: '$n នាទី');
  String nOrdersCount(int n)  => _t(zh: '${n}单',     en: '$n orders',       vi: '$n đơn',          km: '$n ការ');

  // ==================== 操作按钮 ====================
  String get applyWithdraw    => _t(zh: '申请提现',   en: 'Withdraw',        vi: 'Rút tiền',         km: 'ដកប្រាក់');
  String get availableHint    => _t(zh: '可提现余额：', en: 'Available: ',    vi: 'Có thể rút: ',    km: 'អាចដក: ');
  String get completeService  => _t(zh: '完成服务',   en: 'Complete',        vi: 'Hoàn thành',       km: 'បញ្ចប់');
  String get navigateBtn      => _t(zh: '导航',       en: 'Navigate',        vi: 'Điều hướng',       km: 'នាំទិស');
  String get contact          => _t(zh: '联系',       en: 'Contact',         vi: 'Liên hệ',          km: 'ទំនាក់ទំនង');
  String get performance      => _t(zh: '业绩',       en: 'Performance',     vi: 'Hiệu suất',        km: 'ការអនុវត្ត');
  String get addTechBtn       => _t(zh: '添加技师',   en: 'Add Therapist',   vi: 'Thêm KTV',         km: 'បន្ថែម');
  String get sendInvite       => _t(zh: '发送邀请',   en: 'Send Invite',     vi: 'Gửi lời mời',     km: 'ផ្ញើការអញ្ជើញ');
  String get confirmOrder     => _t(zh: '确认接单',   en: 'Confirm',         vi: 'Xác nhận đơn',    km: 'បញ្ជាក់');
  String get addItem          => _t(zh: '添加',       en: 'Add',             vi: 'Thêm',             km: 'បន្ថែម');
  String get confirmAdd       => _t(zh: '确认添加',   en: 'Confirm Add',     vi: 'Xác nhận',         km: 'បញ្ជាក់ការបន្ថែម');
  String get merchantWallet   => _t(zh: '商户钱包',   en: 'Merchant Wallet', vi: 'Ví thương nhân',  km: 'កាបូប');
  String get inviteSent       => _t(zh: '邀请链接已发送', en: 'Invite sent',  vi: 'Đã gửi lời mời', km: 'ការអញ្ជើញត្រូវបានផ្ញើ');
  String get serviceAdded     => _t(zh: '服务项目已添加', en: 'Service added', vi: 'Đã thêm dịch vụ', km: 'សេវាត្រូវបានបន្ថែម');

  // ==================== 区块标题 ====================
  String get pendingOrders    => _t(zh: '待接订单',   en: 'Pending Orders',  vi: 'Đơn chờ nhận',    km: 'ការបញ្ជាទិញរង់ចាំ');
  String get activeOrdersTitle => _t(zh: '服务中',    en: 'Active',          vi: 'Đang phục vụ',    km: 'កំពុងបម្រើ');
  String get noActiveOrders   => _t(zh: '暂无进行中的订单', en: 'No active orders', vi: 'Không có đơn', km: 'គ្មានការបញ្ជាទិញ');
  String get activeOrderHint  => _t(zh: '接单后将显示在这里', en: 'Will appear after accepting', vi: 'Hiển thị sau khi nhận', km: 'នឹងបង្ហាញបន្ទាប់ពីទទួល');
  String get quickActions     => _t(zh: '快捷操作',   en: 'Quick Actions',   vi: 'Thao tác nhanh',  km: 'សកម្មភាពរហ័ស');
  String get serviceManagement => _t(zh: '服务项目管理', en: 'Service Management', vi: 'Quản lý dịch vụ', km: 'គ្រប់គ្រងសេវា');
  String get merchantHub      => _t(zh: '商户大盘',   en: 'Merchant Hub',    vi: 'Bảng tổng quan',  km: 'ក្ដារបន្ទះ');

  // ==================== 技师端菜单 ====================
  String get myServices       => _t(zh: '我的服务',   en: 'My Services',     vi: 'Dịch vụ của tôi', km: 'សេវារបស់ខ្ញុំ');
  String get personalInfo     => _t(zh: '个人信息',   en: 'Personal Info',   vi: 'Thông tin cá nhân', km: 'ព័ត៌មានខ្ញុំ');
  String get serviceItems     => _t(zh: '服务项目',   en: 'Services',        vi: 'Dịch vụ',          km: 'ធាតុសេវា');
  String get mySchedule       => _t(zh: '日程安排',   en: 'Schedule',        vi: 'Lịch trình',       km: 'កាលវិភាគ');
  String get serviceRange     => _t(zh: '服务范围',   en: 'Service Range',   vi: 'Phạm vi dịch vụ', km: 'ជួរសេវា');
  String get skillSettings    => _t(zh: '技能设置',   en: 'Skills',          vi: 'Kỹ năng',          km: 'ជំនាញ');
  String get onlineMap        => _t(zh: '在线地图',   en: 'Map',             vi: 'Bản đồ',           km: 'ផែនទី');
  String get certifiedTech    => _t(zh: '认证技师',   en: 'Certified',       vi: 'Đã chứng nhận',   km: 'បានបញ្ជាក់');
  String get certPassed       => _t(zh: '已通过平台认证', en: 'Platform verified', vi: 'Đã được xác nhận', km: 'ត្រូវបានបញ្ជាក់');
  String get underReview      => _t(zh: '审核中',     en: 'Under Review',    vi: 'Đang xem xét',    km: 'កំពុងពិនិត្យ');
  String get reviewWaiting    => _t(zh: '资料审核中，请耐心等待', en: 'Materials under review', vi: 'Đang xem xét tài liệu', km: 'ឯកសារកំពុងត្រូវបានពិនិត្យ');
  String get completeCert     => _t(zh: '完善认证',   en: 'Complete Cert',   vi: 'Hoàn thiện chứng nhận', km: 'បំពេញការបញ្ជាក់');
  String get certHint         => _t(zh: '点击提交认证资料，接更多订单', en: 'Submit cert to get more orders', vi: 'Nộp chứng nhận để nhận thêm đơn', km: 'ដាក់ស្នើការបញ្ជាក់');
  String get personalProfile  => _t(zh: '个人资料',   en: 'Profile',         vi: 'Hồ sơ',            km: 'ប្រវត្តិរូប');
  String get certMaterials    => _t(zh: '认证资料',   en: 'Certificates',    vi: 'Chứng nhận',       km: 'ឯកសារបញ្ជាក់');
  String get notifications    => _t(zh: '消息通知',   en: 'Notifications',   vi: 'Thông báo',        km: 'ការជូនដំណឹង');
  String get languageSettings => _t(zh: '语言设置',   en: 'Language Settings', vi: 'Cài đặt ngôn ngữ', km: 'ការកំណត់ភាសា');
  String get selectPreferredLang => _t(zh: '选择您偏好的语言', en: 'Select your preferred language', vi: 'Chọn ngôn ngữ ưa thích', km: 'ជ្រើសរើសភាសាដែលអ្នកចូលចិត្ត');
  String get success          => _t(zh: '成功',       en: 'Success',         vi: 'Thành công',         km: 'ជោគជ័យ');
  String get unitDollar       => _t(zh: '单位: \$',   en: 'Unit: \$',        vi: 'Đơn vị: \$',         km: 'ឯកតា: \$');

  // ==================== 商户端菜单 ====================
  String get marketingTools   => _t(zh: '营销工具',   en: 'Marketing',       vi: 'Công cụ tiếp thị', km: 'ឧបករណ៍ទីផ្សារ');
  String get couponManagement => _t(zh: '优惠券管理', en: 'Coupons',         vi: 'Phiếu giảm giá',  km: 'គ្រប់គ្រងប័ណ្ណ');
  String get promotions       => _t(zh: '推广活动',   en: 'Promotions',      vi: 'Quảng bá',         km: 'ការផ្សព្វផ្សាយ');
  String get reviewManagement => _t(zh: '评价管理',   en: 'Reviews',         vi: 'Quản lý đánh giá', km: 'គ្រប់គ្រងការពិនិត្យ');
  String get shopSettings     => _t(zh: '店铺设置',   en: 'Shop Settings',   vi: 'Cài đặt cửa hàng', km: 'ការកំណត់ហាង');
  String get shopInfo         => _t(zh: '店铺信息',   en: 'Shop Info',       vi: 'Thông tin cửa hàng', km: 'ព័ត៌មានហាង');
  String get addressMgmt      => _t(zh: '地址管理',   en: 'Addresses',       vi: 'Địa chỉ',          km: 'គ្រប់គ្រងអាសយដ្ឋាន');
  String get businessHoursLabel => _t(zh: '营业时间', en: 'Business Hours',  vi: 'Giờ mở cửa',      km: 'ម៉ោងធ្វើការ');
  String get accountGroup     => _t(zh: '账户',       en: 'Account',         vi: 'Tài khoản',        km: 'គណនី');
  String get couponsLabel     => _t(zh: '优惠券',     en: 'Coupons',         vi: 'Phiếu giảm giá',  km: 'ប័ណ្ណ');

  // ==================== 对话框字段 ====================
  String get techNameField    => _t(zh: '技师姓名',   en: 'Therapist Name',  vi: 'Tên KTV',          km: 'ឈ្មោះ');
  String get skillTags        => _t(zh: '技能标签',   en: 'Skill Tags',      vi: 'Nhãn kỹ năng',    km: 'ស្លាកជំនាញ');
  String get serviceNameField => _t(zh: '服务名称',   en: 'Service Name',    vi: 'Tên dịch vụ',     km: 'ឈ្មោះសេវា');
  String get priceUSD         => _t(zh: '价格 (USD)', en: 'Price (USD)',     vi: 'Giá (USD)',        km: 'តម្លៃ (USD)');
  String get durationMinField => _t(zh: '时长 (分钟)', en: 'Duration (min)',  vi: 'Thời gian (phút)', km: 'រយៈពេល (នាទី)');
  String get clientLabel      => _t(zh: '客户',       en: 'Client',          vi: 'Khách hàng',       km: 'អតិថិជន');
  String get assignedTech     => _t(zh: '指派技师',   en: 'Assigned Tech',   vi: 'KTV được phân công', km: 'អ្នកបច្ចេកទេស');
  String get addServiceDialog => _t(zh: '添加服务项目', en: 'Add Service',   vi: 'Thêm dịch vụ',    km: 'បន្ថែមសេវា');
  String get addTechDialog    => _t(zh: '添加技师',   en: 'Add Therapist',   vi: 'Thêm KTV',         km: 'បន្ថែមអ្នកបច្ចេកទេស');
  String get techDefaultName  => _t(zh: '技师',       en: 'Therapist',       vi: 'KTV',              km: 'អ្នកបច្ចេកទេស');

  // ==================== 星期 ====================
  String get monday          => _t(zh: '周一', en: 'Mon', vi: 'T2', km: 'ច');
  String get tuesday         => _t(zh: '周二', en: 'Tue', vi: 'T3', km: 'អ');
  String get wednesday       => _t(zh: '周三', en: 'Wed', vi: 'T4', km: 'ព');
  String get thursday        => _t(zh: '周四', en: 'Thu', vi: 'T5', km: 'ព្រ');
  String get friday          => _t(zh: '周五', en: 'Fri', vi: 'T6', km: 'សុ');
  String get saturday        => _t(zh: '周六', en: 'Sat', vi: 'T7', km: 'ស');
  String get sunday          => _t(zh: '周日', en: 'Sun', vi: 'CN', km: 'អា');
  List<String> get daysShort => [monday, tuesday, wednesday, thursday, friday, saturday, sunday];

  // ==================== 关于我们 ====================
  String get aboutTagline     => _t(zh: '专业上门按摩 · 让放松触手可及', en: 'Professional home massage · relaxation at your doorstep', vi: 'Massage tại nhà chuyên nghiệp · thư giãn tận cửa', km: 'ម៉ាស្សាផ្ទះជំនាញ · ស្ងប់ស្ងាត់នៅទ្វារ');
  String get aboutStatUsers   => _t(zh: '注册用户', en: 'Registered Users', vi: 'Người dùng', km: 'អ្នកប្រើប្រាស់');
  String get aboutStatTechs   => _t(zh: '认证技师', en: 'Certified Therapists', vi: 'KTV được chứng nhận', km: 'KTV បានបញ្ជាក់');
  String get aboutStatCities  => _t(zh: '覆盖城市', en: 'Cities Covered', vi: 'Thành phố', km: 'ទីក្រុងដែលគ្រប');
  String get aboutStatRating  => _t(zh: '好评率', en: 'Satisfaction Rate', vi: 'Tỷ lệ hài lòng', km: 'អត្រានៃការពេញចិត្ត');
  String get aboutOpenSource  => _t(zh: '开源许可', en: 'Open Source Licenses', vi: 'Giấy phép mã nguồn mở', km: 'អាជ្ញាប័ណ្ណប្រភពបើកចំហ');
  String get aboutOpenSourceComingSoon => _t(zh: '开源许可页面即将上线', en: 'Open source page coming soon', vi: 'Trang giấy phép mã nguồn mở sắp ra mắt', km: 'ទំព័រអាជ្ញាប័ណ្ណនឹងមានឆាប់ៗ');
  String get aboutWebsite     => _t(zh: '官网', en: 'Official Website', vi: 'Trang web chính thức', km: 'គេហទំព័រផ្លូវការ');
  String get aboutFollowUs    => _t(zh: '关注我们', en: 'Follow Us', vi: 'Theo dõi chúng tôi', km: 'តាមដានយើង');

  // ==================== 帮助中心 ====================
  String get faqSearchHint    => _t(zh: '搜索问题关键词', en: 'Search FAQ', vi: 'Tìm câu hỏi', km: 'ស្វែងរកសំណួរ');
  String get faqCatOrders     => _t(zh: '订单相关', en: 'Orders', vi: 'Đơn hàng', km: 'ការបញ្ជាទិញ');
  String get faqCatPayment    => _t(zh: '支付相关', en: 'Payments', vi: 'Thanh toán', km: 'ការទូទាត់');
  String get faqCatTech       => _t(zh: '技师相关', en: 'Therapists', vi: 'Kỹ thuật viên', km: 'អ្នកបច្ចេកទេស');
  String get faqCatAccount    => _t(zh: '账号相关', en: 'Account', vi: 'Tài khoản', km: 'គណនី');
  String get faqNeedHelp      => _t(zh: '仍需要帮助？', en: 'Still need help?', vi: 'Vẫn cần hỗ trợ?', km: 'នៅត្រូវការជំនួយ?');
  String get faqSupportDesc   => _t(zh: '我们 7×12 小时在线，随时为你解答预约与支付问题', en: 'We are online 7×12 hours, ready to help with booking and payment', vi: 'Chúng tôi trực tuyến 7×12 giờ, sẵn sàng hỗ trợ đặt lịch và thanh toán', km: 'យើងអនឡាញ 7×12 ម៉ោង ជួយដោះស្រាយការកក់ និងការទូទាត់');
  String get faqOnlineSupport => _t(zh: '在线客服', en: 'Online Support', vi: 'Hỗ trợ trực tuyến', km: 'ជំនួយអនឡាញ');
  // ==================== 搜索 ====================
  String get rankBadgeAbbr    => _t(zh: '榜', en: 'Top', vi: 'Xh', km: 'ចំ');
  String get offerAbbr        => _t(zh: '惠', en: '⭐', vi: 'Ưu', km: 'ពិ');
  String orders60d(int n)     => _t(zh: '60日接单${n}+', en: '${n}+ orders(60d)', vi: '${n}+ đơn (60 ngày)', km: '${n}+ ការបញ្ជាទិញ');
  String distanceFmt(String d) => _t(zh: '直线$d', en: d, vi: 'cách $d', km: '$d');
  String get recentSearch     => _t(zh: '最近搜索', en: 'Recent', vi: 'Tìm kiếm gần đây', km: 'ស្វែងរកថ្មីៗ');
  String get clearAll         => _t(zh: '清空全部', en: 'Clear All', vi: 'Xóa tất cả', km: 'លុបទាំងអស់');
  String get hotSearch        => _t(zh: '热门搜索', en: 'Trending', vi: 'Tìm kiếm phổ biến', km: 'ស្វែងរកពេញនិយម');
  // ==================== 通知 ====================
  String get markAllRead      => _t(zh: '全部已读', en: 'Mark All Read', vi: 'Đánh dấu tất cả đã đọc', km: 'សម្គាល់ទាំងអស់ថាបានអាន');
  String get notifAlreadyRead => _t(zh: '该通知已读', en: 'Already read', vi: 'Đã đọc', km: 'បានអានហើយ');
  String get notifMarkedRead  => _t(zh: '已标记为已读', en: 'Marked as read', vi: 'Đã đánh dấu là đã đọc', km: 'បានសម្គាល់ថាបានអាន');
  String get notifTabSystem   => _t(zh: '系统通知', en: 'System', vi: 'Hệ thống', km: 'ប្រព័ន្ធ');
  String get notifTabOrder    => _t(zh: '订单通知', en: 'Orders', vi: 'Đơn hàng', km: 'ការបញ្ជាទិញ');
  String get notifTabPromo    => _t(zh: '活动通知', en: 'Promos', vi: 'Khuyến mãi', km: 'ការផ្ដល់ជូន');
  // ==================== 通用页面 ====================
  String get pageNotFound     => _t(zh: '页面走丢了', en: 'Page Not Found', vi: 'Không tìm thấy trang', km: 'រកទំព័រមិនឃើញ');
  String get pageNotFoundDesc => _t(zh: '链接可能已失效，或页面已被移动。请返回首页或联系客服。', en: 'The link may have expired or the page has moved. Return to home or contact support.', vi: 'Liên kết có thể đã hết hạn hoặc trang đã bị di chuyển. Quay về trang chủ hoặc liên hệ hỗ trợ.', km: 'តំណអាចផុតកំណត់ ឬទំព័រត្រូវបានផ្លាស់ប្ដូរ ។ ត្រឡប់ទំព័រដើម ឬទំនាក់ទំនងជំនួយ ។');
  String get backHome         => _t(zh: '返回首页', en: 'Back to Home', vi: 'Về trang chủ', km: 'ត្រឡប់ទំព័រដើម');
  String get yesterday        => _t(zh: '昨天', en: 'Yesterday', vi: 'Hôm qua', km: 'ម្សិលមិញ');
  String get customerService  => _t(zh: '客服支持', en: 'Support', vi: 'Hỗ trợ khách hàng', km: 'ជំនួយអតិថិជន');
  // ==================== 邀请 ====================
  String get yourReward       => _t(zh: '你的奖励', en: 'Your Reward', vi: 'Phần thưởng của bạn', km: 'រង្វាន់របស់អ្នក');
  String get friendReward     => _t(zh: '好友奖励', en: "Friend's Reward", vi: 'Phần thưởng của bạn bè', km: 'រង្វាន់មិត្ត');
  String get inviteRules      => _t(zh: '邀请规则', en: 'Invite Rules', vi: 'Quy tắc mời', km: 'ច្បាប់ការអញ្ជើញ');
  String get inviteStep1      => _t(zh: '分享您的专属邀请码给好友', en: 'Share your exclusive invite code with friends', vi: 'Chia sẻ mã mời độc quyền của bạn với bạn bè', km: 'ចែករំលែកលេខកូដអញ្ជើញផ្ដាច់មុខរបស់អ្នក');
  String get inviteStep2      => _t(zh: '好友注册时填写您的邀请码', en: 'Friends enter your code when registering', vi: 'Bạn bè nhập mã của bạn khi đăng ký', km: 'មិត្តភក្ដិបញ្ចូលលេខកូដពេលចុះឈ្មោះ');
  String get inviteStep3      => _t(zh: '好友下首单后，双方各获奖励', en: 'Both get rewarded after their first order', vi: 'Cả hai nhận phần thưởng sau đơn đầu tiên của bạn bè', km: 'ទាំងពីរទទួលរង្វាន់ក្រោយការបញ្ជាទិញដំបូង');
  // ==================== 订单追踪 ====================
  String get techEnRoute      => _t(zh: '前往中...', en: 'En Route...', vi: 'Đang trên đường...', km: 'កំពុងធ្វើដំណើរ...');
  String get techArrived      => _t(zh: '已到达', en: 'Arrived', vi: 'Đã đến', km: 'បានមកដល់');
  String get techEnRouteLabel => _t(zh: '技师前往', en: 'En Route', vi: 'Đang đến', km: 'កំពុងមក');
  String estimatedArrival(int n) => _t(zh: '预计 $n 分钟后到达', en: 'Arriving in $n min', vi: 'Dự kiến đến sau $n phút', km: 'នឹងដល់ក្នុង $n នាទី');
  // ==================== 评价 ====================
  String get ratingVeryGood  => _t(zh: '非常满意 😍', en: 'Excellent 😍', vi: 'Tuyệt vời 😍', km: 'ល្អប្រសើរ 😍');
  String get ratingGood      => _t(zh: '满意 😊', en: 'Good 😊', vi: 'Tốt 😊', km: 'ល្អ 😊');
  String get ratingOk        => _t(zh: '一般 😐', en: 'Average 😐', vi: 'Tạm được 😐', km: 'មធ្យម 😐');
  String get ratingBad       => _t(zh: '不满意 😕', en: 'Poor 😕', vi: 'Không hài lòng 😕', km: 'មិនពេញចិត្ត 😕');
  String get ratingVeryBad   => _t(zh: '非常差 😞', en: 'Terrible 😞', vi: 'Rất tệ 😞', km: 'អន់ខ្លាំង 😞');
  String scoreFmt(int n)     => _t(zh: '${n}分', en: '${n}pts', vi: '${n}đ', km: '$n ពិន្ទុ');
  String get anonymousHint   => _t(zh: '匿名后其他用户看不到您的信息', en: "Other users won't see your info when anonymous", vi: 'Người dùng khác sẽ không thấy thông tin của bạn', km: 'អ្នកប្រើប្រាស់ផ្សេងនឹងមិនឃើញព័ត៌មានរបស់អ្នក');
  String get selectRatingHint => _t(zh: '请选择评分', en: 'Please select a rating', vi: 'Vui lòng chọn đánh giá', km: 'សូមជ្រើសរើសការវាយតម្លៃ');
  String get tagProfessional => _t(zh: '手法专业', en: 'Professional', vi: 'Chuyên nghiệp', km: 'ជំនាញ');
  String get tagFriendly     => _t(zh: '态度友好', en: 'Friendly', vi: 'Thân thiện', km: 'ស្និទ្ធស្នាល');
  String get tagOnTime       => _t(zh: '准时到达', en: 'On Time', vi: 'Đúng giờ', km: 'ទៀងត្រង់');
  String get tagCareful      => _t(zh: '服务用心', en: 'Attentive', vi: 'Tận tâm', km: 'យកចិត្តទុកដាក់');
  String get tagClean        => _t(zh: '环境整洁', en: 'Clean', vi: 'Sạch sẽ', km: 'ស្អាត');
  String get tagValueForMoney => _t(zh: '超值推荐', en: 'Great Value', vi: 'Đáng tiền', km: 'ល្អតម្លៃ');
  String get tagGoodComm     => _t(zh: '沟通良好', en: 'Good Communication', vi: 'Giao tiếp tốt', km: 'ទំនាក់ទំនងល្អ');
  String get tagRepurchase   => _t(zh: '值得回购', en: 'Would Rebook', vi: 'Sẽ đặt lại', km: 'ចង់កក់ម្ដងទៀត');
  // ==================== 优惠券 ====================
  String get soldOut         => _t(zh: '已抢完', en: 'Sold Out', vi: 'Hết hàng', km: 'អស់ហើយ');
  String discountFmt(String d) => _t(zh: '${d}折', en: '${d}0% off', vi: 'Giảm ${d}0%', km: 'បញ្ចុះ ${d}0%');
  // Orders FAQ
  String get faqOQ1 => _t(zh: '如何取消或改约订单？', en: 'How to cancel or reschedule an order?', vi: 'Làm sao hủy hoặc đổi lịch đơn hàng?', km: 'តើធ្វើយ៉ាងណារម្លោះ ឬប្ដូរការកក់?');
  String get faqOA1 => _t(zh: '在「订单」列表进入详情，若技师未出发可申请取消或改期；已出发订单可能产生路费规则，请以页面提示为准。', en: 'Go to order details. If the therapist has not departed, you can request a cancellation or reschedule. Orders where the therapist has already departed may incur travel fee rules as shown on screen.', vi: 'Vào chi tiết đơn hàng. Nếu KTV chưa xuất phát, bạn có thể hủy hoặc đổi lịch. Đơn đã xuất phát có thể phát sinh phí đi lại theo quy định hiển thị.', km: 'ចូលទៅលម្អិតការបញ្ជាទិញ ។ ប្រសិនបើ KTV មិនទាន់ចេញ អ្នកអាចស្នើរម្លោះ ឬប្ដូរការកក់ ។');
  String get faqOQ2 => _t(zh: '技师迟到怎么办？', en: 'What if the therapist is late?', vi: 'Kỹ thuật viên đến trễ thì sao?', km: 'ត្បូចជំនួយការ ចំណាយ KTV យឺតយ៉ាវ?');
  String get faqOA2 => _t(zh: '您可在订单页查看实时位置；若严重迟到可通过在线客服协助催单或协商改约。', en: 'Check real-time location on the order page. For serious delays, contact online support to expedite or reschedule.', vi: 'Kiểm tra vị trí thực tế trên trang đơn hàng. Nếu trễ nghiêm trọng, liên hệ hỗ trợ trực tuyến.', km: 'ពិនិត្យទីតាំងពេលវេលាជាក់ស្ដែងនៅទំព័រការបញ្ជាទិញ ។ ប្រសិនបើយឺតខ្លាំង ទូរស័ព្ទទៅអ្នកជំនួយ ។');
  String get faqOQ3 => _t(zh: '服务不满意如何反馈？', en: 'How to report unsatisfactory service?', vi: 'Làm sao phản hồi dịch vụ không hài lòng?', km: 'តើធ្វើយ៉ាងណារាយការណ៍សេវាមិនពេញចិត្ត?');
  String get faqOA3 => _t(zh: '服务完成后可在评价页提交反馈，也可联系客服附上订单号，我们会尽快核实处理。', en: 'After service completion, submit feedback on the review page or contact support with your order number.', vi: 'Sau khi hoàn thành dịch vụ, gửi phản hồi trên trang đánh giá hoặc liên hệ hỗ trợ kèm số đơn hàng.', km: 'បន្ទាប់ពីបញ្ចប់សេវា ដាក់ស្នើមតិយោបល់នៅទំព័រពិនិត្យ ឬទូរស័ព្ទទៅផ្នែកជំនួយ ។');
  // Payment FAQ
  String get faqPQ1 => _t(zh: '支持哪些支付方式？', en: 'What payment methods are supported?', vi: 'Hỗ trợ phương thức thanh toán nào?', km: 'ការទូទាត់ប្រភេទណាដែលគ្រប?');
  String get faqPA1 => _t(zh: '目前支持 USDT、ABA 网银等渠道，具体以结算页展示为准；请勿向私人账户转账。', en: 'Currently USDT, ABA bank transfer and more. See checkout page for details. Never transfer to personal accounts.', vi: 'Hiện hỗ trợ USDT, ABA và nhiều kênh khác. Xem trang thanh toán để biết chi tiết. Không chuyển tiền cho tài khoản cá nhân.', km: 'បច្ចុប្បន្នគ្រប USDT, ABA Bank និងច្រើនទៀត ។ មើលទំព័រទូទាត់ ។ ហាមធ្វើការផ្ទេរប្រាក់ទៅគណនីផ្ទាល់ខ្លួន ។');
  String get faqPQ2 => _t(zh: '退款多久到账？', en: 'How long does a refund take?', vi: 'Hoàn tiền mất bao lâu?', km: 'ការសងប្រាក់ចំណាយប៉ុន្មានល?');
  String get faqPA2 => _t(zh: '审核通过后一般 1–3 个工作日原路退回，节假日可能顺延。', en: 'After approval, refunds are typically returned within 1–3 business days. Holidays may cause delays.', vi: 'Sau khi phê duyệt, hoàn tiền trong 1–3 ngày làm việc. Ngày lễ có thể bị chậm trễ.', km: 'ក្រោយការអនុម័ត ការសងប្រាក់ 1-3 ថ្ងៃធ្វើការ ។ ថ្ងៃឈប់ចំណេញប្រហែលពន្យល ។');
  String get faqPQ3 => _t(zh: '优惠券如何使用？', en: 'How to use a coupon?', vi: 'Cách sử dụng phiếu giảm giá?', km: 'ពីរបៀបប្រើប្រាស់គូប៉ុង?');
  String get faqPA3 => _t(zh: '在确认订单页选择可用优惠券即可抵扣；部分活动券有门槛与有效期，请留意说明。', en: 'Select an available coupon on the order confirmation page. Some coupons have minimum spend and expiry dates — check the details.', vi: 'Chọn phiếu giảm giá trên trang xác nhận đơn hàng. Một số phiếu có điều kiện và hạn sử dụng — xem chi tiết.', km: 'ជ្រើសរើសគូប៉ុងនៅទំព័របញ្ជាក់ការបញ្ជាទិញ ។ ខ្លះមានលក្ខខណ្ឌ ។');
  // Therapist FAQ
  String get faqTQ1 => _t(zh: '如何挑选合适的技师？', en: 'How to choose the right therapist?', vi: 'Chọn kỹ thuật viên phù hợp như thế nào?', km: 'ពីរបៀបជ្រើសរើស KTV ត្រឹមត្រូវ?');
  String get faqTA1 => _t(zh: '可结合评分、服务项目、距离与评价筛选；详情页可查看擅长手法与用户反馈。', en: 'Filter by rating, services, distance and reviews. View specialty techniques and user feedback on the profile page.', vi: 'Lọc theo đánh giá, dịch vụ, khoảng cách và nhận xét. Xem kỹ thuật chuyên môn và phản hồi người dùng trên trang hồ sơ.', km: 'ត្រង តាមការវាយតម្លៃ សេវា ចម្ងាយ និងមតិ ។ មើលបច្ចេកទេសពិសេស នៅទំព័រប្រវត្តិរូប ។');
  String get faqTQ2 => _t(zh: '技师是否经过认证？', en: 'Are therapists certified?', vi: 'Kỹ thuật viên có được chứng nhận không?', km: 'តើ KTV ត្រូវបានបញ្ជាក់ទេ?');
  String get faqTA2 => _t(zh: '平台对入驻技师进行资质审核与培训记录备案，您可在详情页查看认证标识。', en: 'The platform verifies credentials and records training for all therapists. Check certification badge on their profile page.', vi: 'Nền tảng xác minh chứng chỉ và lưu hồ sơ đào tạo. Kiểm tra huy hiệu chứng nhận trên trang hồ sơ.', km: 'វេទិកាផ្ទៀងផ្ទាត់ ឯកសារ ហើយកត់ត្រាការបណ្ដុះបណ្ដាល ។ ពិនិត្យផ្លាកបញ្ជាក់នៅទំព័រប្រវត្តិរូប ។');
  // Account FAQ
  String get faqAQ1 => _t(zh: '如何修改手机号或密码？', en: 'How to change phone number or password?', vi: 'Làm sao thay đổi số điện thoại hoặc mật khẩu?', km: 'ពីរបៀបផ្លាស់ប្ដូរលេខទូរស័ព្ទ ឬពាក្យសម្ងាត់?');
  String get faqAA1 => _t(zh: '前往「设置」-「账号安全」按指引完成验证后即可修改。', en: 'Go to Settings → Account Security, follow the verification steps to make changes.', vi: 'Vào Cài đặt → Bảo mật tài khoản, làm theo hướng dẫn xác minh để thay đổi.', km: 'ចូល ការកំណត់ → សុវត្ថិភាពគណនី បន្ទាប់មកអនុវត្ដជំហានផ្ទៀងផ្ទាត់ ។');
  String get faqAQ2 => _t(zh: '收不到验证码？', en: 'Not receiving verification code?', vi: 'Không nhận được mã xác minh?', km: 'មិនទទួលបានលេខកូដ?');
  String get faqAA2 => _t(zh: '请检查区号与号码是否正确、短信是否被拦截；仍无法收到请联系客服协助。', en: 'Check the country code and number, or if SMS is blocked. Contact support if the issue persists.', vi: 'Kiểm tra mã quốc gia và số điện thoại, hoặc xem SMS có bị chặn không. Liên hệ hỗ trợ nếu vẫn không nhận được.', km: 'ពិនិត្យលេខកូដប្រទេស និងលេខ ឬ SMS ត្រូវបានរារាំង ។ ទំនាក់ទំនងជំនួយ ប្រសិនបើបញ្ហានៅតែមាន ។');

  // ==================== 相机/相册 ====================
  String get takePhoto          => _t(zh: '拍照', en: 'Take Photo', vi: 'Chụp ảnh', km: 'ថតរូប');
  String get chooseFromGallery  => _t(zh: '从相册选择', en: 'Choose from Gallery', vi: 'Chọn từ thư viện', km: 'ជ្រើសរើសពីបណ្ណាល័យ');
  // ==================== 社区/动态 ====================
  String get postDetail         => _t(zh: '动态详情', en: 'Post Details', vi: 'Chi tiết bài viết', km: 'ព័ត៌មានលម្អិត');
  String get follow             => _t(zh: '+ 关注', en: '+ Follow', vi: '+ Theo dõi', km: '+ តាម');
  String get following          => _t(zh: '已关注', en: 'Following', vi: 'Đang theo dõi', km: 'កំពុងតាម');
  String get commentHint        => _t(zh: '说点什么…', en: 'Say something…', vi: 'Nói gì đó…', km: 'និយាយអ្វីមួយ…');
  String get commentSent        => _t(zh: '评论已发送', en: 'Comment sent', vi: 'Đã gửi bình luận', km: 'បានផ្ញើយោបល់');
  String get saveFavorite       => _t(zh: '收藏', en: 'Save', vi: 'Lưu', km: 'រក្សាទុក');
  String get timeNow            => _t(zh: '现在', en: 'Now', vi: 'Bây giờ', km: 'ឥឡូវ');
  // ==================== 协议/隐私 ====================
  String get termsTitle          => _t(zh: '用户协议', en: 'Terms of Service', vi: 'Điều khoản dịch vụ', km: 'លក្ខខណ្ឌ');
  String get privacyTitle        => _t(zh: '隐私政策', en: 'Privacy Policy', vi: 'Chính sách bảo mật', km: 'គោលការណ៍ឯកជនភាព');
  String get lastUpdatedApr2026  => _t(zh: '最后更新：2026 年 4 月', en: 'Last updated: April 2026', vi: 'Cập nhật lần cuối: Tháng 4/2026', km: 'ធ្វើបច្ចុប្បន្នភាពចុងក្រោយ: ខែមេសា 2026');
  String get agreeToTerms        => _t(zh: '同意协议', en: 'Agree to Terms', vi: 'Đồng ý điều khoản', km: 'យល់ព្រមលក្ខខណ្ឌ');
  String get agreeToPrivacy      => _t(zh: '同意隐私政策', en: 'Agree to Privacy Policy', vi: 'Đồng ý chính sách', km: 'យល់ព្រមមគោលការណ៍');
  // ==================== 语言切换 ====================
  String get switchLang    => _t(zh: '切换语言', en: 'Switch Language',  vi: 'Đổi ngôn ngữ', km: 'ប្ដូរភាសា');
  String get langZh        => '中文';
  String get langEn        => 'English';
  String get langVi        => 'Tiếng Việt';
  String get langKm        => 'ភាសាខ្មែរ';
  String get langSelected  => _t(zh: '已切换', en: 'Switched', vi: 'Đã chuyển', km: 'បានប្ដូរ');

  // ==================== 内部翻译方法 ====================
  String _t({
    required String zh,
    required String en,
    required String vi,
    required String km,
  }) {
    switch (locale.languageCode) {
      case 'zh':
        return zh;
      case 'vi':
        return vi;
      case 'km':
        return km;
      default:
        return en;
    }
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['zh', 'en', 'vi', 'km'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => true;
}
