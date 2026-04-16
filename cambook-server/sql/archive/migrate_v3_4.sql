-- ============================================================
-- migrate_v3_4: 商户端菜单动态化
-- 1. 为 sys_permission 增加 portal_type 区分管理端/商户端
-- 2. 写入初始商户端菜单数据
-- ============================================================

-- Step 1: 新增 portal_type 字段（0=管理端 1=商户端）
ALTER TABLE sys_permission
    ADD COLUMN portal_type TINYINT NOT NULL DEFAULT 0
    COMMENT '0=管理端 1=商户端'
    AFTER sort;

-- Step 2: 写入商户端菜单（id 使用 1000-1099 区间，避免与管理端冲突）
INSERT INTO sys_permission (id, parent_id, name, code, type, path, component, icon, sort, portal_type, visible, status)
VALUES
-- ── 顶级菜单 ──────────────────────────────────────────────
(1010, 0, '数据看板',  NULL, 2, '/merchant/dashboard',            NULL, 'DashboardOutlined',   1,  1, 1, 1),
(1011, 0, '订单管理',  NULL, 2, '/merchant/orders',               NULL, 'OrderedListOutlined', 2,  1, 1, 1),
(1019, 0, '商户设置',  NULL, 2, '/merchant/profile',              NULL, 'SettingOutlined',     9,  1, 1, 1),

-- ── 公告管理 ─────────────────────────────────────────────
(1000, 0, '公告管理',  NULL, 1, NULL, NULL, 'SoundOutlined',      3,  1, 1, 1),
(1020, 1000, '内部公告', NULL, 2, '/merchant/announce/internal',  NULL, 'TeamOutlined',        1,  1, 1, 1),
(1021, 1000, '客户公告', NULL, 2, '/merchant/announce/customer',  NULL, 'UserOutlined',        2,  1, 1, 1),

-- ── 运营管理 ─────────────────────────────────────────────
(1001, 0, '运营管理',  NULL, 1, NULL, NULL, 'AppstoreOutlined',   4,  1, 1, 1),
(1030, 1001, '会员管理',   NULL, 2, '/merchant/members',                  NULL, 'UserOutlined',        1,  1, 1, 1),
(1031, 1001, '技师管理',   NULL, 2, '/merchant/technicians',              NULL, 'TeamOutlined',        2,  1, 1, 1),
(1032, 1001, '车辆管理',   NULL, 2, '/merchant/vehicles',                 NULL, 'CarOutlined',         3,  1, 1, 1),
(1033, 1001, '服务项目',   NULL, 2, '/merchant/operation/category',       NULL, 'AppstoreOutlined',    4,  1, 1, 1),
(1034, 1001, '评价管理',   NULL, 2, '/merchant/operation/reviews',        NULL, 'StarOutlined',        5,  1, 1, 1),
(1035, 1001, '通知公告',   NULL, 2, '/merchant/operation/notices',        NULL, 'BellOutlined',        6,  1, 1, 1),

-- ── 营销管理 ─────────────────────────────────────────────
(1002, 0, '营销管理',  NULL, 1, NULL, NULL, 'RocketOutlined',     5,  1, 1, 1),
(1040, 1002, '首页轮播',   NULL, 2, '/merchant/operation/banner',         NULL, 'PictureOutlined',     1,  1, 1, 1),
(1041, 1002, '优惠券管理', NULL, 2, '/merchant/coupons',                  NULL, 'TagsOutlined',        2,  1, 1, 1),

-- ── 财务管理 ─────────────────────────────────────────────
(1003, 0, '财务管理',  NULL, 1, NULL, NULL, 'DollarOutlined',     6,  1, 1, 1),
(1050, 1003, '收入统计',   NULL, 2, '/merchant/finance',                  NULL, 'BankOutlined',        1,  1, 1, 1),
(1051, 1003, '提现审核',   NULL, 2, '/merchant/finance/withdraw',         NULL, 'AuditOutlined',       2,  1, 1, 1),

-- ── 权限管理 ─────────────────────────────────────────────
(1004, 0, '权限管理',  NULL, 1, NULL, NULL, 'LockOutlined',       7,  1, 1, 1),
(1060, 1004, '员工管理',   NULL, 2, '/merchant/perm/staff',               NULL, 'IdcardOutlined',      1,  1, 1, 1),
(1061, 1004, '角色权限',   NULL, 2, '/merchant/perm/roles',               NULL, 'KeyOutlined',         2,  1, 1, 1),
(1062, 1004, '部门管理',   NULL, 2, '/merchant/perm/dept',                NULL, 'ApartmentOutlined',   3,  1, 1, 1),
(1063, 1004, '职位管理',   NULL, 2, '/merchant/perm/positions',           NULL, 'SolutionOutlined',    4,  1, 1, 1);
