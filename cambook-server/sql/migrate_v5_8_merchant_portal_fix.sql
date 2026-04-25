-- ═══════════════════════════════════════════════════════════════════════════
-- Migration v5.8 — 商户端全量修复
--
-- 修复内容：
--   1. 确保 cb_service_category 拥有 merchant_id / source_category_id 字段
--   2. 确保商户端所有菜单路径正确，与前端路由完全对齐
--   3. 补全任何缺失的商户端菜单节点
-- ═══════════════════════════════════════════════════════════════════════════

SET NAMES utf8mb4;

-- ─────────────────────────────────────────────────────────────────────────────
-- STEP 1: 确保 cb_service_category 含商户化字段
-- ─────────────────────────────────────────────────────────────────────────────

DROP PROCEDURE IF EXISTS _fix_service_category_cols;
DELIMITER $$
CREATE PROCEDURE _fix_service_category_cols()
BEGIN
    -- merchant_id
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME   = 'cb_service_category'
          AND COLUMN_NAME  = 'merchant_id'
    ) THEN
        ALTER TABLE `cb_service_category`
            ADD COLUMN `merchant_id` BIGINT NULL
                COMMENT '归属商户 ID（NULL = 平台公共类目）'
                AFTER `id`;
    END IF;

    -- source_category_id（写时复制来源）
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME   = 'cb_service_category'
          AND COLUMN_NAME  = 'source_category_id'
    ) THEN
        -- 优先插在 merchant_id 之后，兼容不同排列
        ALTER TABLE `cb_service_category`
            ADD COLUMN `source_category_id` BIGINT NULL
                COMMENT '写时复制来源：商户私有副本记录平台原始类目 ID'
                AFTER `merchant_id`;
    END IF;

    -- price / duration / is_special（migrate_v4_4 应已添加，保险起见）
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME   = 'cb_service_category'
          AND COLUMN_NAME  = 'price'
    ) THEN
        ALTER TABLE `cb_service_category`
            ADD COLUMN `price`      DECIMAL(10,2) NULL COMMENT '服务基础指导价'        AFTER `icon`,
            ADD COLUMN `duration`   INT           NULL COMMENT '标准服务时长（分钟）'   AFTER `price`,
            ADD COLUMN `is_special` TINYINT(1) NOT NULL DEFAULT 0
                COMMENT '是否特殊项目(0=常规,1=特殊)'                                   AFTER `duration`;
    END IF;
END$$
DELIMITER ;
CALL _fix_service_category_cols();
DROP PROCEDURE IF EXISTS _fix_service_category_cols;

SELECT '✅ cb_service_category 字段修复完成' AS step1;

-- ─────────────────────────────────────────────────────────────────────────────
-- STEP 2: 修复商户端菜单路径（按菜单名匹配，安全幂等）
-- ─────────────────────────────────────────────────────────────────────────────

-- 数据看板
UPDATE sys_permission SET path='/merchant/dashboard'
WHERE portal_type=1 AND type=2 AND deleted=0 AND name IN ('数据看板','首页','仪表板')
  AND path NOT IN ('/merchant/dashboard');

-- 在线订单
UPDATE sys_permission SET path='/merchant/orders'
WHERE portal_type=1 AND type=2 AND deleted=0 AND name IN ('在线订单','订单列表','订单管理')
  AND path NOT IN ('/merchant/orders','/merchant/orders/history');

-- 历史记录
UPDATE sys_permission SET path='/merchant/orders/history'
WHERE portal_type=1 AND type=2 AND deleted=0 AND name IN ('历史记录','历史订单','已完成订单')
  AND path NOT IN ('/merchant/orders/history');

-- 散客接待
UPDATE sys_permission SET path='/merchant/walkin'
WHERE portal_type=1 AND type=2 AND deleted=0 AND name IN ('散客接待','门店接待','上门服务')
  AND path NOT IN ('/merchant/walkin');

-- 服务项目
UPDATE sys_permission SET path='/merchant/operation/category'
WHERE portal_type=1 AND type=2 AND deleted=0
  AND (name IN ('服务项目','服务分类','服务类目') OR path LIKE '%category%')
  AND path NOT IN ('/merchant/operation/category');

-- 评价管理
UPDATE sys_permission SET path='/merchant/operation/reviews'
WHERE portal_type=1 AND type=2 AND deleted=0 AND name IN ('评价管理','用户评价','评论管理')
  AND path NOT IN ('/merchant/operation/reviews');

-- 通知公告（店内）
UPDATE sys_permission SET path='/merchant/operation/notices'
WHERE portal_type=1 AND type=2 AND deleted=0 AND name IN ('通知公告','店内公告','门店通知')
  AND path NOT IN ('/merchant/operation/notices','/merchant/announce/internal','/merchant/announce/customer');

-- 首页轮播
UPDATE sys_permission SET path='/merchant/operation/banner'
WHERE portal_type=1 AND type=2 AND deleted=0
  AND (name IN ('首页轮播','轮播图','Banner管理') OR path LIKE '%banner%')
  AND path NOT IN ('/merchant/operation/banner');

-- 会员管理
UPDATE sys_permission SET path='/merchant/members'
WHERE portal_type=1 AND type=2 AND deleted=0 AND name IN ('会员管理','会员列表')
  AND path NOT IN ('/merchant/members');

-- 技师管理
UPDATE sys_permission SET path='/merchant/technicians'
WHERE portal_type=1 AND type=2 AND deleted=0 AND name IN ('技师管理','技师列表')
  AND path NOT IN ('/merchant/technicians');

-- 车辆列表
UPDATE sys_permission SET path='/merchant/vehicles'
WHERE portal_type=1 AND type=2 AND deleted=0 AND name IN ('车辆列表','车辆管理') AND id != 1032
  AND path NOT IN ('/merchant/vehicles','/merchant/vehicles/dispatch');

-- 派车记录
UPDATE sys_permission SET path='/merchant/vehicles/dispatch'
WHERE portal_type=1 AND type=2 AND deleted=0 AND name IN ('派车记录','调度记录','车辆调度')
  AND path NOT IN ('/merchant/vehicles/dispatch');

-- 优惠券管理
UPDATE sys_permission SET path='/merchant/coupons'
WHERE portal_type=1 AND type=2 AND deleted=0 AND name IN ('优惠券管理','优惠券','营销券')
  AND path NOT IN ('/merchant/coupons');

-- 财务概览
UPDATE sys_permission SET path='/merchant/finance/overview'
WHERE portal_type=1 AND type=2 AND deleted=0 AND name IN ('财务概览','收支概览','财务总览')
  AND path NOT IN ('/merchant/finance/overview');

-- 收入统计 / 收入记录
UPDATE sys_permission SET path='/merchant/finance'
WHERE portal_type=1 AND type=2 AND deleted=0 AND name IN ('收入统计','财务统计','综合财务') AND id=1050
  AND path NOT IN ('/merchant/finance');

-- 收入记录（新菜单）
UPDATE sys_permission SET path='/merchant/finance/income'
WHERE portal_type=1 AND type=2 AND deleted=0 AND name IN ('收入记录','收款流水')
  AND path NOT IN ('/merchant/finance/income');

-- 支出管理
UPDATE sys_permission SET path='/merchant/finance/expense'
WHERE portal_type=1 AND type=2 AND deleted=0 AND name IN ('支出管理','费用管理','支出记录')
  AND path NOT IN ('/merchant/finance/expense');

-- 薪资 / 工资管理
UPDATE sys_permission SET path='/merchant/finance/salary'
WHERE portal_type=1 AND type=2 AND deleted=0 AND name IN ('工资管理','薪资管理','员工薪资')
  AND path NOT IN ('/merchant/finance/salary');

-- 技师结算
UPDATE sys_permission SET path='/merchant/finance/settlement'
WHERE portal_type=1 AND type=2 AND deleted=0 AND name IN ('技师结算','结算管理','技师工资')
  AND path NOT IN ('/merchant/finance/settlement');

-- 提现审核
UPDATE sys_permission SET path='/merchant/finance/withdraw'
WHERE portal_type=1 AND type=2 AND deleted=0 AND name IN ('提现审核','提现管理')
  AND path NOT IN ('/merchant/finance/withdraw');

-- 基本资料（商户设置）
UPDATE sys_permission SET path='/merchant/profile'
WHERE portal_type=1 AND type=2 AND deleted=0 AND name IN ('基本资料','商户资料','店铺设置') AND id != 1019
  AND path NOT IN ('/merchant/profile');

-- 结算币种
UPDATE sys_permission SET path='/merchant/settings/currency'
WHERE portal_type=1 AND type=2 AND deleted=0 AND name IN ('结算币种','币种配置','货币管理')
  AND path NOT IN ('/merchant/settings/currency');

-- 内部公告
UPDATE sys_permission SET path='/merchant/announce/internal'
WHERE portal_type=1 AND type=2 AND deleted=0 AND name IN ('内部公告','员工公告')
  AND path NOT IN ('/merchant/announce/internal');

-- 客户公告
UPDATE sys_permission SET path='/merchant/announce/customer'
WHERE portal_type=1 AND type=2 AND deleted=0 AND name IN ('客户公告','会员公告')
  AND path NOT IN ('/merchant/announce/customer');

-- 员工管理
UPDATE sys_permission SET path='/merchant/perm/staff'
WHERE portal_type=1 AND type=2 AND deleted=0 AND name IN ('员工管理','员工列表')
  AND path NOT IN ('/merchant/perm/staff');

-- 角色权限
UPDATE sys_permission SET path='/merchant/perm/roles'
WHERE portal_type=1 AND type=2 AND deleted=0 AND name IN ('角色权限','角色管理')
  AND path NOT IN ('/merchant/perm/roles');

-- 部门管理
UPDATE sys_permission SET path='/merchant/perm/dept'
WHERE portal_type=1 AND type=2 AND deleted=0 AND name IN ('部门管理','部门列表')
  AND path NOT IN ('/merchant/perm/dept');

-- 职位管理
UPDATE sys_permission SET path='/merchant/perm/positions'
WHERE portal_type=1 AND type=2 AND deleted=0 AND name IN ('职位管理','岗位管理')
  AND path NOT IN ('/merchant/perm/positions');

-- 历史订单（migrate_v5_7 可能误插了管理端路径，修正为商户端）
UPDATE sys_permission SET path='/merchant/orders/history'
WHERE portal_type=1 AND type=2 AND deleted=0 AND name IN ('历史订单','订单历史')
  AND path NOT IN ('/merchant/orders/history');

SELECT '✅ 商户端菜单路径修复完成' AS step2;

-- ─────────────────────────────────────────────────────────────────────────────
-- STEP 3: 补全缺失的商户端菜单节点（INSERT IGNORE，ID从 2000 起，不与已有 1000-1210 冲突）
-- ─────────────────────────────────────────────────────────────────────────────

-- 先确保目录节点存在
INSERT IGNORE INTO sys_permission
    (id, parent_id, name, code, type, path, component, icon, sort, portal_type, visible, status, deleted)
VALUES
-- 公告管理 目录（id=1000 已在 migrate_v3_4 存在）
(1000, 0, '公告管理',  NULL, 1, NULL, NULL, 'SoundOutlined',      3, 1, 1, 1, 0),
-- 运营管理 目录
(1001, 0, '运营管理',  NULL, 1, NULL, NULL, 'AppstoreOutlined',   4, 1, 1, 1, 0),
-- 营销管理 目录
(1002, 0, '营销管理',  NULL, 1, NULL, NULL, 'RocketOutlined',     5, 1, 1, 1, 0),
-- 财务管理 目录
(1003, 0, '财务管理',  NULL, 1, NULL, NULL, 'DollarOutlined',     6, 1, 1, 1, 0),
-- 权限管理 目录
(1004, 0, '权限管理',  NULL, 1, NULL, NULL, 'LockOutlined',       7, 1, 1, 1, 0),
-- 订单管理 目录（v4_3 改为 type=1）
(1011, 0, '订单管理',  NULL, 1, NULL, NULL, 'OrderedListOutlined',2, 1, 1, 1, 0),
-- 车辆管理 目录（v4_3 改为 type=1）
(1032, 1001, '车辆管理', NULL, 1, NULL, NULL, 'CarOutlined',      3, 1, 1, 1, 0),
-- 商户设置 目录（v4_3 改为 type=1）
(1019, 0, '商户设置',  NULL, 1, NULL, NULL, 'SettingOutlined',    9, 1, 1, 1, 0);

-- 补全菜单叶节点（只补缺失的）
INSERT IGNORE INTO sys_permission
    (id, parent_id, name, code, type, path, component, icon, sort, portal_type, visible, status, deleted)
VALUES
-- ── 数据看板（顶级）
(1010, 0,    '数据看板', NULL, 2, '/merchant/dashboard',             NULL, 'DashboardOutlined',   1, 1, 1, 1, 0),
-- ── 订单管理 子菜单
(1100, 1011, '在线订单', NULL, 2, '/merchant/orders',                NULL, 'OrderedListOutlined', 1, 1, 1, 1, 0),
(1101, 1011, '历史记录', NULL, 2, '/merchant/orders/history',        NULL, 'FileTextOutlined',    2, 1, 1, 1, 0),
-- ── 散客接待（顶级）
(1102, 0,    '散客接待', NULL, 2, '/merchant/walkin',                NULL, 'IdcardOutlined',     30, 1, 1, 1, 0),
-- ── 运营管理 子菜单
(1030, 1001, '会员管理', NULL, 2, '/merchant/members',               NULL, 'UserOutlined',        1, 1, 1, 1, 0),
(1031, 1001, '技师管理', NULL, 2, '/merchant/technicians',           NULL, 'TeamOutlined',        2, 1, 1, 1, 0),
(1033, 1001, '服务项目', NULL, 2, '/merchant/operation/category',    NULL, 'AppstoreOutlined',    4, 1, 1, 1, 0),
(1034, 1001, '评价管理', NULL, 2, '/merchant/operation/reviews',     NULL, 'StarOutlined',        5, 1, 1, 1, 0),
(1035, 1001, '通知公告', NULL, 2, '/merchant/operation/notices',     NULL, 'BellOutlined',        6, 1, 1, 1, 0),
-- ── 车辆管理 子菜单
(1103, 1032, '车辆列表', NULL, 2, '/merchant/vehicles',              NULL, 'CarOutlined',         1, 1, 1, 1, 0),
(1104, 1032, '派车记录', NULL, 2, '/merchant/vehicles/dispatch',     NULL, 'FileTextOutlined',    2, 1, 1, 1, 0),
-- ── 营销管理 子菜单
(1040, 1002, '首页轮播', NULL, 2, '/merchant/operation/banner',      NULL, 'PictureOutlined',     1, 1, 1, 1, 0),
(1041, 1002, '优惠券管理',NULL,2, '/merchant/coupons',               NULL, 'TagsOutlined',        2, 1, 1, 1, 0),
-- ── 财务管理 子菜单
(1105, 1003, '财务概览', NULL, 2, '/merchant/finance/overview',      NULL, 'BarChartOutlined',    1, 1, 1, 1, 0),
(1050, 1003, '收入统计', NULL, 2, '/merchant/finance',               NULL, 'BankOutlined',        2, 1, 1, 1, 0),
(1106, 1003, '收入记录', NULL, 2, '/merchant/finance/income',        NULL, 'DollarOutlined',      3, 1, 1, 1, 0),
(1107, 1003, '支出管理', NULL, 2, '/merchant/finance/expense',       NULL, 'MinusCircleOutlined', 4, 1, 1, 1, 0),
(1108, 1003, '工资管理', NULL, 2, '/merchant/finance/salary',        NULL, 'TeamOutlined',        5, 1, 1, 1, 0),
(1109, 1003, '技师结算', NULL, 2, '/merchant/finance/settlement',    NULL, 'BankOutlined',        6, 1, 1, 1, 0),
(1051, 1003, '提现审核', NULL, 2, '/merchant/finance/withdraw',      NULL, 'AuditOutlined',       7, 1, 1, 1, 0),
-- ── 商户设置 子菜单
(1111, 1019, '基本资料', NULL, 2, '/merchant/profile',               NULL, 'UserOutlined',        1, 1, 1, 1, 0),
(1112, 1019, '结算币种', NULL, 2, '/merchant/settings/currency',     NULL, 'GlobalOutlined',      2, 1, 1, 1, 0),
-- ── 公告管理 子菜单
(1020, 1000, '内部公告', NULL, 2, '/merchant/announce/internal',     NULL, 'TeamOutlined',        1, 1, 1, 1, 0),
(1021, 1000, '客户公告', NULL, 2, '/merchant/announce/customer',     NULL, 'UserOutlined',        2, 1, 1, 1, 0),
-- ── 权限管理 子菜单
(1060, 1004, '员工管理', NULL, 2, '/merchant/perm/staff',            NULL, 'IdcardOutlined',      1, 1, 1, 1, 0),
(1061, 1004, '角色权限', NULL, 2, '/merchant/perm/roles',            NULL, 'KeyOutlined',         2, 1, 1, 1, 0),
(1062, 1004, '部门管理', NULL, 2, '/merchant/perm/dept',             NULL, 'ApartmentOutlined',   3, 1, 1, 1, 0),
(1063, 1004, '职位管理', NULL, 2, '/merchant/perm/positions',        NULL, 'SolutionOutlined',    4, 1, 1, 1, 0);

SELECT '✅ 商户端菜单节点补全完成' AS step3;

-- ─────────────────────────────────────────────────────────────────────────────
-- STEP 4: 修正 id=1032 车辆管理由 type=2 变为 type=1（目录），清除路径
--         修正 id=1011 订单管理同理
--         修正 id=1019 商户设置同理
-- ─────────────────────────────────────────────────────────────────────────────
UPDATE sys_permission SET type=1, path=NULL WHERE id IN (1011, 1032, 1019) AND portal_type=1;

SELECT '✅ 目录节点 type 修正完成' AS step4;

-- ─────────────────────────────────────────────────────────────────────────────
-- STEP 5: 验证查询——查看所有商户端菜单
-- ─────────────────────────────────────────────────────────────────────────────
SELECT
    id,
    parent_id AS parentId,
    name,
    type,
    path,
    icon,
    sort,
    CASE WHEN deleted=0 THEN '✅启用' ELSE '❌删除' END AS state
FROM sys_permission
WHERE portal_type = 1 AND deleted = 0
ORDER BY sort ASC, id ASC;

SELECT 'Migration v5.8 complete: Merchant portal schema & menus fully fixed.' AS result;
