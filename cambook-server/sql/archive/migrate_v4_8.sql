-- =============================================================================
-- migrate_v4_8.sql
-- 功能：支持商户编辑平台服务类目（写时复制模式）
--
-- 背景：平台类目（merchant_id = NULL）为所有商户共享，商户不能直接修改。
--       引入 source_category_id 字段，记录私有副本的来源平台类目 ID。
--       商户编辑平台类目时，系统自动克隆一份私有副本（merchant_id = 商户ID），
--       后续列表查询自动用私有副本替换对应的平台版本，对前端透明。
-- =============================================================================

DROP PROCEDURE IF EXISTS _add_source_category_id;
DELIMITER $$
CREATE PROCEDURE _add_source_category_id()
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME   = 'cb_service_category'
          AND COLUMN_NAME  = 'source_category_id'
    ) THEN
        ALTER TABLE `cb_service_category`
            ADD COLUMN `source_category_id` BIGINT NULL
                COMMENT '写时复制来源：若本条为商户私有副本，则记录平台原始类目 ID；平台类目本身为 NULL'
                AFTER `merchant_id`;
    END IF;
END$$
DELIMITER ;
CALL _add_source_category_id();
DROP PROCEDURE IF EXISTS _add_source_category_id;

-- 验证
SELECT COLUMN_NAME, COLUMN_TYPE, IS_NULLABLE, COLUMN_COMMENT
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_NAME   = 'cb_service_category'
  AND COLUMN_NAME  = 'source_category_id';
