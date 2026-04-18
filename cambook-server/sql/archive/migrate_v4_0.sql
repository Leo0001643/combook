-- ================================================================================
-- CamBook 数据库迁移脚本 v4.0
-- 描述：新增散客接待、多支付、派车记录、财务管理核心表
-- 版本：v4.0.0
-- 日期：2026-04-13
-- ================================================================================

-- ── 1. cb_order 扩展：支持散客/在线两种客户类型 ──────────────────────────────
ALTER TABLE `cb_order`
    ADD COLUMN `order_type`    TINYINT      NOT NULL DEFAULT 1  COMMENT '订单类型：1=在线预约 2=散客上门' AFTER `id`,
    ADD COLUMN `session_id`    BIGINT                           COMMENT '散客接待 session ID（order_type=2 时有值），关联 cb_walkin_session.id' AFTER `order_type`,
    ADD COLUMN `wristband_no`  VARCHAR(20)                      COMMENT '手环编号（散客上门时的识别号，如 0928）' AFTER `session_id`;

-- ── 2. cb_walkin_session：散客接待（手环）Session ──────────────────────────────
CREATE TABLE IF NOT EXISTS `cb_walkin_session` (
    `id`              BIGINT        NOT NULL AUTO_INCREMENT          COMMENT '主键',
    `session_no`      VARCHAR(32)   NOT NULL                        COMMENT '接待流水号（系统生成，格式 WK+yyyyMMdd+4位序号）',
    `wristband_no`    VARCHAR(20)   NOT NULL                        COMMENT '手环编号（前台发放，当日唯一，如 0928）',
    `merchant_id`     BIGINT        NOT NULL                        COMMENT '所属商户 ID',
    `member_id`       BIGINT                                        COMMENT '关联会员 ID（若客户已注册则关联，散客可为空）',
    `member_name`     VARCHAR(100)                                  COMMENT '客户姓名/称呼（散客登记名，可为空）',
    `member_mobile`   VARCHAR(30)                                   COMMENT '客户手机号（散客登记，可为空）',
    `staff_id`        BIGINT                                        COMMENT '接待员工 ID',
    `status`          TINYINT       NOT NULL DEFAULT 0              COMMENT '状态：0=接待中 1=服务中 2=待结算 3=已结算 4=已取消',
    `total_amount`    DECIMAL(10,2) NOT NULL DEFAULT 0.00           COMMENT '消费总金额',
    `paid_amount`     DECIMAL(10,2) NOT NULL DEFAULT 0.00           COMMENT '已结算金额',
    `remark`          VARCHAR(500)                                  COMMENT '接待备注',
    `check_in_time`   DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '到店时间',
    `check_out_time`  DATETIME                                      COMMENT '离店/结算时间',
    `create_time`     DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `update_time`     DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_session_no` (`session_no`),
    KEY `idx_wristband`   (`merchant_id`, `wristband_no`, `check_in_time`),
    KEY `idx_merchant_status` (`merchant_id`, `status`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci
  COMMENT = '散客接待 Session：一次到店对应一个 session，手环是识别载体';

-- ── 3. cb_payment_record：支付流水（支持多种支付方式混合结算）─────────────────
CREATE TABLE IF NOT EXISTS `cb_payment_record` (
    `id`              BIGINT        NOT NULL AUTO_INCREMENT          COMMENT '主键',
    `merchant_id`     BIGINT        NOT NULL                        COMMENT '所属商户 ID',
    `session_id`      BIGINT                                        COMMENT '关联散客 session ID（散客结算时有值）',
    `order_id`        BIGINT                                        COMMENT '关联订单 ID（在线预约时有值）',
    `pay_method`      TINYINT       NOT NULL                        COMMENT '支付方式：1=现金 2=微信 3=支付宝 4=银行转账 5=USDT 6=ABA Pay 7=Wing 8=其它',
    `amount`          DECIMAL(10,2) NOT NULL                        COMMENT '本次支付金额',
    `currency`        VARCHAR(10)   NOT NULL DEFAULT 'USD'          COMMENT '货币类型：USD/CNY/KHR',
    `exchange_rate`   DECIMAL(10,4) NOT NULL DEFAULT 1.0000         COMMENT '对 USD 汇率',
    `usd_amount`      DECIMAL(10,2) NOT NULL                        COMMENT '折算 USD 金额',
    `reference_no`    VARCHAR(100)                                  COMMENT '支付参考号/交易流水（转账凭证号）',
    `remark`          VARCHAR(200)                                  COMMENT '备注',
    `operator_id`     BIGINT                                        COMMENT '操作员工 ID',
    `pay_time`        DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '收款时间',
    `create_time`     DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_session`   (`session_id`),
    KEY `idx_order`     (`order_id`),
    KEY `idx_merchant_time` (`merchant_id`, `pay_time`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci
  COMMENT = '支付流水：支持多种支付方式，一次结算可拆分多笔支付';

-- ── 4. cb_vehicle_dispatch：派车记录 ──────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `cb_vehicle_dispatch` (
    `id`              BIGINT        NOT NULL AUTO_INCREMENT          COMMENT '主键',
    `dispatch_no`     VARCHAR(32)   NOT NULL                        COMMENT '派车单号',
    `merchant_id`     BIGINT        NOT NULL                        COMMENT '所属商户 ID',
    `vehicle_id`      BIGINT        NOT NULL                        COMMENT '车辆 ID，关联 cb_vehicle.id',
    `vehicle_plate`   VARCHAR(30)   NOT NULL                        COMMENT '车牌号快照',
    `driver_id`       BIGINT                                        COMMENT '驾驶员员工 ID',
    `driver_name`     VARCHAR(50)                                   COMMENT '驾驶员姓名快照',
    `purpose`         TINYINT       NOT NULL DEFAULT 1              COMMENT '用途：1=接送客户 2=采购 3=员工通勤 4=业务出行 5=其它',
    `destination`     VARCHAR(200)                                  COMMENT '目的地',
    `passenger_info`  VARCHAR(200)                                  COMMENT '乘客/随行人员信息',
    `order_id`        BIGINT                                        COMMENT '关联订单 ID（接送客户时）',
    `depart_time`     DATETIME                                      COMMENT '出发时间',
    `return_time`     DATETIME                                      COMMENT '返回时间',
    `mileage`         DECIMAL(8,2)                                  COMMENT '行驶里程（km）',
    `fuel_cost`       DECIMAL(8,2)                                  COMMENT '油费（USD）',
    `other_cost`      DECIMAL(8,2)                                  COMMENT '其它费用（USD）',
    `total_cost`      DECIMAL(8,2)  NOT NULL DEFAULT 0.00           COMMENT '本次用车总费用（USD）',
    `status`          TINYINT       NOT NULL DEFAULT 0              COMMENT '状态：0=待出发 1=行程中 2=已返回 3=已取消',
    `remark`          VARCHAR(500)                                  COMMENT '备注',
    `operator_id`     BIGINT                                        COMMENT '派车操作人 ID',
    `create_time`     DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `update_time`     DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_dispatch_no` (`dispatch_no`),
    KEY `idx_vehicle`   (`vehicle_id`, `create_time`),
    KEY `idx_driver`    (`driver_id`),
    KEY `idx_merchant`  (`merchant_id`, `create_time`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci
  COMMENT = '派车记录：记录每次车辆使用情况，支持多维度查询';

-- ── 5. cb_finance_expense：支出记录 ───────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `cb_finance_expense` (
    `id`              BIGINT        NOT NULL AUTO_INCREMENT          COMMENT '主键',
    `merchant_id`     BIGINT        NOT NULL                        COMMENT '所属商户 ID',
    `expense_no`      VARCHAR(32)   NOT NULL                        COMMENT '支出单号',
    `category`        TINYINT       NOT NULL                        COMMENT '支出类型：1=店租/场地 2=车辆费用 3=水电费 4=员工工资 5=采购进货 6=营销推广 7=设备维修 8=其它',
    `amount`          DECIMAL(10,2) NOT NULL                        COMMENT '支出金额（USD）',
    `currency`        VARCHAR(10)   NOT NULL DEFAULT 'USD'          COMMENT '原始货币',
    `exchange_rate`   DECIMAL(10,4) NOT NULL DEFAULT 1.0000         COMMENT '汇率',
    `usd_amount`      DECIMAL(10,2) NOT NULL                        COMMENT '折算 USD 金额',
    `pay_method`      TINYINT       NOT NULL DEFAULT 1              COMMENT '支付方式：1=现金 2=微信 3=支付宝 4=银行 5=USDT 8=其它',
    `title`           VARCHAR(200)  NOT NULL                        COMMENT '支出标题/摘要',
    `description`     VARCHAR(500)                                  COMMENT '详细说明',
    `voucher_images`  TEXT                                          COMMENT '凭证图片 URL（JSON 数组）',
    `expense_date`    DATE          NOT NULL                        COMMENT '支出日期',
    `operator_id`     BIGINT                                        COMMENT '经办人员工 ID',
    `approver_id`     BIGINT                                        COMMENT '审核人 ID',
    `status`          TINYINT       NOT NULL DEFAULT 1              COMMENT '状态：0=草稿 1=已确认 2=已作废',
    `create_time`     DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `update_time`     DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_expense_no` (`expense_no`),
    KEY `idx_merchant_date` (`merchant_id`, `expense_date`),
    KEY `idx_category`      (`merchant_id`, `category`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci
  COMMENT = '支出记录：覆盖店租、车辆、水电、工资、采购、营销等全类目';

-- ── 6. cb_finance_salary：薪资单 ──────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `cb_finance_salary` (
    `id`              BIGINT        NOT NULL AUTO_INCREMENT          COMMENT '主键',
    `merchant_id`     BIGINT        NOT NULL                        COMMENT '所属商户 ID',
    `salary_month`    VARCHAR(7)    NOT NULL                        COMMENT '薪资月份（格式 yyyy-MM）',
    `staff_id`        BIGINT                                        COMMENT '员工 ID（关联 sys_user 或技师）',
    `staff_type`      TINYINT       NOT NULL DEFAULT 1              COMMENT '人员类型：1=员工 2=技师',
    `staff_name`      VARCHAR(50)   NOT NULL                        COMMENT '姓名快照',
    `base_salary`     DECIMAL(10,2) NOT NULL DEFAULT 0.00           COMMENT '基本工资（USD）',
    `commission`      DECIMAL(10,2) NOT NULL DEFAULT 0.00           COMMENT '提成金额（USD，技师按订单分成）',
    `bonus`           DECIMAL(10,2) NOT NULL DEFAULT 0.00           COMMENT '绩效奖金（USD）',
    `deduction`       DECIMAL(10,2) NOT NULL DEFAULT 0.00           COMMENT '扣款（USD，迟到/违规等）',
    `total_amount`    DECIMAL(10,2) NOT NULL DEFAULT 0.00           COMMENT '实发工资（USD，= base_salary + commission + bonus - deduction）',
    `order_count`     INT           NOT NULL DEFAULT 0              COMMENT '本月完成订单数（技师）',
    `order_revenue`   DECIMAL(10,2) NOT NULL DEFAULT 0.00           COMMENT '本月服务营收（技师）',
    `pay_method`      TINYINT                                       COMMENT '发薪方式：1=现金 2=银行 3=USDT',
    `pay_time`        DATETIME                                      COMMENT '实际发薪时间',
    `status`          TINYINT       NOT NULL DEFAULT 0              COMMENT '状态：0=待发放 1=已发放 2=已作废',
    `remark`          VARCHAR(300)                                  COMMENT '备注',
    `create_time`     DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `update_time`     DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_merchant_month` (`merchant_id`, `salary_month`),
    KEY `idx_staff`          (`staff_id`, `staff_type`, `salary_month`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci
  COMMENT = '薪资单：覆盖员工工资和技师提成，支持按月汇总发放';
