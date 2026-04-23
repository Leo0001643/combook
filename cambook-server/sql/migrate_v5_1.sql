-- ============================================================
-- migrate_v5_1.sql  技师端登录状态消息补全
--
-- 补充内容：
--   1. TECHNICIAN_NOT_FOUND     —— 技师账号/密码错误（账号不存在 & 密码错误统一消息，防枚举）
--   2. TECHNICIAN_AUDIT_PENDING —— 账号待审核
--
-- 使用 ON DUPLICATE KEY UPDATE 保证脚本幂等（重复执行不报错）
-- ============================================================

INSERT INTO `sys_i18n` (`enum_code`, `lang`, `message`) VALUES

-- ── TECHNICIAN_NOT_FOUND（账号不存在 或 密码错误，统一提示防枚举攻击）───────────
('TECHNICIAN_NOT_FOUND','zh','账号或密码错误，请重新输入'),
('TECHNICIAN_NOT_FOUND','en','Incorrect account or password, please try again'),
('TECHNICIAN_NOT_FOUND','vi','Tài khoản hoặc mật khẩu không đúng, vui lòng thử lại'),
('TECHNICIAN_NOT_FOUND','km','គណនី ឬលេខសម្ងាត់មិនត្រឹមត្រូវ សូមព្យាយាមម្ដងទៀត'),
('TECHNICIAN_NOT_FOUND','ja','アカウントまたはパスワードが正しくありません。再度入力してください'),
('TECHNICIAN_NOT_FOUND','ko','계정 또는 비밀번호가 올바르지 않습니다. 다시 입력해 주세요'),

-- ── TECHNICIAN_AUDIT_PENDING（注册后等待商户审核）────────────────────────────────
('TECHNICIAN_AUDIT_PENDING','zh','账号正在审核中，请耐心等待商户审核通过后再登录'),
('TECHNICIAN_AUDIT_PENDING','en','Your account is under review, please wait for merchant approval before logging in'),
('TECHNICIAN_AUDIT_PENDING','vi','Tài khoản đang được xem xét, vui lòng chờ đối tác phê duyệt trước khi đăng nhập'),
('TECHNICIAN_AUDIT_PENDING','km','គណនីរបស់អ្នកកំពុងត្រូវបានពិនិត្យ សូមរង់ចាំការអនុម័តពីឈ្មួញ'),
('TECHNICIAN_AUDIT_PENDING','ja','アカウントは審査中です。加盟店の承認後にログインしてください'),
('TECHNICIAN_AUDIT_PENDING','ko','계정이 심사 중입니다. 가맹점 승인 후 로그인해 주세요')

AS new_vals(enum_code, lang, message)
ON DUPLICATE KEY UPDATE message = new_vals.message;
