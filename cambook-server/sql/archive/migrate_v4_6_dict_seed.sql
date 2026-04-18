-- ══════════════════════════════════════════════════════════════════════════════
-- Migration v4.6 — 数据字典全量初始化
--
-- 覆盖系统全部可配置枚举字段，写入 sys_dict_type + sys_dict
-- 幂等设计：INSERT IGNORE，可安全重复执行（已存在的行自动跳过）
--
-- ┌─────────────────────────────────────────────────────────────────────────┐
-- │  字典类型速查                                                           │
-- ├────────────────────────────┬────────────────────────────────────────────┤
-- │ 系统/通用                  │                                            │
-- │   common_status            │ 通用启用/停用                              │
-- │   gender                   │ 性别                                       │
-- │   user_type                │ 用户身份类型                               │
-- │   login_type               │ 登录方式                                   │
-- │   menu_type                │ 菜单节点类型                               │
-- │   portal_type              │ 所属门户                                   │
-- │   notice_type              │ 推送通知类型                               │
-- │   announce_status          │ 公告状态                                   │
-- │   announce_target          │ 公告发送对象                               │
-- │   msg_type                 │ 即时消息类型                               │
-- │   sender_type              │ 消息发送方类型                             │
-- │   client_type              │ 客户端类型                                 │
-- │   banner_link_type         │ Banner 跳转类型                            │
-- │   tag_type                 │ 标签类型                                   │
-- ├────────────────────────────┬────────────────────────────────────────────┤
-- │ 地理/语言                  │                                            │
-- │   service_city             │ 服务城市（柬埔寨）                         │
-- │   nationality              │ 国籍                                       │
-- │   language                 │ 常用语言                                   │
-- ├────────────────────────────┬────────────────────────────────────────────┤
-- │ 会员                       │                                            │
-- │   member_status            │ 会员账号状态                               │
-- │   member_level             │ 会员等级                                   │
-- │   register_source          │ 注册来源                                   │
-- ├────────────────────────────┬────────────────────────────────────────────┤
-- │ 技师                       │                                            │
-- │   technician_status        │ 技师账号状态                               │
-- │   technician_audit         │ 入驻审核状态（技师&商户共用）              │
-- │   technician_online        │ 技师在线状态                               │
-- │   bust_size                │ 罩杯尺码                                   │
-- │   settlement_mode          │ 技师结算方式                               │
-- │   commission_type          │ 技师提成类型                               │
-- ├────────────────────────────┬────────────────────────────────────────────┤
-- │ 商户                       │                                            │
-- │   merchant_status          │ 商户账号状态                               │
-- │   merchant_business_type   │ 商户业务类型                               │
-- │   dept_category            │ 部门类别                                   │
-- │   job_grade                │ 职级等级                                   │
-- │   staff_status             │ 员工/司机状态                              │
-- ├────────────────────────────┬────────────────────────────────────────────┤
-- │ 服务/订单                  │                                            │
-- │   service_type             │ 服务项目类型（常规/特殊）                  │
-- │   order_status             │ 订单状态（在线预约）                       │
-- │   walkin_status            │ 门店散客会话状态                           │
-- │   walkin_pay_type          │ 门店收银支付方式                           │
-- ├────────────────────────────┬────────────────────────────────────────────┤
-- │ 支付/财务                  │                                            │
-- │   pay_type                 │ 在线支付方式                               │
-- │   pay_status               │ 支付状态                                   │
-- │   currency                 │ 结算货币                                   │
-- │   coupon_type              │ 优惠券类型                                 │
-- │   coupon_use_status        │ 优惠券使用状态                             │
-- │   wallet_status            │ 钱包状态                                   │
-- │   wallet_flow_type         │ 钱包流水类型                               │
-- │   settlement_status        │ 结算单状态                                 │
-- │   salary_status            │ 薪资发放状态                               │
-- │   staff_type               │ 薪资员工类型                               │
-- │   expense_category         │ 支出类别                                   │
-- ├────────────────────────────┬────────────────────────────────────────────┤
-- │ 车辆                       │                                            │
-- │   vehicle_status           │ 车辆状态                                   │
-- │   vehicle_brand            │ 车辆品牌                                   │
-- │   vehicle_color            │ 车辆颜色                                   │
-- │   vehicle_purpose          │ 出行目的                                   │
-- │   dispatch_status          │ 派车单状态                                 │
-- └────────────────────────────┴────────────────────────────────────────────┘
-- ══════════════════════════════════════════════════════════════════════════════

-- ── 0. 幂等添加 sys_dict.remark 列（存储 Tag 颜色 / 品牌色 / 国旗 emoji）──────
DROP PROCEDURE IF EXISTS _add_dict_remark;
DELIMITER $$
CREATE PROCEDURE _add_dict_remark()
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME   = 'sys_dict'
          AND COLUMN_NAME  = 'remark'
    ) THEN
        ALTER TABLE `sys_dict`
            ADD COLUMN `remark` VARCHAR(200) NULL COMMENT '附加信息：Ant Design Tag color / 品牌色 hex / 国旗 emoji 等' AFTER `status`;
        SELECT '✅ sys_dict.remark 字段已添加' AS msg;
    ELSE
        SELECT '⏭️  sys_dict.remark 已存在，跳过' AS msg;
    END IF;
END$$
DELIMITER ;
CALL _add_dict_remark();
DROP PROCEDURE IF EXISTS _add_dict_remark;

-- ── 一、字典类型表 ────────────────────────────────────────────────────────────
INSERT IGNORE INTO `sys_dict_type` (`dict_type`, `dict_name`, `status`, `remark`) VALUES
-- 系统/通用
('common_status',          '通用状态',           1, '通用启用/停用，适用于大多数实体的 status 字段'),
('gender',                 '性别',               1, 'cb_member.gender / cb_technician.gender'),
('user_type',              '用户身份类型',        1, 'cb_wallet.user_type / cb_wallet_flow.owner_type'),
('login_type',             '登录方式',            1, 'cb_login_log.login_type'),
('menu_type',              '菜单节点类型',        1, 'sys_menu.type：目录/菜单/按钮'),
('portal_type',            '所属门户',            1, 'sys_menu.portal_type：管理端/商户端'),
('notice_type',            '推送通知类型',        1, 'cb_notice.type'),
('announce_status',        '公告状态',            1, 'cb_announce.status'),
('announce_target',        '公告发送对象',        1, 'cb_announce.target'),
('msg_type',               '即时消息类型',        1, 'cb_chat_message.msg_type'),
('sender_type',            '消息发送方类型',      1, 'cb_chat_message.sender_type'),
('client_type',            '客户端类型',          1, 'cb_notice.client_type，推送目标客户端'),
('banner_link_type',       'Banner 跳转类型',     1, 'cb_banner.link_type'),
('tag_type',               '标签类型',            1, 'cb_tag.tag_type：技师/服务/商户'),
-- 地理/语言
('service_city',           '服务城市',            1, '技师/商户服务城市（柬埔寨城市）'),
('nationality',            '国籍',                1, '技师/会员国籍，含国旗 emoji 存 remark'),
('language',               '常用语言',            1, '技师/会员常用语言'),
-- 会员
('member_status',          '会员账号状态',        1, 'cb_member.status'),
('member_level',           '会员等级',            1, 'cb_member.level'),
('register_source',        '注册来源',            1, 'cb_member.register_source'),
-- 技师
('technician_status',      '技师账号状态',        1, 'cb_technician.status'),
('technician_audit',       '入驻审核状态',        1, '技师与商户共用，audit_status'),
('technician_online',      '技师在线状态',        1, 'cb_technician.online_status'),
('bust_size',              '罩杯尺码',            1, '技师罩杯尺码，A~G'),
('settlement_mode',        '技师结算方式',        1, 'cb_technician.settlement_mode'),
('commission_type',        '技师提成类型',        1, 'cb_technician.commission_type'),
-- 商户
('merchant_status',        '商户账号状态',        1, 'cb_merchant.status'),
('merchant_business_type', '商户业务类型',        1, 'cb_merchant.business_type'),
('dept_category',          '部门类别',            1, '组织架构部门分类'),
('job_grade',              '职级等级',            1, '员工职级，P序列技术/M序列管理'),
('staff_status',           '员工/司机状态',       1, 'cb_staff.status'),
-- 服务/订单
('service_type',           '服务项目类型',        1, 'cb_service_category.is_special：0常规 1特殊'),
('order_status',           '订单状态',            1, 'cb_order.status，完整预约订单生命周期'),
('walkin_status',          '门店散客会话状态',    1, 'cb_walkin_session.status，散客上门服务状态'),
('walkin_pay_type',        '门店收银支付方式',    1, '散客上门收款方式，含现金/转账/扫码等'),
-- 支付/财务
('pay_type',               '在线支付方式',        1, 'cb_order.pay_type / cb_payment.pay_type'),
('pay_status',             '支付状态',            1, 'cb_payment.status'),
('currency',               '结算货币',            1, '支付/结算使用的货币，含汇率参考'),
('coupon_type',            '优惠券类型',          1, 'cb_coupon.type'),
('coupon_use_status',      '优惠券使用状态',      1, 'cb_member_coupon.status'),
('wallet_status',          '钱包状态',            1, 'cb_wallet.status'),
('wallet_flow_type',       '钱包流水类型',        1, 'cb_wallet_flow.type'),
('settlement_status',      '结算单状态',          1, '技师结算单审核/打款状态'),
('salary_status',          '薪资发放状态',        1, '员工薪资单状态'),
('staff_type',             '薪资员工类型',        1, '薪资管理中的员工类型分类'),
('expense_category',       '支出类别',            1, '门店运营支出分类'),
-- 车辆
('vehicle_status',         '车辆状态',            1, 'cb_vehicle.status'),
('vehicle_brand',          '车辆品牌',            1, '车辆品牌列表，remark 存品牌标志色'),
('vehicle_color',          '车辆颜色',            1, '车辆常见颜色，remark 存 hex 色值'),
('vehicle_purpose',        '出行目的',            1, '派车单出行目的分类'),
('dispatch_status',        '派车单状态',          1, 'cb_vehicle_dispatch.status'),
('vehicle_dispatch_purpose','内部派车用途',        1, 'VehicleDispatch 页面用途分类，remark JSON {c:颜色,i:emoji}'),
('vehicle_dispatch_status', '内部车辆调度状态',   1, 'VehicleDispatch 页面使用状态，remark JSON {c:颜色,b:badge}'),
('walkin_session_status',   '门店会话状态',        1, 'WalkinSessionPage SESSION_STATUS，remark JSON {c:颜色,b:badge}'),
('walkin_svc_status',       '服务项目进度',        1, 'WalkinSessionPage 服务行项目状态，remark JSON {c:颜色,i:emoji}'),
('income_type',             '收入类型',            1, '门店收入来源类型，IncomeRecordPage INCOME_TYPES');


-- ── 二、字典数据项 ────────────────────────────────────────────────────────────
-- 格式：(dict_type, dict_value, label_zh, label_en, label_vi, label_km, label_ja, label_ko, sort, status, remark)

INSERT IGNORE INTO `sys_dict` (`dict_type`, `dict_value`, `label_zh`, `label_en`, `label_vi`, `label_km`, `label_ja`, `label_ko`, `sort`, `status`, `remark`) VALUES

-- ── 通用状态 ─────────────────────────────────────────────────────────────────
('common_status', '1', '启用',  'Enabled',  'Đang hoạt động', 'ដំណើរការ', '有効', '활성',   1, 1, 'green'),
('common_status', '0', '停用',  'Disabled', 'Tạm dừng',       'បិទ',      '無効', '비활성', 2, 1, 'default'),

-- ── 性别 ─────────────────────────────────────────────────────────────────────
('gender', '0', '未知', 'Unknown', 'Không rõ', 'មិនដឹង', '不明', '미상', 1, 1, 'default'),
('gender', '1', '男',   'Male',    'Nam',      'ប្រុស',   '男性', '남성', 2, 1, 'blue'),
('gender', '2', '女',   'Female',  'Nữ',       'ស្រី',    '女性', '여성', 3, 1, 'pink'),

-- ── 用户身份类型 ──────────────────────────────────────────────────────────────
('user_type', '1', '会员',   'Member',     'Thành viên',      'សមាជិក',          '会員',   '회원',   1, 1, 'cyan'),
('user_type', '2', '技师',   'Technician', 'Kỹ thuật viên',   'អ្នកបច្ចេកទេស',   '技師',   '기술자', 2, 1, 'purple'),
('user_type', '3', '商户',   'Merchant',   'Thương gia',       'ពាណិជ្ជករ',      '商店',   '가맹점', 3, 1, 'orange'),

-- ── 登录方式 ─────────────────────────────────────────────────────────────────
('login_type', '1', '短信验证码', 'SMS Code', 'Mã SMS',    'លេខកូដ SMS',   'SMSコード', 'SMS 코드', 1, 1, NULL),
('login_type', '2', '账号密码',   'Password', 'Mật khẩu', 'ពាក្យសម្ងាត់', 'パスワード', '비밀번호',  2, 1, NULL),

-- ── 菜单节点类型 ──────────────────────────────────────────────────────────────
('menu_type', '1', '目录', 'Directory', 'Thư mục',     'ថតឯកសារ', 'ディレクトリ', '디렉토리', 1, 1, NULL),
('menu_type', '2', '菜单', 'Menu',      'Menu',        'ម៉ឺនុយ',   'メニュー',    '메뉴',     2, 1, NULL),
('menu_type', '3', '按钮', 'Button',    'Nút thao tác','ប៊ូតុង',   'ボタン',      '버튼',     3, 1, NULL),

-- ── 所属门户 ─────────────────────────────────────────────────────────────────
('portal_type', '0', '管理端', 'Admin',    'Quản trị',  'ទំព័រគ្រប់គ្រង', '管理ポータル', '관리자', 1, 1, NULL),
('portal_type', '1', '商户端', 'Merchant', 'Thương gia','ពាណិជ្ជករ',       '商店ポータル', '가맹점', 2, 1, NULL),

-- ── 推送通知类型 ──────────────────────────────────────────────────────────────
('notice_type', '1', '系统公告', 'System',    'Thông báo hệ thống', 'ការជូនដំណឹង', 'システム通知',  '시스템',   1, 1, 'blue'),
('notice_type', '2', '订单通知', 'Order',     'Thông báo đơn hàng', 'ការជូនដំណឹងការបញ្ជាទិញ', '注文通知', '주문',    2, 1, 'green'),
('notice_type', '3', '活动营销', 'Promotion', 'Khuyến mãi',         'ការផ្សព្វផ្សាយ', 'プロモーション', '프로모션', 3, 1, 'orange'),

-- ── 公告状态 ─────────────────────────────────────────────────────────────────
('announce_status', '0', '草稿',   'Draft',     'Nháp',          'សំណាង',      '下書き', '초안',     1, 1, 'default'),
('announce_status', '1', '已发布', 'Published', 'Đã xuất bản',   'បានផ្សព្វផ្សាយ','公開済み', '게시됨', 2, 1, 'green'),
('announce_status', '2', '已撤回', 'Recalled',  'Đã thu hồi',    'បានដកវិញ',    '撤回済み', '회수됨', 3, 1, 'red'),

-- ── 公告发送对象 ──────────────────────────────────────────────────────────────
('announce_target', '0', '全部成员', 'All',        'Tất cả',       'ទាំងអស់',          '全員',   '전체',     1, 1, NULL),
('announce_target', '1', '本部门',   'Department', 'Phòng ban',    'នាយកដ្ឋាន',        '部署',   '부서',     2, 1, NULL),
('announce_target', '2', '指定人员', 'Specific',   'Chỉ định',     'បញ្ជាក់ជាក់លាក់',  '指定',   '지정',     3, 1, NULL),

-- ── 即时消息类型 ──────────────────────────────────────────────────────────────
('msg_type', '1', '文字',     'Text',                'Văn bản', 'អក្សរ',      'テキスト',   '텍스트',   1, 1, NULL),
('msg_type', '2', '图片',     'Image',               'Hình ảnh','រូបភាព',     '画像',       '이미지',   2, 1, NULL),
('msg_type', '3', '系统通知', 'System Notification', 'Hệ thống','ការជូនដំណឹង','システム通知','시스템 알림', 3, 1, NULL),

-- ── 消息发送方类型 ────────────────────────────────────────────────────────────
('sender_type', '1', '会员', 'Member',     'Thành viên',    'សមាជិក',          '会員',   '회원',    1, 1, NULL),
('sender_type', '2', '技师', 'Technician', 'Kỹ thuật viên', 'អ្នកបច្ចេកទេស',   '技師',   '기술자',  2, 1, NULL),
('sender_type', '3', '商户', 'Merchant',   'Thương gia',    'ពាណិជ្ជករ',       '商店',   '가맹점',  3, 1, NULL),
('sender_type', '4', '系统', 'System',     'Hệ thống',      'ប្រព័ន្ធ',        'システム','시스템',  4, 1, NULL),

-- ── 客户端类型 ────────────────────────────────────────────────────────────────
('client_type', '1', '会员 APP',  'Member APP',     'APP Thành viên', 'APP សមាជិក',          '会員APP',  '회원 앱',   1, 1, NULL),
('client_type', '2', '技师 APP',  'Technician APP', 'APP Kỹ thuật',   'APP អ្នកបច្ចេកទេស',  '技師APP',  '기술자 앱', 2, 1, NULL),
('client_type', '3', '商户 APP',  'Merchant APP',   'APP Thương gia', 'APP ពាណិជ្ជករ',      '商店APP',  '가맹점 앱', 3, 1, NULL),
('client_type', '4', 'H5',        'H5',             'H5',             'H5',                  'H5',       'H5',        4, 1, NULL),

-- ── Banner 跳转类型 ───────────────────────────────────────────────────────────
('banner_link_type', '0', '无跳转',   'No Link',       'Không liên kết', 'គ្មានតំណ',          'リンクなし',   '링크 없음', 1, 1, NULL),
('banner_link_type', '1', '内部路由', 'Internal Route','Trang nội bộ',   'ទំព័រខាងក្នុង',     '内部リンク',   '내부 링크', 2, 1, NULL),
('banner_link_type', '2', '外部链接', 'External URL',  'Liên kết ngoài', 'តំណខ្សែខាងក្រៅ',   '外部リンク',   '외부 링크', 3, 1, NULL),

-- ── 标签类型 ─────────────────────────────────────────────────────────────────
('tag_type', '1', '技师标签', 'Technician', 'Nhãn kỹ thuật viên', 'ស្លាក​អ្នក​បច្ចេកទេស', '技師タグ',    '기술자 태그', 1, 1, NULL),
('tag_type', '2', '服务标签', 'Service',    'Nhãn dịch vụ',       'ស្លាក​សេវាកម្ម',       'サービスタグ', '서비스 태그', 2, 1, NULL),
('tag_type', '3', '商户标签', 'Merchant',   'Nhãn thương gia',    'ស្លាក​ពាណិជ្ជករ',      '商店タグ',    '가맹점 태그', 3, 1, NULL),

-- ── 服务城市（柬埔寨）────────────────────────────────────────────────────────
-- dict_value 使用中文名，与数据库已有存储值保持一致（前端 serviceCity 字段直接存储中文）
('service_city', '金边',     '金边',     'Phnom Penh',      'Phnom Penh',      'ភ្នំពេញ',    '金辺',           '프놈펜',     1,  1, NULL),
('service_city', '暹粒',     '暹粒',     'Siem Reap',       'Siem Reap',       'សៀមរាប',     'シェムリアップ', '시엠립',     2,  1, NULL),
('service_city', '西哈努克', '西哈努克', 'Sihanoukville',   'Sihanoukville',   'ព្រះសីហនុ',  'シアヌークビル', '시아누크빌',  3,  1, NULL),
('service_city', '贡布',     '贡布',     'Kampot',          'Kampot',          'កំពត',        'カンポット',    '캄폿',        4,  1, NULL),
('service_city', '白马',     '白马',     'Kep',             'Kep',             'កែប',         'ケップ',        '켑',          5,  1, NULL),
('service_city', '磅湛',     '磅湛',     'Kampong Cham',    'Kampong Cham',    'កំពង់ចាម',    'コンポンチャム','콤퐁참',      6,  1, NULL),
('service_city', '菩萨',     '菩萨',     'Pursat',          'Pursat',          'ពោធិ៍សាត់',   'プルサット',    '뿌르삿',      7,  1, NULL),
('service_city', '磅通',     '磅通',     'Kampong Thom',    'Kampong Thom',    'កំពង់ធំ',     'コンポントム',  '콤퐁톰',      8,  1, NULL),
('service_city', '茶胶',     '茶胶',     'Takeo',           'Takeo',           'តាកែវ',        'タケオ',        '따께오',      9,  1, NULL),
('service_city', '柴桢',     '柴桢',     'Svay Rieng',      'Svay Rieng',      'ស្វាយរៀង',   'スヴァイリエン','스바이리엥',  10, 1, NULL),
('service_city', '磅清扬',   '磅清扬',   'Kampong Chhnang', 'Kampong Chhnang', 'កំពង់ឆ្នាំង', 'コンポンチュナン','콤퐁츠낭',  11, 1, NULL),
('service_city', '其他',     '其他',     'Other',           'Khác',            'ផ្សេងទៀត',   'その他',        '기타',        99, 1, NULL),

-- ── 国籍 ─────────────────────────────────────────────────────────────────────
('nationality', 'CN', '中国',      'China',       'Trung Quốc',   'ចិន',         '中国',      '중국',    1,  1, '🇨🇳'),
('nationality', 'KH', '柬埔寨',    'Cambodia',    'Campuchia',    'កម្ពុជា',     'カンボジア','캄보디아',2,  1, '🇰🇭'),
('nationality', 'VN', '越南',      'Vietnam',     'Việt Nam',     'វៀតណាម',     'ベトナム',  '베트남',  3,  1, '🇻🇳'),
('nationality', 'TH', '泰国',      'Thailand',    'Thái Lan',     'ថៃ',          'タイ',      '태국',    4,  1, '🇹🇭'),
('nationality', 'MY', '马来西亚',  'Malaysia',    'Malaysia',     'មាឡេស៊ី',    'マレーシア','말레이시아',5,1,'🇲🇾'),
('nationality', 'SG', '新加坡',    'Singapore',   'Singapore',    'សិង្ហបុរី', 'シンガポール','싱가포르',6,1,'🇸🇬'),
('nationality', 'MM', '缅甸',      'Myanmar',     'Myanmar',      'មីយ៉ាន់ម៉ា', 'ミャンマー','미얀마',   7,  1, '🇲🇲'),
('nationality', 'LA', '老挝',      'Laos',        'Lào',          'ឡាវ',         'ラオス',    '라오스',  8,  1, '🇱🇦'),
('nationality', 'PH', '菲律宾',    'Philippines', 'Philippines',  'ហ្វីលីពីន',  'フィリピン','필리핀',  9,  1, '🇵🇭'),
('nationality', 'KR', '韩国',      'Korea',       'Hàn Quốc',     'កូរ៉េ',       '韓国',      '한국',    10, 1, '🇰🇷'),
('nationality', 'JP', '日本',      'Japan',       'Nhật Bản',     'ជប៉ុន',       '日本',      '일본',    11, 1, '🇯🇵'),
('nationality', 'RU', '俄罗斯',    'Russia',      'Nga',          'រូស្ស៊ី',    'ロシア',    '러시아',  12, 1, '🇷🇺'),
('nationality', 'US', '美国',      'USA',         'Mỹ',           'អាមេរិក',    'アメリカ',  '미국',    13, 1, '🇺🇸'),
('nationality', 'GB', '英国',      'UK',          'Anh',          'អង់គ្លេស',   'イギリス',  '영국',    14, 1, '🇬🇧'),
('nationality', 'OT', '其他',      'Other',       'Khác',         'ផ្សេងទៀត',   'その他',    '기타',    99, 1, NULL),

-- ── 常用语言 ─────────────────────────────────────────────────────────────────
('language', 'zh', '中文',   'Chinese',    'Tiếng Trung',  'ភាសាចិន',      '中国語',     '중국어',  1, 1, NULL),
('language', 'km', '柬埔寨语','Khmer',     'Tiếng Khmer',  'ភាសាខ្មែរ',    'クメール語', '크메르어',2, 1, NULL),
('language', 'en', '英语',   'English',    'Tiếng Anh',    'ភាសាអង់គ្លេស', '英語',       '영어',    3, 1, NULL),
('language', 'vi', '越南语', 'Vietnamese', 'Tiếng Việt',   'ភាសាវៀតណាម',  'ベトナム語', '베트남어',4, 1, NULL),
('language', 'ko', '韩语',   'Korean',     'Tiếng Hàn',    'ភាសាកូរ៉េ',    '韓国語',     '한국어',  5, 1, NULL),
('language', 'ja', '日语',   'Japanese',   'Tiếng Nhật',   'ភាសាជប៉ុន',    '日本語',     '일본어',  6, 1, NULL),
('language', 'th', '泰语',   'Thai',       'Tiếng Thái',   'ភាសាថៃ',       'タイ語',     '태국어',  7, 1, NULL),
('language', 'ru', '俄语',   'Russian',    'Tiếng Nga',    'ភាសារូស្ស៊ី',  'ロシア語',   '러시아어',8, 1, NULL),

-- ── 会员账号状态 ──────────────────────────────────────────────────────────────
('member_status', '1', '正常',       'Normal',     'Bình thường', 'ធម្មតា',          '正常',       '정상',      1, 1, 'green'),
('member_status', '2', '已封禁',     'Banned',     'Bị cấm',      'ត្រូវបានហាម',     '停止',       '정지',      2, 1, 'red'),
('member_status', '3', '注销申请中', 'Cancelling', 'Đang hủy',    'កំពុងលុប',        '退会申請中', '탈퇴 신청중',3, 1, 'orange'),

-- ── 会员等级 ─────────────────────────────────────────────────────────────────
('member_level', '0', '普通会员', 'Regular', 'Thường',   'ធម្មតា', 'レギュラー', '일반', 1, 1, 'default'),
('member_level', '1', '银卡会员', 'Silver',  'Bạc',      'ប្រាក់', 'シルバー',   '실버', 2, 1, 'silver'),
('member_level', '2', '金卡会员', 'Gold',    'Vàng',     'មាស',    'ゴールド',   '골드', 3, 1, 'gold'),
('member_level', '3', '钻石会员', 'Diamond', 'Kim cương','ماس',    'ダイヤモンド','다이아',4, 1, 'cyan'),

-- ── 注册来源 ─────────────────────────────────────────────────────────────────
('register_source', '1', 'APP',  'APP', 'APP', 'APP', 'APP', 'APP', 1, 1, NULL),
('register_source', '2', 'H5',   'H5',  'H5',  'H5',  'H5',  'H5',  2, 1, NULL),

-- ── 技师账号状态 ──────────────────────────────────────────────────────────────
('technician_status', '1', '正常', 'Active',    'Hoạt động', 'ដំណើរការ',      '有効', '활성', 1, 1, 'green'),
('technician_status', '2', '停用', 'Suspended', 'Tạm dừng',  'ផ្អាកការ',       '停止', '정지', 2, 1, 'red'),

-- ── 入驻审核状态（技师 & 商户共用）───────────────────────────────────────────
('technician_audit', '0', '待审核',   'Pending',  'Đang chờ',  'កំពុងរង់ចាំ',     '審査待ち', '심사 중', 1, 1, 'orange'),
('technician_audit', '1', '审核通过', 'Approved', 'Đã duyệt',  'បានអនុម័ត',       '承認済み', '승인됨',  2, 1, 'green'),
('technician_audit', '2', '审核拒绝', 'Rejected', 'Từ chối',   'ត្រូវបានបដិសេធ',  '拒否',     '거절됨',  3, 1, 'red'),

-- ── 技师在线状态 ──────────────────────────────────────────────────────────────
('technician_online', '0', '离线',    'Offline',    'Ngoại tuyến', 'គ្មានអ៊ីនធ័ណ',  'オフライン',  '오프라인', 1, 1, 'default'),
('technician_online', '1', '在线待单','Online',      'Trực tuyến',  'អ៊ីនធ័ណ',        'オンライン',  '온라인',   2, 1, 'green'),
('technician_online', '2', '服务中',  'In Service',  'Đang phục vụ','កំពុងបម្រើ',     'サービス中', '서비스 중',3, 1, 'blue'),

-- ── 罩杯尺码 ─────────────────────────────────────────────────────────────────
('bust_size', 'A', 'A 杯', 'Cup A', NULL, NULL, NULL, NULL, 1, 1, NULL),
('bust_size', 'B', 'B 杯', 'Cup B', NULL, NULL, NULL, NULL, 2, 1, NULL),
('bust_size', 'C', 'C 杯', 'Cup C', NULL, NULL, NULL, NULL, 3, 1, NULL),
('bust_size', 'D', 'D 杯', 'Cup D', NULL, NULL, NULL, NULL, 4, 1, NULL),
('bust_size', 'E', 'E 杯', 'Cup E', NULL, NULL, NULL, NULL, 5, 1, NULL),
('bust_size', 'F', 'F 杯', 'Cup F', NULL, NULL, NULL, NULL, 6, 1, NULL),
('bust_size', 'G', 'G 杯', 'Cup G', NULL, NULL, NULL, NULL, 7, 1, NULL),

-- ── 技师结算方式 ──────────────────────────────────────────────────────────────
('settlement_mode', '0', '每笔结算', 'Per Order', 'Theo đơn',   'តាមការបញ្ជាទិញ', '都度精算', '건별', 1, 1, NULL),
('settlement_mode', '1', '日结',     'Daily',     'Hàng ngày',  'ប្រចាំថ្ងៃ',      '日次',     '일별', 2, 1, NULL),
('settlement_mode', '2', '周结',     'Weekly',    'Hàng tuần',  'ប្រចាំសប្ដាហ៍',   '週次',     '주별', 3, 1, NULL),
('settlement_mode', '3', '月结',     'Monthly',   'Hàng tháng', 'ប្រចាំខែ',        '月次',     '월별', 4, 1, NULL),

-- ── 技师提成类型 ──────────────────────────────────────────────────────────────
('commission_type', '0', '按比例(%)', 'Percentage', 'Theo %',     'តាមភាគរយ', '歩合制', '비율제', 1, 1, NULL),
('commission_type', '1', '固定金额',  'Fixed',      'Cố định',    'ចំនួនថេរ',  '固定額', '고정액', 2, 1, NULL),

-- ── 商户账号状态 ──────────────────────────────────────────────────────────────
('merchant_status', '1', '正常营业', 'Open',   'Đang mở cửa', 'បើក',  '営業中', '영업 중', 1, 1, 'green'),
('merchant_status', '2', '已停业',   'Closed', 'Đóng cửa',    'បិទ',   '休業中', '휴업',    2, 1, 'default'),

-- ── 商户业务类型 ──────────────────────────────────────────────────────────────
('merchant_business_type', '1', '综合SPA',  'Spa',          'Spa Tổng Hợp', 'ស្ប៉ារួម',     'スパ総合', '종합 스파', 1, 1, 'purple'),
('merchant_business_type', '2', '洗浴中心', 'Bath Center',  'Tắm hơi',      'មជ្ឈមណ្ឌលងូត', '入浴施設', '목욕탕',    2, 1, 'blue'),
('merchant_business_type', '3', '美容美体', 'Beauty Salon', 'Làm đẹp',      'សាឡីត្រូវ',    '美容',     '미용실',    3, 1, 'pink'),
('merchant_business_type', '4', '足疗',     'Foot Massage', 'Massage chân', 'គីមីជើង',      '足療',     '발마사지',  4, 1, 'cyan'),

-- ── 部门类别 ─────────────────────────────────────────────────────────────────
('dept_category', '1', '业务',   'Business',   'Nghiệp vụ', 'ជំនួញ',  '事業',       '영업',  1, 1, 'blue'),
('dept_category', '2', '技术',   'Technical',  'Kỹ thuật',  'បច្ចេកទេស','技術',      '기술',  2, 1, 'purple'),
('dept_category', '3', '职能',   'Operations', 'Vận hành',  'ប្រតិបត្តិការ','管理',  '운영',  3, 1, 'cyan'),
('dept_category', '4', '管理',   'Management', 'Quản lý',   'គ្រប់គ្រង','経営',      '경영',  4, 1, 'gold'),

-- ── 职级等级 ─────────────────────────────────────────────────────────────────
('job_grade', 'P1', 'P1 初级',   'Junior',     NULL, NULL, NULL, NULL, 1, 1, NULL),
('job_grade', 'P2', 'P2 中级',   'Mid',        NULL, NULL, NULL, NULL, 2, 1, NULL),
('job_grade', 'P3', 'P3 高级',   'Senior',     NULL, NULL, NULL, NULL, 3, 1, NULL),
('job_grade', 'P4', 'P4 专家',   'Expert',     NULL, NULL, NULL, NULL, 4, 1, NULL),
('job_grade', 'P5', 'P5 首席',   'Principal',  NULL, NULL, NULL, NULL, 5, 1, NULL),
('job_grade', 'M1', 'M1 组长',   'Team Lead',  NULL, NULL, NULL, NULL, 6, 1, NULL),
('job_grade', 'M2', 'M2 主管',   'Supervisor', NULL, NULL, NULL, NULL, 7, 1, NULL),
('job_grade', 'M3', 'M3 经理',   'Manager',    NULL, NULL, NULL, NULL, 8, 1, NULL),
('job_grade', 'M4', 'M4 总监',   'Director',   NULL, NULL, NULL, NULL, 9, 1, NULL),
('job_grade', 'M5', 'M5 VP',     'VP',         NULL, NULL, NULL, NULL, 10,1, NULL),

-- ── 员工/司机状态 ─────────────────────────────────────────────────────────────
('staff_status', '0', '待审核', 'Pending',   'Đang chờ', 'រង់ចាំ',   '審査待ち', '심사 중', 1, 1, 'orange'),
('staff_status', '1', '在职',   'Active',    'Đang làm', 'ធ្វើការ',   '在職',     '재직',    2, 1, 'green'),
('staff_status', '2', '停职',   'Suspended', 'Tạm dừng', 'ផ្អាកការ',  '停職',     '정직',    3, 1, 'red'),

-- ── 服务项目类型 ──────────────────────────────────────────────────────────────
('service_type', '0', '常规项目', 'Regular', 'Thông thường', 'ធម្មតា', '通常',      '일반',   1, 1, 'blue'),
('service_type', '1', '特殊项目', 'Special', 'Đặc biệt',     'ពិសេស',  'スペシャル','스페셜', 2, 1, 'gold'),

-- ── 订单状态（在线预约）──────────────────────────────────────────────────────
('order_status', '0', '待支付',   'Pending Payment', 'Chờ TT',     'រង់ចាំ',         '支払待ち',   '결제 대기',  1, 1, 'default'),
('order_status', '1', '已支付',   'Paid',            'Đã TT',      'បានទូទាត់',      '支払済み',   '결제 완료',  2, 1, 'cyan'),
('order_status', '2', '已派单',   'Dispatched',      'Đã phân',    'បានបញ្ជូន',      '配車済み',   '배차 완료',  3, 1, 'blue'),
('order_status', '3', '技师前往', 'On Way',          'Đang đến',   'កំពុងទៅ',        '向かっています','이동 중', 4, 1, 'purple'),
('order_status', '4', '服务中',   'In Service',      'Đang phục vụ','កំពុងបម្រើ',    'サービス中', '서비스 중',  5, 1, 'blue'),
('order_status', '5', '待评价',   'Pending Review',  'Chờ đánh giá','រង់ចាំ',        '評価待ち',   '평가 대기',  6, 1, 'orange'),
('order_status', '6', '已完成',   'Completed',       'Hoàn thành',  'បានបញ្ចប់',     '完了',       '완료',       7, 1, 'green'),
('order_status', '7', '取消中',   'Cancelling',      'Đang hủy',    'កំពុងលុប',      'キャンセル中','취소 중',   8, 1, 'orange'),
('order_status', '8', '已取消',   'Cancelled',       'Đã hủy',      'បានលុបចោល',     'キャンセル済','취소됨',    9, 1, 'red'),
('order_status', '9', '已退款',   'Refunded',        'Đã hoàn',     'បានសងប្រាក់',   '返金済み',   '환불됨',     10,1, 'volcano'),

-- ── 门店散客会话状态 ──────────────────────────────────────────────────────────
('walkin_status', '0', '待分配',   'Waiting',   'Đang chờ',     'រង់ចាំ',        '待機中',     '대기 중',   1, 1, 'default'),
('walkin_status', '1', '服务中',   'Serving',   'Đang phục vụ', 'កំពុងបម្រើ',   'サービス中', '서비스 중', 2, 1, 'blue'),
('walkin_status', '2', '已结账',   'Settled',   'Đã thanh toán','បានទូទាត់',     '会計済み',   '정산 완료', 3, 1, 'green'),
('walkin_status', '3', '已取消',   'Cancelled', 'Đã hủy',       'បានលុបចោល',    'キャンセル', '취소됨',    4, 1, 'red'),

-- ── 门店散客支付方式 ──────────────────────────────────────────────────────────
('walkin_pay_type', '1', '现金',   'Cash',           'Tiền mặt',     'សាច់ប្រាក់',     '現金',      '현금',      1, 1, 'green'),
('walkin_pay_type', '2', 'ABA Pay','ABA Pay',         'ABA Pay',      'ABA Pay',         'ABA Pay',   'ABA Pay',   2, 1, 'blue'),
('walkin_pay_type', '3', 'USDT',   'USDT',            'USDT',         'USDT',            'USDT',      'USDT',      3, 1, 'orange'),
('walkin_pay_type', '4', '微信支付','WeChat Pay',      'WeChat',       'WeChat',          'WeChat',    'WeChat',    4, 1, 'green'),
('walkin_pay_type', '5', '支付宝', 'Alipay',          'Alipay',       'Alipay',          'Alipay',    'Alipay',    5, 1, 'blue'),
('walkin_pay_type', '6', '挂账',   'On Account',      'Chịu nợ',      'ខ្ចីប្រាក់',    '付け',      '외상',      6, 1, 'default'),

-- ── 在线支付方式 ──────────────────────────────────────────────────────────────
('pay_type', '1', 'ABA Pay',  'ABA Pay', 'ABA Pay', 'ABA Pay', 'ABA Pay', 'ABA Pay', 1, 1, 'blue'),
('pay_type', '2', 'USDT',     'USDT',    'USDT',    'USDT',    'USDT',    'USDT',    2, 1, 'green'),
('pay_type', '3', '钱包余额', 'Wallet',  'Ví điện tử','កាបូបអេឡិចត្រូនិក','ウォレット','지갑', 3, 1, 'purple'),
('pay_type', '4', '现金',     'Cash',   'Tiền mặt', 'សាច់ប្រាក់',      '現金',     '현금', 4, 1, 'default'),

-- ── 支付状态 ─────────────────────────────────────────────────────────────────
('pay_status', '0', '待支付',   'Pending',  'Chờ TT',        'រង់ចាំ',       '支払待ち', '결제 대기', 1, 1, 'default'),
('pay_status', '1', '支付成功', 'Success',  'Thành công',     'ជោគជ័យ',      '支払成功', '결제 성공', 2, 1, 'green'),
('pay_status', '2', '支付失败', 'Failed',   'Thất bại',       'បរាជ័យ',       '支払失敗', '결제 실패', 3, 1, 'red'),
('pay_status', '3', '已退款',   'Refunded', 'Đã hoàn tiền',   'បានសងប្រាក់', '返金済み', '환불됨',    4, 1, 'volcano'),

-- ── 结算货币 ─────────────────────────────────────────────────────────────────
('currency', 'USD',  'USD 美元',   'USD', NULL, NULL, NULL, NULL, 1, 1, '#3b82f6'),
('currency', 'USDT', 'USDT 泰达币','USDT',NULL, NULL, NULL, NULL, 2, 1, '#26a17b'),
('currency', 'KHR',  'KHR 瑞尔',   'KHR', NULL, NULL, NULL, NULL, 3, 1, '#dc2626'),
('currency', 'CNY',  'CNY 人民币', 'CNY', NULL, NULL, NULL, NULL, 4, 1, '#ef4444'),
('currency', 'THB',  'THB 泰铢',   'THB', NULL, NULL, NULL, NULL, 5, 1, '#a855f7'),
('currency', 'SGD',  'SGD 新元',   'SGD', NULL, NULL, NULL, NULL, 6, 1, '#f59e0b'),

-- ── 优惠券类型 ────────────────────────────────────────────────────────────────
('coupon_type', '1', '满减券',     'Cash Discount',  'Phiếu giảm giá', 'គូប៉ុងបញ្ចុះ', '割引クーポン', '할인 쿠폰',   1, 1, 'red'),
('coupon_type', '2', '折扣券',     'Percentage Off', 'Giảm phần trăm', 'ប័ណ្ណ%',         '割引券',       '% 할인권',    2, 1, 'purple'),
('coupon_type', '3', '免交通费券', 'Free Delivery',  'Miễn phí đi lại','ឥតគិតថ្លៃ',    '交通費無料券', '교통비 무료', 3, 1, 'cyan'),

-- ── 优惠券使用状态 ────────────────────────────────────────────────────────────
('coupon_use_status', '0', '未使用', 'Unused',  'Chưa dùng', 'មិនទាន់ប្រើ', '未使用', '미사용', 1, 1, 'green'),
('coupon_use_status', '1', '已使用', 'Used',    'Đã dùng',   'បានប្រើ',      '使用済み','사용됨', 2, 1, 'default'),
('coupon_use_status', '2', '已过期', 'Expired', 'Đã hết hạn','ផុតកំណត់',     '期限切れ','만료됨', 3, 1, 'red'),

-- ── 钱包状态 ─────────────────────────────────────────────────────────────────
('wallet_status', '1', '正常', 'Normal', 'Bình thường', 'ធម្មតា', '正常', '정상', 1, 1, 'green'),
('wallet_status', '0', '冻结', 'Frozen', 'Bị đóng băng','凍結',   '凍結', '동결', 2, 1, 'blue'),

-- ── 钱包流水类型 ──────────────────────────────────────────────────────────────
('wallet_flow_type', '1', '充值',     'Top Up',         'Nạp tiền',       'បញ្ចូល',        'チャージ',     '충전',         1, 1, 'green'),
('wallet_flow_type', '2', '消费扣款', 'Deduction',      'Thanh toán',     'ការផ្ទេរ',       '支払い',       '결제',         2, 1, 'red'),
('wallet_flow_type', '3', '退款到账', 'Refund',         'Hoàn tiền',      'ការស្ដារ',       '返金',         '환불',         3, 1, 'volcano'),
('wallet_flow_type', '4', '接单收入', 'Service Income', 'Thu nhập DV',    'ប្រាក់ចំណូល',   '収入',         '서비스 수입',  4, 1, 'blue'),
('wallet_flow_type', '5', '申请提现', 'Withdrawal',     'Rút tiền',       'ដកប្រាក់',       '出金',         '출금',         5, 1, 'orange'),
('wallet_flow_type', '6', '平台佣金', 'Platform Fee',   'Hoa hồng',       'ផ្ដល់ជូនវេទិកា', '手数料',       '플랫폼 수수료',6, 1, 'purple'),

-- ── 结算单状态 ────────────────────────────────────────────────────────────────
('settlement_status', '0', '待结算', 'Pending',  'Chờ thanh lý', 'រង់ចាំ',         '精算待ち', '정산 대기', 1, 1, 'orange'),
('settlement_status', '1', '已结算', 'Settled',  'Đã thanh lý',  'បានបញ្ចប់',      '精算済み', '정산 완료', 2, 1, 'green'),
('settlement_status', '2', '争议暂扣','Disputed','Đang tranh chấp','ជំទាស់',         '係争中',   '분쟁 중',   3, 1, 'red'),

-- ── 薪资发放状态 ──────────────────────────────────────────────────────────────
('salary_status', '0', '待发放', 'Pending',   'Chờ phát',  'រង់ចាំ',     '支給待ち', '지급 대기', 1, 1, 'orange'),
('salary_status', '1', '已发放', 'Paid',      'Đã phát',   'បានផ្ដល់',   '支給済み', '지급 완료', 2, 1, 'green'),
('salary_status', '2', '已作废', 'Voided',    'Đã hủy',    'បានបោះបង់',  '無効',     '무효',      3, 1, 'red'),

-- ── 薪资员工类型 ──────────────────────────────────────────────────────────────
('staff_type', '1', '员工',   'Staff',      'Nhân viên', 'បុគ្គលិក', 'スタッフ', '직원', 1, 1, NULL),
('staff_type', '2', '技师',   'Technician', 'Kỹ thuật',  'អ្នកបច្ចេកទេស','技師', '기술자',2, 1, NULL),

-- ── 支出类别 ─────────────────────────────────────────────────────────────────
('expense_category', '1', '房租水电', 'Utilities',   'Tiện ích',       'ឧបករណ៍',         '光熱費',   '공과금',    1, 1, NULL),
('expense_category', '2', '耗材采购', 'Supplies',    'Vật tư',         'ជ្រើសរើស',       '消耗品',   '소모품',    2, 1, NULL),
('expense_category', '3', '员工工资', 'Payroll',     'Lương',          'ប្រាក់ខែ',        '給与',     '급여',      3, 1, NULL),
('expense_category', '4', '市场营销', 'Marketing',   'Tiếp thị',       'ទីផ្សារ',         '広告費',   '마케팅',    4, 1, NULL),
('expense_category', '5', '设备维修', 'Maintenance', 'Bảo trì',        'ថែទាំ',           '保守費',   '유지보수',  5, 1, NULL),
('expense_category', '6', '其他支出', 'Others',      'Khác',           'ផ្សេងទៀត',        'その他',   '기타',      6, 1, NULL),

-- ── 车辆状态 ─────────────────────────────────────────────────────────────────
('vehicle_status', '0', '空闲',   'Idle',        'Rảnh',           'ទំនេរ',     '空車',   '대기',    1, 1, 'green'),
('vehicle_status', '1', '使用中', 'In Use',      'Đang sử dụng',   'កំពុងប្រើ', '使用中', '사용 중', 2, 1, 'blue'),
('vehicle_status', '2', '维修中', 'Maintenance', 'Đang sửa chữa',  'ជួសជុល',    '整備中', '정비 중', 3, 1, 'orange'),

-- ── 车辆品牌 ─────────────────────────────────────────────────────────────────
-- remark 字段存储品牌主色（用于前端 Tag 颜色）
('vehicle_brand', 'Toyota',     'Toyota 丰田',     'Toyota',     NULL, NULL, NULL, NULL, 1,  1, '#eb0a1e'),
('vehicle_brand', 'Honda',      'Honda 本田',      'Honda',      NULL, NULL, NULL, NULL, 2,  1, '#cc0000'),
('vehicle_brand', 'Mazda',      'Mazda 马自达',    'Mazda',      NULL, NULL, NULL, NULL, 3,  1, '#c00000'),
('vehicle_brand', 'Mitsubishi', 'Mitsubishi 三菱', 'Mitsubishi', NULL, NULL, NULL, NULL, 4,  1, '#e60012'),
('vehicle_brand', 'Hyundai',    'Hyundai 现代',    'Hyundai',    NULL, NULL, NULL, NULL, 5,  1, '#002c5f'),
('vehicle_brand', 'Kia',        'Kia 起亚',        'Kia',        NULL, NULL, NULL, NULL, 6,  1, '#05141f'),
('vehicle_brand', 'Lexus',      'Lexus 雷克萨斯',  'Lexus',      NULL, NULL, NULL, NULL, 7,  1, '#1a1a1a'),
('vehicle_brand', 'BMW',        'BMW 宝马',        'BMW',        NULL, NULL, NULL, NULL, 8,  1, '#1c69d4'),
('vehicle_brand', 'Mercedes',   'Mercedes 奔驰',   'Mercedes',   NULL, NULL, NULL, NULL, 9,  1, '#222222'),
('vehicle_brand', 'Audi',       'Audi 奥迪',       'Audi',       NULL, NULL, NULL, NULL, 10, 1, '#bb0a14'),
('vehicle_brand', 'Nissan',     'Nissan 日产',     'Nissan',     NULL, NULL, NULL, NULL, 11, 1, '#c3002f'),
('vehicle_brand', 'Ford',       'Ford 福特',       'Ford',       NULL, NULL, NULL, NULL, 12, 1, '#003499'),
('vehicle_brand', 'Suzuki',     'Suzuki 铃木',     'Suzuki',     NULL, NULL, NULL, NULL, 13, 1, '#1e4ea3'),
('vehicle_brand', 'Isuzu',      'Isuzu 五十铃',    'Isuzu',      NULL, NULL, NULL, NULL, 14, 1, '#e8141f'),
('vehicle_brand', 'Other',      '其他品牌',        'Other',      NULL, NULL, NULL, NULL, 99, 1, '#667eea'),

-- ── 车辆颜色 ─────────────────────────────────────────────────────────────────
-- remark 字段存储颜色 hex 值，前端可直接用于色块展示
('vehicle_color', 'pearl_white',   '珍珠白', 'Pearl White',    NULL, NULL, NULL, NULL, 1,  1, '#f0ede8'),
('vehicle_color', 'deep_black',    '深空黑', 'Deep Black',     NULL, NULL, NULL, NULL, 2,  1, '#1a1a1a'),
('vehicle_color', 'silver_gray',   '银灰色', 'Silver Gray',    NULL, NULL, NULL, NULL, 3,  1, '#c0c0c0'),
('vehicle_color', 'magnetic_gray', '磁性灰', 'Magnetic Gray',  NULL, NULL, NULL, NULL, 4,  1, '#757575'),
('vehicle_color', 'soul_red',      '魂动红', 'Soul Red',       NULL, NULL, NULL, NULL, 5,  1, '#c1121f'),
('vehicle_color', 'nebula_blue',   '星云蓝', 'Nebula Blue',    NULL, NULL, NULL, NULL, 6,  1, '#2563eb'),
('vehicle_color', 'olive_green',   '橄榄绿', 'Olive Green',    NULL, NULL, NULL, NULL, 7,  1, '#4d7c0f'),
('vehicle_color', 'crystal_black', '水晶黑', 'Crystal Black',  NULL, NULL, NULL, NULL, 8,  1, '#0f172a'),
('vehicle_color', 'crystal_white', '晶石白', 'Crystal White',  NULL, NULL, NULL, NULL, 9,  1, '#f8fafc'),
('vehicle_color', 'rock_gray',     '岩石灰', 'Rock Gray',      NULL, NULL, NULL, NULL, 10, 1, '#6b7280'),
('vehicle_color', 'zircon_silver', '锆沙银', 'Zircon Silver',  NULL, NULL, NULL, NULL, 11, 1, '#94a3b8'),
('vehicle_color', 'polar_white',   '极地白', 'Polar White',    NULL, NULL, NULL, NULL, 12, 1, '#f1f5f9'),
('vehicle_color', 'champagne',     '香槟金', 'Champagne Gold', NULL, NULL, NULL, NULL, 13, 1, '#c5a028'),

-- ── 出行目的 ─────────────────────────────────────────────────────────────────
('vehicle_purpose', '1', '接送技师',  'Tech Transport', 'Đón kỹ thuật viên', 'ដឹកអ្នកបច្ចេកទេស','技師送迎', '기술자 이동', 1, 1, NULL),
('vehicle_purpose', '2', '接送客户',  'Client Transfer','Đón khách hàng',    'ដឹកភ្ញៀវ',         '顧客送迎', '고객 이동',   2, 1, NULL),
('vehicle_purpose', '3', '采购物资',  'Procurement',    'Mua sắm',           'ទិញទំនិញ',          '仕入れ',   '구매',        3, 1, NULL),
('vehicle_purpose', '4', '办公出行',  'Business',       'Công vụ',           'ការងារ',             '業務',     '업무',        4, 1, NULL),
('vehicle_purpose', '9', '其他',      'Other',          'Khác',              'ផ្សេងទៀត',          'その他',   '기타',        99,1, NULL),

-- ── 派车单状态 ────────────────────────────────────────────────────────────────
('dispatch_status', '0', '待接单',   'Waiting',   'Chờ nhận',     'រង់ចាំ',          '受注待ち',       '배차 대기', 1, 1, 'default'),
('dispatch_status', '1', '已接单',   'Accepted',  'Đã nhận',      'បានទទួល',         '受注済み',       '수락됨',    2, 1, 'blue'),
('dispatch_status', '2', '前往接客', 'En Route',  'Đang đến',     'កំពុងទៅ',         '向かっています', '이동 중',   3, 1, 'purple'),
('dispatch_status', '3', '已到达',   'Arrived',   'Đã đến',       'បានមកដល់',        '到着',           '도착',      4, 1, 'cyan'),
('dispatch_status', '4', '已上车',   'Picked Up', 'Đã lên xe',    'ឡើងរថយន្ត',      '乗車済み',       '탑승됨',    5, 1, 'geekblue'),
('dispatch_status', '5', '已完成',   'Completed', 'Hoàn thành',   'បានបញ្ចប់',       '完了',           '완료',      6, 1, 'green'),
('dispatch_status', '9', '已取消',   'Cancelled', 'Đã hủy',       'បានលុបចោល',       'キャンセル',     '취소됨',    7, 1, 'red'),

-- ── 内部派车用途（含颜色/图标，remark JSON: {"c":"hex","i":"emoji"}）──────────
('vehicle_dispatch_purpose', '1', '接送客户', 'Client Transfer', 'Đón khách',   'ដឹកភ្ញៀវ',       '顧客送迎', '고객 이동',   1, 1, '{"c":"#6366f1","i":"🚕"}'),
('vehicle_dispatch_purpose', '2', '采购物资', 'Procurement',     'Mua sắm',     'ទិញទំនិញ',        '仕入れ',   '구매',        2, 1, '{"c":"#f59e0b","i":"🛒"}'),
('vehicle_dispatch_purpose', '3', '员工通勤', 'Commute',         'Đi làm',      'ធ្វើដំណើរ',       '通勤',     '출퇴근',      3, 1, '{"c":"#3b82f6","i":"🚌"}'),
('vehicle_dispatch_purpose', '4', '业务出行', 'Business Trip',   'Công vụ',     'ការងារ',           '業務',     '업무',        4, 1, '{"c":"#10b981","i":"💼"}'),
('vehicle_dispatch_purpose', '5', '其它',     'Other',           'Khác',        'ផ្សេងទៀត',        'その他',   '기타',        9, 1, '{"c":"#94a3b8","i":"🚗"}'),

-- ── 内部车辆调度状态（remark JSON: {"c":"hex","b":"badge"}）──────────────────
('vehicle_dispatch_status', '0', '待出发', 'Pending',   'Chờ khởi hành', 'រង់ចាំ',         '出発待ち', '출발 대기', 1, 1, '{"c":"#3b82f6","b":"default"}'),
('vehicle_dispatch_status', '1', '行程中', 'In Transit','Đang trên đường','កំពុងធ្វើដំណើរ', '移動中',   '이동 중',   2, 1, '{"c":"#f97316","b":"processing"}'),
('vehicle_dispatch_status', '2', '已返回', 'Returned',  'Đã trở về',     'បានត្រឡប់',       '帰還済み', '복귀 완료', 3, 1, '{"c":"#10b981","b":"success"}'),
('vehicle_dispatch_status', '3', '已取消', 'Cancelled', 'Đã hủy',        'បានលុបចោល',      'キャンセル','취소됨',    4, 1, '{"c":"#94a3b8","b":"default"}'),

-- ── 门店散客会话状态（remark JSON: {"c":"hex","b":"badge"}）──────────────────
('walkin_session_status', '0', '待服务', 'Waiting',  'Chờ phục vụ',  'រង់ចាំ',          '待機中',       '대기 중',   1, 1, '{"c":"#3b82f6","b":"processing"}'),
('walkin_session_status', '1', '服务中', 'Serving',  'Đang phục vụ', 'កំពុងបម្រើ',      'サービス中',   '서비스 중', 2, 1, '{"c":"#f97316","b":"processing"}'),
('walkin_session_status', '2', '待结算', 'Settling', 'Chờ thanh toán','រង់ចាំ',          '精算待ち',     '정산 대기', 3, 1, '{"c":"#f59e0b","b":"warning"}'),
('walkin_session_status', '3', '已结算', 'Settled',  'Đã thanh toán','បានទូទាត់',        '精算済み',     '정산 완료', 4, 1, '{"c":"#10b981","b":"success"}'),
('walkin_session_status', '4', '已取消', 'Cancelled','Đã hủy',       'បានលុបចោល',        'キャンセル',   '취소됨',    5, 1, '{"c":"#94a3b8","b":"default"}'),

-- ── 服务项目进度状态（remark JSON: {"c":"hex","i":"emoji"}）──────────────────
('walkin_svc_status', '0', '待服务', 'Pending',   'Chờ phục vụ',  'រង់ចាំ',     '待機中',   '대기 중',   1, 1, '{"c":"#9ca3af","i":"⏳"}'),
('walkin_svc_status', '1', '服务中', 'In Service','Đang phục vụ', 'កំពុងបម្រើ', 'サービス中','서비스 중', 2, 1, '{"c":"#f97316","i":"🔄"}'),
('walkin_svc_status', '2', '已完成', 'Completed', 'Hoàn thành',   'បានបញ្ចប់',   '完了',     '완료',      3, 1, '{"c":"#10b981","i":"✅"}'),

-- ── 收入类型 ─────────────────────────────────────────────────────────────────
('income_type', '1', '订单收入', 'Order Income',  'Thu từ đơn hàng',  'ប្រាក់ចំណូល',     '注文収入',  '주문 수입',  1, 1, '#6366f1'),
('income_type', '2', '散客结算', 'Walk-in',       'Thanh toán trực',  'ការទូទាត់',        '散客精算',  '산발 정산',  2, 1, '#F5A623'),
('income_type', '3', '会员充值', 'Top-up',        'Nạp tiền thành',   'ការបញ្ចូល',        '会員チャージ','회원 충전', 3, 1, '#10b981'),
('income_type', '4', '其它收入', 'Other',         'Khác',             'ផ្សេងទៀត',         'その他',    '기타',       4, 1, '#94a3b8');


-- ── 三、验证输出 ──────────────────────────────────────────────────────────────
SELECT CONCAT(
    '✅ Migration v4.6 完成：写入字典类型 ',
    (SELECT COUNT(*) FROM sys_dict_type),
    ' 种，字典数据项 ',
    (SELECT COUNT(*) FROM sys_dict),
    ' 条'
) AS result;
