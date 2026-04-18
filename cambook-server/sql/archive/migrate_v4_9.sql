-- ============================================================
-- migrate_v4_9.sql  在线订单增强：服务方式 / 组合支付 / 多服务项
-- 本脚本幂等：重复执行不报错，使用存储过程判断列是否存在
-- ============================================================

-- ─────────────────────────────────────────────────────────────
-- 1. cb_order: 新增 service_mode / pay_records / technician_no
-- ─────────────────────────────────────────────────────────────
DROP PROCEDURE IF EXISTS _add_col_order_service_mode;
DELIMITER $$
CREATE PROCEDURE _add_col_order_service_mode()
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = DATABASE()
          AND table_name   = 'cb_order'
          AND column_name  = 'service_mode'
    ) THEN
        ALTER TABLE cb_order
            ADD COLUMN service_mode TINYINT(1) NOT NULL DEFAULT 2
                COMMENT '服务方式：1=上门服务 2=到店服务'
                AFTER order_type;
    END IF;
END$$
DELIMITER ;
CALL _add_col_order_service_mode();
DROP PROCEDURE IF EXISTS _add_col_order_service_mode;

DROP PROCEDURE IF EXISTS _add_col_order_pay_records;
DELIMITER $$
CREATE PROCEDURE _add_col_order_pay_records()
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = DATABASE()
          AND table_name   = 'cb_order'
          AND column_name  = 'pay_records'
    ) THEN
        ALTER TABLE cb_order
            ADD COLUMN pay_records TEXT DEFAULT NULL
                COMMENT '组合支付明细 JSON（[{method,currency,amount}]）'
                AFTER pay_type;
    END IF;
END$$
DELIMITER ;
CALL _add_col_order_pay_records();
DROP PROCEDURE IF EXISTS _add_col_order_pay_records;

DROP PROCEDURE IF EXISTS _add_col_order_technician_no;
DELIMITER $$
CREATE PROCEDURE _add_col_order_technician_no()
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = DATABASE()
          AND table_name   = 'cb_order'
          AND column_name  = 'technician_no'
    ) THEN
        ALTER TABLE cb_order
            ADD COLUMN technician_no VARCHAR(32) DEFAULT NULL
                COMMENT '技师编号快照（上门服务时用于识别身份）'
                AFTER technician_id;
    END IF;
END$$
DELIMITER ;
CALL _add_col_order_technician_no();
DROP PROCEDURE IF EXISTS _add_col_order_technician_no;

DROP PROCEDURE IF EXISTS _add_col_order_technician_mobile;
DELIMITER $$
CREATE PROCEDURE _add_col_order_technician_mobile()
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = DATABASE()
          AND table_name   = 'cb_order'
          AND column_name  = 'technician_mobile'
    ) THEN
        ALTER TABLE cb_order
            ADD COLUMN technician_mobile VARCHAR(20) DEFAULT NULL
                COMMENT '技师手机快照'
                AFTER technician_no;
    END IF;
END$$
DELIMITER ;
CALL _add_col_order_technician_mobile();
DROP PROCEDURE IF EXISTS _add_col_order_technician_mobile;

-- ─────────────────────────────────────────────────────────────
-- 2. cb_order_item: 多服务项（一单多项）
-- ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS cb_order_item (
    id               BIGINT       NOT NULL AUTO_INCREMENT PRIMARY KEY,
    order_id         BIGINT       NOT NULL           COMMENT '关联订单ID',
    service_item_id  BIGINT       DEFAULT NULL        COMMENT '服务项ID',
    service_name     VARCHAR(100) NOT NULL            COMMENT '服务名称快照',
    service_duration INT          NOT NULL DEFAULT 60 COMMENT '时长(分钟)',
    unit_price       DECIMAL(10,2) NOT NULL           COMMENT '单价',
    qty              INT          NOT NULL DEFAULT 1  COMMENT '数量',
    svc_status       TINYINT(1)   NOT NULL DEFAULT 0  COMMENT '0=待服务 1=服务中 2=已完成',
    start_time       DATETIME     DEFAULT NULL        COMMENT '服务开始时间',
    end_time         DATETIME     DEFAULT NULL        COMMENT '服务结束时间',
    remark           VARCHAR(200) DEFAULT NULL,
    deleted          TINYINT(1)   NOT NULL DEFAULT 0  COMMENT '逻辑删除：0正常 1删除',
    create_time      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    update_time      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_order_id (order_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='在线订单服务项明细';

-- ─────────────────────────────────────────────────────────────
-- 3. 修复 walkin_pay_type 字典 remark — 从简单颜色名改为 JSON 格式
--    格式：{"c":"颜色hex","i":"emoji图标","nc":1(可选,银行转账需选币种)}
--    使用 INSERT ... ON DUPLICATE KEY UPDATE 幂等更新
-- ─────────────────────────────────────────────────────────────
INSERT INTO `sys_dict`
  (`dict_type`,`dict_value`,`label_zh`,`label_en`,`label_vi`,`label_km`,`label_ja`,`label_ko`,`sort`,`status`,`remark`)
VALUES
  ('walkin_pay_type','1','现金',   'Cash',        'Tiền mặt',  'សាច់ប្រាក់', '現金',    '현금',    1,1,'{"c":"#10b981","i":"💵"}'),
  ('walkin_pay_type','2','ABA Pay','ABA Pay',     'ABA Pay',   'ABA Pay',     'ABA Pay', 'ABA Pay', 2,1,'{"c":"#2563eb","i":"🏦","nc":1}'),
  ('walkin_pay_type','3','USDT',   'USDT',        'USDT',      'USDT',        'USDT',    'USDT',    3,1,'{"c":"#f59e0b","i":"₮"}'),
  ('walkin_pay_type','4','微信支付','WeChat Pay',  'WeChat',    'WeChat',      'WeChat',  'WeChat',  4,1,'{"c":"#07C160","i":"💚"}'),
  ('walkin_pay_type','5','支付宝', 'Alipay',      'Alipay',    'Alipay',      'Alipay',  'Alipay',  5,1,'{"c":"#1677FF","i":"💙"}'),
  ('walkin_pay_type','6','挂账',   'On Account',  'Chịu nợ',   'ខ្ចីប្រាក់', '付け',   '외상',    6,1,'{"c":"#94a3b8","i":"📝"}')
ON DUPLICATE KEY UPDATE
  `remark` = VALUES(`remark`);

-- 同步修复 pay_type（在线订单支付方式）
INSERT INTO `sys_dict`
  (`dict_type`,`dict_value`,`label_zh`,`label_en`,`label_vi`,`label_km`,`label_ja`,`label_ko`,`sort`,`status`,`remark`)
VALUES
  ('pay_type','1','ABA Pay',  'ABA Pay', 'ABA Pay',    'ABA Pay',              'ABA Pay',    'ABA Pay', 1,1,'{"c":"#2563eb","i":"🏦"}'),
  ('pay_type','2','USDT',     'USDT',    'USDT',        'USDT',                'USDT',       'USDT',    2,1,'{"c":"#f59e0b","i":"₮"}'),
  ('pay_type','3','钱包余额', 'Wallet',  'Ví điện tử',  'កាបូបអេឡិចត្រូនិក',  'ウォレット', '지갑',    3,1,'{"c":"#8b5cf6","i":"👛"}'),
  ('pay_type','4','现金',     'Cash',    'Tiền mặt',    'សាច់ប្រាក់',          '現金',       '현금',    4,1,'{"c":"#10b981","i":"💵"}')
ON DUPLICATE KEY UPDATE
  `remark` = VALUES(`remark`);

-- 修复 walkin_session_status（确保 remark 格式正确）
INSERT INTO `sys_dict`
  (`dict_type`,`dict_value`,`label_zh`,`label_en`,`label_vi`,`label_km`,`label_ja`,`label_ko`,`sort`,`status`,`remark`)
VALUES
  ('walkin_session_status','0','待服务','Waiting',    'Chờ',    'រង់ចាំ',     '待ち',   '대기',   1,1,'{"c":"#3b82f6","b":"processing"}'),
  ('walkin_session_status','1','服务中','In Service', 'Đang',   'ដំណើរការ',   '進行中', '진행중', 2,1,'{"c":"#f97316","b":"processing"}'),
  ('walkin_session_status','2','待结算','Pending Pay','Chờ TT', 'រង់ចាំ TT',  '精算待ち','정산대기',3,1,'{"c":"#f59e0b","b":"warning"}'),
  ('walkin_session_status','3','已结算','Settled',    'Đã TT',  'បានទូទាត់',  '精算済み','정산완료',4,1,'{"c":"#10b981","b":"success"}'),
  ('walkin_session_status','4','已取消','Cancelled',  'Hủy',    'បោះបង់',     'キャンセル','취소',  5,1,'{"c":"#94a3b8","b":"default"}')
ON DUPLICATE KEY UPDATE
  `remark` = VALUES(`remark`);

-- 修复 walkin_svc_status（服务项进度状态）
INSERT INTO `sys_dict`
  (`dict_type`,`dict_value`,`label_zh`,`label_en`,`label_vi`,`label_km`,`label_ja`,`label_ko`,`sort`,`status`,`remark`)
VALUES
  ('walkin_svc_status','0','待服务','Waiting',   'Chờ',  'រង់ចាំ',   '待ち',   '대기',   1,1,'{"c":"#9ca3af","i":"⏳"}'),
  ('walkin_svc_status','1','服务中','In Service','Đang',  'ដំណើរការ', '進行中', '진행중', 2,1,'{"c":"#f97316","i":"🔄"}'),
  ('walkin_svc_status','2','已完成','Completed', 'Xong', 'បញ្ចប់',   '完了',   '완료',   3,1,'{"c":"#10b981","i":"✅"}')
ON DUPLICATE KEY UPDATE
  `remark` = VALUES(`remark`);

-- 修复 order_status（在线订单状态）
INSERT INTO `sys_dict`
  (`dict_type`,`dict_value`,`label_zh`,`label_en`,`label_vi`,`label_km`,`label_ja`,`label_ko`,`sort`,`status`,`remark`)
VALUES
  ('order_status','0','待支付','Unpaid',     'Chờ TT',  'រង់ចាំ',      '支払待ち',  '결제대기',   1,1,'{"c":"#f59e0b","b":"warning"}'),
  ('order_status','1','待接单','Waiting',    'Chờ',     'រង់ចាំ',      '受注待ち',  '접수대기',   2,1,'{"c":"#3b82f6","b":"processing"}'),
  ('order_status','2','已接单','Accepted',   'Đã nhận', 'ទទួលបាន',     '受注済み',  '접수완료',   3,1,'{"c":"#8b5cf6","b":"processing"}'),
  ('order_status','3','前往中','On the way', 'Đang đến','កំពុងទៅ',     '向かい中',  '이동중',     4,1,'{"c":"#f97316","b":"processing"}'),
  ('order_status','4','已到达','Arrived',    'Đến rồi', 'ដល់ហើយ',     '到着済み',  '도착완료',   5,1,'{"c":"#06b6d4","b":"processing"}'),
  ('order_status','5','服务中','In Service', 'Đang làm','ដំណើរការ',    '施術中',    '시술중',     6,1,'{"c":"#f97316","b":"processing"}'),
  ('order_status','6','已完成','Completed',  'Hoàn tất','បញ្ចប់',      '完了',      '완료',       7,1,'{"c":"#10b981","b":"success"}'),
  ('order_status','7','已取消','Cancelled',  'Đã hủy',  'បោះបង់',      'キャンセル','취소',       8,1,'{"c":"#94a3b8","b":"default"}'),
  ('order_status','8','退款中','Refunding',  'Hoàn tiền','ដំណើរការ HT', '返金中',    '환불중',     9,1,'{"c":"#ec4899","b":"warning"}'),
  ('order_status','9','已退款','Refunded',   'Đã HT',   'បានសង HT',    '返金済み',  '환불완료',  10,1,'{"c":"#6b7280","b":"default"}')
ON DUPLICATE KEY UPDATE
  `remark` = VALUES(`remark`);

