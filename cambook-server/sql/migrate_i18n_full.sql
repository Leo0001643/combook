-- ============================================================
-- CamBook sys_i18n 国际化错误码 全量脚本（生产可直接执行）
-- Version  : v5.17（合并 v5_14 + v5_17）
-- Date     : 2026-05-06
-- 语言支持 : zh / en / vi / km / th
--
-- 包含枚举分组：
--   1.  通用响应码          SUCCESS / SERVER_ERROR / PARAM_ERROR …
--   2.  认证 / 令牌         TOKEN_INVALID / TOKEN_EXPIRED
--   3.  账号状态            ACCOUNT_BANNED / ACCOUNT_NOT_FOUND / NO_PERMISSION
--   4.  短信验证码          SMS_CODE_WRONG / SMS_CODE_EXPIRED
--   5.  商户                MERCHANT_NOT_FOUND / MERCHANT_AUDIT_PENDING / MERCHANT_NO_INVALID
--   6.  技师                TECHNICIAN_NOT_FOUND / TECHNICIAN_OFFLINE / TECHNICIAN_BUSY
--                           TECHNICIAN_ALREADY_APPLIED / TECHNICIAN_AUDIT_PENDING
--                           TECHNICIAN_AUDIT_REJECTED / TECHNICIAN_BANNED / TECHNICIAN_MOBILE_EXISTS
--   7.  会员                MEMBER_NOT_FOUND
--   8.  订单                ORDER_NOT_FOUND / ORDER_STATUS_ILLEGAL / ORDER_CANNOT_CANCEL / ORDER_ALREADY_REVIEWED
--   9.  支付 / 钱包         PAYMENT_FAILED / WITHDRAW_MIN_AMOUNT / BALANCE_INSUFFICIENT
--   10. 优惠券              COUPON_NOT_FOUND / COUPON_EXPIRED / COUPON_USED …
--   11. 散客接待            WALKIN_NOT_FOUND / WALKIN_ALREADY_SETTLED …
--   12. 技师结算            SETTLEMENT_NOT_FOUND / SETTLEMENT_ALREADY_PAID …
--   13. 部门 / 权限树       DEPT_HAS_CHILDREN / PERM_MOVE_TO_SELF …
--   14. 车辆                VEHICLE_NOT_FOUND
--   15. 币种                CURRENCY_NOT_FOUND / CURRENCY_CODE_EXISTS …
--   16. 系统配置            CONFIG_KEY_EXISTS / CONFIG_BUILTIN
--   17. 分类                CATEGORY_HAS_CHILDREN
--   18. 定价                PRICING_NOT_SPECIAL
--   19. 通用参数 / HTTP     REPEAT_SUBMIT / DATA_DUPLICATE / MISSING_PARAM / METHOD_NOT_ALLOWED
--
-- 执行说明：
--   · CREATE TABLE IF NOT EXISTS：幂等，表不存在时才创建
--   · INSERT ... ON DUPLICATE KEY UPDATE：幂等，可重复执行
-- ============================================================

SET NAMES utf8mb4;

-- ── 表结构（幂等）────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `sys_i18n` (
    `id`          BIGINT       NOT NULL AUTO_INCREMENT COMMENT '主键，自增',
    `enum_code`   VARCHAR(100) NOT NULL                COMMENT 'CbCodeEnum 枚举常量名',
    `lang`        VARCHAR(10)  NOT NULL                COMMENT '语言标识：zh / en / vi / km / th',
    `message`     VARCHAR(500) NOT NULL                COMMENT '对应语言的消息文本',
    `create_time` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP                            COMMENT '创建时间',
    `update_time` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '最后修改时间',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_enum_lang`  (`enum_code`, `lang`),
    KEY           `idx_enum_code` (`enum_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='国际化枚举消息表';

-- ── 1. 通用响应码 ─────────────────────────────────────────────────────────────
INSERT INTO `sys_i18n` (`enum_code`, `lang`, `message`) VALUES
  ('SUCCESS',               'zh', '操作成功'),
  ('SUCCESS',               'en', 'Success'),
  ('SUCCESS',               'vi', 'Thành công'),
  ('SUCCESS',               'km', 'បាន​ជោគ​ជ័យ'),
  ('SUCCESS',               'th', 'สำเร็จ'),

  ('SERVER_ERROR',          'zh', '服务器内部错误'),
  ('SERVER_ERROR',          'en', 'Internal server error'),
  ('SERVER_ERROR',          'vi', 'Lỗi máy chủ nội bộ'),
  ('SERVER_ERROR',          'km', 'កំហុស​ម៉ាស៊ីន​បម្រើ​ផ្ទៃ​ក្នុង'),
  ('SERVER_ERROR',          'th', 'ข้อผิดพลาดเซิร์ฟเวอร์ภายใน'),

  ('PARAM_ERROR',           'zh', '请求参数错误'),
  ('PARAM_ERROR',           'en', 'Invalid request parameters'),
  ('PARAM_ERROR',           'vi', 'Tham số yêu cầu không hợp lệ'),
  ('PARAM_ERROR',           'km', 'ប៉ារ៉ាម៉ែត្រ​សំណើ​មិន​ត្រឹម​ត្រូវ'),
  ('PARAM_ERROR',           'th', 'พารามิเตอร์คำขอไม่ถูกต้อง'),

  ('DATA_NOT_FOUND',        'zh', '数据不存在'),
  ('DATA_NOT_FOUND',        'en', 'Data not found'),
  ('DATA_NOT_FOUND',        'vi', 'Không tìm thấy dữ liệu'),
  ('DATA_NOT_FOUND',        'km', 'រក​មិន​ឃើញ​ទិន្នន័យ'),
  ('DATA_NOT_FOUND',        'th', 'ไม่พบข้อมูล'),

  ('REPEAT_SUBMIT',         'zh', '请勿重复提交'),
  ('REPEAT_SUBMIT',         'en', 'Duplicate submission, please do not retry'),
  ('REPEAT_SUBMIT',         'vi', 'Vui lòng không gửi trùng lặp'),
  ('REPEAT_SUBMIT',         'km', 'សូម​កុំ​ដាក់​ស្នើ​ម្ដង​ទៀត'),
  ('REPEAT_SUBMIT',         'th', 'กรุณาอย่าส่งซ้ำ'),

  ('DATA_DUPLICATE',        'zh', '数据已存在，不允许重复'),
  ('DATA_DUPLICATE',        'en', 'Data already exists'),
  ('DATA_DUPLICATE',        'vi', 'Dữ liệu đã tồn tại'),
  ('DATA_DUPLICATE',        'km', 'ទិន្នន័យ​មាន​រួច​ហើយ'),
  ('DATA_DUPLICATE',        'th', 'ข้อมูลมีอยู่แล้ว'),

  ('MISSING_PARAM',         'zh', '缺少必填参数'),
  ('MISSING_PARAM',         'en', 'Missing required parameters'),
  ('MISSING_PARAM',         'vi', 'Thiếu tham số bắt buộc'),
  ('MISSING_PARAM',         'km', 'ខ្វះ​ប៉ារ៉ាម៉ែត្រ​ដែល​ត្រូវ​ការ'),
  ('MISSING_PARAM',         'th', 'ขาดพารามิเตอร์ที่จำเป็น'),

  ('METHOD_NOT_ALLOWED',    'zh', '不支持的请求方式'),
  ('METHOD_NOT_ALLOWED',    'en', 'HTTP method not allowed'),
  ('METHOD_NOT_ALLOWED',    'vi', 'Phương thức HTTP không được phép'),
  ('METHOD_NOT_ALLOWED',    'km', 'វិធី​ HTTP ​មិន​ត្រូវ​បាន​អនុញ្ញាត'),
  ('METHOD_NOT_ALLOWED',    'th', 'ไม่อนุญาตวิธี HTTP นี้')
ON DUPLICATE KEY UPDATE `message` = VALUES(`message`);

-- ── 2. 认证 / 令牌 ────────────────────────────────────────────────────────────
INSERT INTO `sys_i18n` (`enum_code`, `lang`, `message`) VALUES
  ('TOKEN_INVALID',         'zh', '登录凭证无效，请重新登录'),
  ('TOKEN_INVALID',         'en', 'Token invalid, please login again'),
  ('TOKEN_INVALID',         'vi', 'Token không hợp lệ, vui lòng đăng nhập lại'),
  ('TOKEN_INVALID',         'km', 'ថូ​ខឹន​មិន​ត្រឹម​ត្រូវ'),
  ('TOKEN_INVALID',         'th', 'โทเค็นไม่ถูกต้อง กรุณาเข้าสู่ระบบใหม่'),

  ('TOKEN_EXPIRED',         'zh', '登录已过期，请重新登录'),
  ('TOKEN_EXPIRED',         'en', 'Token expired, please login again'),
  ('TOKEN_EXPIRED',         'vi', 'Token đã hết hạn, vui lòng đăng nhập lại'),
  ('TOKEN_EXPIRED',         'km', 'ថូ​ខឹន​ផុត​សុពលភាព'),
  ('TOKEN_EXPIRED',         'th', 'โทเค็นหมดอายุ กรุณาเข้าสู่ระบบใหม่')
ON DUPLICATE KEY UPDATE `message` = VALUES(`message`);

-- ── 3. 账号状态 ───────────────────────────────────────────────────────────────
INSERT INTO `sys_i18n` (`enum_code`, `lang`, `message`) VALUES
  ('NO_PERMISSION',         'zh', '无权限访问'),
  ('NO_PERMISSION',         'en', 'Access denied'),
  ('NO_PERMISSION',         'vi', 'Từ chối truy cập'),
  ('NO_PERMISSION',         'km', 'ហាម​ចូល​ប្រើ'),
  ('NO_PERMISSION',         'th', 'ไม่มีสิทธิ์เข้าถึง'),

  ('ACCOUNT_BANNED',        'zh', '账号已被封禁'),
  ('ACCOUNT_BANNED',        'en', 'Account banned'),
  ('ACCOUNT_BANNED',        'vi', 'Tài khoản bị khóa'),
  ('ACCOUNT_BANNED',        'km', 'គណនី​ត្រូវ​បាន​ហាម'),
  ('ACCOUNT_BANNED',        'th', 'บัญชีถูกระงับ'),

  ('ACCOUNT_NOT_FOUND',     'zh', '账号不存在'),
  ('ACCOUNT_NOT_FOUND',     'en', 'Account not found'),
  ('ACCOUNT_NOT_FOUND',     'vi', 'Tài khoản không tồn tại'),
  ('ACCOUNT_NOT_FOUND',     'km', 'រក​មិន​ឃើញ​គណនី'),
  ('ACCOUNT_NOT_FOUND',     'th', 'ไม่พบบัญชี')
ON DUPLICATE KEY UPDATE `message` = VALUES(`message`);

-- ── 4. 短信验证码 ─────────────────────────────────────────────────────────────
INSERT INTO `sys_i18n` (`enum_code`, `lang`, `message`) VALUES
  ('SMS_CODE_WRONG',        'zh', '密码错误'),
  ('SMS_CODE_WRONG',        'en', 'Password incorrect'),
  ('SMS_CODE_WRONG',        'vi', 'Mật khẩu không đúng'),
  ('SMS_CODE_WRONG',        'km', 'លេខ​សម្ងាត់​មិន​ត្រឹម​ត្រូវ'),
  ('SMS_CODE_WRONG',        'th', 'รหัสผ่านไม่ถูกต้อง'),

  ('SMS_CODE_EXPIRED',      'zh', '验证码已过期，请重新获取'),
  ('SMS_CODE_EXPIRED',      'en', 'Verification code expired, please request a new one'),
  ('SMS_CODE_EXPIRED',      'vi', 'Mã xác minh đã hết hạn, vui lòng lấy mã mới'),
  ('SMS_CODE_EXPIRED',      'km', 'លេខ​កូដ​ផ្ទៀងផ្ទាត់​ផុត​កំណត់ ​សូម​ស្នើ​លេខ​កូដ​ថ្មី'),
  ('SMS_CODE_EXPIRED',      'th', 'รหัสยืนยันหมดอายุ กรุณาขอรหัสใหม่')
ON DUPLICATE KEY UPDATE `message` = VALUES(`message`);

-- ── 5. 商户 ───────────────────────────────────────────────────────────────────
INSERT INTO `sys_i18n` (`enum_code`, `lang`, `message`) VALUES
  ('MERCHANT_NOT_FOUND',    'zh', '商户不存在'),
  ('MERCHANT_NOT_FOUND',    'en', 'Merchant not found'),
  ('MERCHANT_NOT_FOUND',    'vi', 'Không tìm thấy thương nhân'),
  ('MERCHANT_NOT_FOUND',    'km', 'រក​មិន​ឃើញ​ពណិជ្ជករ'),
  ('MERCHANT_NOT_FOUND',    'th', 'ไม่พบข้อมูลผู้ค้า'),

  ('MERCHANT_AUDIT_PENDING','zh', '商户尚未审核通过'),
  ('MERCHANT_AUDIT_PENDING','en', 'Merchant pending approval'),
  ('MERCHANT_AUDIT_PENDING','vi', 'Thương nhân chờ phê duyệt'),
  ('MERCHANT_AUDIT_PENDING','km', 'ពណិជ្ជករ​កំពុង​រង់ចាំ​ការ​អនុម័ត'),
  ('MERCHANT_AUDIT_PENDING','th', 'ผู้ค้ากำลังรอการอนุมัติ'),

  ('MERCHANT_NO_INVALID',   'zh', '商户号不存在或已停用'),
  ('MERCHANT_NO_INVALID',   'en', 'Merchant number is invalid or disabled'),
  ('MERCHANT_NO_INVALID',   'vi', 'Số thương nhân không hợp lệ hoặc đã bị vô hiệu'),
  ('MERCHANT_NO_INVALID',   'km', 'លេខ​ពណិជ្ជករ​មិន​ត្រឹម​ត្រូវ​ឬ​ត្រូវ​បាន​បិទ'),
  ('MERCHANT_NO_INVALID',   'th', 'หมายเลขผู้ค้าไม่ถูกต้องหรือถูกปิดใช้งาน')
ON DUPLICATE KEY UPDATE `message` = VALUES(`message`);

-- ── 6. 技师 ───────────────────────────────────────────────────────────────────
INSERT INTO `sys_i18n` (`enum_code`, `lang`, `message`) VALUES
  ('TECHNICIAN_NOT_FOUND',        'zh', '技师不存在'),
  ('TECHNICIAN_NOT_FOUND',        'en', 'Technician not found'),
  ('TECHNICIAN_NOT_FOUND',        'vi', 'Không tìm thấy kỹ thuật viên'),
  ('TECHNICIAN_NOT_FOUND',        'km', 'រក​មិន​ឃើញ​អ្នក​បច្ចេកទេស'),
  ('TECHNICIAN_NOT_FOUND',        'th', 'ไม่พบช่างเทคนิค'),

  ('TECHNICIAN_OFFLINE',          'zh', '技师当前不在线'),
  ('TECHNICIAN_OFFLINE',          'en', 'Technician is offline'),
  ('TECHNICIAN_OFFLINE',          'vi', 'Kỹ thuật viên đang ngoại tuyến'),
  ('TECHNICIAN_OFFLINE',          'km', 'អ្នក​បច្ចេកទេស​ផ្តាច់​ការ​ភ្ជាប់'),
  ('TECHNICIAN_OFFLINE',          'th', 'ช่างเทคนิคออฟไลน์'),

  ('TECHNICIAN_BUSY',             'zh', '技师正忙，请稍后再试'),
  ('TECHNICIAN_BUSY',             'en', 'Technician is busy, please try again later'),
  ('TECHNICIAN_BUSY',             'vi', 'Kỹ thuật viên đang bận, vui lòng thử lại sau'),
  ('TECHNICIAN_BUSY',             'km', 'អ្នក​បច្ចេកទេស​ận​ការ'),
  ('TECHNICIAN_BUSY',             'th', 'ช่างเทคนิคยุ่งอยู่ กรุณาลองใหม่ภายหลัง'),

  ('TECHNICIAN_ALREADY_APPLIED',  'zh', '您已提交过申请，请勿重复提交'),
  ('TECHNICIAN_ALREADY_APPLIED',  'en', 'You have already submitted an application'),
  ('TECHNICIAN_ALREADY_APPLIED',  'vi', 'Bạn đã nộp đơn đăng ký, vui lòng không nộp lại'),
  ('TECHNICIAN_ALREADY_APPLIED',  'km', 'អ្នក​បាន​ដាក់​ពាក្យ​ស្នើ​រួច​ហើយ'),
  ('TECHNICIAN_ALREADY_APPLIED',  'th', 'คุณได้ส่งใบสมัครแล้ว กรุณาอย่าส่งซ้ำ'),

  ('TECHNICIAN_AUDIT_PENDING',    'zh', '资质审核中，请耐心等待'),
  ('TECHNICIAN_AUDIT_PENDING',    'en', 'Your application is under review, please wait'),
  ('TECHNICIAN_AUDIT_PENDING',    'vi', 'Đơn của bạn đang được xét duyệt, vui lòng chờ'),
  ('TECHNICIAN_AUDIT_PENDING',    'km', 'ពាក្យ​ស្នើ​របស់​អ្នក​កំពុង​ពិនិត្យ ​សូម​រង់ចាំ'),
  ('TECHNICIAN_AUDIT_PENDING',    'th', 'ใบสมัครของคุณอยู่ระหว่างการตรวจสอบ กรุณารอ'),

  ('TECHNICIAN_AUDIT_REJECTED',   'zh', '审核未通过，请联系客服了解原因'),
  ('TECHNICIAN_AUDIT_REJECTED',   'en', 'Application rejected, please contact support for details'),
  ('TECHNICIAN_AUDIT_REJECTED',   'vi', 'Đơn bị từ chối, vui lòng liên hệ hỗ trợ'),
  ('TECHNICIAN_AUDIT_REJECTED',   'km', 'ពាក្យ​ស្នើ​ត្រូវ​បាន​បដិសេធ ​សូម​ទំនាក់​ទំនង​ជំនួយ'),
  ('TECHNICIAN_AUDIT_REJECTED',   'th', 'ใบสมัครถูกปฏิเสธ กรุณาติดต่อฝ่ายสนับสนุน'),

  ('TECHNICIAN_BANNED',           'zh', '账号已被封禁，请联系客服'),
  ('TECHNICIAN_BANNED',           'en', 'Account has been banned, please contact support'),
  ('TECHNICIAN_BANNED',           'vi', 'Tài khoản bị cấm, vui lòng liên hệ hỗ trợ'),
  ('TECHNICIAN_BANNED',           'km', 'គណនី​ត្រូវ​បាន​ហាម ​សូម​ទំនាក់​ទំនង​ជំនួយ'),
  ('TECHNICIAN_BANNED',           'th', 'บัญชีถูกระงับ กรุณาติดต่อฝ่ายสนับสนุน'),

  ('TECHNICIAN_MOBILE_EXISTS',    'zh', '该手机号已被注册，请直接登录'),
  ('TECHNICIAN_MOBILE_EXISTS',    'en', 'Mobile number already registered, please login directly'),
  ('TECHNICIAN_MOBILE_EXISTS',    'vi', 'Số điện thoại đã được đăng ký, vui lòng đăng nhập'),
  ('TECHNICIAN_MOBILE_EXISTS',    'km', 'លេខ​ទូរស័ព្ទ​ត្រូវ​បាន​ចុះ​ឈ្មោះ​រួច​ហើយ'),
  ('TECHNICIAN_MOBILE_EXISTS',    'th', 'เบอร์โทรศัพท์นี้ลงทะเบียนแล้ว กรุณาเข้าสู่ระบบโดยตรง')
ON DUPLICATE KEY UPDATE `message` = VALUES(`message`);

-- ── 7. 会员 ───────────────────────────────────────────────────────────────────
INSERT INTO `sys_i18n` (`enum_code`, `lang`, `message`) VALUES
  ('MEMBER_NOT_FOUND',      'zh', '用户不存在'),
  ('MEMBER_NOT_FOUND',      'en', 'User not found'),
  ('MEMBER_NOT_FOUND',      'vi', 'Không tìm thấy người dùng'),
  ('MEMBER_NOT_FOUND',      'km', 'រក​មិន​ឃើញ​អ្នក​ប្រើ'),
  ('MEMBER_NOT_FOUND',      'th', 'ไม่พบผู้ใช้')
ON DUPLICATE KEY UPDATE `message` = VALUES(`message`);

-- ── 8. 订单 ───────────────────────────────────────────────────────────────────
INSERT INTO `sys_i18n` (`enum_code`, `lang`, `message`) VALUES
  ('ORDER_NOT_FOUND',       'zh', '订单不存在'),
  ('ORDER_NOT_FOUND',       'en', 'Order not found'),
  ('ORDER_NOT_FOUND',       'vi', 'Không tìm thấy đơn hàng'),
  ('ORDER_NOT_FOUND',       'km', 'រក​មិន​ឃើញ​ការ​បញ្ជា'),
  ('ORDER_NOT_FOUND',       'th', 'ไม่พบคำสั่งซื้อ'),

  ('ORDER_STATUS_ILLEGAL',  'zh', '当前订单状态不允许此操作'),
  ('ORDER_STATUS_ILLEGAL',  'en', 'Order status does not allow this operation'),
  ('ORDER_STATUS_ILLEGAL',  'vi', 'Trạng thái đơn hàng không cho phép thao tác này'),
  ('ORDER_STATUS_ILLEGAL',  'km', 'ស្ថានភាព​ការ​បញ្ជា​មិន​អនុញ្ញាត​ប្រតិបត្តិ​ការ​នេះ'),
  ('ORDER_STATUS_ILLEGAL',  'th', 'สถานะคำสั่งซื้อไม่อนุญาตให้ดำเนินการ'),

  ('ORDER_CANNOT_CANCEL',   'zh', '当前订单状态不允许取消'),
  ('ORDER_CANNOT_CANCEL',   'en', 'Order cannot be cancelled at current status'),
  ('ORDER_CANNOT_CANCEL',   'vi', 'Không thể hủy đơn hàng ở trạng thái hiện tại'),
  ('ORDER_CANNOT_CANCEL',   'km', 'មិន​អាច​លុប​ការ​បញ្ជា​ក្នុង​ស្ថានភាព​នេះ'),
  ('ORDER_CANNOT_CANCEL',   'th', 'ไม่สามารถยกเลิกคำสั่งซื้อในสถานะนี้ได้'),

  ('ORDER_ALREADY_REVIEWED','zh', '该订单已完成评价，无法重复提交'),
  ('ORDER_ALREADY_REVIEWED','en', 'Order has already been reviewed'),
  ('ORDER_ALREADY_REVIEWED','vi', 'Đơn hàng đã được đánh giá'),
  ('ORDER_ALREADY_REVIEWED','km', 'ការ​បញ្ជា​ត្រូវ​បាន​វាយ​តម្លៃ​រួច​ហើយ'),
  ('ORDER_ALREADY_REVIEWED','th', 'คำสั่งซื้อได้รับการรีวิวแล้ว')
ON DUPLICATE KEY UPDATE `message` = VALUES(`message`);

-- ── 9. 支付 / 钱包 ────────────────────────────────────────────────────────────
INSERT INTO `sys_i18n` (`enum_code`, `lang`, `message`) VALUES
  ('PAYMENT_FAILED',        'zh', '支付失败，请稍后重试'),
  ('PAYMENT_FAILED',        'en', 'Payment failed, please try again'),
  ('PAYMENT_FAILED',        'vi', 'Thanh toán thất bại, vui lòng thử lại'),
  ('PAYMENT_FAILED',        'km', 'ការ​ទូទាត់​បាន​បរាជ័យ ​សូម​ព្យាយាម​ម្ដង​ទៀត'),
  ('PAYMENT_FAILED',        'th', 'การชำระเงินล้มเหลว กรุณาลองใหม่'),

  ('WITHDRAW_MIN_AMOUNT',   'zh', '提现金额不足最低限额'),
  ('WITHDRAW_MIN_AMOUNT',   'en', 'Withdrawal amount is below the minimum limit'),
  ('WITHDRAW_MIN_AMOUNT',   'vi', 'Số tiền rút thấp hơn mức tối thiểu'),
  ('WITHDRAW_MIN_AMOUNT',   'km', 'ចំនួន​ដក​ប្រាក់​ទាប​ជាង​ដែន​កំណត់​អប្បបរមា'),
  ('WITHDRAW_MIN_AMOUNT',   'th', 'จำนวนการถอนต่ำกว่าขั้นต่ำที่กำหนด'),

  ('BALANCE_INSUFFICIENT',  'zh', '账户余额不足'),
  ('BALANCE_INSUFFICIENT',  'en', 'Insufficient balance'),
  ('BALANCE_INSUFFICIENT',  'vi', 'Số dư không đủ'),
  ('BALANCE_INSUFFICIENT',  'km', 'សមតុល្យ​មិន​គ្រប់​គ្រាន់'),
  ('BALANCE_INSUFFICIENT',  'th', 'ยอดเงินคงเหลือไม่เพียงพอ')
ON DUPLICATE KEY UPDATE `message` = VALUES(`message`);

-- ── 10. 优惠券 ────────────────────────────────────────────────────────────────
INSERT INTO `sys_i18n` (`enum_code`, `lang`, `message`) VALUES
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
ON DUPLICATE KEY UPDATE `message` = VALUES(`message`);

-- ── 11. 散客接待（Walk-in）───────────────────────────────────────────────────
INSERT INTO `sys_i18n` (`enum_code`, `lang`, `message`) VALUES
  ('WALKIN_NOT_FOUND',          'zh', '接待记录不存在'),
  ('WALKIN_NOT_FOUND',          'en', 'Walk-in session not found'),
  ('WALKIN_NOT_FOUND',          'vi', 'Không tìm thấy phiên tiếp đón'),
  ('WALKIN_NOT_FOUND',          'km', 'រក​មិន​ឃើញ​វគ្គ​接待'),
  ('WALKIN_NOT_FOUND',          'th', 'ไม่พบบันทึกการรับบริการ'),

  ('WALKIN_ALREADY_SETTLED',    'zh', '接待已结算，无法重复操作'),
  ('WALKIN_ALREADY_SETTLED',    'en', 'Walk-in session already settled'),
  ('WALKIN_ALREADY_SETTLED',    'vi', 'Phiên tiếp đón đã được thanh toán'),
  ('WALKIN_ALREADY_SETTLED',    'km', 'វគ្គ​接待​ត្រូវ​បាន​ទូទាត់​រួច​ហើយ'),
  ('WALKIN_ALREADY_SETTLED',    'th', 'รายการรับบริการนี้ชำระเงินแล้ว'),

  ('WALKIN_ALREADY_CANCELLED',  'zh', '接待已取消'),
  ('WALKIN_ALREADY_CANCELLED',  'en', 'Walk-in session already cancelled'),
  ('WALKIN_ALREADY_CANCELLED',  'vi', 'Phiên tiếp đón đã bị hủy'),
  ('WALKIN_ALREADY_CANCELLED',  'km', 'វគ្គ​接待​ត្រូវ​បាន​លុបចោល​រួច​ហើយ'),
  ('WALKIN_ALREADY_CANCELLED',  'th', 'รายการรับบริการนี้ถูกยกเลิกแล้ว'),

  ('WALKIN_HAS_ACTIVE_SERVICE', 'zh', '存在进行中的服务项，无法执行此操作'),
  ('WALKIN_HAS_ACTIVE_SERVICE', 'en', 'There are active service items, operation not allowed'),
  ('WALKIN_HAS_ACTIVE_SERVICE', 'vi', 'Có dịch vụ đang thực hiện, không thể thực hiện thao tác này'),
  ('WALKIN_HAS_ACTIVE_SERVICE', 'km', 'មាន​សេវា​ដែល​កំពុង​ដំណើរ​ការ ការ​ប្រតិបត្តិ​មិន​អាច​ធ្វើ​បាន'),
  ('WALKIN_HAS_ACTIVE_SERVICE', 'th', 'มีบริการที่กำลังดำเนินการอยู่ ไม่สามารถดำเนินการได้'),

  ('WALKIN_ITEM_NOT_FOUND',     'zh', '服务项不存在'),
  ('WALKIN_ITEM_NOT_FOUND',     'en', 'Service item not found'),
  ('WALKIN_ITEM_NOT_FOUND',     'vi', 'Không tìm thấy mục dịch vụ'),
  ('WALKIN_ITEM_NOT_FOUND',     'km', 'រក​មិន​ឃើញ​ធាតុ​សេវា'),
  ('WALKIN_ITEM_NOT_FOUND',     'th', 'ไม่พบรายการบริการ')
ON DUPLICATE KEY UPDATE `message` = VALUES(`message`);

-- ── 12. 技师结算 ──────────────────────────────────────────────────────────────
INSERT INTO `sys_i18n` (`enum_code`, `lang`, `message`) VALUES
  ('SETTLEMENT_NOT_FOUND',      'zh', '结算单不存在'),
  ('SETTLEMENT_NOT_FOUND',      'en', 'Settlement record not found'),
  ('SETTLEMENT_NOT_FOUND',      'vi', 'Không tìm thấy phiếu quyết toán'),
  ('SETTLEMENT_NOT_FOUND',      'km', 'រក​មិន​ឃើញ​កំណត់​ត្រា​ទូទាត់'),
  ('SETTLEMENT_NOT_FOUND',      'th', 'ไม่พบรายการชำระเงิน'),

  ('SETTLEMENT_ALREADY_PAID',   'zh', '该结算单已完成打款，无法重复操作'),
  ('SETTLEMENT_ALREADY_PAID',   'en', 'Settlement already paid'),
  ('SETTLEMENT_ALREADY_PAID',   'vi', 'Phiếu quyết toán đã được thanh toán'),
  ('SETTLEMENT_ALREADY_PAID',   'km', 'ការ​ទូទាត់​ត្រូវ​បាន​ទូទាត់​រួច​ហើយ'),
  ('SETTLEMENT_ALREADY_PAID',   'th', 'รายการชำระเงินนี้ดำเนินการแล้ว'),

  ('SETTLEMENT_PERIOD_EXISTS',  'zh', '该周期已存在结算单，请勿重复生成'),
  ('SETTLEMENT_PERIOD_EXISTS',  'en', 'Settlement for this period already exists'),
  ('SETTLEMENT_PERIOD_EXISTS',  'vi', 'Phiếu quyết toán cho kỳ này đã tồn tại'),
  ('SETTLEMENT_PERIOD_EXISTS',  'km', 'ការ​ទូទាត់​សម្រាប់​រយៈ​ពេល​នេះ​មាន​រួច​ហើយ'),
  ('SETTLEMENT_PERIOD_EXISTS',  'th', 'รายการชำระเงินในงวดนี้มีอยู่แล้ว'),

  ('SETTLEMENT_MODE_INVALID',   'zh', '不支持的结算模式'),
  ('SETTLEMENT_MODE_INVALID',   'en', 'Invalid settlement mode'),
  ('SETTLEMENT_MODE_INVALID',   'vi', 'Chế độ thanh toán không hợp lệ'),
  ('SETTLEMENT_MODE_INVALID',   'km', 'របៀប​ទូទាត់​មិន​ត្រឹម​ត្រូវ'),
  ('SETTLEMENT_MODE_INVALID',   'th', 'รูปแบบการชำระเงินไม่ถูกต้อง'),

  ('SETTLEMENT_IDS_EMPTY',      'zh', '结算单 ID 列表不能为空'),
  ('SETTLEMENT_IDS_EMPTY',      'en', 'Settlement ID list cannot be empty'),
  ('SETTLEMENT_IDS_EMPTY',      'vi', 'Danh sách ID quyết toán không được để trống'),
  ('SETTLEMENT_IDS_EMPTY',      'km', 'បញ្ជី​ ID ​ការ​ទូទាត់​មិន​អាច​ទទេ'),
  ('SETTLEMENT_IDS_EMPTY',      'th', 'รายการ ID การชำระเงินไม่สามารถว่างได้')
ON DUPLICATE KEY UPDATE `message` = VALUES(`message`);

-- ── 13. 部门 / 权限树 ─────────────────────────────────────────────────────────
INSERT INTO `sys_i18n` (`enum_code`, `lang`, `message`) VALUES
  ('DEPT_HAS_CHILDREN',          'zh', '存在子部门，不允许删除'),
  ('DEPT_HAS_CHILDREN',          'en', 'Cannot delete department with sub-departments'),
  ('DEPT_HAS_CHILDREN',          'vi', 'Không thể xóa phòng ban có phòng ban con'),
  ('DEPT_HAS_CHILDREN',          'km', 'មិន​អាច​លុប​នាយកដ្ឋាន​ដែល​មាន​នាយកដ្ឋាន​រង'),
  ('DEPT_HAS_CHILDREN',          'th', 'ไม่สามารถลบแผนกที่มีแผนกย่อยได้'),

  ('PERM_MOVE_TO_SELF',          'zh', '不能将节点移动到自身'),
  ('PERM_MOVE_TO_SELF',          'en', 'Cannot move node to itself'),
  ('PERM_MOVE_TO_SELF',          'vi', 'Không thể di chuyển nút vào chính nó'),
  ('PERM_MOVE_TO_SELF',          'km', 'មិន​អាច​ផ្លាស់ទី​ថ្នាំង​ទៅ​ខ្លួន​វា​ផ្ទាល់'),
  ('PERM_MOVE_TO_SELF',          'th', 'ไม่สามารถย้ายโหนดไปยังตัวเองได้'),

  ('PERM_MOVE_TO_DESCENDANT',    'zh', '不能将节点移动到其子孙节点下'),
  ('PERM_MOVE_TO_DESCENDANT',    'en', 'Cannot move node to its own descendant'),
  ('PERM_MOVE_TO_DESCENDANT',    'vi', 'Không thể di chuyển nút vào nút con của nó'),
  ('PERM_MOVE_TO_DESCENDANT',    'km', 'មិន​អាច​ផ្លាស់ទី​ថ្នាំង​ទៅ​ថ្នាំង​កូន​របស់​វា'),
  ('PERM_MOVE_TO_DESCENDANT',    'th', 'ไม่สามารถย้ายโหนดไปยังโหนดลูกหลานของตัวเองได้'),

  ('PERM_NODE_PLACEMENT_INVALID','zh', '节点放置位置不符合权限树规则'),
  ('PERM_NODE_PLACEMENT_INVALID','en', 'Node placement violates permission tree rules'),
  ('PERM_NODE_PLACEMENT_INVALID','vi', 'Vị trí đặt nút vi phạm quy tắc cây quyền'),
  ('PERM_NODE_PLACEMENT_INVALID','km', 'ការ​ដាក់​ថ្នាំង​ខុស​ច្បាប់​ដើម​ការ​អនុញ្ញាត'),
  ('PERM_NODE_PLACEMENT_INVALID','th', 'ตำแหน่งโหนดละเมิดกฎของแผนผังสิทธิ์')
ON DUPLICATE KEY UPDATE `message` = VALUES(`message`);

-- ── 14. 车辆 ──────────────────────────────────────────────────────────────────
INSERT INTO `sys_i18n` (`enum_code`, `lang`, `message`) VALUES
  ('VEHICLE_NOT_FOUND',         'zh', '车辆不存在'),
  ('VEHICLE_NOT_FOUND',         'en', 'Vehicle not found'),
  ('VEHICLE_NOT_FOUND',         'vi', 'Không tìm thấy phương tiện'),
  ('VEHICLE_NOT_FOUND',         'km', 'រក​មិន​ឃើញ​យាន​យន្ត'),
  ('VEHICLE_NOT_FOUND',         'th', 'ไม่พบข้อมูลยานพาหนะ')
ON DUPLICATE KEY UPDATE `message` = VALUES(`message`);

-- ── 15. 币种 ──────────────────────────────────────────────────────────────────
INSERT INTO `sys_i18n` (`enum_code`, `lang`, `message`) VALUES
  ('CURRENCY_NOT_FOUND',        'zh', '币种不存在'),
  ('CURRENCY_NOT_FOUND',        'en', 'Currency not found'),
  ('CURRENCY_NOT_FOUND',        'vi', 'Không tìm thấy loại tiền tệ'),
  ('CURRENCY_NOT_FOUND',        'km', 'រក​មិន​ឃើញ​រូបិយបណ្ណ'),
  ('CURRENCY_NOT_FOUND',        'th', 'ไม่พบสกุลเงิน'),

  ('CURRENCY_CODE_EXISTS',      'zh', '货币代码已存在'),
  ('CURRENCY_CODE_EXISTS',      'en', 'Currency code already exists'),
  ('CURRENCY_CODE_EXISTS',      'vi', 'Mã tiền tệ đã tồn tại'),
  ('CURRENCY_CODE_EXISTS',      'km', 'លេខ​កូដ​រូបិយបណ្ណ​មាន​រួច​ហើយ'),
  ('CURRENCY_CODE_EXISTS',      'th', 'รหัสสกุลเงินมีอยู่แล้ว'),

  ('CURRENCY_DEFAULT_CONFLICT', 'zh', '只能设置一个默认收款币种'),
  ('CURRENCY_DEFAULT_CONFLICT', 'en', 'Only one default payment currency is allowed'),
  ('CURRENCY_DEFAULT_CONFLICT', 'vi', 'Chỉ được phép có một loại tiền thanh toán mặc định'),
  ('CURRENCY_DEFAULT_CONFLICT', 'km', 'អាច​កំណត់​រូបិយបណ្ណ​ទូទាត់​លំនាំ​ដើម​បាន​តែ​មួយ'),
  ('CURRENCY_DEFAULT_CONFLICT', 'th', 'อนุญาตให้มีสกุลเงินชำระเงินค่าเริ่มต้นได้เพียงหนึ่งรายการ'),

  ('CURRENCY_INVALID',          'zh', '包含无效或已停用的币种'),
  ('CURRENCY_INVALID',          'en', 'Contains invalid or disabled currencies'),
  ('CURRENCY_INVALID',          'vi', 'Chứa loại tiền tệ không hợp lệ hoặc đã bị vô hiệu hóa'),
  ('CURRENCY_INVALID',          'km', 'មាន​រូបិយបណ្ណ​មិន​ត្រឹម​ត្រូវ​ឬ​ត្រូវ​បាន​បិទ'),
  ('CURRENCY_INVALID',          'th', 'มีสกุลเงินที่ไม่ถูกต้องหรือถูกปิดใช้งาน')
ON DUPLICATE KEY UPDATE `message` = VALUES(`message`);

-- ── 16. 系统配置 ──────────────────────────────────────────────────────────────
INSERT INTO `sys_i18n` (`enum_code`, `lang`, `message`) VALUES
  ('CONFIG_KEY_EXISTS',         'zh', '参数键名已存在'),
  ('CONFIG_KEY_EXISTS',         'en', 'Config key already exists'),
  ('CONFIG_KEY_EXISTS',         'vi', 'Khóa cấu hình đã tồn tại'),
  ('CONFIG_KEY_EXISTS',         'km', 'សោ​ការ​កំណត់​មាន​រួច​ហើយ'),
  ('CONFIG_KEY_EXISTS',         'th', 'คีย์การกำหนดค่ามีอยู่แล้ว'),

  ('CONFIG_BUILTIN',            'zh', '内置参数不允许删除'),
  ('CONFIG_BUILTIN',            'en', 'Built-in config cannot be deleted'),
  ('CONFIG_BUILTIN',            'vi', 'Không thể xóa cấu hình tích hợp sẵn'),
  ('CONFIG_BUILTIN',            'km', 'មិន​អាច​លុប​ការ​កំណត់​ដែល​បង្កើត​ក្នុង​ប្រព័ន្ធ'),
  ('CONFIG_BUILTIN',            'th', 'ไม่สามารถลบค่าการกำหนดค่าในตัวได้')
ON DUPLICATE KEY UPDATE `message` = VALUES(`message`);

-- ── 17. 分类 ──────────────────────────────────────────────────────────────────
INSERT INTO `sys_i18n` (`enum_code`, `lang`, `message`) VALUES
  ('CATEGORY_HAS_CHILDREN',     'zh', '存在子分类，请先删除子分类'),
  ('CATEGORY_HAS_CHILDREN',     'en', 'Cannot delete category with sub-categories'),
  ('CATEGORY_HAS_CHILDREN',     'vi', 'Không thể xóa danh mục có danh mục con'),
  ('CATEGORY_HAS_CHILDREN',     'km', 'មិន​អាច​លុប​ប្រភេទ​ដែល​មាន​ប្រភេទ​រង'),
  ('CATEGORY_HAS_CHILDREN',     'th', 'ไม่สามารถลบหมวดหมู่ที่มีหมวดหมู่ย่อยได้')
ON DUPLICATE KEY UPDATE `message` = VALUES(`message`);

-- ── 18. 定价 ──────────────────────────────────────────────────────────────────
INSERT INTO `sys_i18n` (`enum_code`, `lang`, `message`) VALUES
  ('PRICING_NOT_SPECIAL',       'zh', '仅特殊项目支持设置技师专属价格'),
  ('PRICING_NOT_SPECIAL',       'en', 'Technician-specific pricing is only available for special service items'),
  ('PRICING_NOT_SPECIAL',       'vi', 'Giá riêng cho kỹ thuật viên chỉ áp dụng cho dịch vụ đặc biệt'),
  ('PRICING_NOT_SPECIAL',       'km', 'តម្លៃ​ជំនាញ​ប្រហាក់​ប្រហែល​ចំពោះ​សេវា​ពិសេស​ប៉ុណ្ណោះ'),
  ('PRICING_NOT_SPECIAL',       'th', 'การกำหนดราคาเฉพาะช่างใช้ได้กับรายการบริการพิเศษเท่านั้น')
ON DUPLICATE KEY UPDATE `message` = VALUES(`message`);

-- ── 验证 ──────────────────────────────────────────────────────────────────────
SELECT
    COUNT(*)                           AS total_records,
    COUNT(DISTINCT `enum_code`)        AS total_enums,
    SUM(IF(`lang` = 'zh', 1, 0))      AS zh_count,
    SUM(IF(`lang` = 'en', 1, 0))      AS en_count,
    SUM(IF(`lang` = 'vi', 1, 0))      AS vi_count,
    SUM(IF(`lang` = 'km', 1, 0))      AS km_count,
    SUM(IF(`lang` = 'th', 1, 0))      AS th_count
FROM `sys_i18n`;

SELECT '✅ migrate_i18n_full 执行完成' AS result;
