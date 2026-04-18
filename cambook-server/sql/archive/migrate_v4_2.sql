-- ================================================================================
-- CamBook 数据库迁移脚本 v4.2
-- 描述：技师工资结算体系（每笔/日结/周结/月结）+ 越南盾 VND 币种
-- 日期：2026-04-13
-- ================================================================================

-- ── 1. 补充越南盾到全局币种表 ────────────────────────────────────────────────
INSERT IGNORE INTO `sys_currency`
    (`currency_code`, `currency_name`, `currency_name_en`, `symbol`, `flag`, `is_crypto`, `rate_to_usd`, `decimal_places`, `sort_order`, `status`, `remark`)
VALUES
    ('VND', '越南盾', 'Vietnamese Dong', '₫', '🇻🇳', 0, 0.000039000, 0, 9, 1, '越南官方货币，无小数位');

-- ── 2. 技师表扩展结算配置字段 ────────────────────────────────────────────────
-- settlement_mode: 0=每笔结算 1=日结 2=周结 3=月结
-- commission_type: 0=按比例提成 1=固定金额/单
-- 注意：ADD COLUMN IF NOT EXISTS 仅 MySQL 8.0.3+ 支持，此处改为标准写法。
-- 若字段已存在会报错，重复执行时请跳过或手动注释掉本段。
ALTER TABLE `cb_technician`
    ADD COLUMN `settlement_mode`     TINYINT      NOT NULL DEFAULT 3     COMMENT '结算方式：0=每笔结算 1=日结 2=周结 3=月结',
    ADD COLUMN `commission_type`     TINYINT      NOT NULL DEFAULT 0     COMMENT '提成类型：0=按比例(%) 1=固定金额/单',
    ADD COLUMN `commission_rate`     DECIMAL(8,2) NOT NULL DEFAULT 60.00 COMMENT '提成比例(%) 或 固定金额/单（取决于 commission_type）',
    ADD COLUMN `commission_currency` VARCHAR(10)  NOT NULL DEFAULT 'USD' COMMENT '固定金额类型时的结算币种';

-- ── 3. 技师结算批次主表 ──────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `cb_technician_settlement` (
    `id`                BIGINT        NOT NULL AUTO_INCREMENT COMMENT '主键',
    `merchant_id`       BIGINT        NOT NULL               COMMENT '所属商户 ID',
    `technician_id`     BIGINT        NOT NULL               COMMENT '技师 ID',
    `technician_name`   VARCHAR(50)                          COMMENT '技师姓名（冗余，防止联表）',
    `settlement_no`     VARCHAR(32)   NOT NULL               COMMENT '结算单号（唯一）',
    `settlement_mode`   TINYINT       NOT NULL               COMMENT '结算方式：0=每笔 1=日结 2=周结 3=月结',
    `period_start`      DATE                                 COMMENT '结算周期开始日期',
    `period_end`        DATE                                 COMMENT '结算周期结束日期',
    `order_count`       INT           NOT NULL DEFAULT 0     COMMENT '本批次订单数量',
    `total_revenue`     DECIMAL(12,2) NOT NULL DEFAULT 0     COMMENT '本批次总营业额',
    `commission_rate`   DECIMAL(8,2)  NOT NULL DEFAULT 0     COMMENT '提成比例(%) 或 固定金额',
    `commission_type`   TINYINT       NOT NULL DEFAULT 0     COMMENT '0=按比例 1=固定',
    `commission_amount` DECIMAL(12,2) NOT NULL DEFAULT 0     COMMENT '基础提成金额',
    `bonus_amount`      DECIMAL(12,2) NOT NULL DEFAULT 0     COMMENT '奖励金额（好评奖、达标奖等）',
    `deduction_amount`  DECIMAL(12,2) NOT NULL DEFAULT 0     COMMENT '扣款金额（违规、损耗等）',
    `final_amount`      DECIMAL(12,2) NOT NULL DEFAULT 0     COMMENT '最终应付金额 = 提成+奖励-扣款',
    `currency_code`     VARCHAR(10)   NOT NULL DEFAULT 'USD' COMMENT '结算币种',
    `currency_symbol`   VARCHAR(10)                          COMMENT '货币符号（冗余展示）',
    `payment_method`    VARCHAR(30)                          COMMENT '支付方式：cash/bank/usdt/wechat/...',
    `payment_ref`       VARCHAR(100)                         COMMENT '转账/流水号',
    `status`            TINYINT       NOT NULL DEFAULT 0     COMMENT '状态：0=待结算 1=已结算 2=争议/暂扣',
    `paid_time`         DATETIME                             COMMENT '实际打款时间',
    `remark`            VARCHAR(500)                         COMMENT '结算备注',
    `operator`          VARCHAR(50)                          COMMENT '操作人',
    `create_time`       DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `update_time`       DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_settlement_no` (`settlement_no`),
    KEY `idx_merchant_tech`  (`merchant_id`, `technician_id`),
    KEY `idx_status`         (`status`),
    KEY `idx_period`         (`period_start`, `period_end`),
    KEY `idx_mode`           (`settlement_mode`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci
  COMMENT = '技师结算批次：支持每笔/日结/周结/月结四种方式';

-- ── 4. 结算明细表：记录哪些订单被纳入本次结算 ───────────────────────────────
CREATE TABLE IF NOT EXISTS `cb_technician_settlement_item` (
    `id`                BIGINT        NOT NULL AUTO_INCREMENT COMMENT '主键',
    `settlement_id`     BIGINT        NOT NULL               COMMENT '关联结算批次 ID',
    `order_id`          BIGINT        NOT NULL               COMMENT '关联订单 ID',
    `order_no`          VARCHAR(32)                          COMMENT '订单号（冗余）',
    `service_name`      VARCHAR(100)                         COMMENT '服务项目名称（冗余）',
    `order_amount`      DECIMAL(12,2)                        COMMENT '订单金额',
    `commission_rate`   DECIMAL(8,2)                         COMMENT '本单适用提成比例/金额',
    `commission_amount` DECIMAL(12,2)                        COMMENT '本单提成金额',
    `service_time`      DATETIME                             COMMENT '服务时间',
    PRIMARY KEY (`id`),
    KEY `idx_settlement_id` (`settlement_id`),
    KEY `idx_order_id`      (`order_id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci
  COMMENT = '技师结算明细：本次结算包含的订单及各自提成';

-- ── 5. 结算配置模板表（可选：商户级别默认提成规则）────────────────────────────
CREATE TABLE IF NOT EXISTS `cb_commission_rule` (
    `id`               BIGINT        NOT NULL AUTO_INCREMENT COMMENT '主键',
    `merchant_id`      BIGINT        NOT NULL               COMMENT '商户 ID（0=平台默认）',
    `rule_name`        VARCHAR(50)   NOT NULL               COMMENT '规则名称',
    `settlement_mode`  TINYINT       NOT NULL DEFAULT 3     COMMENT '默认结算方式',
    `commission_type`  TINYINT       NOT NULL DEFAULT 0     COMMENT '0=按比例 1=固定金额',
    `commission_value` DECIMAL(8,2)  NOT NULL DEFAULT 60    COMMENT '提成比例(%) 或 固定金额',
    `currency_code`    VARCHAR(10)   NOT NULL DEFAULT 'USD' COMMENT '固定金额时的币种',
    `bonus_threshold`  DECIMAL(12,2)                        COMMENT '奖励达标门槛（月营业额超过此值触发奖励）',
    `bonus_amount`     DECIMAL(12,2)                        COMMENT '奖励金额',
    `is_default`       TINYINT       NOT NULL DEFAULT 0     COMMENT '是否商户默认规则',
    `status`           TINYINT       NOT NULL DEFAULT 1,
    `remark`           VARCHAR(200),
    `create_time`      DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `update_time`      DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_merchant` (`merchant_id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci
  COMMENT = '提成规则配置：商户可设置不同技师群体的提成模板';
