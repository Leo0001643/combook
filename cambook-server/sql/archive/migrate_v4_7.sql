-- =============================================================================
-- migrate_v4_7.sql
-- 修复：sys_dict_type / sys_dict / sys_config 缺少 deleted 逻辑删除列
--
-- 根因：三张系统配置表在建表时未加 deleted 列，但对应 Java 实体均继承
--       BaseEntity（含 @TableLogic），导致 MyBatis-Plus 自动追加
--       AND deleted = 0 条件，引发 "Unknown column 'deleted'" 错误，
--       前端字典管理页面因此始终显示空数据。
--
-- 幂等设计：通过 information_schema 检查列是否存在，安全重复执行。
-- =============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. sys_dict_type 添加 deleted 列
-- ─────────────────────────────────────────────────────────────────────────────
DROP PROCEDURE IF EXISTS _add_deleted_dict_type;
DELIMITER $$
CREATE PROCEDURE _add_deleted_dict_type()
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME   = 'sys_dict_type'
          AND COLUMN_NAME  = 'deleted'
    ) THEN
        ALTER TABLE `sys_dict_type`
            ADD COLUMN `deleted` TINYINT NOT NULL DEFAULT 0
                COMMENT '逻辑删除：0=正常 1=已删除';
    END IF;
END$$
DELIMITER ;
CALL _add_deleted_dict_type();
DROP PROCEDURE IF EXISTS _add_deleted_dict_type;

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. sys_dict 添加 deleted 列
-- ─────────────────────────────────────────────────────────────────────────────
DROP PROCEDURE IF EXISTS _add_deleted_dict;
DELIMITER $$
CREATE PROCEDURE _add_deleted_dict()
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME   = 'sys_dict'
          AND COLUMN_NAME  = 'deleted'
    ) THEN
        ALTER TABLE `sys_dict`
            ADD COLUMN `deleted` TINYINT NOT NULL DEFAULT 0
                COMMENT '逻辑删除：0=正常 1=已删除';
    END IF;
END$$
DELIMITER ;
CALL _add_deleted_dict();
DROP PROCEDURE IF EXISTS _add_deleted_dict;

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. sys_config 添加 deleted 列
-- ─────────────────────────────────────────────────────────────────────────────
DROP PROCEDURE IF EXISTS _add_deleted_config;
DELIMITER $$
CREATE PROCEDURE _add_deleted_config()
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME   = 'sys_config'
          AND COLUMN_NAME  = 'deleted'
    ) THEN
        ALTER TABLE `sys_config`
            ADD COLUMN `deleted` TINYINT NOT NULL DEFAULT 0
                COMMENT '逻辑删除：0=正常 1=已删除';
    END IF;
END$$
DELIMITER ;
CALL _add_deleted_config();
DROP PROCEDURE IF EXISTS _add_deleted_config;

-- ─────────────────────────────────────────────────────────────────────────────
-- 4. sys_config 添加 config_name 列（SysConfig 实体字段 configName 需对应）
-- ─────────────────────────────────────────────────────────────────────────────
DROP PROCEDURE IF EXISTS _add_config_name;
DELIMITER $$
CREATE PROCEDURE _add_config_name()
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME   = 'sys_config'
          AND COLUMN_NAME  = 'config_name'
    ) THEN
        ALTER TABLE `sys_config`
            ADD COLUMN `config_name` VARCHAR(200) NULL
                COMMENT '配置项名称（中文可读）'
                AFTER `config_group`;
    END IF;
END$$
DELIMITER ;
CALL _add_config_name();
DROP PROCEDURE IF EXISTS _add_config_name;

-- ─────────────────────────────────────────────────────────────────────────────
-- 验证
-- ─────────────────────────────────────────────────────────────────────────────
SELECT
    TABLE_NAME,
    COLUMN_NAME,
    COLUMN_TYPE,
    COLUMN_DEFAULT,
    IS_NULLABLE
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_NAME IN ('sys_dict_type', 'sys_dict', 'sys_config')
  AND COLUMN_NAME IN ('deleted', 'config_name')
ORDER BY TABLE_NAME, COLUMN_NAME;
