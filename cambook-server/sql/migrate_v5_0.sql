-- ============================================================
-- migrate_v5_0.sql  国际化消息补全
--
-- 补充内容：
--   1. CbCodeEnum 新增的技师端枚举（TECHNICIAN_AUDIT_REJECTED /
--      TECHNICIAN_BANNED / TECHNICIAN_MOBILE_EXISTS / MERCHANT_NO_INVALID）
--   2. 通用枚举新增（DATA_DUPLICATE / MISSING_PARAM / METHOD_NOT_ALLOWED）
--
-- 使用 ON DUPLICATE KEY UPDATE 保证脚本幂等（重复执行不报错）
-- ============================================================

INSERT INTO `sys_i18n` (`enum_code`, `lang`, `message`) VALUES

-- ── TECHNICIAN_AUDIT_REJECTED ────────────────────────────────────────────────
('TECHNICIAN_AUDIT_REJECTED','zh','审核未通过，请联系商户了解详情'),
('TECHNICIAN_AUDIT_REJECTED','en','Your application has been rejected, please contact the merchant for details'),
('TECHNICIAN_AUDIT_REJECTED','vi','Đơn đăng ký của bạn bị từ chối, vui lòng liên hệ đối tác để biết thêm chi tiết'),
('TECHNICIAN_AUDIT_REJECTED','km','ពាក្យស្នើសុំរបស់អ្នកត្រូវបានបដិសេធ សូមទំនាក់ទំនងឈ្មួញ'),
('TECHNICIAN_AUDIT_REJECTED','ja','申請が却下されました。詳細は加盟店にお問い合わせください'),
('TECHNICIAN_AUDIT_REJECTED','ko','신청이 거부되었습니다. 가맹점에 문의하세요'),

-- ── TECHNICIAN_BANNED ────────────────────────────────────────────────────────
('TECHNICIAN_BANNED','zh','账号已被停用，请联系商户处理'),
('TECHNICIAN_BANNED','en','Your account has been suspended, please contact the merchant'),
('TECHNICIAN_BANNED','vi','Tài khoản của bạn đã bị đình chỉ, vui lòng liên hệ đối tác'),
('TECHNICIAN_BANNED','km','គណនីរបស់អ្នកត្រូវបានផ្អាក សូមទំនាក់ទំនងឈ្មួញ'),
('TECHNICIAN_BANNED','ja','アカウントが停止されました。加盟店にお問い合わせください'),
('TECHNICIAN_BANNED','ko','계정이 정지되었습니다. 가맹점에 문의하세요'),

-- ── TECHNICIAN_MOBILE_EXISTS ─────────────────────────────────────────────────
('TECHNICIAN_MOBILE_EXISTS','zh','该手机号已注册，请直接登录'),
('TECHNICIAN_MOBILE_EXISTS','en','This mobile number is already registered, please log in directly'),
('TECHNICIAN_MOBILE_EXISTS','vi','Số điện thoại này đã được đăng ký, vui lòng đăng nhập trực tiếp'),
('TECHNICIAN_MOBILE_EXISTS','km','លេខទូរស័ព្ទនេះបានចុះឈ្មោះហើយ សូមចូលដោយផ្ទាល់'),
('TECHNICIAN_MOBILE_EXISTS','ja','この携帯番号はすでに登録されています。直接ログインしてください'),
('TECHNICIAN_MOBILE_EXISTS','ko','이 휴대폰 번호는 이미 등록되어 있습니다. 직접 로그인하세요'),

-- ── MERCHANT_NO_INVALID ──────────────────────────────────────────────────────
('MERCHANT_NO_INVALID','zh','商户编号无效或商户审核未通过，请核实后重试'),
('MERCHANT_NO_INVALID','en','Invalid merchant code or merchant not approved, please verify and retry'),
('MERCHANT_NO_INVALID','vi','Mã đối tác không hợp lệ hoặc chưa được phê duyệt'),
('MERCHANT_NO_INVALID','km','លេខកូដឈ្មួញមិនត្រឹមត្រូវ ឬឈ្មួញមិនទាន់ដំណើរការ'),
('MERCHANT_NO_INVALID','ja','加盟店コードが無効か、加盟店が承認されていません'),
('MERCHANT_NO_INVALID','ko','가맹점 코드가 유효하지 않거나 승인되지 않았습니다'),

-- ── DATA_DUPLICATE ───────────────────────────────────────────────────────────
('DATA_DUPLICATE','zh','数据已存在，请勿重复提交'),
('DATA_DUPLICATE','en','Data already exists, please do not submit again'),
('DATA_DUPLICATE','vi','Dữ liệu đã tồn tại, vui lòng không gửi lại'),
('DATA_DUPLICATE','km','ទិន្នន័យមានស្រាប់ សូមមិនបញ្ជូនម្ដងទៀត'),
('DATA_DUPLICATE','ja','データが既に存在します。再送信しないでください'),
('DATA_DUPLICATE','ko','데이터가 이미 존재합니다. 다시 제출하지 마세요'),

-- ── MISSING_PARAM ────────────────────────────────────────────────────────────
('MISSING_PARAM','zh','缺少必要请求参数，请检查后重试'),
('MISSING_PARAM','en','Missing required request parameter, please check and retry'),
('MISSING_PARAM','vi','Thiếu tham số yêu cầu bắt buộc, vui lòng kiểm tra lại'),
('MISSING_PARAM','km','ខ្វះប៉ារ៉ាម៉ែត្រស្នើសុំដែលតម្រូវ'),
('MISSING_PARAM','ja','必須リクエストパラメータが不足しています'),
('MISSING_PARAM','ko','필수 요청 매개변수가 누락되었습니다'),

-- ── METHOD_NOT_ALLOWED ───────────────────────────────────────────────────────
('METHOD_NOT_ALLOWED','zh','请求方式不支持，请使用正确的 HTTP 方法'),
('METHOD_NOT_ALLOWED','en','HTTP method not supported, please use the correct method'),
('METHOD_NOT_ALLOWED','vi','Phương thức HTTP không được hỗ trợ'),
('METHOD_NOT_ALLOWED','km','វិធីសាស្ត្រ HTTP មិនត្រូវបានគាំទ្រ'),
('METHOD_NOT_ALLOWED','ja','HTTPメソッドはサポートされていません'),
('METHOD_NOT_ALLOWED','ko','HTTP 메서드가 지원되지 않습니다')

AS new_vals(enum_code, lang, message)
ON DUPLICATE KEY UPDATE message = new_vals.message;
