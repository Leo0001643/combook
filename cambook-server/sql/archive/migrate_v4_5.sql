-- ══════════════════════════════════════════════════════════════════════════════
-- Migration v4.5 — 技师表字段补全
--
-- 补充 cb_technician 缺失的业务字段：
--   1. video_url           展示视频
--   2. settlement_mode     结算方式
--   3. commission_type     提成类型（按比例 / 固定金额）
--   4. commission_rate_pct 按比例提成百分比
--   5. commission_currency 固定金额结算币种
--
-- ⚠️ MySQL 不支持 ADD COLUMN IF NOT EXISTS，改用存储过程+information_schema
--    实现幂等执行（可安全重复运行，已存在的字段自动跳过）
-- ══════════════════════════════════════════════════════════════════════════════

-- 执行前请先备份数据库！

DROP PROCEDURE IF EXISTS _add_col;

DELIMITER $$

CREATE PROCEDURE _add_col(
    IN p_table  VARCHAR(64),
    IN p_col    VARCHAR(64),
    IN p_ddl    TEXT
)
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME   = p_table
          AND COLUMN_NAME  = p_col
    ) THEN
        SET @sql = CONCAT('ALTER TABLE `', p_table, '` ADD COLUMN ', p_ddl);
        PREPARE stmt FROM @sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
        SELECT CONCAT('✅ 已添加字段: ', p_table, '.', p_col) AS result;
    ELSE
        SELECT CONCAT('⏭️  字段已存在，跳过: ', p_table, '.', p_col) AS result;
    END IF;
END$$

DELIMITER ;

-- ── 逐列幂等添加 ─────────────────────────────────────────────────────────────

CALL _add_col('cb_technician', 'video_url',
    "`video_url` VARCHAR(500) NULL COMMENT '展示视频 URL' AFTER `photos`");

CALL _add_col('cb_technician', 'settlement_mode',
    "`settlement_mode` TINYINT(1) NOT NULL DEFAULT 3 COMMENT '结算方式: 0每笔 1日结 2周结 3月结' AFTER `commission_rate`");

CALL _add_col('cb_technician', 'commission_type',
    "`commission_type` TINYINT(1) NOT NULL DEFAULT 0 COMMENT '提成类型: 0按比例 1固定金额' AFTER `settlement_mode`");

CALL _add_col('cb_technician', 'commission_rate_pct',
    "`commission_rate_pct` DECIMAL(5,2) NULL COMMENT '按比例提成百分比(%)' AFTER `commission_type`");

CALL _add_col('cb_technician', 'commission_currency',
    "`commission_currency` VARCHAR(10) NULL COMMENT '固定金额结算币种(USD/CNY/USDT…)' AFTER `commission_rate_pct`");

-- ── 清理临时存储过程 ─────────────────────────────────────────────────────────
DROP PROCEDURE IF EXISTS _add_col;

SELECT '✅ Migration v4.5 执行完成：cb_technician 字段补全' AS result;
