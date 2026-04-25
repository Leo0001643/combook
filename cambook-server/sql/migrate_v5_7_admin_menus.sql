-- ═══════════════════════════════════════════════════════════════════════════
-- Migration v5.7 — 管理端菜单路径全量修复 & 新功能菜单补全
--
-- 背景：前端路由从 /admin/xxx 风格重构为 /operation/xxx、/xxx 等新式路径，
--       但 sys_permission 表中的管理端菜单路径未同步更新，导致点击菜单后
--       React Outlet 无法匹配路由，内容区呈现空白。
--
-- 修复策略：
--   1. STEP 1 — 更新已有菜单的错误路径（按名称匹配，安全幂等）
--   2. STEP 2 — 确保全量目录节点存在（REPLACE INTO 高ID区间 9000-9050）
--   3. STEP 3 — 确保全量菜单节点存在（REPLACE INTO 高ID区间 9051-9150）
--   4. STEP 4 — 授权给 SUPER_ADMIN 角色（INSERT IGNORE）
-- ═══════════════════════════════════════════════════════════════════════════

SET NAMES utf8mb4;

-- ─────────────────────────────────────────────────────────────────────────────
-- STEP 1: 更新已有路径错误的菜单项（按名称精确匹配，安全）
-- ─────────────────────────────────────────────────────────────────────────────

-- 数据看板
UPDATE sys_permission SET path='/dashboard'
WHERE portal_type=0 AND type=2 AND deleted=0 AND (name='数据看板' OR name='仪表板' OR name='首页')
  AND path NOT IN ('/dashboard');

-- 会员管理
UPDATE sys_permission SET path='/users'
WHERE portal_type=0 AND type=2 AND deleted=0 AND name IN ('会员管理','用户管理','会员列表')
  AND path NOT IN ('/users');

-- 技师管理
UPDATE sys_permission SET path='/technicians'
WHERE portal_type=0 AND type=2 AND deleted=0 AND name IN ('技师管理','技师列表')
  AND path NOT IN ('/technicians');

-- 技师审核
UPDATE sys_permission SET path='/technicians/audit'
WHERE portal_type=0 AND type=2 AND deleted=0 AND name IN ('技师审核','审核列表','入驻审核')
  AND path NOT IN ('/technicians/audit');

-- 商户管理
UPDATE sys_permission SET path='/merchants'
WHERE portal_type=0 AND type=2 AND deleted=0 AND name IN ('商户管理','商户列表')
  AND path NOT IN ('/merchants');

-- 在线订单
UPDATE sys_permission SET path='/orders'
WHERE portal_type=0 AND type=2 AND deleted=0 AND name IN ('在线订单','订单列表','订单管理')
  AND path NOT IN ('/orders', '/walkin');

-- 订单历史
UPDATE sys_permission SET path='/orders/history'
WHERE portal_type=0 AND type=2 AND deleted=0 AND name IN ('历史订单','订单历史','已完成订单')
  AND path NOT IN ('/orders/history');

-- 门店订单
UPDATE sys_permission SET path='/walkin'
WHERE portal_type=0 AND type=2 AND deleted=0 AND name IN ('门店订单','散客接待','上门服务')
  AND path NOT IN ('/walkin');

-- 服务类目（旧：/admin/category、/system/category等）
UPDATE sys_permission SET path='/operation/category', icon='AppstoreOutlined'
WHERE portal_type=0 AND type=2 AND deleted=0
  AND (name IN ('服务项目','服务类目','服务分类') OR (path LIKE '%category%' AND path NOT LIKE '%merchant%'))
  AND path NOT IN ('/operation/category');

-- Banner管理（旧：/admin/banner、/system/banner等）
UPDATE sys_permission SET path='/operation/banner', icon='PictureOutlined'
WHERE portal_type=0 AND type=2 AND deleted=0
  AND (name IN ('Banner管理','轮播图','横幅管理','首页轮播') OR (path LIKE '%banner%' AND path NOT LIKE '%merchant%' AND path NOT LIKE '%system%'))
  AND path NOT IN ('/operation/banner');

-- 评价管理
UPDATE sys_permission SET path='/operation/reviews', icon='StarOutlined'
WHERE portal_type=0 AND type=2 AND deleted=0 AND name IN ('评价管理','用户评价','评论管理')
  AND path NOT IN ('/operation/reviews');

-- 车辆管理
UPDATE sys_permission SET path='/vehicles'
WHERE portal_type=0 AND type=2 AND deleted=0 AND name IN ('车辆管理','车辆列表')
  AND path NOT IN ('/vehicles', '/vehicles/dispatch');

-- 派车记录
UPDATE sys_permission SET path='/vehicles/dispatch'
WHERE portal_type=0 AND type=2 AND deleted=0 AND name IN ('派车记录','调度记录','车辆调度')
  AND path NOT IN ('/vehicles/dispatch');

-- 优惠券
UPDATE sys_permission SET path='/coupons'
WHERE portal_type=0 AND type=2 AND deleted=0 AND name IN ('优惠券','优惠券管理','优惠管理')
  AND path NOT IN ('/coupons');

-- 财务管理/收入统计
UPDATE sys_permission SET path='/finance'
WHERE portal_type=0 AND type=2 AND deleted=0 AND name IN ('财务管理','收入统计','财务报表')
  AND path NOT IN ('/finance', '/finance/overview', '/finance/income', '/finance/expense', '/finance/salary', '/finance/settlement');

-- 财务概览
UPDATE sys_permission SET path='/finance/overview'
WHERE portal_type=0 AND type=2 AND deleted=0 AND name IN ('财务概览','收支概览','财务总览')
  AND path NOT IN ('/finance/overview');

-- 员工管理（旧：/admin/staff 可能已是对的）
UPDATE sys_permission SET path='/admin/staff'
WHERE portal_type=0 AND type=2 AND deleted=0 AND name IN ('员工管理','员工列表')
  AND path NOT IN ('/admin/staff');

-- 职位管理
UPDATE sys_permission SET path='/admin/positions'
WHERE portal_type=0 AND type=2 AND deleted=0 AND name IN ('职位管理','岗位管理','职位列表')
  AND path NOT IN ('/admin/positions');

-- 角色权限
UPDATE sys_permission SET path='/system/roles'
WHERE portal_type=0 AND type=2 AND deleted=0 AND name IN ('角色权限','角色管理','角色列表')
  AND path NOT IN ('/system/roles');

-- 菜单管理
UPDATE sys_permission SET path='/admin/menus'
WHERE portal_type=0 AND type=2 AND deleted=0 AND name IN ('菜单管理','菜单配置','菜单列表')
  AND path NOT IN ('/admin/menus');

-- 权限配置
UPDATE sys_permission SET path='/system/permissions'
WHERE portal_type=0 AND type=2 AND deleted=0 AND name IN ('权限配置','权限管理','权限树')
  AND path NOT IN ('/system/permissions');

-- 部门管理
UPDATE sys_permission SET path='/system/dept'
WHERE portal_type=0 AND type=2 AND deleted=0 AND name IN ('部门管理','部门列表','组织架构')
  AND path NOT IN ('/system/dept');

-- 数据字典
UPDATE sys_permission SET path='/system/dict'
WHERE portal_type=0 AND type=2 AND deleted=0 AND name IN ('数据字典','字典管理','字典列表')
  AND path NOT IN ('/system/dict');

-- 系统参数
UPDATE sys_permission SET path='/system/param'
WHERE portal_type=0 AND type=2 AND deleted=0 AND name IN ('系统参数','参数配置','参数管理')
  AND path NOT IN ('/system/param');

-- 通知公告
UPDATE sys_permission SET path='/system/notice'
WHERE portal_type=0 AND type=2 AND deleted=0 AND name IN ('通知公告','公告管理','系统公告')
  AND path NOT IN ('/system/notice');

-- 操作日志
UPDATE sys_permission SET path='/system/log'
WHERE portal_type=0 AND type=2 AND deleted=0 AND name IN ('操作日志','日志管理','系统日志')
  AND path NOT IN ('/system/log');

-- 币种管理
UPDATE sys_permission SET path='/system/currency'
WHERE portal_type=0 AND type=2 AND deleted=0 AND name IN ('币种管理','货币管理','结算币种')
  AND path NOT IN ('/system/currency');

-- 监控：在线用户
UPDATE sys_permission SET path='/monitor/online'
WHERE portal_type=0 AND type=2 AND deleted=0 AND name IN ('在线用户','在线列表')
  AND path NOT IN ('/monitor/online');

-- 监控：定时任务
UPDATE sys_permission SET path='/monitor/job'
WHERE portal_type=0 AND type=2 AND deleted=0 AND name IN ('定时任务','任务调度','计划任务')
  AND path NOT IN ('/monitor/job');

-- 监控：服务器
UPDATE sys_permission SET path='/monitor/server'
WHERE portal_type=0 AND type=2 AND deleted=0 AND name IN ('服务器监控','服务器信息','系统监控')
  AND path NOT IN ('/monitor/server');

-- 监控：缓存
UPDATE sys_permission SET path='/monitor/cache'
WHERE portal_type=0 AND type=2 AND deleted=0 AND name IN ('缓存监控','缓存管理','Redis监控')
  AND path NOT IN ('/monitor/cache');

-- ─────────────────────────────────────────────────────────────────────────────
-- STEP 2: 确保目录节点存在（REPLACE INTO，ID范围 9001-9010，portal_type=0）
-- 若已有同名目录则通过 ID 确保存在；REPLACE INTO 对不存在的ID做插入，已存在则替换
-- ─────────────────────────────────────────────────────────────────────────────

INSERT IGNORE INTO sys_permission
    (id, parent_id, name, code, type, path, component, icon, sort, portal_type, visible, status, deleted)
VALUES
-- 目录节点（type=1，无 path）
(9001, 0, '用户管理', NULL, 1, NULL, NULL, 'TeamOutlined',       10, 0, 1, 1, 0),
(9002, 0, '订单管理', NULL, 1, NULL, NULL, 'OrderedListOutlined', 20, 0, 1, 1, 0),
(9003, 0, '运营管理', NULL, 1, NULL, NULL, 'AppstoreOutlined',    30, 0, 1, 1, 0),
(9004, 0, '财务管理', NULL, 1, NULL, NULL, 'DollarOutlined',      40, 0, 1, 1, 0),
(9005, 0, '系统管理', NULL, 1, NULL, NULL, 'SettingOutlined',     50, 0, 1, 1, 0),
(9006, 0, '监控管理', NULL, 1, NULL, NULL, 'DesktopOutlined',     60, 0, 1, 1, 0);

-- ─────────────────────────────────────────────────────────────────────────────
-- STEP 3: 确保菜单节点存在（INSERT IGNORE，ID范围 9051-9120）
-- 只补全缺失的菜单项；已存在的同 path 菜单不会被影响
-- ─────────────────────────────────────────────────────────────────────────────

-- 先确定目录 ID 变量（使用刚插入的 9001-9006 或者找已有同名目录）
SET @d_user    = IFNULL((SELECT id FROM sys_permission WHERE portal_type=0 AND type=1 AND deleted=0 AND name='用户管理' ORDER BY id LIMIT 1), 9001);
SET @d_order   = IFNULL((SELECT id FROM sys_permission WHERE portal_type=0 AND type=1 AND deleted=0 AND name='订单管理' ORDER BY id LIMIT 1), 9002);
SET @d_ops     = IFNULL((SELECT id FROM sys_permission WHERE portal_type=0 AND type=1 AND deleted=0 AND name='运营管理' ORDER BY id LIMIT 1), 9003);
SET @d_finance = IFNULL((SELECT id FROM sys_permission WHERE portal_type=0 AND type=1 AND deleted=0 AND name='财务管理' ORDER BY id LIMIT 1), 9004);
SET @d_system  = IFNULL((SELECT id FROM sys_permission WHERE portal_type=0 AND type=1 AND deleted=0 AND name='系统管理' ORDER BY id LIMIT 1), 9005);
SET @d_monitor = IFNULL((SELECT id FROM sys_permission WHERE portal_type=0 AND type=1 AND deleted=0 AND name='监控管理' ORDER BY id LIMIT 1), 9006);

-- 数据看板（顶级菜单）
INSERT IGNORE INTO sys_permission (id, parent_id, name, code, type, path, icon, sort, portal_type, visible, status, deleted)
VALUES (9051, 0, '数据看板', NULL, 2, '/dashboard', 'DashboardOutlined', 1, 0, 1, 1, 0);

-- 用户管理子菜单
INSERT IGNORE INTO sys_permission (id, parent_id, name, code, type, path, icon, sort, portal_type, visible, status, deleted)
VALUES
(9052, @d_user, '会员管理',   NULL, 2, '/users',              'UserOutlined',    1, 0, 1, 1, 0),
(9053, @d_user, '技师管理',   NULL, 2, '/technicians',        'TeamOutlined',    2, 0, 1, 1, 0),
(9054, @d_user, '技师审核',   NULL, 2, '/technicians/audit',  'AuditOutlined',   3, 0, 1, 1, 0),
(9055, @d_user, '商户管理',   NULL, 2, '/merchants',          'ShopOutlined',    4, 0, 1, 1, 0);

-- 订单管理子菜单
INSERT IGNORE INTO sys_permission (id, parent_id, name, code, type, path, icon, sort, portal_type, visible, status, deleted)
VALUES
(9056, @d_order, '在线订单', NULL, 2, '/orders',         'OrderedListOutlined', 1, 0, 1, 1, 0),
(9057, @d_order, '历史订单', NULL, 2, '/orders/history', 'FileTextOutlined',    2, 0, 1, 1, 0),
(9058, @d_order, '门店订单', NULL, 2, '/walkin',         'IdcardOutlined',      3, 0, 1, 1, 0);

-- 运营管理子菜单
INSERT IGNORE INTO sys_permission (id, parent_id, name, code, type, path, icon, sort, portal_type, visible, status, deleted)
VALUES
(9059, @d_ops, '服务类目',  NULL, 2, '/operation/category', 'AppstoreOutlined',    1, 0, 1, 1, 0),
(9060, @d_ops, 'Banner管理',NULL, 2, '/operation/banner',   'PictureOutlined',     2, 0, 1, 1, 0),
(9061, @d_ops, '评价管理',  NULL, 2, '/operation/reviews',  'StarOutlined',        3, 0, 1, 1, 0),
(9062, @d_ops, '车辆管理',  NULL, 2, '/vehicles',           'CarOutlined',         4, 0, 1, 1, 0),
(9063, @d_ops, '派车记录',  NULL, 2, '/vehicles/dispatch',  'FileTextOutlined',    5, 0, 1, 1, 0),
(9064, @d_ops, '优惠券',    NULL, 2, '/coupons',            'TagsOutlined',        6, 0, 1, 1, 0);

-- 财务管理子菜单
INSERT IGNORE INTO sys_permission (id, parent_id, name, code, type, path, icon, sort, portal_type, visible, status, deleted)
VALUES
(9065, @d_finance, '财务概览',  NULL, 2, '/finance/overview',   'BarChartOutlined',    1, 0, 1, 1, 0),
(9066, @d_finance, '收入统计',  NULL, 2, '/finance',            'DollarOutlined',      2, 0, 1, 1, 0),
(9067, @d_finance, '收入记录',  NULL, 2, '/finance/income',     'BankOutlined',        3, 0, 1, 1, 0),
(9068, @d_finance, '支出管理',  NULL, 2, '/finance/expense',    'MinusCircleOutlined', 4, 0, 1, 1, 0),
(9069, @d_finance, '薪资管理',  NULL, 2, '/finance/salary',     'IdcardOutlined',      5, 0, 1, 1, 0),
(9070, @d_finance, '技师结算',  NULL, 2, '/finance/settlement', 'AuditOutlined',       6, 0, 1, 1, 0);

-- 系统管理子菜单
INSERT IGNORE INTO sys_permission (id, parent_id, name, code, type, path, icon, sort, portal_type, visible, status, deleted)
VALUES
(9071, @d_system, '员工管理',  NULL, 2, '/admin/staff',        'IdcardOutlined',   1, 0, 1, 1, 0),
(9072, @d_system, '职位管理',  NULL, 2, '/admin/positions',    'SolutionOutlined', 2, 0, 1, 1, 0),
(9073, @d_system, '部门管理',  NULL, 2, '/system/dept',        'ApartmentOutlined',3, 0, 1, 1, 0),
(9074, @d_system, '角色权限',  NULL, 2, '/system/roles',       'KeyOutlined',      4, 0, 1, 1, 0),
(9075, @d_system, '菜单管理',  NULL, 2, '/admin/menus',        'MenuOutlined',     5, 0, 1, 1, 0),
(9076, @d_system, '权限配置',  NULL, 2, '/system/permissions', 'SafetyOutlined',   6, 0, 1, 1, 0),
(9077, @d_system, '数据字典',  NULL, 2, '/system/dict',        'DatabaseOutlined', 7, 0, 1, 1, 0),
(9078, @d_system, '系统参数',  NULL, 2, '/system/param',       'SettingOutlined',  8, 0, 1, 1, 0),
(9079, @d_system, '通知公告',  NULL, 2, '/system/notice',      'NotificationOutlined', 9, 0, 1, 1, 0),
(9080, @d_system, '操作日志',  NULL, 2, '/system/log',         'AuditOutlined',   10, 0, 1, 1, 0),
(9081, @d_system, '币种管理',  NULL, 2, '/system/currency',    'GlobalOutlined',  11, 0, 1, 1, 0);

-- 监控管理子菜单
INSERT IGNORE INTO sys_permission (id, parent_id, name, code, type, path, icon, sort, portal_type, visible, status, deleted)
VALUES
(9082, @d_monitor, '在线用户',   NULL, 2, '/monitor/online',  'UserOutlined',    1, 0, 1, 1, 0),
(9083, @d_monitor, '定时任务',   NULL, 2, '/monitor/job',     'ClockCircleOutlined', 2, 0, 1, 1, 0),
(9084, @d_monitor, '服务器监控', NULL, 2, '/monitor/server',  'DesktopOutlined', 3, 0, 1, 1, 0),
(9085, @d_monitor, '缓存监控',   NULL, 2, '/monitor/cache',   'DatabaseOutlined',4, 0, 1, 1, 0);

-- ─────────────────────────────────────────────────────────────────────────────
-- STEP 4: 将新增菜单授权给 SUPER_ADMIN 角色
-- ─────────────────────────────────────────────────────────────────────────────

INSERT IGNORE INTO sys_role_permission (role_id, permission_id)
SELECT r.id, p.id
FROM sys_role r
JOIN sys_permission p ON p.id BETWEEN 9001 AND 9120 AND p.deleted = 0
WHERE r.role_code = 'SUPER_ADMIN' AND r.deleted = 0
  AND NOT EXISTS (
    SELECT 1 FROM sys_role_permission rp
    WHERE rp.role_id = r.id AND rp.permission_id = p.id
  );

-- ─────────────────────────────────────────────────────────────────────────────
-- 注意：商户端（portal_type=1）菜单修复请使用 migrate_v5_8_merchant_portal_fix.sql
--       本文件仅处理管理员端（portal_type=0）
-- ─────────────────────────────────────────────────────────────────────────────

-- ─────────────────────────────────────────────────────────────────────────────
-- 验证结果（仅管理员端）
-- ─────────────────────────────────────────────────────────────────────────────
SELECT
    id,
    name,
    path,
    type,
    portal_type,
    icon,
    sort,
    CASE WHEN deleted=0 THEN '✅启用' ELSE '❌已删除' END AS status_label
FROM sys_permission
WHERE portal_type = 0 AND type = 2 AND deleted = 0
ORDER BY sort, id;

SELECT 'Migration v5.7 complete: Admin (portal_type=0) menu paths fixed, missing menus added.' AS result;
