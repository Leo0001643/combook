-- ============================================================
-- CamBook Migration v5.17 — 补全缺失的 sys_i18n 国际化配置
-- Date    : 2026-05-06
-- 说明    :
--   启动日志 WARN "[I18n] 枚举 X 在 sys_i18n 中无配置" 共 20 条。
--   本脚本补全全部缺失枚举，覆盖 5 种语言：zh / en / vi / km / th
--   全部使用 INSERT ... ON DUPLICATE KEY UPDATE，可幂等重复执行。
-- ============================================================

SET NAMES utf8mb4;

-- ── 1. 通用参数 / HTTP 语义错误 ───────────────────────────────────────────────

INSERT INTO `sys_i18n` (enum_code, lang, message) VALUES
  ('REPEAT_SUBMIT',   'zh', '请勿重复提交'),
  ('REPEAT_SUBMIT',   'en', 'Duplicate submission, please do not retry'),
  ('REPEAT_SUBMIT',   'vi', 'Vui lòng không gửi trùng lặp'),
  ('REPEAT_SUBMIT',   'km', 'សូម​កុំ​ដាក់​ស្នើ​ម្ដង​ទៀត'),
  ('REPEAT_SUBMIT',   'th', 'กรุณาอย่าส่งซ้ำ'),

  ('DATA_DUPLICATE',  'zh', '数据已存在，不允许重复'),
  ('DATA_DUPLICATE',  'en', 'Data already exists'),
  ('DATA_DUPLICATE',  'vi', 'Dữ liệu đã tồn tại'),
  ('DATA_DUPLICATE',  'km', 'ទិន្នន័យ​មាន​រួច​ហើយ'),
  ('DATA_DUPLICATE',  'th', 'ข้อมูลมีอยู่แล้ว'),

  ('MISSING_PARAM',   'zh', '缺少必填参数'),
  ('MISSING_PARAM',   'en', 'Missing required parameters'),
  ('MISSING_PARAM',   'vi', 'Thiếu tham số bắt buộc'),
  ('MISSING_PARAM',   'km', 'ខ្វះ​ប៉ារ៉ាម៉ែត្រ​ដែល​ត្រូវ​ការ'),
  ('MISSING_PARAM',   'th', 'ขาดพารามิเตอร์ที่จำเป็น'),

  ('METHOD_NOT_ALLOWED', 'zh', '不支持的请求方式'),
  ('METHOD_NOT_ALLOWED', 'en', 'HTTP method not allowed'),
  ('METHOD_NOT_ALLOWED', 'vi', 'Phương thức HTTP không được phép'),
  ('METHOD_NOT_ALLOWED', 'km', 'វិធី​ HTTP ​មិន​ត្រូវ​បាន​អនុញ្ញាត'),
  ('METHOD_NOT_ALLOWED', 'th', 'ไม่อนุญาตวิธี HTTP นี้')

ON DUPLICATE KEY UPDATE message = VALUES(message);

-- ── 2. 认证 / 短信验证码 ──────────────────────────────────────────────────────

INSERT INTO `sys_i18n` (enum_code, lang, message) VALUES
  ('SMS_CODE_EXPIRED', 'zh', '验证码已过期，请重新获取'),
  ('SMS_CODE_EXPIRED', 'en', 'Verification code expired, please request a new one'),
  ('SMS_CODE_EXPIRED', 'vi', 'Mã xác minh đã hết hạn, vui lòng lấy mã mới'),
  ('SMS_CODE_EXPIRED', 'km', 'លេខ​កូដ​ផ្ទៀងផ្ទាត់​ផុត​កំណត់ ​សូម​ស្នើ​លេខ​កូដ​ថ្មី'),
  ('SMS_CODE_EXPIRED', 'th', 'รหัสยืนยันหมดอายุ กรุณาขอรหัสใหม่')

ON DUPLICATE KEY UPDATE message = VALUES(message);

-- ── 3. 技师状态错误 ───────────────────────────────────────────────────────────

INSERT INTO `sys_i18n` (enum_code, lang, message) VALUES
  ('TECHNICIAN_ALREADY_APPLIED', 'zh', '您已提交过申请，请勿重复提交'),
  ('TECHNICIAN_ALREADY_APPLIED', 'en', 'You have already submitted an application'),
  ('TECHNICIAN_ALREADY_APPLIED', 'vi', 'Bạn đã nộp đơn đăng ký, vui lòng không nộp lại'),
  ('TECHNICIAN_ALREADY_APPLIED', 'km', 'អ្នក​បាន​ដាក់​ពាក្យ​ស្នើ​រួច​ហើយ'),
  ('TECHNICIAN_ALREADY_APPLIED', 'th', 'คุณได้ส่งใบสมัครแล้ว กรุณาอย่าส่งซ้ำ'),

  ('TECHNICIAN_AUDIT_PENDING',   'zh', '资质审核中，请耐心等待'),
  ('TECHNICIAN_AUDIT_PENDING',   'en', 'Your application is under review, please wait'),
  ('TECHNICIAN_AUDIT_PENDING',   'vi', 'Đơn của bạn đang được xét duyệt, vui lòng chờ'),
  ('TECHNICIAN_AUDIT_PENDING',   'km', 'ពាក្យ​ស្នើ​របស់​អ្នក​កំពុង​ពិនិត្យ ​សូម​រង់ចាំ'),
  ('TECHNICIAN_AUDIT_PENDING',   'th', 'ใบสมัครของคุณอยู่ระหว่างการตรวจสอบ กรุณารอ'),

  ('TECHNICIAN_AUDIT_REJECTED',  'zh', '审核未通过，请联系客服了解原因'),
  ('TECHNICIAN_AUDIT_REJECTED',  'en', 'Application rejected, please contact support for details'),
  ('TECHNICIAN_AUDIT_REJECTED',  'vi', 'Đơn bị từ chối, vui lòng liên hệ hỗ trợ'),
  ('TECHNICIAN_AUDIT_REJECTED',  'km', 'ពាក្យ​ស្នើ​ត្រូវ​បាន​បដិសេធ ​សូម​ទំនាក់​ទំនង​ជំនួយ'),
  ('TECHNICIAN_AUDIT_REJECTED',  'th', 'ใบสมัครถูกปฏิเสธ กรุณาติดต่อฝ่ายสนับสนุน'),

  ('TECHNICIAN_BANNED',          'zh', '账号已被封禁，请联系客服'),
  ('TECHNICIAN_BANNED',          'en', 'Account has been banned, please contact support'),
  ('TECHNICIAN_BANNED',          'vi', 'Tài khoản bị cấm, vui lòng liên hệ hỗ trợ'),
  ('TECHNICIAN_BANNED',          'km', 'គណនី​ត្រូវ​បាន​ហាម ​សូម​ទំនាក់​ទំនង​ជំនួយ'),
  ('TECHNICIAN_BANNED',          'th', 'บัญชีถูกระงับ กรุณาติดต่อฝ่ายสนับสนุน'),

  ('TECHNICIAN_MOBILE_EXISTS',   'zh', '该手机号已被注册，请直接登录'),
  ('TECHNICIAN_MOBILE_EXISTS',   'en', 'Mobile number already registered, please login directly'),
  ('TECHNICIAN_MOBILE_EXISTS',   'vi', 'Số điện thoại đã được đăng ký, vui lòng đăng nhập'),
  ('TECHNICIAN_MOBILE_EXISTS',   'km', 'លេខ​ទូរស័ព្ទ​ត្រូវ​បាន​ចុះ​ឈ្មោះ​រួច​ហើយ'),
  ('TECHNICIAN_MOBILE_EXISTS',   'th', 'เบอร์โทรศัพท์นี้ลงทะเบียนแล้ว กรุณาเข้าสู่ระบบโดยตรง')

ON DUPLICATE KEY UPDATE message = VALUES(message);

-- ── 4. 商户 ───────────────────────────────────────────────────────────────────

INSERT INTO `sys_i18n` (enum_code, lang, message) VALUES
  ('MERCHANT_NO_INVALID', 'zh', '商户号不存在或已停用'),
  ('MERCHANT_NO_INVALID', 'en', 'Merchant number is invalid or disabled'),
  ('MERCHANT_NO_INVALID', 'vi', 'Số thương nhân không hợp lệ hoặc đã bị vô hiệu'),
  ('MERCHANT_NO_INVALID', 'km', 'លេខ​ពណិជ្ជករ​មិន​ត្រឹម​ត្រូវ​ឬ​ត្រូវ​បាន​បិទ'),
  ('MERCHANT_NO_INVALID', 'th', 'หมายเลขผู้ค้าไม่ถูกต้องหรือถูกปิดใช้งาน')

ON DUPLICATE KEY UPDATE message = VALUES(message);

-- ── 5. 订单 ───────────────────────────────────────────────────────────────────

INSERT INTO `sys_i18n` (enum_code, lang, message) VALUES
  ('ORDER_CANNOT_CANCEL',    'zh', '当前订单状态不允许取消'),
  ('ORDER_CANNOT_CANCEL',    'en', 'Order cannot be cancelled at current status'),
  ('ORDER_CANNOT_CANCEL',    'vi', 'Không thể hủy đơn hàng ở trạng thái hiện tại'),
  ('ORDER_CANNOT_CANCEL',    'km', 'មិន​អាច​លុប​ការ​បញ្ជា​ក្នុង​ស្ថានភាព​នេះ'),
  ('ORDER_CANNOT_CANCEL',    'th', 'ไม่สามารถยกเลิกคำสั่งซื้อในสถานะนี้ได้'),

  ('ORDER_ALREADY_REVIEWED', 'zh', '该订单已完成评价，无法重复提交'),
  ('ORDER_ALREADY_REVIEWED', 'en', 'Order has already been reviewed'),
  ('ORDER_ALREADY_REVIEWED', 'vi', 'Đơn hàng đã được đánh giá'),
  ('ORDER_ALREADY_REVIEWED', 'km', 'ការ​បញ្ជា​ត្រូវ​បាន​វាយ​តម្លៃ​រួច​ហើយ'),
  ('ORDER_ALREADY_REVIEWED', 'th', 'คำสั่งซื้อได้รับการรีวิวแล้ว')

ON DUPLICATE KEY UPDATE message = VALUES(message);

-- ── 6. 支付 / 钱包 ────────────────────────────────────────────────────────────

INSERT INTO `sys_i18n` (enum_code, lang, message) VALUES
  ('PAYMENT_FAILED',    'zh', '支付失败，请稍后重试'),
  ('PAYMENT_FAILED',    'en', 'Payment failed, please try again'),
  ('PAYMENT_FAILED',    'vi', 'Thanh toán thất bại, vui lòng thử lại'),
  ('PAYMENT_FAILED',    'km', 'ការ​ទូទាត់​បាន​បរាជ័យ ​សូម​ព្យាយាម​ម្ដង​ទៀត'),
  ('PAYMENT_FAILED',    'th', 'การชำระเงินล้มเหลว กรุณาลองใหม่'),

  ('WITHDRAW_MIN_AMOUNT', 'zh', '提现金额不足最低限额'),
  ('WITHDRAW_MIN_AMOUNT', 'en', 'Withdrawal amount is below the minimum limit'),
  ('WITHDRAW_MIN_AMOUNT', 'vi', 'Số tiền rút thấp hơn mức tối thiểu'),
  ('WITHDRAW_MIN_AMOUNT', 'km', 'ចំនួន​ដក​ប្រាក់​ទាប​ជាង​ដែន​កំណត់​អប្បបរមា'),
  ('WITHDRAW_MIN_AMOUNT', 'th', 'จำนวนการถอนต่ำกว่าขั้นต่ำที่กำหนด')

ON DUPLICATE KEY UPDATE message = VALUES(message);

-- ── 7. 优惠券 ─────────────────────────────────────────────────────────────────

INSERT INTO `sys_i18n` (enum_code, lang, message) VALUES
  ('COUPON_NOT_FOUND',      'zh', '优惠券不存在'),
  ('COUPON_NOT_FOUND',      'en', 'Coupon not found'),
  ('COUPON_NOT_FOUND',      'vi', 'Không tìm thấy phiếu giảm giá'),
  ('COUPON_NOT_FOUND',      'km', 'រក​មិន​ឃើញ​គូប​ប៉ុ'),
  ('COUPON_NOT_FOUND',      'th', 'ไม่พบคูปอง'),

  ('COUPON_EXPIRED',        'zh', '优惠券已过期'),
  ('COUPON_EXPIRED',        'en', 'Coupon has expired'),
  ('COUPON_EXPIRED',        'vi', 'Phiếu giảm giá đã hết hạn'),
  ('COUPON_EXPIRED',        'km', 'គូប​ប៉ុ​ផុត​កំណត'),
  ('COUPON_EXPIRED',        'th', 'คูปองหมดอายุแล้ว'),

  ('COUPON_USED',           'zh', '优惠券已使用'),
  ('COUPON_USED',           'en', 'Coupon has already been used'),
  ('COUPON_USED',           'vi', 'Phiếu giảm giá đã được sử dụng'),
  ('COUPON_USED',           'km', 'គូប​ប៉ុ​ត្រូវ​បាន​ប្រើ​ហើយ'),
  ('COUPON_USED',           'th', 'คูปองถูกใช้แล้ว'),

  ('COUPON_NOT_APPLICABLE', 'zh', '优惠券不适用于此订单'),
  ('COUPON_NOT_APPLICABLE', 'en', 'Coupon is not applicable to this order'),
  ('COUPON_NOT_APPLICABLE', 'vi', 'Phiếu giảm giá không áp dụng cho đơn hàng này'),
  ('COUPON_NOT_APPLICABLE', 'km', 'គូប​ប៉ុ​មិន​អាច​ប្រើ​សម្រាប់​ការ​បញ្ជា​នេះ'),
  ('COUPON_NOT_APPLICABLE', 'th', 'คูปองไม่สามารถใช้กับคำสั่งซื้อนี้ได้'),

  ('COUPON_STOCK_EMPTY',    'zh', '优惠券已抢完，请关注下次活动'),
  ('COUPON_STOCK_EMPTY',    'en', 'Coupon stock depleted, please check back next time'),
  ('COUPON_STOCK_EMPTY',    'vi', 'Phiếu giảm giá đã hết, hãy theo dõi lần sau'),
  ('COUPON_STOCK_EMPTY',    'km', 'ស្តុក​គូប​ប៉ុ​អស់​ហើយ'),
  ('COUPON_STOCK_EMPTY',    'th', 'คูปองหมดแล้ว กรุณาติดตามกิจกรรมครั้งหน้า')

ON DUPLICATE KEY UPDATE message = VALUES(message);

-- ── 验证结果 ──────────────────────────────────────────────────────────────────

SELECT
    COUNT(*)                                                    AS total_records,
    COUNT(DISTINCT enum_code)                                   AS total_enums,
    SUM(IF(lang = 'zh', 1, 0))                                 AS zh_count,
    SUM(IF(lang = 'en', 1, 0))                                 AS en_count,
    SUM(IF(lang = 'vi', 1, 0))                                 AS vi_count,
    SUM(IF(lang = 'km', 1, 0))                                 AS km_count,
    SUM(IF(lang = 'th', 1, 0))                                 AS th_count
FROM `sys_i18n`;

-- 展示仍有缺失的枚举（理论上执行后为空）
SELECT CONCAT('⚠ 仍缺配置：', e.enum_code) AS missing
FROM (
    SELECT 'REPEAT_SUBMIT'              AS enum_code UNION ALL
    SELECT 'DATA_DUPLICATE'             UNION ALL
    SELECT 'MISSING_PARAM'              UNION ALL
    SELECT 'METHOD_NOT_ALLOWED'         UNION ALL
    SELECT 'SMS_CODE_EXPIRED'           UNION ALL
    SELECT 'TECHNICIAN_ALREADY_APPLIED' UNION ALL
    SELECT 'TECHNICIAN_AUDIT_PENDING'   UNION ALL
    SELECT 'TECHNICIAN_AUDIT_REJECTED'  UNION ALL
    SELECT 'TECHNICIAN_BANNED'          UNION ALL
    SELECT 'TECHNICIAN_MOBILE_EXISTS'   UNION ALL
    SELECT 'MERCHANT_NO_INVALID'        UNION ALL
    SELECT 'ORDER_CANNOT_CANCEL'        UNION ALL
    SELECT 'ORDER_ALREADY_REVIEWED'     UNION ALL
    SELECT 'PAYMENT_FAILED'             UNION ALL
    SELECT 'WITHDRAW_MIN_AMOUNT'        UNION ALL
    SELECT 'COUPON_NOT_FOUND'           UNION ALL
    SELECT 'COUPON_EXPIRED'             UNION ALL
    SELECT 'COUPON_USED'                UNION ALL
    SELECT 'COUPON_NOT_APPLICABLE'      UNION ALL
    SELECT 'COUPON_STOCK_EMPTY'
) e
LEFT JOIN `sys_i18n` i ON i.enum_code = e.enum_code AND i.lang = 'zh'
WHERE i.enum_code IS NULL;

SELECT '✅ migrate_v5_17 执行完成，所有 I18n 枚举已补全' AS result;
