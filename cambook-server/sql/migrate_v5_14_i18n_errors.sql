-- ═══════════════════════════════════════════════════════════════════════════
-- Migration v5.14 — 补全 sys_i18n 多语言错误码（Walk-in + Settlement + Order）
--
-- 对应 CbCodeEnum 新增枚举常量：
--   WALKIN_NOT_FOUND / WALKIN_ALREADY_SETTLED / WALKIN_ALREADY_CANCELLED
--   WALKIN_HAS_ACTIVE_SERVICE / WALKIN_ITEM_NOT_FOUND
--   SETTLEMENT_NOT_FOUND / SETTLEMENT_ALREADY_PAID
--   SETTLEMENT_PERIOD_EXISTS / SETTLEMENT_MODE_INVALID / SETTLEMENT_IDS_EMPTY
--
-- 支持语言：zh / en / vi / km / th
-- ═══════════════════════════════════════════════════════════════════════════

SET NAMES utf8mb4;

-- ──────────────────────────────────────────────────────────────────────────
-- 重建表：先删后建，确保表结构与 cambook_baseline.sql 完全一致
-- ──────────────────────────────────────────────────────────────────────────
DROP TABLE IF EXISTS `sys_i18n`;

CREATE TABLE `sys_i18n` (
    `id`          BIGINT       NOT NULL AUTO_INCREMENT                              COMMENT '主键，自增',
    `enum_code`   VARCHAR(100) NOT NULL                                             COMMENT 'CbCodeEnum 枚举常量名',
    `lang`        VARCHAR(10)  NOT NULL                                             COMMENT '语言标识：zh/en/vi/km/th',
    `message`     VARCHAR(500) NOT NULL                                             COMMENT '对应语言的消息文本',
    `create_time` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP                   COMMENT '创建时间，自动填充',
    `update_time` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '最后修改时间，自动更新',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_enum_lang`  (`enum_code`, `lang`),
    KEY           `idx_enum_code` (`enum_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='国际化枚举消息表';


-- ──────────────────────────────────────────────────────────────────────────
-- Walk-in 散客接待错误码
-- ──────────────────────────────────────────────────────────────────────────
INSERT INTO sys_i18n (enum_code, lang, message) VALUES
  ('WALKIN_NOT_FOUND',         'zh', '接待记录不存在'),
  ('WALKIN_NOT_FOUND',         'en', 'Walk-in session not found'),
  ('WALKIN_NOT_FOUND',         'vi', 'Không tìm thấy phiên tiếp đón'),
  ('WALKIN_NOT_FOUND',         'km', 'រក​មិន​ឃើញ​វគ្គ​接待'),
  ('WALKIN_NOT_FOUND',         'th', 'ไม่พบบันทึกการรับบริการ'),

  ('WALKIN_ALREADY_SETTLED',   'zh', '接待已结算，无法重复操作'),
  ('WALKIN_ALREADY_SETTLED',   'en', 'Walk-in session already settled'),
  ('WALKIN_ALREADY_SETTLED',   'vi', 'Phiên tiếp đón đã được thanh toán'),
  ('WALKIN_ALREADY_SETTLED',   'km', 'វគ្គ​接待​ត្រូវ​បាន​ទូទាត់​រួច​ហើយ'),
  ('WALKIN_ALREADY_SETTLED',   'th', 'รายการรับบริการนี้ชำระเงินแล้ว'),

  ('WALKIN_ALREADY_CANCELLED', 'zh', '接待已取消'),
  ('WALKIN_ALREADY_CANCELLED', 'en', 'Walk-in session already cancelled'),
  ('WALKIN_ALREADY_CANCELLED', 'vi', 'Phiên tiếp đón đã bị hủy'),
  ('WALKIN_ALREADY_CANCELLED', 'km', 'វគ្គ​接待​ត្រូវ​បាន​លុបចោល​រួច​ហើយ'),
  ('WALKIN_ALREADY_CANCELLED', 'th', 'รายการรับบริการนี้ถูกยกเลิกแล้ว'),

  ('WALKIN_HAS_ACTIVE_SERVICE','zh', '存在进行中的服务项，无法执行此操作'),
  ('WALKIN_HAS_ACTIVE_SERVICE','en', 'There are active service items, operation not allowed'),
  ('WALKIN_HAS_ACTIVE_SERVICE','vi', 'Có dịch vụ đang thực hiện, không thể thực hiện thao tác này'),
  ('WALKIN_HAS_ACTIVE_SERVICE','km', 'មាន​សេវា​ដែល​កំពុង​ដំណើរ​ការ ការ​ប្រតិបត្តិ​មិន​អាច​ធ្វើ​បាន'),
  ('WALKIN_HAS_ACTIVE_SERVICE','th', 'มีบริการที่กำลังดำเนินการอยู่ ไม่สามารถดำเนินการได้'),

  ('WALKIN_ITEM_NOT_FOUND',    'zh', '服务项不存在'),
  ('WALKIN_ITEM_NOT_FOUND',    'en', 'Service item not found'),
  ('WALKIN_ITEM_NOT_FOUND',    'vi', 'Không tìm thấy mục dịch vụ'),
  ('WALKIN_ITEM_NOT_FOUND',    'km', 'រក​មិន​ឃើញ​ធាតុ​សេវា'),
  ('WALKIN_ITEM_NOT_FOUND',    'th', 'ไม่พบรายการบริการ')
ON DUPLICATE KEY UPDATE message = VALUES(message);

-- ──────────────────────────────────────────────────────────────────────────
-- 技师结算错误码
-- ──────────────────────────────────────────────────────────────────────────
INSERT INTO sys_i18n (enum_code, lang, message) VALUES
  ('SETTLEMENT_NOT_FOUND',     'zh', '结算单不存在'),
  ('SETTLEMENT_NOT_FOUND',     'en', 'Settlement record not found'),
  ('SETTLEMENT_NOT_FOUND',     'vi', 'Không tìm thấy phiếu quyết toán'),
  ('SETTLEMENT_NOT_FOUND',     'km', 'រក​មិន​ឃើញ​កំណត់​ត្រា​ទូទាត់'),
  ('SETTLEMENT_NOT_FOUND',     'th', 'ไม่พบรายการชำระเงิน'),

  ('SETTLEMENT_ALREADY_PAID',  'zh', '该结算单已完成打款，无法重复操作'),
  ('SETTLEMENT_ALREADY_PAID',  'en', 'Settlement already paid'),
  ('SETTLEMENT_ALREADY_PAID',  'vi', 'Phiếu quyết toán đã được thanh toán'),
  ('SETTLEMENT_ALREADY_PAID',  'km', 'ការ​ទូទាត់​ត្រូវ​បាន​ទូទាត់​រួច​ហើយ'),
  ('SETTLEMENT_ALREADY_PAID',  'th', 'รายการชำระเงินนี้ดำเนินการแล้ว'),

  ('SETTLEMENT_PERIOD_EXISTS', 'zh', '该周期已存在结算单，请勿重复生成'),
  ('SETTLEMENT_PERIOD_EXISTS', 'en', 'Settlement for this period already exists'),
  ('SETTLEMENT_PERIOD_EXISTS', 'vi', 'Phiếu quyết toán cho kỳ này đã tồn tại'),
  ('SETTLEMENT_PERIOD_EXISTS', 'km', 'ការ​ទូទាត់​សម្រាប់​រយៈ​ពេល​នេះ​មាន​រួច​ហើយ'),
  ('SETTLEMENT_PERIOD_EXISTS', 'th', 'รายการชำระเงินในงวดนี้มีอยู่แล้ว'),

  ('SETTLEMENT_MODE_INVALID',  'zh', '不支持的结算模式'),
  ('SETTLEMENT_MODE_INVALID',  'en', 'Invalid settlement mode'),
  ('SETTLEMENT_MODE_INVALID',  'vi', 'Chế độ thanh toán không hợp lệ'),
  ('SETTLEMENT_MODE_INVALID',  'km', 'របៀប​ទូទាត់​មិន​ត្រឹម​ត្រូវ'),
  ('SETTLEMENT_MODE_INVALID',  'th', 'รูปแบบการชำระเงินไม่ถูกต้อง'),

  ('SETTLEMENT_IDS_EMPTY',     'zh', '结算单 ID 列表不能为空'),
  ('SETTLEMENT_IDS_EMPTY',     'en', 'Settlement ID list cannot be empty'),
  ('SETTLEMENT_IDS_EMPTY',     'vi', 'Danh sách ID quyết toán không được để trống'),
  ('SETTLEMENT_IDS_EMPTY',     'km', 'បញ្ជី​ ID ​ការ​ទូទាត់​មិន​អាច​ទទេ'),
  ('SETTLEMENT_IDS_EMPTY',     'th', 'รายการ ID การชำระเงินไม่สามารถว่างได้')
ON DUPLICATE KEY UPDATE message = VALUES(message);

-- ──────────────────────────────────────────────────────────────────────────
-- 补全现有枚举（之前未在 sys_i18n 中配置的）
-- ──────────────────────────────────────────────────────────────────────────
INSERT INTO sys_i18n (enum_code, lang, message) VALUES
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

  ('TOKEN_INVALID',         'zh', '登录凭证无效，请重新登录'),
  ('TOKEN_INVALID',         'en', 'Token invalid, please login again'),
  ('TOKEN_INVALID',         'vi', 'Token không hợp lệ, vui lòng đăng nhập lại'),
  ('TOKEN_INVALID',         'km', 'ថូ​ខឹន​មិន​ត្រឹម​ត្រូវ'),
  ('TOKEN_INVALID',         'th', 'โทเค็นไม่ถูกต้อง กรุณาเข้าสู่ระบบใหม่'),

  ('TOKEN_EXPIRED',         'zh', '登录已过期，请重新登录'),
  ('TOKEN_EXPIRED',         'en', 'Token expired, please login again'),
  ('TOKEN_EXPIRED',         'vi', 'Token đã hết hạn, vui lòng đăng nhập lại'),
  ('TOKEN_EXPIRED',         'km', 'ថូ​ខឹន​ផុត​សុពលភាព'),
  ('TOKEN_EXPIRED',         'th', 'โทเค็นหมดอายุ กรุณาเข้าสู่ระบบใหม่'),

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
  ('ACCOUNT_NOT_FOUND',     'th', 'ไม่พบบัญชี'),

  ('SMS_CODE_WRONG',        'zh', '密码错误'),
  ('SMS_CODE_WRONG',        'en', 'Password incorrect'),
  ('SMS_CODE_WRONG',        'vi', 'Mật khẩu không đúng'),
  ('SMS_CODE_WRONG',        'km', 'លេខ​សម្ងាត់​មិន​ត្រឹម​ត្រូវ'),
  ('SMS_CODE_WRONG',        'th', 'รหัสผ่านไม่ถูกต้อง'),

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

  ('BALANCE_INSUFFICIENT',  'zh', '账户余额不足'),
  ('BALANCE_INSUFFICIENT',  'en', 'Insufficient balance'),
  ('BALANCE_INSUFFICIENT',  'vi', 'Số dư không đủ'),
  ('BALANCE_INSUFFICIENT',  'km', 'សមតុល្យ​មិន​គ្រប់​គ្រាន់'),
  ('BALANCE_INSUFFICIENT',  'th', 'ยอดเงินคงเหลือไม่เพียงพอ'),

  ('MEMBER_NOT_FOUND',      'zh', '用户不存在'),
  ('MEMBER_NOT_FOUND',      'en', 'User not found'),
  ('MEMBER_NOT_FOUND',      'vi', 'Không tìm thấy người dùng'),
  ('MEMBER_NOT_FOUND',      'km', 'រក​មិន​ឃើញ​អ្នក​ប្រើ'),
  ('MEMBER_NOT_FOUND',      'th', 'ไม่พบผู้ใช้'),

  ('TECHNICIAN_NOT_FOUND',  'zh', '技师不存在'),
  ('TECHNICIAN_NOT_FOUND',  'en', 'Technician not found'),
  ('TECHNICIAN_NOT_FOUND',  'vi', 'Không tìm thấy kỹ thuật viên'),
  ('TECHNICIAN_NOT_FOUND',  'km', 'រក​មិន​ឃើញ​អ្នក​បច្ចេកទេស'),
  ('TECHNICIAN_NOT_FOUND',  'th', 'ไม่พบช่างเทคนิค'),

  ('TECHNICIAN_OFFLINE',    'zh', '技师当前不在线'),
  ('TECHNICIAN_OFFLINE',    'en', 'Technician is offline'),
  ('TECHNICIAN_OFFLINE',    'vi', 'Kỹ thuật viên đang ngoại tuyến'),
  ('TECHNICIAN_OFFLINE',    'km', 'អ្នក​បច្ចេកទេស​ផ្តាច់​ការ​ភ្ជាប់'),
  ('TECHNICIAN_OFFLINE',    'th', 'ช่างเทคนิคออฟไลน์'),

  ('TECHNICIAN_BUSY',       'zh', '技师正忙，请稍后再试'),
  ('TECHNICIAN_BUSY',       'en', 'Technician is busy, please try again later'),
  ('TECHNICIAN_BUSY',       'vi', 'Kỹ thuật viên đang bận, vui lòng thử lại sau'),
  ('TECHNICIAN_BUSY',       'km', 'អ្នក​បច្ចេកទេស​ận​ការ'),
  ('TECHNICIAN_BUSY',       'th', 'ช่างเทคนิคยุ่งอยู่ กรุณาลองใหม่ภายหลัง')
ON DUPLICATE KEY UPDATE message = VALUES(message);

-- ──────────────────────────────────────────────────────────────────────────
-- 本次新增枚举码（本轮架构优化新增）
-- ──────────────────────────────────────────────────────────────────────────
INSERT INTO sys_i18n (enum_code, lang, message) VALUES
  ('DEPT_HAS_CHILDREN',        'zh', '存在子部门，不允许删除'),
  ('DEPT_HAS_CHILDREN',        'en', 'Cannot delete department with sub-departments'),
  ('DEPT_HAS_CHILDREN',        'vi', 'Không thể xóa phòng ban có phòng ban con'),
  ('DEPT_HAS_CHILDREN',        'km', 'មិន​អាច​លុប​នាយកដ្ឋាន​ដែល​មាន​នាយកដ្ឋាន​រង'),
  ('DEPT_HAS_CHILDREN',        'th', 'ไม่สามารถลบแผนกที่มีแผนกย่อยได้'),

  ('VEHICLE_NOT_FOUND',        'zh', '车辆不存在'),
  ('VEHICLE_NOT_FOUND',        'en', 'Vehicle not found'),
  ('VEHICLE_NOT_FOUND',        'vi', 'Không tìm thấy phương tiện'),
  ('VEHICLE_NOT_FOUND',        'km', 'រក​មិន​ឃើញ​យាន​យន្ត'),
  ('VEHICLE_NOT_FOUND',        'th', 'ไม่พบข้อมูลยานพาหนะ'),

  ('CURRENCY_NOT_FOUND',       'zh', '币种不存在'),
  ('CURRENCY_NOT_FOUND',       'en', 'Currency not found'),
  ('CURRENCY_NOT_FOUND',       'vi', 'Không tìm thấy loại tiền tệ'),
  ('CURRENCY_NOT_FOUND',       'km', 'រក​មិន​ឃើញ​រូបិយបណ្ណ'),
  ('CURRENCY_NOT_FOUND',       'th', 'ไม่พบสกุลเงิน'),

  ('CURRENCY_CODE_EXISTS',     'zh', '货币代码已存在'),
  ('CURRENCY_CODE_EXISTS',     'en', 'Currency code already exists'),
  ('CURRENCY_CODE_EXISTS',     'vi', 'Mã tiền tệ đã tồn tại'),
  ('CURRENCY_CODE_EXISTS',     'km', 'លេខ​កូដ​រូបិយបណ្ណ​មាន​រួច​ហើយ'),
  ('CURRENCY_CODE_EXISTS',     'th', 'รหัสสกุลเงินมีอยู่แล้ว'),

  ('CURRENCY_DEFAULT_CONFLICT','zh', '只能设置一个默认收款币种'),
  ('CURRENCY_DEFAULT_CONFLICT','en', 'Only one default payment currency is allowed'),
  ('CURRENCY_DEFAULT_CONFLICT','vi', 'Chỉ được phép có một loại tiền thanh toán mặc định'),
  ('CURRENCY_DEFAULT_CONFLICT','km', 'អាច​កំណត់​រូបិយបណ្ណ​ទូទាត់​លំនាំ​ដើម​បាន​តែ​មួយ'),
  ('CURRENCY_DEFAULT_CONFLICT','th', 'อนุญาตให้มีสกุลเงินชำระเงินค่าเริ่มต้นได้เพียงหนึ่งรายการ'),

  ('CURRENCY_INVALID',         'zh', '包含无效或已停用的币种'),
  ('CURRENCY_INVALID',         'en', 'Contains invalid or disabled currencies'),
  ('CURRENCY_INVALID',         'vi', 'Chứa loại tiền tệ không hợp lệ hoặc đã bị vô hiệu hóa'),
  ('CURRENCY_INVALID',         'km', 'មាន​រូបិយបណ្ណ​មិន​ត្រឹម​ត្រូវ​ឬ​ត្រូវ​បាន​បិទ'),
  ('CURRENCY_INVALID',         'th', 'มีสกุลเงินที่ไม่ถูกต้องหรือถูกปิดใช้งาน'),

  ('CONFIG_KEY_EXISTS',        'zh', '参数键名已存在'),
  ('CONFIG_KEY_EXISTS',        'en', 'Config key already exists'),
  ('CONFIG_KEY_EXISTS',        'vi', 'Khóa cấu hình đã tồn tại'),
  ('CONFIG_KEY_EXISTS',        'km', 'សោ​ការ​កំណត់​មាន​រួច​ហើយ'),
  ('CONFIG_KEY_EXISTS',        'th', 'คีย์การกำหนดค่ามีอยู่แล้ว'),

  ('CONFIG_BUILTIN',           'zh', '内置参数不允许删除'),
  ('CONFIG_BUILTIN',           'en', 'Built-in config cannot be deleted'),
  ('CONFIG_BUILTIN',           'vi', 'Không thể xóa cấu hình tích hợp sẵn'),
  ('CONFIG_BUILTIN',           'km', 'មិន​អាច​លុប​ការ​កំណត់​ដែល​បង្កើត​ក្នុង​ប្រព័ន្ធ'),
  ('CONFIG_BUILTIN',           'th', 'ไม่สามารถลบค่าการกำหนดค่าในตัวได้'),

  ('CATEGORY_HAS_CHILDREN',    'zh', '存在子分类，请先删除子分类'),
  ('CATEGORY_HAS_CHILDREN',    'en', 'Cannot delete category with sub-categories'),
  ('CATEGORY_HAS_CHILDREN',    'vi', 'Không thể xóa danh mục có danh mục con'),
  ('CATEGORY_HAS_CHILDREN',    'km', 'មិន​អាច​លុប​ប្រភេទ​ដែល​មាន​ប្រភេទ​រង'),
  ('CATEGORY_HAS_CHILDREN',    'th', 'ไม่สามารถลบหมวดหมู่ที่มีหมวดหมู่ย่อยได้'),

  ('PERM_MOVE_TO_SELF',        'zh', '不能将节点移动到自身'),
  ('PERM_MOVE_TO_SELF',        'en', 'Cannot move node to itself'),
  ('PERM_MOVE_TO_SELF',        'vi', 'Không thể di chuyển nút vào chính nó'),
  ('PERM_MOVE_TO_SELF',        'km', 'មិន​អាច​ផ្លាស់ទី​ថ្នាំង​ទៅ​ខ្លួន​វា​ផ្ទាល់'),
  ('PERM_MOVE_TO_SELF',        'th', 'ไม่สามารถย้ายโหนดไปยังตัวเองได้'),

  ('PERM_MOVE_TO_DESCENDANT',  'zh', '不能将节点移动到其子孙节点下'),
  ('PERM_MOVE_TO_DESCENDANT',  'en', 'Cannot move node to its own descendant'),
  ('PERM_MOVE_TO_DESCENDANT',  'vi', 'Không thể di chuyển nút vào nút con của nó'),
  ('PERM_MOVE_TO_DESCENDANT',  'km', 'មិន​អាច​ផ្លាស់ទី​ថ្នាំង​ទៅ​ថ្នាំង​កូន​របស់​វា'),
  ('PERM_MOVE_TO_DESCENDANT',  'th', 'ไม่สามารถย้ายโหนดไปยังโหนดลูกหลานของตัวเองได้'),

  ('PERM_NODE_PLACEMENT_INVALID','zh', '节点放置位置不符合权限树规则'),
  ('PERM_NODE_PLACEMENT_INVALID','en', 'Node placement violates permission tree rules'),
  ('PERM_NODE_PLACEMENT_INVALID','vi', 'Vị trí đặt nút vi phạm quy tắc cây quyền'),
  ('PERM_NODE_PLACEMENT_INVALID','km', 'ការ​ដាក់​ថ្នាំង​ខុស​ច្បាប់​ដើម​ការ​អនុញ្ញាត'),
  ('PERM_NODE_PLACEMENT_INVALID','th', 'ตำแหน่งโหนดละเมิดกฎของแผนผังสิทธิ์'),

  ('PRICING_NOT_SPECIAL',      'zh', '仅特殊项目支持设置技师专属价格'),
  ('PRICING_NOT_SPECIAL',      'en', 'Technician-specific pricing is only available for special service items'),
  ('PRICING_NOT_SPECIAL',      'vi', 'Giá riêng cho kỹ thuật viên chỉ áp dụng cho dịch vụ đặc biệt'),
  ('PRICING_NOT_SPECIAL',      'km', 'តម្លៃ​ជំនាញ​ប្រហាក់​ប្រហែល​ចំពោះ​សេវា​ពិសេស​ប៉ុណ្ណោះ'),
  ('PRICING_NOT_SPECIAL',      'th', 'การกำหนดราคาเฉพาะช่างใช้ได้กับรายการบริการพิเศษเท่านั้น')
ON DUPLICATE KEY UPDATE message = VALUES(message);

SELECT CONCAT('sys_i18n 国际化数据插入/更新完成（zh/en/vi/km/th）') AS result;
