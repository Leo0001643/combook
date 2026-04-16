-- ============================================================
-- migrate_v2_2.sql — 服务项目多语言 & 坐标字段补丁
-- 兼容 MySQL 5.7+ / 8.x，通过存储过程实现幂等性（重复执行无副作用）
-- ============================================================

DELIMITER $$

DROP PROCEDURE IF EXISTS add_col$$
CREATE PROCEDURE add_col(
    IN tbl  VARCHAR(64),
    IN col  VARCHAR(64),
    IN def  TEXT
)
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM   INFORMATION_SCHEMA.COLUMNS
        WHERE  TABLE_SCHEMA = DATABASE()
          AND  TABLE_NAME   = tbl
          AND  COLUMN_NAME  = col
    ) THEN
        SET @sql = CONCAT('ALTER TABLE `', tbl, '` ADD COLUMN `', col, '` ', def);
        PREPARE stmt FROM @sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
    END IF;
END$$

DELIMITER ;

-- ── service_package：多语言名称 ──────────────────────────────────────────────
-- 格式：{"zh":"精油香薰SPA","en":"Aromatherapy SPA","vi":"...","km":"..."}
CALL add_col('service_package', 'names_json',
    'JSON DEFAULT NULL COMMENT \'多语言名称 JSON，键：zh/en/vi/km\' AFTER `name`');

-- ── service_package：补齐 Java 实体对应的其他字段 ───────────────────────────
CALL add_col('service_package', 'original_price',
    'DECIMAL(10,2) DEFAULT NULL COMMENT \'套餐原价（USD）\' AFTER `member_price`');

CALL add_col('service_package', 'current_price',
    'DECIMAL(10,2) DEFAULT NULL COMMENT \'套餐现价（USD）\' AFTER `original_price`');

CALL add_col('service_package', 'tags',
    'VARCHAR(500) DEFAULT NULL COMMENT \'标签 JSON 数组，如[\"热门\",\"新品\"]\' AFTER `description`');

CALL add_col('service_package', 'includes',
    'TEXT DEFAULT NULL COMMENT \'包含项目 JSON 数组\' AFTER `tags`');

CALL add_col('service_package', 'max_persons',
    'INT NOT NULL DEFAULT 1 COMMENT \'服务人数上限\' AFTER `duration`');

CALL add_col('service_package', 'sort_weight',
    'INT NOT NULL DEFAULT 0 COMMENT \'排序权重（越大越靠前）\' AFTER `sort_order`');

CALL add_col('service_package', 'sales_count',
    'INT NOT NULL DEFAULT 0 COMMENT \'销量（含历史）\' AFTER `sold_count`');

CALL add_col('service_package', 'min_age',
    'INT NOT NULL DEFAULT 0 COMMENT \'最低年龄限制（0=不限）\'');

CALL add_col('service_package', 'max_age',
    'INT NOT NULL DEFAULT 0 COMMENT \'最高年龄限制（0=不限）\'');

-- ── order_info：冗余多语言套餐名称 ──────────────────────────────────────────
-- 记录下单时的多语言套餐名，防止套餐更名后历史订单显示错误
CALL add_col('order_info', 'package_names_json',
    'JSON DEFAULT NULL COMMENT \'套餐多语言名称快照 JSON，键：zh/en/vi/km\' AFTER `package_name`');

-- ── 清理临时存储过程 ────────────────────────────────────────────────────────
DROP PROCEDURE IF EXISTS add_col;

SELECT 'migrate_v2_2.sql executed successfully.' AS result;
