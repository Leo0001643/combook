-- ═══════════════════════════════════════════════════════════════════════════
-- Migration v5.5 — cb_order_item 多技师并行服务支持
--
-- 核心设计：
--   一笔订单（cb_order）属于一个客户的一次服务 session
--   一个 session 中可以有多个技师同时服务不同的服务项目（并行）
--   每个服务项（cb_order_item）独立关联一名技师，并独立跟踪完成状态
--
-- 变更：cb_order_item 新增两列
--   technician_id  — 执行该项目的技师 ID（与 cb_technician.id 关联）
--   tech_income    — 该项目技师实际收入（扣佣后），结算时写入
-- ═══════════════════════════════════════════════════════════════════════════

SET NAMES utf8mb4;

-- ── 幂等：仅在列不存在时才 ADD ──────────────────────────────────────────────

-- technician_id
SET @col_exists = (
    SELECT COUNT(*) FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME   = 'cb_order_item'
      AND COLUMN_NAME  = 'technician_id'
);
SET @ddl = IF(@col_exists = 0,
    'ALTER TABLE cb_order_item
     ADD COLUMN technician_id BIGINT NULL
         COMMENT ''执行该服务项的技师ID（关联 cb_technician.id）''
         AFTER order_id',
    'SELECT ''technician_id already exists'' AS info'
);
PREPARE stmt FROM @ddl; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- tech_income
SET @col_exists2 = (
    SELECT COUNT(*) FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME   = 'cb_order_item'
      AND COLUMN_NAME  = 'tech_income'
);
SET @ddl2 = IF(@col_exists2 = 0,
    'ALTER TABLE cb_order_item
     ADD COLUMN tech_income DECIMAL(10,2) NULL
         COMMENT ''技师实际收入（含佣金比例，结算时写入）''
         AFTER svc_status',
    'SELECT ''tech_income already exists'' AS info'
);
PREPARE stmt2 FROM @ddl2; EXECUTE stmt2; DEALLOCATE PREPARE stmt2;

-- ── 索引（加速按技师查询服务项）────────────────────────────────────────────
SET @idx_exists = (
    SELECT COUNT(*) FROM information_schema.STATISTICS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME   = 'cb_order_item'
      AND INDEX_NAME   = 'idx_order_item_tech'
);
SET @ddl3 = IF(@idx_exists = 0,
    'ALTER TABLE cb_order_item
     ADD INDEX idx_order_item_tech (technician_id, deleted)',
    'SELECT ''idx_order_item_tech already exists'' AS info'
);
PREPARE stmt3 FROM @ddl3; EXECUTE stmt3; DEALLOCATE PREPARE stmt3;

-- ── 回填：将 cb_order.technician_id 同步到其服务项（历史数据兼容）──────────
-- 对于旧的单项订单（items 已存在但无 technician_id），用订单级别的技师 ID 回填
UPDATE cb_order_item oi
JOIN   cb_order o ON o.id = oi.order_id AND o.deleted = 0
SET    oi.technician_id = o.technician_id
WHERE  oi.technician_id IS NULL
  AND  o.technician_id  IS NOT NULL
  AND  oi.deleted = 0;

SELECT CONCAT(
    'Migration v5.5 complete. ',
    ROW_COUNT(), ' order_item rows backfilled with technician_id.'
) AS result;
