-- ================================================================================
-- CamBook 数据库迁移脚本 v4.1
-- 描述：多币种支持 — 全局币种注册表 + 商户币种配置
-- 日期：2026-04-13
-- ================================================================================

-- ── 1. sys_currency：全平台支持的币种注册表 ──────────────────────────────────
CREATE TABLE IF NOT EXISTS `sys_currency` (
    `id`                   BIGINT        NOT NULL AUTO_INCREMENT          COMMENT '主键',
    `currency_code`        VARCHAR(10)   NOT NULL                        COMMENT '货币代码（ISO 4217）：USD / CNY / USDT / PHP / THB / KRW / AED / MYR',
    `currency_name`        VARCHAR(50)   NOT NULL                        COMMENT '货币中文名：美元 / 人民币 / USDT',
    `currency_name_en`     VARCHAR(50)   NOT NULL                        COMMENT '货币英文名：US Dollar / Chinese Yuan',
    `symbol`               VARCHAR(10)   NOT NULL                        COMMENT '货币符号：$ / ¥ / ₱ / ฿ / ₩ / د.إ / RM / ₮',
    `flag`                 VARCHAR(10)                                   COMMENT '国旗 Emoji：🇺🇸 / 🇨🇳 / 🇵🇭 / 🇹🇭 / 🇰🇷 / 🇦🇪 / 🇲🇾',
    `is_crypto`            TINYINT       NOT NULL DEFAULT 0              COMMENT '是否加密货币：0=法币 1=加密货币（USDT等）',
    `rate_to_usd`          DECIMAL(20,8) NOT NULL DEFAULT 1.00000000     COMMENT '对 USD 汇率（1 单位本币 = X USD），USDT=1',
    `rate_update_time`     DATETIME                                      COMMENT '汇率最后更新时间',
    `decimal_places`       TINYINT       NOT NULL DEFAULT 2              COMMENT '小数位数（KRW=0, USDT=6）',
    `sort_order`           INT           NOT NULL DEFAULT 0              COMMENT '排序（越小越靠前）',
    `status`               TINYINT       NOT NULL DEFAULT 1              COMMENT '状态：0=停用 1=启用',
    `remark`               VARCHAR(200)                                  COMMENT '备注',
    `create_time`          DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `update_time`          DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_currency_code` (`currency_code`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci
  COMMENT = '币种注册表：平台支持的所有结算货币及实时汇率';

-- ── 2. 初始化内置币种数据 ────────────────────────────────────────────────────
INSERT INTO `sys_currency`
    (`currency_code`, `currency_name`, `currency_name_en`, `symbol`, `flag`, `is_crypto`, `rate_to_usd`, `decimal_places`, `sort_order`, `status`, `remark`)
VALUES
    ('USD',  '美元',       'US Dollar',         '$',    '🇺🇸', 0, 1.00000000,    2, 1,  1, '平台基准货币'),
    ('USDT', 'USDT',      'Tether USD',         '₮',    '💵', 1, 1.00000000,    6, 2,  1, '加密稳定币，1:1 锚定 USD'),
    ('CNY',  '人民币',     'Chinese Yuan',       '¥',    '🇨🇳', 0, 0.13800000,    2, 3,  1, '中国人民币'),
    ('PHP',  '菲律宾比索', 'Philippine Peso',    '₱',    '🇵🇭', 0, 0.01700000,    2, 4,  1, '菲律宾官方货币'),
    ('THB',  '泰铢',       'Thai Baht',          '฿',    '🇹🇭', 0, 0.02800000,    2, 5,  1, '泰国官方货币'),
    ('KRW',  '韩元',       'Korean Won',         '₩',    '🇰🇷', 0, 0.00073000,    0, 6,  1, '韩国官方货币，无小数'),
    ('AED',  '迪拜迪拉姆', 'UAE Dirham',         'د.إ',  '🇦🇪', 0, 0.27200000,    2, 7,  1, '阿联酋官方货币'),
    ('MYR',  '马来西亚林吉特', 'Malaysian Ringgit', 'RM', '🇲🇾', 0, 0.22000000,   2, 8,  1, '马来西亚官方货币'),
    ('KHR',  '柬埔寨瑞尔', 'Cambodian Riel',     '៛',    '🇰🇭', 0, 0.00024000,    0, 9,  1, '柬埔寨官方货币'),
    ('SGD',  '新加坡元',   'Singapore Dollar',   'S$',   '🇸🇬', 0, 0.74000000,    2, 10, 1, '新加坡官方货币'),
    ('EUR',  '欧元',       'Euro',               '€',    '🇪🇺', 0, 1.08000000,    2, 11, 1, '欧元区货币'),
    ('GBP',  '英镑',       'British Pound',       '£',    '🇬🇧', 0, 1.26000000,    2, 12, 1, '英国官方货币'),
    ('JPY',  '日元',       'Japanese Yen',        '¥',    '🇯🇵', 0, 0.00660000,    0, 13, 1, '日本官方货币'),
    ('BTC',  'Bitcoin',   'Bitcoin',             '₿',    '🪙',  1, 65000.00000000, 8, 20, 1, '比特币，汇率每日更新'),
    ('ETH',  'Ethereum',  'Ethereum',            'Ξ',    '💎',  1, 3200.00000000,  8, 21, 1, '以太坊，汇率每日更新');

-- ── 3. cb_merchant_currency：商户启用的币种配置 ──────────────────────────────
CREATE TABLE IF NOT EXISTS `cb_merchant_currency` (
    `id`             BIGINT        NOT NULL AUTO_INCREMENT          COMMENT '主键',
    `merchant_id`    BIGINT        NOT NULL                        COMMENT '商户 ID，关联 cb_merchant.id',
    `currency_code`  VARCHAR(10)   NOT NULL                        COMMENT '货币代码，关联 sys_currency.currency_code',
    `is_default`     TINYINT       NOT NULL DEFAULT 0              COMMENT '是否默认收款币种：0=否 1=是（每个商户只能有一个默认）',
    `custom_rate`    DECIMAL(20,8)                                 COMMENT '商户自定义汇率（优先级高于 sys_currency.rate_to_usd，为空则用全局汇率）',
    `display_name`   VARCHAR(50)                                   COMMENT '商户自定义显示名（如 空=使用全局名）',
    `sort_order`     INT           NOT NULL DEFAULT 0              COMMENT '商户侧排序',
    `status`         TINYINT       NOT NULL DEFAULT 1              COMMENT '状态：0=停用 1=启用',
    `create_time`    DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `update_time`    DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_merchant_currency` (`merchant_id`, `currency_code`),
    KEY `idx_merchant_id` (`merchant_id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci
  COMMENT = '商户币种配置：每家商户可独立启用不同结算货币，支持自定义汇率';

-- ── 4. 补充 cb_payment_record 字段（若已存在则跳过）──────────────────────────
-- 支付流水已有 currency / exchange_rate / usd_amount，无需新增
-- 仅补充 original_amount（本币金额）字段的注释统一
-- ALTER TABLE `cb_payment_record` 已在 migrate_v4_0.sql 定义，此处无需重复

-- ── 5. 汇率历史记录表（支持汇率走势查询）────────────────────────────────────
CREATE TABLE IF NOT EXISTS `sys_currency_rate_log` (
    `id`             BIGINT        NOT NULL AUTO_INCREMENT          COMMENT '主键',
    `currency_code`  VARCHAR(10)   NOT NULL                        COMMENT '货币代码',
    `rate_to_usd`    DECIMAL(20,8) NOT NULL                        COMMENT '对 USD 汇率',
    `source`         VARCHAR(50)                                   COMMENT '汇率来源：manual=手动 / api=自动拉取',
    `create_time`    DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '记录时间',
    PRIMARY KEY (`id`),
    KEY `idx_currency_time` (`currency_code`, `create_time`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci
  COMMENT = '汇率变动历史：支持查看某币种汇率走势';
