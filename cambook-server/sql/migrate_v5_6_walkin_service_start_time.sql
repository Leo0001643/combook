-- ═══════════════════════════════════════════════════════════════════════════
-- Migration v5.6 — cb_walkin_session 服务开始时间支持
--
-- 新增 service_start_time 列，记录技师实际开始服务的时间（Unix 秒）。
-- 技师在 APP 点击"开始服务"时写入，用于专注模式页面从正确时间点开始计时。
-- ═══════════════════════════════════════════════════════════════════════════

SET NAMES utf8mb4;

SET @col_exists = (
    SELECT COUNT(*) FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME   = 'cb_walkin_session'
      AND COLUMN_NAME  = 'service_start_time'
);
SET @ddl = IF(@col_exists = 0,
    'ALTER TABLE cb_walkin_session
     ADD COLUMN service_start_time BIGINT NULL
         COMMENT ''技师开始服务的时间戳（Unix 秒），点击"开始服务"时写入''
         AFTER check_in_time',
    'SELECT ''service_start_time already exists'' AS info'
);
PREPARE stmt FROM @ddl; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SELECT 'Migration v5.6 complete: cb_walkin_session.service_start_time added.' AS result;
