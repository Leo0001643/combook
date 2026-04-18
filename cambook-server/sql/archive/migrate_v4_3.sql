-- ============================================================
-- migrate_v4_3.sql
-- 1. 补全商户端菜单树（散客接待、历史订单、派车记录、完整财务、货币设置）
-- 2. 重构订单管理/车辆管理/财务管理/商户设置为目录，添加子菜单
-- 3. 写入完整商户测试数据（会员、技师、订单、财务记录等）
-- ============================================================

-- ─────────────────────────────────────────────────────────────
-- PART 1: 商户端菜单重构
-- ─────────────────────────────────────────────────────────────

-- ── Step 1: 调整现有顶级菜单 sort 为 10x 档位（留出插入空间）
UPDATE sys_permission SET sort = 10  WHERE id = 1010 AND portal_type = 1; -- 数据看板
UPDATE sys_permission SET sort = 20  WHERE id = 1011 AND portal_type = 1; -- 订单管理
UPDATE sys_permission SET sort = 40  WHERE id = 1000 AND portal_type = 1; -- 公告管理
UPDATE sys_permission SET sort = 50  WHERE id = 1001 AND portal_type = 1; -- 运营管理
UPDATE sys_permission SET sort = 60  WHERE id = 1002 AND portal_type = 1; -- 营销管理
UPDATE sys_permission SET sort = 70  WHERE id = 1003 AND portal_type = 1; -- 财务管理
UPDATE sys_permission SET sort = 80  WHERE id = 1004 AND portal_type = 1; -- 权限管理
UPDATE sys_permission SET sort = 90  WHERE id = 1019 AND portal_type = 1; -- 商户设置

-- ── Step 2: 将 "订单管理" 从 type=2(页面) 改为 type=1(目录)，清空 path
UPDATE sys_permission
SET type = 1, path = NULL, component = NULL
WHERE id = 1011 AND portal_type = 1;

-- ── Step 3: 将 "车辆管理" 从 type=2(页面) 改为 type=1(目录)，清空 path
UPDATE sys_permission
SET type = 1, path = NULL, component = NULL
WHERE id = 1032 AND portal_type = 1;

-- ── Step 4: 将 "商户设置" 从 type=2(页面) 改为 type=1(目录)，清空 path
UPDATE sys_permission
SET type = 1, path = NULL, component = NULL
WHERE id = 1019 AND portal_type = 1;

-- ── Step 5: 将 "财务管理" 下旧的两条菜单隐藏（不删除，兼容旧路由）
UPDATE sys_permission SET visible = 0 WHERE id IN (1050, 1051) AND portal_type = 1;

-- ── Step 6: 新增所有缺失菜单（id 从 1100 开始）
-- 防重复：先删再插
DELETE FROM sys_permission WHERE id BETWEEN 1100 AND 1130 AND portal_type = 1;

INSERT INTO sys_permission
    (id, parent_id, name, code, type, path, component, icon, sort, portal_type, visible, status, deleted)
VALUES
-- ── 订单管理子菜单（parent=1011）────────────────────────────
(1100, 1011, '在线订单',   NULL, 2, '/merchant/orders',          NULL, 'OrderedListOutlined', 1, 1, 1, 1, 0),
(1101, 1011, '历史记录',   NULL, 2, '/merchant/orders/history',  NULL, 'FileTextOutlined',    2, 1, 1, 1, 0),

-- ── 散客接待（顶级，sort=30）────────────────────────────────
(1102, 0,    '散客接待',   NULL, 2, '/merchant/walkin',          NULL, 'IdcardOutlined',     30, 1, 1, 1, 0),

-- ── 车辆管理子菜单（parent=1032）────────────────────────────
(1103, 1032, '车辆列表',   NULL, 2, '/merchant/vehicles',          NULL, 'CarOutlined',       1, 1, 1, 1, 0),
(1104, 1032, '派车记录',   NULL, 2, '/merchant/vehicles/dispatch', NULL, 'FileTextOutlined',  2, 1, 1, 1, 0),

-- ── 财务管理完整子菜单（parent=1003）────────────────────────
(1105, 1003, '财务概览',   NULL, 2, '/merchant/finance/overview',    NULL, 'BarChartOutlined',   1, 1, 1, 1, 0),
(1106, 1003, '收入记录',   NULL, 2, '/merchant/finance/income',      NULL, 'DollarOutlined',     2, 1, 1, 1, 0),
(1107, 1003, '支出管理',   NULL, 2, '/merchant/finance/expense',     NULL, 'MinusCircleOutlined',3, 1, 1, 1, 0),
(1108, 1003, '工资管理',   NULL, 2, '/merchant/finance/salary',      NULL, 'TeamOutlined',       4, 1, 1, 1, 0),
(1109, 1003, '技师结算',   NULL, 2, '/merchant/finance/settlement',  NULL, 'BankOutlined',       5, 1, 1, 1, 0),
(1110, 1003, '提现审核',   NULL, 2, '/merchant/finance/withdraw',    NULL, 'AuditOutlined',      6, 1, 1, 1, 0),

-- ── 商户设置子菜单（parent=1019）────────────────────────────
(1111, 1019, '基本资料',   NULL, 2, '/merchant/profile',               NULL, 'UserOutlined',      1, 1, 1, 1, 0),
(1112, 1019, '结算币种',   NULL, 2, '/merchant/settings/currency',     NULL, 'GlobalOutlined',    2, 1, 1, 1, 0);

-- ── Step 7: 为 SUPER_ADMIN 角色分配所有新增操作权限
INSERT IGNORE INTO sys_role_permission (role_id, permission_id)
SELECT r.id, p.id
FROM sys_role r
JOIN sys_permission p ON p.id BETWEEN 1100 AND 1130 AND p.deleted = 0
WHERE r.role_code = 'SUPER_ADMIN'
  AND NOT EXISTS (
    SELECT 1 FROM sys_role_permission rp
    WHERE rp.role_id = r.id AND rp.permission_id = p.id
  );

-- ─────────────────────────────────────────────────────────────
-- PART 2: 商户测试数据
-- ─────────────────────────────────────────────────────────────

-- 取第一个商户 ID 备用
SET @merchant_id = (SELECT id FROM cb_merchant WHERE deleted = 0 ORDER BY id LIMIT 1);

-- ── 会员测试数据 ───────────────────────────────────────────────
-- member_no 唯一，mobile 唯一；字段按实际 schema 对齐
INSERT IGNORE INTO cb_member
    (id, member_no, mobile, nickname, avatar, gender, balance,
     total_recharge, total_spend, order_count, level, points,
     status, deleted, register_time, create_time, update_time)
VALUES
(10001,'CB202603170001','+8613800001001','张伟', 'https://api.dicebear.com/7.x/avataaars/svg?seed=10001',1, 580.00,1000.00, 420.00,5,1,520,1,0,NOW()-INTERVAL 90 DAY,NOW()-INTERVAL 90 DAY,NOW()),
(10002,'CB202603180001','+8613800001002','李娜', 'https://api.dicebear.com/7.x/avataaars/svg?seed=10002',2,1200.00,2000.00, 800.00,8,2,800,1,0,NOW()-INTERVAL 75 DAY,NOW()-INTERVAL 75 DAY,NOW()),
(10003,'CB202603190001','+8613800001003','王芳', 'https://api.dicebear.com/7.x/avataaars/svg?seed=10003',2, 350.00, 500.00, 150.00,2,0,150,1,0,NOW()-INTERVAL 60 DAY,NOW()-INTERVAL 60 DAY,NOW()),
(10004,'CB202603200001','+8613800001004','赵强', 'https://api.dicebear.com/7.x/avataaars/svg?seed=10004',1,   0.00, 800.00, 800.00,6,1,800,1,0,NOW()-INTERVAL 50 DAY,NOW()-INTERVAL 50 DAY,NOW()),
(10005,'CB202603210001','+8613800001005','陈洁', 'https://api.dicebear.com/7.x/avataaars/svg?seed=10005',2,2500.00,3000.00, 500.00,4,3,500,1,0,NOW()-INTERVAL 40 DAY,NOW()-INTERVAL 40 DAY,NOW()),
(10006,'CB202603220001','+8613800001006','刘磊', 'https://api.dicebear.com/7.x/avataaars/svg?seed=10006',1, 100.00, 600.00, 500.00,3,1,500,1,0,NOW()-INTERVAL 35 DAY,NOW()-INTERVAL 35 DAY,NOW()),
(10007,'CB202603230001','+8613800001007','周梅', 'https://api.dicebear.com/7.x/avataaars/svg?seed=10007',2, 700.00,1200.00, 500.00,3,1,500,1,0,NOW()-INTERVAL 28 DAY,NOW()-INTERVAL 28 DAY,NOW()),
(10008,'CB202603240001','+8613800001008','吴昊', 'https://api.dicebear.com/7.x/avataaars/svg?seed=10008',1,  50.00, 300.00, 250.00,2,0,250,1,0,NOW()-INTERVAL 20 DAY,NOW()-INTERVAL 20 DAY,NOW()),
(10009,'CB202603250001','+8613800001009','郑丽', 'https://api.dicebear.com/7.x/avataaars/svg?seed=10009',2,   0.00, 100.00, 100.00,1,0,100,2,0,NOW()-INTERVAL 15 DAY,NOW()-INTERVAL 15 DAY,NOW()),
(10010,'CB202603260001','+8613800001010','孙博', 'https://api.dicebear.com/7.x/avataaars/svg?seed=10010',1,3200.00,4000.00, 800.00,5,3,800,1,0,NOW()-INTERVAL 10 DAY,NOW()-INTERVAL 10 DAY,NOW());

-- ── 技师测试数据（补全现有技师的 merchant_id）────────────────
UPDATE cb_technician SET merchant_id = @merchant_id
WHERE (merchant_id IS NULL OR merchant_id = 0) AND deleted = 0;

-- 新增测试技师（tech_no/mobile 必须唯一）
INSERT IGNORE INTO cb_technician
    (id, tech_no, merchant_id, mobile, real_name, nickname, avatar,
     gender, rating, order_count, audit_status, online_status,
     commission_rate, settlement_mode, commission_type,
     intro_zh, deleted, create_time, update_time)
VALUES
(2001,'T20260101001',@merchant_id,'+8613900002001','李小美','小美',
 'https://api.dicebear.com/7.x/avataaars/svg?seed=t2001',
 2, 4.90, 312, 1, 1, 60.00, 3, 0,
 '专业推拿技师，5年经验，擅长全身放松按摩', 0, NOW()-INTERVAL 180 DAY, NOW()),

(2002,'T20260101002',@merchant_id,'+8613900002002','陈小雨','小雨',
 'https://api.dicebear.com/7.x/avataaars/svg?seed=t2002',
 2, 4.80, 256, 1, 1, 60.00, 3, 0,
 '泰式按摩专家，精通传统泰式手法', 0, NOW()-INTERVAL 150 DAY, NOW()),

(2003,'T20260101003',@merchant_id,'+8613900002003','王小阳','小阳',
 'https://api.dicebear.com/7.x/avataaars/svg?seed=t2003',
 1, 4.70, 198, 1, 0, 55.00, 2, 0,
 '中医推拿专业，擅长颈肩腰腿痛调理', 0, NOW()-INTERVAL 120 DAY, NOW()),

(2004,'T20260101004',@merchant_id,'+8613900002004','赵小珊','小珊',
 'https://api.dicebear.com/7.x/avataaars/svg?seed=t2004',
 2, 4.60, 145, 1, 0, 60.00, 3, 0,
 '面部护理与美容养生专家，手法细腻', 0, NOW()-INTERVAL 90 DAY, NOW()),

(2005,'T20260101005',@merchant_id,'+8613900002005','孙小龙','小龙',
 'https://api.dicebear.com/7.x/avataaars/svg?seed=t2005',
 1, 4.95, 421, 1, 2, 70.00, 1, 1,
 '足部反射理疗专家，擅长经络调理，日结提成制度', 0, NOW()-INTERVAL 365 DAY, NOW());

-- ── 服务大类测试数据 ──────────────────────────────────────────
INSERT IGNORE INTO cb_service_category
    (id, parent_id, name_zh, name_en, icon, sort, status, deleted, create_time, update_time)
VALUES
(3001, 0, '按摩养生', 'Massage & Wellness', '', 1, 1, 0, NOW(), NOW()),
(3002, 0, '足浴足疗', 'Foot Spa',           '', 2, 1, 0, NOW(), NOW()),
(3003, 0, '面部护理', 'Facial Care',         '', 3, 1, 0, NOW(), NOW()),
(3004, 0, '芳香SPA',  'Aroma SPA',           '', 4, 1, 0, NOW(), NOW());

-- ── 服务项目测试数据 ──────────────────────────────────────────
INSERT IGNORE INTO cb_service_item
    (id, category_id, name_zh, name_en, desc_zh, base_price, duration, sort, status, deleted, create_time, update_time)
VALUES
(4001, 3001, '全身经络疏通', 'Full Body Meridian',     '全身经络梳理，促进血液循环，释放身体疲劳', 298.00, 90, 1, 1, 0, NOW(), NOW()),
(4002, 3001, '肩颈舒缓按摩', 'Neck & Shoulder Relief', '专注肩颈部位，缓解颈椎压力',               168.00, 60, 2, 1, 0, NOW(), NOW()),
(4003, 3001, '泰式传统按摩', 'Thai Traditional',       '正宗泰式手法，拉伸筋骨，舒经活络',           258.00, 90, 3, 1, 0, NOW(), NOW()),
(4004, 3002, '精油足底按摩', 'Foot Reflex Oil',        '精选植物精油配合穴位按摩',                  128.00, 60, 1, 1, 0, NOW(), NOW()),
(4005, 3002, '泡脚足疗套餐', 'Foot Bath Package',      '中药泡脚+专业足疗，去湿气排寒毒',            198.00, 90, 2, 1, 0, NOW(), NOW()),
(4006, 3003, '深层清洁护肤', 'Deep Cleansing Facial',  '深层清洁毛孔，补水保湿，提亮肤色',           188.00, 75, 1, 1, 0, NOW(), NOW()),
(4007, 3004, '薰衣草全身SPA','Lavender Full SPA',      '薰衣草精油全身包裹护理，深度放松解压',        388.00,120, 1, 1, 0, NOW(), NOW()),
(4008, 3004, '玫瑰浴盐去角质','Rose Salt Scrub',        '玫瑰浴盐全身去角质+保湿精华涂抹',            268.00, 90, 2, 1, 0, NOW(), NOW());

-- ── 历史订单测试数据（字段按实际 cb_order schema 对齐）────────
-- 注：address_id/address_detail/appoint_time/service_name/service_duration 均为必填
INSERT IGNORE INTO cb_order
    (id, order_no, merchant_id, member_id, technician_id, service_item_id,
     service_name, service_duration,
     address_id, address_detail,
     appoint_time, start_time, end_time,
     original_amount, pay_amount,
     pay_type, pay_time, status,
     remark, deleted, create_time, update_time)
VALUES
-- ─ 近30天完成订单 ─
(5001,'OD20260317153001',@merchant_id,10001,2001,4001,'全身经络疏通',90,0,'店内服务',NOW()-INTERVAL 30 DAY+INTERVAL 2 HOUR,NOW()-INTERVAL 30 DAY+INTERVAL 3 HOUR,NOW()-INTERVAL 30 DAY+INTERVAL 4 HOUR+INTERVAL 30 MINUTE,298.00,298.00,4,NOW()-INTERVAL 30 DAY+INTERVAL 2 HOUR,6,'',0,NOW()-INTERVAL 30 DAY,NOW()),
(5002,'OD20260318153002',@merchant_id,10002,2002,4003,'泰式传统按摩',90,0,'店内服务',NOW()-INTERVAL 29 DAY+INTERVAL 2 HOUR,NOW()-INTERVAL 29 DAY+INTERVAL 3 HOUR,NOW()-INTERVAL 29 DAY+INTERVAL 4 HOUR+INTERVAL 30 MINUTE,258.00,258.00,3,NOW()-INTERVAL 29 DAY+INTERVAL 2 HOUR,6,'',0,NOW()-INTERVAL 29 DAY,NOW()),
(5003,'OD20260319153003',@merchant_id,10003,2003,4002,'肩颈舒缓按摩',60,0,'店内服务',NOW()-INTERVAL 28 DAY+INTERVAL 2 HOUR,NOW()-INTERVAL 28 DAY+INTERVAL 3 HOUR,NOW()-INTERVAL 28 DAY+INTERVAL 4 HOUR,168.00,168.00,4,NOW()-INTERVAL 28 DAY+INTERVAL 2 HOUR,6,'',0,NOW()-INTERVAL 28 DAY,NOW()),
(5004,'OD20260320153004',@merchant_id,10004,2005,4004,'精油足底按摩',60,0,'店内服务',NOW()-INTERVAL 27 DAY+INTERVAL 2 HOUR,NOW()-INTERVAL 27 DAY+INTERVAL 3 HOUR,NOW()-INTERVAL 27 DAY+INTERVAL 4 HOUR,128.00,128.00,4,NOW()-INTERVAL 27 DAY+INTERVAL 2 HOUR,6,'',0,NOW()-INTERVAL 27 DAY,NOW()),
(5005,'OD20260321153005',@merchant_id,10005,2001,4007,'薰衣草全身SPA',120,0,'店内服务',NOW()-INTERVAL 26 DAY+INTERVAL 2 HOUR,NOW()-INTERVAL 26 DAY+INTERVAL 3 HOUR,NOW()-INTERVAL 26 DAY+INTERVAL 5 HOUR,388.00,388.00,2,NOW()-INTERVAL 26 DAY+INTERVAL 2 HOUR,6,'',0,NOW()-INTERVAL 26 DAY,NOW()),
(5006,'OD20260322153006',@merchant_id,10006,2004,4006,'深层清洁护肤',75,0,'店内服务',NOW()-INTERVAL 25 DAY+INTERVAL 2 HOUR,NOW()-INTERVAL 25 DAY+INTERVAL 3 HOUR,NOW()-INTERVAL 25 DAY+INTERVAL 4 HOUR+INTERVAL 15 MINUTE,188.00,188.00,4,NOW()-INTERVAL 25 DAY+INTERVAL 2 HOUR,6,'',0,NOW()-INTERVAL 25 DAY,NOW()),
(5007,'OD20260323153007',@merchant_id,10007,2002,4005,'泡脚足疗套餐',90,0,'店内服务',NOW()-INTERVAL 24 DAY+INTERVAL 2 HOUR,NOW()-INTERVAL 24 DAY+INTERVAL 3 HOUR,NOW()-INTERVAL 24 DAY+INTERVAL 4 HOUR+INTERVAL 30 MINUTE,198.00,198.00,3,NOW()-INTERVAL 24 DAY+INTERVAL 2 HOUR,6,'',0,NOW()-INTERVAL 24 DAY,NOW()),
(5008,'OD20260324153008',@merchant_id,10008,2003,4008,'玫瑰浴盐去角质',90,0,'店内服务',NOW()-INTERVAL 23 DAY+INTERVAL 2 HOUR,NOW()-INTERVAL 23 DAY+INTERVAL 3 HOUR,NOW()-INTERVAL 23 DAY+INTERVAL 4 HOUR+INTERVAL 30 MINUTE,268.00,268.00,4,NOW()-INTERVAL 23 DAY+INTERVAL 2 HOUR,6,'',0,NOW()-INTERVAL 23 DAY,NOW()),
(5009,'OD20260325153009',@merchant_id,10001,2005,4001,'全身经络疏通',90,0,'店内服务',NOW()-INTERVAL 22 DAY+INTERVAL 2 HOUR,NOW()-INTERVAL 22 DAY+INTERVAL 3 HOUR,NOW()-INTERVAL 22 DAY+INTERVAL 4 HOUR+INTERVAL 30 MINUTE,298.00,298.00,4,NOW()-INTERVAL 22 DAY+INTERVAL 2 HOUR,6,'',0,NOW()-INTERVAL 22 DAY,NOW()),
(5010,'OD20260326153010',@merchant_id,10010,2001,4007,'薰衣草全身SPA',120,0,'店内服务',NOW()-INTERVAL 21 DAY+INTERVAL 2 HOUR,NOW()-INTERVAL 21 DAY+INTERVAL 3 HOUR,NOW()-INTERVAL 21 DAY+INTERVAL 5 HOUR,388.00,388.00,2,NOW()-INTERVAL 21 DAY+INTERVAL 2 HOUR,6,'',0,NOW()-INTERVAL 21 DAY,NOW()),
-- ─ 本周完成订单 ─
(5011,'OD20260410153011',@merchant_id,10002,2002,4003,'泰式传统按摩',90,0,'店内服务',NOW()-INTERVAL 7 DAY+INTERVAL 10 HOUR,NOW()-INTERVAL 7 DAY+INTERVAL 11 HOUR,NOW()-INTERVAL 7 DAY+INTERVAL 12 HOUR+INTERVAL 30 MINUTE,258.00,258.00,4,NOW()-INTERVAL 7 DAY+INTERVAL 10 HOUR,6,'',0,NOW()-INTERVAL 7 DAY,NOW()),
(5012,'OD20260411153012',@merchant_id,10003,2003,4002,'肩颈舒缓按摩',60,0,'店内服务',NOW()-INTERVAL 6 DAY+INTERVAL 10 HOUR,NOW()-INTERVAL 6 DAY+INTERVAL 11 HOUR,NOW()-INTERVAL 6 DAY+INTERVAL 12 HOUR,168.00,168.00,3,NOW()-INTERVAL 6 DAY+INTERVAL 10 HOUR,6,'',0,NOW()-INTERVAL 6 DAY,NOW()),
(5013,'OD20260412153013',@merchant_id,10005,2001,4007,'薰衣草全身SPA',120,0,'店内服务',NOW()-INTERVAL 5 DAY+INTERVAL 10 HOUR,NOW()-INTERVAL 5 DAY+INTERVAL 11 HOUR,NOW()-INTERVAL 5 DAY+INTERVAL 13 HOUR,388.00,388.00,2,NOW()-INTERVAL 5 DAY+INTERVAL 10 HOUR,6,'',0,NOW()-INTERVAL 5 DAY,NOW()),
(5014,'OD20260413153014',@merchant_id,10007,2004,4006,'深层清洁护肤',75,0,'店内服务',NOW()-INTERVAL 4 DAY+INTERVAL 14 HOUR,NOW()-INTERVAL 4 DAY+INTERVAL 15 HOUR,NOW()-INTERVAL 4 DAY+INTERVAL 16 HOUR+INTERVAL 15 MINUTE,188.00,188.00,4,NOW()-INTERVAL 4 DAY+INTERVAL 14 HOUR,6,'',0,NOW()-INTERVAL 4 DAY,NOW()),
(5015,'OD20260414153015',@merchant_id,10009,2005,4004,'精油足底按摩',60,0,'店内服务',NOW()-INTERVAL 3 DAY+INTERVAL 14 HOUR,NULL,NULL,128.00,128.00,NULL,NULL,8,'客户临时取消',0,NOW()-INTERVAL 3 DAY,NOW()),
(5016,'OD20260415153016',@merchant_id,10010,2002,4003,'泰式传统按摩',90,0,'店内服务',NOW()-INTERVAL 2 DAY+INTERVAL 10 HOUR,NOW()-INTERVAL 2 DAY+INTERVAL 11 HOUR,NOW()-INTERVAL 2 DAY+INTERVAL 12 HOUR+INTERVAL 30 MINUTE,258.00,258.00,4,NOW()-INTERVAL 2 DAY+INTERVAL 10 HOUR,6,'',0,NOW()-INTERVAL 2 DAY,NOW()),
(5017,'OD20260416153017',@merchant_id,10006,2001,4001,'全身经络疏通',90,0,'店内服务',NOW()-INTERVAL 1 DAY+INTERVAL 10 HOUR,NOW()-INTERVAL 1 DAY+INTERVAL 11 HOUR,NOW()-INTERVAL 1 DAY+INTERVAL 12 HOUR+INTERVAL 30 MINUTE,298.00,298.00,4,NOW()-INTERVAL 1 DAY+INTERVAL 10 HOUR,6,'',0,NOW()-INTERVAL 1 DAY,NOW()),
-- ─ 今日订单 ─
(5018,'OD20260417153018',@merchant_id,10001,2003,4002,'肩颈舒缓按摩',60,0,'店内服务',NOW()-INTERVAL 2 HOUR,NOW()-INTERVAL 1 HOUR,NULL,168.00,168.00,4,NOW()-INTERVAL 1 HOUR,4,'服务中',0,NOW()-INTERVAL 2 HOUR,NOW()),
(5019,'OD20260417153019',@merchant_id,10004,2005,4005,'泡脚足疗套餐',90,0,'店内服务',NOW()+INTERVAL 30 MINUTE,NULL,NULL,198.00,198.00,NULL,NULL,2,'',0,NOW()-INTERVAL 30 MINUTE,NOW()),
(5020,'OD20260417153020',@merchant_id,10002,2001,4007,'薰衣草全身SPA',120,0,'店内服务',NOW()+INTERVAL 1 HOUR,NULL,NULL,388.00,388.00,NULL,NULL,1,'待接单',0,NOW()-INTERVAL 10 MINUTE,NOW());

-- ── 车辆测试数据（字段按实际 cb_vehicle schema 对齐）────────
INSERT IGNORE INTO cb_vehicle
    (id, plate_number, brand, model, color, seats, status, remark, deleted, create_time, update_time)
VALUES
(6001,'粤A12345','丰田','埃尔法','白色',7,0,'VIP接送专用车',   0,NOW(),NOW()),
(6002,'粤A67890','奔驰','V260', '黑色',6,0,'商务接送车辆',    0,NOW(),NOW()),
(6003,'粤B54321','别克','GL8',  '银色',7,2,'维修中，预计3天后恢复',0,NOW(),NOW());

-- ─────────────────────────────────────────────────────────────
-- PART 3: 币种测试数据（若 sys_currency 存在且为空）
-- ─────────────────────────────────────────────────────────────

INSERT IGNORE INTO sys_currency
    (id, currency_code, currency_name, currency_name_en, symbol, flag, is_crypto, rate_to_usd, decimal_places, sort_order, status, remark, create_time, update_time)
VALUES
(1,  'USD',  '美元',   'US Dollar',       '$',   '🇺🇸', 0, 1.000000,    2, 1,  1, '全球储备货币',     NOW(), NOW()),
(2,  'USDT', '泰达币', 'Tether USD',      '₮',   '💎', 1, 1.000000,    6, 2,  1, '稳定币，与USD 1:1',NOW(), NOW()),
(3,  'CNY',  '人民币', 'Chinese Yuan',    '¥',   '🇨🇳', 0, 0.138000,    2, 3,  1, '中国法币',         NOW(), NOW()),
(4,  'PHP',  '菲律宾比索','Philippine Peso','₱', '🇵🇭', 0, 0.017500,    2, 4,  1, '菲律宾法币',       NOW(), NOW()),
(5,  'THB',  '泰铢',   'Thai Baht',       '฿',   '🇹🇭', 0, 0.027800,    2, 5,  1, '泰国法币',         NOW(), NOW()),
(6,  'KRW',  '韩元',   'Korean Won',      '₩',   '🇰🇷', 0, 0.000730,    0, 6,  1, '韩国法币',         NOW(), NOW()),
(7,  'AED',  '迪拜币', 'UAE Dirham',      'د.إ', '🇦🇪', 0, 0.272200,    2, 7,  1, '阿联酋法币',       NOW(), NOW()),
(8,  'MYR',  '马来西亚令吉','Malaysian Ringgit','RM','🇲🇾',0,0.213000,  2, 8,  1, '马来西亚法币',     NOW(), NOW()),
(9,  'VND',  '越南盾', 'Vietnamese Dong', '₫',   '🇻🇳', 0, 0.000039,    0, 9,  1, '越南法币',         NOW(), NOW()),
(10, 'SGD',  '新加坡元','Singapore Dollar','S$',  '🇸🇬', 0, 0.740000,    2, 10, 1, '新加坡法币',       NOW(), NOW()),
(11, 'EUR',  '欧元',   'Euro',            '€',   '🇪🇺', 0, 1.080000,    2, 11, 1, '欧盟法币',         NOW(), NOW()),
(12, 'GBP',  '英镑',   'British Pound',   '£',   '🇬🇧', 0, 1.270000,    2, 12, 1, '英国法币',         NOW(), NOW()),
(13, 'JPY',  '日元',   'Japanese Yen',    '¥',   '🇯🇵', 0, 0.006500,    0, 13, 1, '日本法币',         NOW(), NOW()),
(14, 'BTC',  '比特币', 'Bitcoin',         '₿',   '🟠', 1, 67000.000000, 8, 14, 1, '数字黄金',         NOW(), NOW()),
(15, 'ETH',  '以太坊', 'Ethereum',        'Ξ',   '⬡',  1, 3500.000000,  8, 15, 1, '智能合约平台币',   NOW(), NOW());

-- ── 为测试商户配置币种 ────────────────────────────────────────
INSERT IGNORE INTO cb_merchant_currency
    (merchant_id, currency_code, is_default, custom_rate, display_name, sort_order, status, create_time, update_time)
VALUES
(@merchant_id, 'CNY',  1, NULL, NULL, 1, 1, NOW(), NOW()),
(@merchant_id, 'USDT', 0, NULL, NULL, 2, 1, NOW(), NOW()),
(@merchant_id, 'USD',  0, NULL, NULL, 3, 1, NOW(), NOW());

-- ─────────────────────────────────────────────────────────────
-- 完成提示
-- ─────────────────────────────────────────────────────────────
SELECT '✅ migrate_v4_3 执行完成：菜单已补全，测试数据已写入' AS result;
