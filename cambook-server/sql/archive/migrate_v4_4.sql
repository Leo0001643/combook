-- ================================================================================
-- CamBook 数据库迁移脚本 v4.4
-- 描述：散客接待闭环 — 补全 cb_walkin_session 字段 + 写入完整测试数据
-- 日期：2026-04-13
-- ================================================================================
-- ── 2. cb_order 散客接待关联字段 ──────────────────────────────────────────────────
-- ⚠️ migrate_v4_0.sql 已包含 order_type / session_id / wristband_no，
--    若已执行过 v4_0，此段已无需重复执行，保留注释仅作说明。
-- ALTER TABLE `cb_order`
--     ADD COLUMN `order_type`   TINYINT     NOT NULL DEFAULT 1 COMMENT '订单类型：1=在线预约 2=散客上门' AFTER `id`,
--     ADD COLUMN `session_id`   BIGINT                         COMMENT '散客接待 session ID'             AFTER `order_type`,
--     ADD COLUMN `wristband_no` VARCHAR(20)                    COMMENT '手环编号'                         AFTER `session_id`;

-- ── 3. 取测试商户 ID ────────────────────────────────────────────────────────────
SET @merchant_id = (SELECT id FROM cb_merchant WHERE deleted = 0 ORDER BY id LIMIT 1);

-- ── 4. 写入散客接待 Session 测试数据 ────────────────────────────────────────────
-- 场景覆盖：接待中(0)、服务中(1)、待结算(2)、已结算(3)、已取消(4)
DELETE FROM `cb_walkin_session` WHERE id BETWEEN 7001 AND 7010;

INSERT INTO `cb_walkin_session`
    (id, session_no, wristband_no, merchant_id,
     member_id, member_name, member_mobile,
     technician_id, technician_name, technician_no, technician_mobile,
     status, total_amount, paid_amount, remark,
     check_in_time, check_out_time,
     deleted, create_time, update_time)
VALUES
-- ── 接待中（刚登记，尚未开始任何服务）─────────────────────────────────────────
(7001, 'WK20260413001', '0317', @merchant_id,
 NULL, '张先生', '139****6666',
 2001, '李小美', 'T001', '138****1001',
 0, 0.00, 0.00, '',
 NOW() - INTERVAL 15 MINUTE, NULL,
 0, NOW() - INTERVAL 15 MINUTE, NOW()),

-- ── 服务中（已录入2项服务，1项正在进行，1项排队待服务）─────────────────────────
(7002, 'WK20260413002', '0928', @merchant_id,
 10001, '王先生', '138****8888',
 2001, '李小美', 'T001', '138****1001',
 1, 466.00, 0.00, '',
 NOW() - INTERVAL 55 MINUTE, NULL,
 0, NOW() - INTERVAL 55 MINUTE, NOW()),

-- ── 服务中（2项服务，1项完成，1项正在进行）─────────────────────────────────────
(7003, 'WK20260413003', '1024', @merchant_id,
 10002, '李女士', '',
 2002, '陈小雨', 'T002', '138****1002',
 1, 456.00, 0.00, '',
 NOW() - INTERVAL 100 MINUTE, NULL,
 0, NOW() - INTERVAL 100 MINUTE, NOW()),

-- ── 待结算（所有服务已完成，等待前台结算）────────────────────────────────────────
(7004, 'WK20260413004', '0512', @merchant_id,
 NULL, '', '',
 2003, '王小阳', 'T003', '138****1003',
 2, 388.00, 0.00, '',
 NOW() - INTERVAL 150 MINUTE, NULL,
 0, NOW() - INTERVAL 150 MINUTE, NOW()),

-- ── 已结算（今日已完成）────────────────────────────────────────────────────────
(7005, 'WK20260413005', '0781', @merchant_id,
 10003, '王芳', '138****1003',
 2001, '李小美', 'T001', '138****1001',
 3, 298.00, 298.00, '',
 NOW() - INTERVAL 4 HOUR, NOW() - INTERVAL 2 HOUR,
 0, NOW() - INTERVAL 4 HOUR, NOW()),

-- ── 已取消 ──────────────────────────────────────────────────────────────────────
(7006, 'WK20260413006', '0256', @merchant_id,
 NULL, '散客', '',
 NULL, '', '', '',
 4, 0.00, 0.00, '客户临时离开',
 NOW() - INTERVAL 3 HOUR, NOW() - INTERVAL 3 HOUR + INTERVAL 5 MINUTE,
 0, NOW() - INTERVAL 3 HOUR, NOW());

-- ── 5. 写入散客接待关联订单（cb_order，order_type=2） ───────────────────────────
-- 状态说明（cb_order.status）：1=待接单 2=已确认 5=服务中 6=已完成 7=已取消
-- 前端映射：svcStatus: 0=待服务(status 1/2), 1=服务中(status 5), 2=已完成(status 6)
DELETE FROM `cb_order` WHERE id BETWEEN 8001 AND 8020;

INSERT INTO `cb_order`
    (id, order_no, order_type, session_id, wristband_no,
     merchant_id, member_id, technician_id,
     service_item_id, service_name, service_duration,
     address_id, address_detail,
     appoint_time, start_time, end_time,
     original_amount, pay_amount,
     pay_type, pay_time, status, remark,
     deleted, create_time, update_time)
VALUES
-- ── Session 7002（手环 0928，服务中）──────────────────────────────────────────
-- 服务1：全身经络疏通 90min — 服务中（进行了42min）
(8001, 'WK20260413001-01', 2, 7002, '0928',
 @merchant_id, 10001, 2001,
 4001, '全身经络疏通', 90,
 0, '店内服务',
 NOW() - INTERVAL 55 MINUTE,
 NOW() - INTERVAL 42 MINUTE,
 NULL,
 298.00, 298.00,
 NULL, NULL, 5, '',
 0, NOW() - INTERVAL 55 MINUTE, NOW()),

-- 服务2：肩颈舒缓按摩 60min — 待服务（排队等候）
(8002, 'WK20260413001-02', 2, 7002, '0928',
 @merchant_id, 10001, 2001,
 4002, '肩颈舒缓按摩', 60,
 0, '店内服务',
 NOW() - INTERVAL 55 MINUTE,
 NULL,
 NULL,
 168.00, 168.00,
 NULL, NULL, 2, '',
 0, NOW() - INTERVAL 55 MINUTE, NOW()),

-- ── Session 7003（手环 1024，多项服务，1完成1服务中）─────────────────────────
-- 服务1：足底精油按摩 60min — 已完成（75min前开始，60min后结束）
(8003, 'WK20260413002-01', 2, 7003, '1024',
 @merchant_id, 10002, 2002,
 4004, '精油足底按摩', 60,
 0, '店内服务',
 NOW() - INTERVAL 100 MINUTE,
 NOW() - INTERVAL 95 MINUTE,
 NOW() - INTERVAL 35 MINUTE,
 128.00, 128.00,
 NULL, NULL, 6, '',
 0, NOW() - INTERVAL 100 MINUTE, NOW()),

-- 服务2：SPA 护理套餐 90min — 服务中（10min前开始）
(8004, 'WK20260413002-02', 2, 7003, '1024',
 @merchant_id, 10002, 2002,
 4007, '薰衣草全身SPA', 120,
 0, '店内服务',
 NOW() - INTERVAL 100 MINUTE,
 NOW() - INTERVAL 10 MINUTE,
 NULL,
 388.00, 388.00,
 NULL, NULL, 5, '',
 0, NOW() - INTERVAL 100 MINUTE, NOW()),

-- ── Session 7004（手环 0512，待结算，全部完成）────────────────────────────────
(8005, 'WK20260413003-01', 2, 7004, '0512',
 @merchant_id, 0, 2003,
 4007, '薰衣草全身SPA', 120,
 0, '店内服务',
 NOW() - INTERVAL 150 MINUTE,
 NOW() - INTERVAL 140 MINUTE,
 NOW() - INTERVAL 20 MINUTE,
 388.00, 388.00,
 NULL, NULL, 6, '',
 0, NOW() - INTERVAL 150 MINUTE, NOW()),

-- ── Session 7005（手环 0781，已结算）─────────────────────────────────────────
(8006, 'WK20260413004-01', 2, 7005, '0781',
 @merchant_id, 10003, 2001,
 4001, '全身经络疏通', 90,
 0, '店内服务',
 NOW() - INTERVAL 4 HOUR,
 NOW() - INTERVAL 3 HOUR - INTERVAL 50 MINUTE,
 NOW() - INTERVAL 2 HOUR - INTERVAL 20 MINUTE,
 298.00, 298.00,
 4, NOW() - INTERVAL 2 HOUR, 6, '',
 0, NOW() - INTERVAL 4 HOUR, NOW());

-- ── 6. 更新 session 的 total_amount（从关联订单汇总）───────────────────────────
UPDATE `cb_walkin_session` s
SET s.total_amount = (
    SELECT COALESCE(SUM(o.pay_amount), 0)
    FROM `cb_order` o
    WHERE o.session_id = s.id AND o.deleted = 0 AND o.status != 7
)
WHERE s.id BETWEEN 7001 AND 7010;

SELECT '✅ migrate_v4_4 执行完成：散客接待闭环测试数据已写入' AS result;

-- ── 7. 修复：恢复车辆管理目录及相关菜单的图标（排序操作后可能被清空）────────────
-- id=1032: 车辆管理（目录）
UPDATE `sys_permission` SET `icon` = 'CarOutlined'       WHERE `id` = 1032 AND `portal_type` = 1;
-- id=1103: 车辆列表（菜单）
UPDATE `sys_permission` SET `icon` = 'CarOutlined'       WHERE `id` = 1103 AND `portal_type` = 1;
-- id=1104: 派车记录（菜单）
UPDATE `sys_permission` SET `icon` = 'FileTextOutlined'  WHERE `id` = 1104 AND `portal_type` = 1;

-- 顺便修复其他可能漏掉图标的菜单
UPDATE `sys_permission` SET `icon` = 'IdcardOutlined'       WHERE `id` = 1102 AND `portal_type` = 1 AND (`icon` IS NULL OR `icon` = '');
UPDATE `sys_permission` SET `icon` = 'BarChartOutlined'     WHERE `id` = 1105 AND `portal_type` = 1 AND (`icon` IS NULL OR `icon` = '');
UPDATE `sys_permission` SET `icon` = 'DollarOutlined'       WHERE `id` = 1106 AND `portal_type` = 1 AND (`icon` IS NULL OR `icon` = '');
UPDATE `sys_permission` SET `icon` = 'MinusCircleOutlined'  WHERE `id` = 1107 AND `portal_type` = 1 AND (`icon` IS NULL OR `icon` = '');
UPDATE `sys_permission` SET `icon` = 'TeamOutlined'         WHERE `id` = 1108 AND `portal_type` = 1 AND (`icon` IS NULL OR `icon` = '');
UPDATE `sys_permission` SET `icon` = 'BankOutlined'         WHERE `id` = 1109 AND `portal_type` = 1 AND (`icon` IS NULL OR `icon` = '');

SELECT '✅ 图标修复完成' AS result;

-- ── 8. 菜单重命名：散客接待 → 门店订单 ────────────────────────────────────────
UPDATE `sys_permission` SET `name` = '门店订单' WHERE `id` = 1102 AND `portal_type` = 1;

SELECT '✅ 菜单重命名完成：散客接待 → 门店订单' AS result;

-- ── 9. 技师服务类目字段 ────────────────────────────────────────────────────────
-- 存储技师可提供的服务类目 ID 列表（JSON 数组，如 [1,2,3]），对应 cb_service_category.id
ALTER TABLE `cb_technician`
    ADD COLUMN `service_item_ids` VARCHAR(1000) NULL COMMENT '可提供服务类目ID列表(JSON)' AFTER `skill_tags`;

SELECT '✅ cb_technician.service_item_ids 字段添加完成' AS result;

-- ── 10. 服务类目扩展字段：价格 / 时长 / 是否特殊项目 ────────────────────────────
-- price      : 服务基础指导价（常规项系统统一配置，特殊项可由技师覆盖）
-- duration   : 服务标准时长（分钟）
-- is_special : 0=常规项目（价格统一）  1=特殊项目（技师可自行定价）
ALTER TABLE `cb_service_category`
    ADD COLUMN `price`      DECIMAL(10,2) NULL    COMMENT '服务基础指导价'        AFTER `icon`,
    ADD COLUMN `duration`   INT           NULL    COMMENT '标准服务时长（分钟）'   AFTER `price`,
    ADD COLUMN `is_special` TINYINT(1)    NOT NULL DEFAULT 0 COMMENT '是否特殊项目(0=常规,1=特殊)' AFTER `duration`;

SELECT '✅ cb_service_category 扩展字段添加完成' AS result;

-- ── 11. 技师服务专属定价表 ──────────────────────────────────────────────────────
-- 特殊项目支持技师自行定价；普通项目沿用 cb_service_category.price
CREATE TABLE IF NOT EXISTS `cb_technician_service_price` (
    `id`              BIGINT       NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `merchant_id`     BIGINT       NOT NULL COMMENT '商户ID',
    `technician_id`   BIGINT       NOT NULL COMMENT '技师ID',
    `service_item_id` BIGINT       NOT NULL COMMENT '服务类目ID (cb_service_category.id)',
    `price`           DECIMAL(10,2) NOT NULL COMMENT '技师专属价格',
    `create_time`     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `update_time`     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY `uniq_tech_svc` (`technician_id`, `service_item_id`),
    KEY `idx_merchant_id` (`merchant_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='技师服务专属定价表';

SELECT '✅ cb_technician_service_price 表创建完成' AS result;
