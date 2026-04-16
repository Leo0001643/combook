-- ============================================================
-- migrate_v3_5.sql  按钮级操作权限（type=3）
--
-- 说明：
--   type=3  操作权限，不在侧边栏显示（visible=0）
--   portal_type=0  管理端
--   parent_id 通过子查询动态关联对应菜单，找不到则挂在根节点(0)
-- ============================================================

-- 防止重复执行
DELETE FROM sys_permission WHERE type = 3 AND portal_type = 0 AND deleted = 0;

-- ─── 辅助变量：各菜单 ID ───────────────────────────────────
SET @p_tech       = IFNULL((SELECT id FROM sys_permission WHERE path LIKE '%/admin/technician%' AND type = 2 AND portal_type = 0 AND deleted = 0 LIMIT 1), 0);
SET @p_order      = IFNULL((SELECT id FROM sys_permission WHERE path LIKE '%/admin/order%'      AND type = 2 AND portal_type = 0 AND deleted = 0 LIMIT 1), 0);
SET @p_merchant   = IFNULL((SELECT id FROM sys_permission WHERE path LIKE '%/admin/merchant%'   AND type = 2 AND portal_type = 0 AND deleted = 0 LIMIT 1), 0);
SET @p_member     = IFNULL((SELECT id FROM sys_permission WHERE path LIKE '%/admin/member%'     AND type = 2 AND portal_type = 0 AND deleted = 0 LIMIT 1), 0);
SET @p_role       = IFNULL((SELECT id FROM sys_permission WHERE path LIKE '%/admin/role%'       AND type = 2 AND portal_type = 0 AND deleted = 0 LIMIT 1), 0);
SET @p_staff      = IFNULL((SELECT id FROM sys_permission WHERE path LIKE '%/admin/staff%'      AND type = 2 AND portal_type = 0 AND deleted = 0 LIMIT 1), 0);
SET @p_position   = IFNULL((SELECT id FROM sys_permission WHERE path LIKE '%/admin/position%'   AND type = 2 AND portal_type = 0 AND deleted = 0 LIMIT 1), 0);
SET @p_perm       = IFNULL((SELECT id FROM sys_permission WHERE path LIKE '%/admin/permission%' AND type = 2 AND portal_type = 0 AND deleted = 0 LIMIT 1), 0);
SET @p_menu       = IFNULL((SELECT id FROM sys_permission WHERE path LIKE '%/admin/menu%'       AND type = 2 AND portal_type = 0 AND deleted = 0 LIMIT 1), 0);
SET @p_dept       = IFNULL((SELECT id FROM sys_permission WHERE path LIKE '%/admin/dept%'       AND type = 2 AND portal_type = 0 AND deleted = 0 LIMIT 1), 0);
SET @p_vehicle    = IFNULL((SELECT id FROM sys_permission WHERE path LIKE '%/admin/vehicle%'    AND type = 2 AND portal_type = 0 AND deleted = 0 LIMIT 1), 0);
SET @p_coupon     = IFNULL((SELECT id FROM sys_permission WHERE path LIKE '%/admin/coupon%'     AND type = 2 AND portal_type = 0 AND deleted = 0 LIMIT 1), 0);
SET @p_category   = IFNULL((SELECT id FROM sys_permission WHERE path LIKE '%/admin/category%'   AND type = 2 AND portal_type = 0 AND deleted = 0 LIMIT 1), 0);
SET @p_banner     = IFNULL((SELECT id FROM sys_permission WHERE path LIKE '%/admin/banner%'     AND type = 2 AND portal_type = 0 AND deleted = 0 LIMIT 1), 0);
SET @p_notice     = IFNULL((SELECT id FROM sys_permission WHERE path LIKE '%/admin/notice%'     AND type = 2 AND portal_type = 0 AND deleted = 0 LIMIT 1), 0);
SET @p_dict       = IFNULL((SELECT id FROM sys_permission WHERE path LIKE '%/admin/dict%'       AND type = 2 AND portal_type = 0 AND deleted = 0 LIMIT 1), 0);
SET @p_sysconfig  = IFNULL((SELECT id FROM sys_permission WHERE path LIKE '%/admin/sysconfig%'  AND type = 2 AND portal_type = 0 AND deleted = 0 LIMIT 1), 0);
SET @p_log        = IFNULL((SELECT id FROM sys_permission WHERE path LIKE '%/admin/log%'        AND type = 2 AND portal_type = 0 AND deleted = 0 LIMIT 1), 0);
SET @p_review     = IFNULL((SELECT id FROM sys_permission WHERE path LIKE '%/admin/review%'     AND type = 2 AND portal_type = 0 AND deleted = 0 LIMIT 1), 0);
SET @p_announce   = IFNULL((SELECT id FROM sys_permission WHERE path LIKE '%/admin/announce%'   AND type = 2 AND portal_type = 0 AND deleted = 0 LIMIT 1), 0);

-- ─── 技师管理 ─────────────────────────────────────────────
INSERT INTO sys_permission (parent_id, name, code, type, sort, portal_type, visible, status, deleted) VALUES
(@p_tech, '查看技师列表',   'technician:list',   3, 1, 0, 0, 1, 0),
(@p_tech, '新增技师',       'technician:add',    3, 2, 0, 0, 1, 0),
(@p_tech, '编辑技师',       'technician:edit',   3, 3, 0, 0, 1, 0),
(@p_tech, '删除技师',       'technician:delete', 3, 4, 0, 0, 1, 0),
(@p_tech, '审核技师',       'technician:audit',  3, 5, 0, 0, 1, 0),
(@p_tech, '切换技师状态',   'technician:toggle', 3, 6, 0, 0, 1, 0),
(@p_tech, '设置推荐技师',   'technician:feature',3, 7, 0, 0, 1, 0);

-- ─── 订单管理 ─────────────────────────────────────────────
INSERT INTO sys_permission (parent_id, name, code, type, sort, portal_type, visible, status, deleted) VALUES
(@p_order, '查看订单列表', 'order:list',   3, 1, 0, 0, 1, 0),
(@p_order, '取消订单',     'order:cancel', 3, 2, 0, 0, 1, 0),
(@p_order, '删除订单',     'order:delete', 3, 3, 0, 0, 1, 0);

-- ─── 会员管理 ─────────────────────────────────────────────
INSERT INTO sys_permission (parent_id, name, code, type, sort, portal_type, visible, status, deleted) VALUES
(@p_member, '查看会员列表', 'member:list', 3, 1, 0, 0, 1, 0),
(@p_member, '封禁/解封会员','member:ban',  3, 2, 0, 0, 1, 0);

-- ─── 商户管理 ─────────────────────────────────────────────
INSERT INTO sys_permission (parent_id, name, code, type, sort, portal_type, visible, status, deleted) VALUES
(@p_merchant, '查看商户列表', 'merchant:list',       3, 1, 0, 0, 1, 0),
(@p_merchant, '新增商户',     'merchant:add',        3, 2, 0, 0, 1, 0),
(@p_merchant, '审核商户',     'merchant:audit',      3, 3, 0, 0, 1, 0),
(@p_merchant, '设置佣金',     'merchant:commission', 3, 4, 0, 0, 1, 0),
(@p_merchant, '切换商户状态', 'merchant:toggle',     3, 5, 0, 0, 1, 0);

-- ─── 角色管理 ─────────────────────────────────────────────
INSERT INTO sys_permission (parent_id, name, code, type, sort, portal_type, visible, status, deleted) VALUES
(@p_role, '查看角色列表', 'role:list',       3, 1, 0, 0, 1, 0),
(@p_role, '新增角色',     'role:add',        3, 2, 0, 0, 1, 0),
(@p_role, '编辑角色',     'role:edit',       3, 3, 0, 0, 1, 0),
(@p_role, '删除角色',     'role:delete',     3, 4, 0, 0, 1, 0),
(@p_role, '分配角色权限', 'role:permission', 3, 5, 0, 0, 1, 0);

-- ─── 员工管理 ─────────────────────────────────────────────
INSERT INTO sys_permission (parent_id, name, code, type, sort, portal_type, visible, status, deleted) VALUES
(@p_staff, '查看员工列表', 'staff:list',   3, 1, 0, 0, 1, 0),
(@p_staff, '新增员工',     'staff:add',    3, 2, 0, 0, 1, 0),
(@p_staff, '编辑员工',     'staff:edit',   3, 3, 0, 0, 1, 0),
(@p_staff, '删除员工',     'staff:delete', 3, 4, 0, 0, 1, 0),
(@p_staff, '切换员工状态', 'staff:toggle', 3, 5, 0, 0, 1, 0);

-- ─── 岗位管理 ─────────────────────────────────────────────
INSERT INTO sys_permission (parent_id, name, code, type, sort, portal_type, visible, status, deleted) VALUES
(@p_position, '查看岗位列表', 'position:list',   3, 1, 0, 0, 1, 0),
(@p_position, '新增岗位',     'position:add',    3, 2, 0, 0, 1, 0),
(@p_position, '编辑岗位',     'position:edit',   3, 3, 0, 0, 1, 0),
(@p_position, '删除岗位',     'position:delete', 3, 4, 0, 0, 1, 0),
(@p_position, '切换岗位状态', 'position:toggle', 3, 5, 0, 0, 1, 0);

-- ─── 权限管理 ─────────────────────────────────────────────
INSERT INTO sys_permission (parent_id, name, code, type, sort, portal_type, visible, status, deleted) VALUES
(@p_perm, '查看权限树',   'permission:list',   3, 1, 0, 0, 1, 0),
(@p_perm, '新增权限节点', 'permission:add',    3, 2, 0, 0, 1, 0),
(@p_perm, '编辑权限节点', 'permission:edit',   3, 3, 0, 0, 1, 0),
(@p_perm, '删除权限节点', 'permission:delete', 3, 4, 0, 0, 1, 0);

-- ─── 菜单管理 ─────────────────────────────────────────────
INSERT INTO sys_permission (parent_id, name, code, type, sort, portal_type, visible, status, deleted) VALUES
(@p_menu, '查看菜单列表', 'menu:list',   3, 1, 0, 0, 1, 0),
(@p_menu, '新增菜单',     'menu:add',    3, 2, 0, 0, 1, 0),
(@p_menu, '编辑菜单',     'menu:edit',   3, 3, 0, 0, 1, 0),
(@p_menu, '删除菜单',     'menu:delete', 3, 4, 0, 0, 1, 0);

-- ─── 部门管理（管理端） ───────────────────────────────────
INSERT INTO sys_permission (parent_id, name, code, type, sort, portal_type, visible, status, deleted) VALUES
(@p_dept, '查看部门列表', 'dept:list',   3, 1, 0, 0, 1, 0),
(@p_dept, '新增部门',     'dept:add',    3, 2, 0, 0, 1, 0),
(@p_dept, '编辑部门',     'dept:edit',   3, 3, 0, 0, 1, 0),
(@p_dept, '删除部门',     'dept:delete', 3, 4, 0, 0, 1, 0),
(@p_dept, '切换部门状态', 'dept:toggle', 3, 5, 0, 0, 1, 0);

-- ─── 车辆管理 ─────────────────────────────────────────────
INSERT INTO sys_permission (parent_id, name, code, type, sort, portal_type, visible, status, deleted) VALUES
(@p_vehicle, '查看车辆列表', 'vehicle:list',   3, 1, 0, 0, 1, 0),
(@p_vehicle, '新增车辆',     'vehicle:add',    3, 2, 0, 0, 1, 0),
(@p_vehicle, '编辑车辆',     'vehicle:edit',   3, 3, 0, 0, 1, 0),
(@p_vehicle, '删除车辆',     'vehicle:delete', 3, 4, 0, 0, 1, 0),
(@p_vehicle, '修改车辆状态', 'vehicle:status', 3, 5, 0, 0, 1, 0);

-- ─── 优惠券管理 ───────────────────────────────────────────
INSERT INTO sys_permission (parent_id, name, code, type, sort, portal_type, visible, status, deleted) VALUES
(@p_coupon, '查看优惠券列表', 'coupon:list',   3, 1, 0, 0, 1, 0),
(@p_coupon, '新增优惠券',     'coupon:add',    3, 2, 0, 0, 1, 0),
(@p_coupon, '编辑优惠券',     'coupon:edit',   3, 3, 0, 0, 1, 0),
(@p_coupon, '删除优惠券',     'coupon:delete', 3, 4, 0, 0, 1, 0);

-- ─── 类目管理 ─────────────────────────────────────────────
INSERT INTO sys_permission (parent_id, name, code, type, sort, portal_type, visible, status, deleted) VALUES
(@p_category, '查看类目列表', 'category:list',   3, 1, 0, 0, 1, 0),
(@p_category, '新增类目',     'category:add',    3, 2, 0, 0, 1, 0),
(@p_category, '编辑类目',     'category:edit',   3, 3, 0, 0, 1, 0),
(@p_category, '删除类目',     'category:delete', 3, 4, 0, 0, 1, 0);

-- ─── 横幅管理 ─────────────────────────────────────────────
INSERT INTO sys_permission (parent_id, name, code, type, sort, portal_type, visible, status, deleted) VALUES
(@p_banner, '查看横幅列表', 'banner:list',   3, 1, 0, 0, 1, 0),
(@p_banner, '新增横幅',     'banner:add',    3, 2, 0, 0, 1, 0),
(@p_banner, '编辑横幅',     'banner:edit',   3, 3, 0, 0, 1, 0),
(@p_banner, '删除横幅',     'banner:delete', 3, 4, 0, 0, 1, 0);

-- ─── 公告管理 ─────────────────────────────────────────────
INSERT INTO sys_permission (parent_id, name, code, type, sort, portal_type, visible, status, deleted) VALUES
(@p_notice, '查看公告列表', 'notice:list',   3, 1, 0, 0, 1, 0),
(@p_notice, '新增公告',     'notice:add',    3, 2, 0, 0, 1, 0),
(@p_notice, '编辑公告',     'notice:edit',   3, 3, 0, 0, 1, 0),
(@p_notice, '删除公告',     'notice:delete', 3, 4, 0, 0, 1, 0);

-- ─── 字典管理 ─────────────────────────────────────────────
INSERT INTO sys_permission (parent_id, name, code, type, sort, portal_type, visible, status, deleted) VALUES
(@p_dict, '查看字典列表', 'dict:list',   3, 1, 0, 0, 1, 0),
(@p_dict, '新增字典',     'dict:add',    3, 2, 0, 0, 1, 0),
(@p_dict, '编辑字典',     'dict:edit',   3, 3, 0, 0, 1, 0),
(@p_dict, '删除字典',     'dict:delete', 3, 4, 0, 0, 1, 0);

-- ─── 系统参数 ─────────────────────────────────────────────
INSERT INTO sys_permission (parent_id, name, code, type, sort, portal_type, visible, status, deleted) VALUES
(@p_sysconfig, '查看系统参数', 'sysconfig:list',   3, 1, 0, 0, 1, 0),
(@p_sysconfig, '新增系统参数', 'sysconfig:add',    3, 2, 0, 0, 1, 0),
(@p_sysconfig, '编辑系统参数', 'sysconfig:edit',   3, 3, 0, 0, 1, 0),
(@p_sysconfig, '删除系统参数', 'sysconfig:delete', 3, 4, 0, 0, 1, 0);

-- ─── 操作日志 ─────────────────────────────────────────────
INSERT INTO sys_permission (parent_id, name, code, type, sort, portal_type, visible, status, deleted) VALUES
(@p_log, '查看操作日志', 'log:list',   3, 1, 0, 0, 1, 0),
(@p_log, '删除操作日志', 'log:delete', 3, 2, 0, 0, 1, 0);

-- ─── 评价管理 ─────────────────────────────────────────────
INSERT INTO sys_permission (parent_id, name, code, type, sort, portal_type, visible, status, deleted) VALUES
(@p_review, '查看评价列表', 'review:list',   3, 1, 0, 0, 1, 0),
(@p_review, '隐藏/显示评价','review:toggle', 3, 2, 0, 0, 1, 0),
(@p_review, '删除评价',     'review:delete', 3, 3, 0, 0, 1, 0),
(@p_review, '回复评价',     'review:reply',  3, 4, 0, 0, 1, 0);

-- ─── 通知公告（商户端） ───────────────────────────────────
INSERT INTO sys_permission (parent_id, name, code, type, sort, portal_type, visible, status, deleted) VALUES
(@p_announce, '查看通知列表', 'announce:list',   3, 1, 0, 0, 1, 0),
(@p_announce, '新增通知',     'announce:add',    3, 2, 0, 0, 1, 0),
(@p_announce, '编辑通知',     'announce:edit',   3, 3, 0, 0, 1, 0),
(@p_announce, '删除通知',     'announce:delete', 3, 4, 0, 0, 1, 0);

-- ─── 运维监控 ─────────────────────────────────────────────
SET @p_monitor_job    = IFNULL((SELECT id FROM sys_permission WHERE path LIKE '%/admin/monitor/job%'    AND portal_type = 0 AND deleted = 0 LIMIT 1), 0);
SET @p_monitor_online = IFNULL((SELECT id FROM sys_permission WHERE path LIKE '%/admin/monitor/online%' AND portal_type = 0 AND deleted = 0 LIMIT 1), 0);
SET @p_monitor_cache  = IFNULL((SELECT id FROM sys_permission WHERE path LIKE '%/admin/monitor/cache%'  AND portal_type = 0 AND deleted = 0 LIMIT 1), 0);

INSERT INTO sys_permission (parent_id, name, code, type, sort, portal_type, visible, status, deleted) VALUES
(@p_monitor_job,    '查看定时任务',     'monitor:job:list',   3, 1, 0, 0, 1, 0),
(@p_monitor_job,    '暂停/恢复任务',    'monitor:job:toggle', 3, 2, 0, 0, 1, 0),
(@p_monitor_job,    '立即执行任务',     'monitor:job:run',    3, 3, 0, 0, 1, 0),
(@p_monitor_online, '查看在线用户',     'monitor:online',     3, 1, 0, 0, 1, 0),
(@p_monitor_online, '强制下线用户',     'monitor:online:kick',3, 2, 0, 0, 1, 0),
(@p_monitor_cache,  '查看缓存',         'monitor:cache',      3, 1, 0, 0, 1, 0),
(@p_monitor_cache,  '清除缓存',         'monitor:cache:clear',3, 2, 0, 0, 1, 0);

-- ═══════════════════════════════════════════════════════════════════════════
-- 商户端（portal_type=1）按钮级操作权限
-- 注：商户用户登录后前端默认持有 ["*"]，此处权限用于商户端 PermissionTreePage
--     展示及未来精细化授权扩展，不影响现有功能
-- ═══════════════════════════════════════════════════════════════════════════

-- 删除旧的商户端 type=3 操作权限（防止重复）
DELETE FROM sys_permission WHERE type = 3 AND portal_type = 1 AND deleted = 0;

-- 商户端父菜单 ID 变量
SET @m_dashboard  = IFNULL((SELECT id FROM sys_permission WHERE path LIKE '%/merchant/dashboard%'    AND portal_type = 1 AND deleted = 0 LIMIT 1), 0);
SET @m_order      = IFNULL((SELECT id FROM sys_permission WHERE path LIKE '%/merchant/order%'        AND portal_type = 1 AND deleted = 0 LIMIT 1), 0);
SET @m_tech       = IFNULL((SELECT id FROM sys_permission WHERE path LIKE '%/merchant/technician%'   AND portal_type = 1 AND deleted = 0 LIMIT 1), 0);
SET @m_review     = IFNULL((SELECT id FROM sys_permission WHERE path LIKE '%/merchant/review%'       AND portal_type = 1 AND deleted = 0 LIMIT 1), 0);
SET @m_coupon     = IFNULL((SELECT id FROM sys_permission WHERE path LIKE '%/merchant/coupon%'       AND portal_type = 1 AND deleted = 0 LIMIT 1), 0);
SET @m_announce   = IFNULL((SELECT id FROM sys_permission WHERE path LIKE '%/merchant/announce%'     AND portal_type = 1 AND deleted = 0 LIMIT 1), 0);
SET @m_staff      = IFNULL((SELECT id FROM sys_permission WHERE path LIKE '%/merchant/perm/staff%'   AND portal_type = 1 AND deleted = 0 LIMIT 1), 0);
SET @m_dept       = IFNULL((SELECT id FROM sys_permission WHERE path LIKE '%/merchant/perm/dept%'    AND portal_type = 1 AND deleted = 0 LIMIT 1), 0);
SET @m_position   = IFNULL((SELECT id FROM sys_permission WHERE path LIKE '%/merchant/perm/position%' AND portal_type = 1 AND deleted = 0 LIMIT 1), 0);
SET @m_role       = IFNULL((SELECT id FROM sys_permission WHERE path LIKE '%/merchant/perm/role%'    AND portal_type = 1 AND deleted = 0 LIMIT 1), 0);
SET @m_member     = IFNULL((SELECT id FROM sys_permission WHERE path LIKE '%/merchant/member%'       AND portal_type = 1 AND deleted = 0 LIMIT 1), 0);
SET @m_finance    = IFNULL((SELECT id FROM sys_permission WHERE path LIKE '%/merchant/finance%'      AND portal_type = 1 AND deleted = 0 LIMIT 1), 0);

-- 商户端：订单管理
INSERT INTO sys_permission (parent_id, name, code, type, sort, portal_type, visible, status, deleted) VALUES
(@m_order, '查看订单列表', 'order:list',   3, 1, 1, 0, 1, 0),
(@m_order, '取消订单',     'order:cancel', 3, 2, 1, 0, 1, 0),
(@m_order, '删除订单',     'order:delete', 3, 3, 1, 0, 1, 0);

-- 商户端：技师管理
INSERT INTO sys_permission (parent_id, name, code, type, sort, portal_type, visible, status, deleted) VALUES
(@m_tech, '查看技师列表',   'technician:list',    3, 1, 1, 0, 1, 0),
(@m_tech, '新增技师',       'technician:add',     3, 2, 1, 0, 1, 0),
(@m_tech, '编辑技师',       'technician:edit',    3, 3, 1, 0, 1, 0),
(@m_tech, '删除技师',       'technician:delete',  3, 4, 1, 0, 1, 0),
(@m_tech, '切换技师状态',   'technician:toggle',  3, 5, 1, 0, 1, 0),
(@m_tech, '设置推荐技师',   'technician:feature', 3, 6, 1, 0, 1, 0);

-- 商户端：评价管理
INSERT INTO sys_permission (parent_id, name, code, type, sort, portal_type, visible, status, deleted) VALUES
(@m_review, '查看评价列表', 'review:list',   3, 1, 1, 0, 1, 0),
(@m_review, '隐藏/显示评价','review:toggle', 3, 2, 1, 0, 1, 0),
(@m_review, '回复评价',     'review:reply',  3, 3, 1, 0, 1, 0),
(@m_review, '删除评价',     'review:delete', 3, 4, 1, 0, 1, 0);

-- 商户端：优惠券管理
INSERT INTO sys_permission (parent_id, name, code, type, sort, portal_type, visible, status, deleted) VALUES
(@m_coupon, '查看优惠券列表', 'coupon:list',   3, 1, 1, 0, 1, 0),
(@m_coupon, '申请/新增优惠券','coupon:add',    3, 2, 1, 0, 1, 0),
(@m_coupon, '编辑优惠券',     'coupon:edit',   3, 3, 1, 0, 1, 0),
(@m_coupon, '删除优惠券',     'coupon:delete', 3, 4, 1, 0, 1, 0);

-- 商户端：通知公告
INSERT INTO sys_permission (parent_id, name, code, type, sort, portal_type, visible, status, deleted) VALUES
(@m_announce, '查看通知列表', 'announce:list',   3, 1, 1, 0, 1, 0),
(@m_announce, '发布通知',     'announce:add',    3, 2, 1, 0, 1, 0),
(@m_announce, '编辑通知',     'announce:edit',   3, 3, 1, 0, 1, 0),
(@m_announce, '删除通知',     'announce:delete', 3, 4, 1, 0, 1, 0);

-- 商户端：员工管理
INSERT INTO sys_permission (parent_id, name, code, type, sort, portal_type, visible, status, deleted) VALUES
(@m_staff, '查看员工列表', 'staff:list',   3, 1, 1, 0, 1, 0),
(@m_staff, '新增员工',     'staff:add',    3, 2, 1, 0, 1, 0),
(@m_staff, '编辑员工',     'staff:edit',   3, 3, 1, 0, 1, 0),
(@m_staff, '删除员工',     'staff:delete', 3, 4, 1, 0, 1, 0),
(@m_staff, '切换员工状态', 'staff:toggle', 3, 5, 1, 0, 1, 0);

-- 商户端：部门管理
INSERT INTO sys_permission (parent_id, name, code, type, sort, portal_type, visible, status, deleted) VALUES
(@m_dept, '查看部门列表', 'dept:list',   3, 1, 1, 0, 1, 0),
(@m_dept, '新增部门',     'dept:add',    3, 2, 1, 0, 1, 0),
(@m_dept, '编辑部门',     'dept:edit',   3, 3, 1, 0, 1, 0),
(@m_dept, '删除部门',     'dept:delete', 3, 4, 1, 0, 1, 0),
(@m_dept, '切换部门状态', 'dept:toggle', 3, 5, 1, 0, 1, 0);

-- 商户端：岗位管理
INSERT INTO sys_permission (parent_id, name, code, type, sort, portal_type, visible, status, deleted) VALUES
(@m_position, '查看岗位列表', 'position:list',   3, 1, 1, 0, 1, 0),
(@m_position, '新增岗位',     'position:add',    3, 2, 1, 0, 1, 0),
(@m_position, '编辑岗位',     'position:edit',   3, 3, 1, 0, 1, 0),
(@m_position, '删除岗位',     'position:delete', 3, 4, 1, 0, 1, 0),
(@m_position, '切换岗位状态', 'position:toggle', 3, 5, 1, 0, 1, 0);

-- 商户端：角色权限管理
INSERT INTO sys_permission (parent_id, name, code, type, sort, portal_type, visible, status, deleted) VALUES
(@m_role, '查看角色列表', 'role:list',       3, 1, 1, 0, 1, 0),
(@m_role, '新增角色',     'role:add',        3, 2, 1, 0, 1, 0),
(@m_role, '编辑角色',     'role:edit',       3, 3, 1, 0, 1, 0),
(@m_role, '删除角色',     'role:delete',     3, 4, 1, 0, 1, 0),
(@m_role, '分配角色权限', 'role:permission', 3, 5, 1, 0, 1, 0);

-- 商户端：会员列表（只读）
INSERT INTO sys_permission (parent_id, name, code, type, sort, portal_type, visible, status, deleted) VALUES
(@m_member, '查看会员列表', 'member:list', 3, 1, 1, 0, 1, 0);

-- ─── 为 SUPER_ADMIN 角色分配所有新增操作权限（管理端 + 商户端） ──────────
INSERT INTO sys_role_permission (role_id, permission_id)
SELECT r.id, p.id
FROM sys_role r
JOIN sys_permission p ON p.type = 3 AND p.deleted = 0
WHERE r.role_code = 'SUPER_ADMIN'
  AND NOT EXISTS (
    SELECT 1 FROM sys_role_permission rp
    WHERE rp.role_id = r.id AND rp.permission_id = p.id
  );
