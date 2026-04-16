-- ============================================================
-- CamBook V2.1 迁移脚本（兼容 MySQL 8.x）
-- ============================================================
USE cambook;

DROP PROCEDURE IF EXISTS add_col;
DELIMITER $$
CREATE PROCEDURE add_col(
    tbl VARCHAR(64), col VARCHAR(64), definition TEXT)
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = 'cambook' AND TABLE_NAME = tbl AND COLUMN_NAME = col
  ) THEN
    SET @sql = CONCAT('ALTER TABLE `', tbl, '` ADD COLUMN `', col, '` ', definition);
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
  END IF;
END$$
DELIMITER ;

-- ① member_info 补全缺失列
CALL add_col('member_info','total_points',           'INT NOT NULL DEFAULT 0 COMMENT ''历史累计积分'' AFTER `points`');
CALL add_col('member_info','membership_expire_time',  'DATETIME DEFAULT NULL COMMENT ''付费会员到期时间'' AFTER `total_points`');
CALL add_col('member_info','completed_orders',        'INT NOT NULL DEFAULT 0 COMMENT ''累计完成订单数'' AFTER `total_orders`');
CALL add_col('member_info','cancel_count',            'INT NOT NULL DEFAULT 0 COMMENT ''取消次数'' AFTER `completed_orders`');
CALL add_col('member_info','last_order_time',         'DATETIME DEFAULT NULL COMMENT ''最近下单时间'' AFTER `total_amount`');
CALL add_col('member_info','first_order_time',        'DATETIME DEFAULT NULL COMMENT ''首次下单时间'' AFTER `last_order_time`');
CALL add_col('member_info','preferred_gender_tech',   'TINYINT NOT NULL DEFAULT 0 COMMENT ''技师性别偏好:0无1男2女'' AFTER `first_order_time`');
CALL add_col('member_info','preferred_massage_style', 'VARCHAR(50) DEFAULT NULL COMMENT ''偏好按摩风格'' AFTER `preferred_gender_tech`');
CALL add_col('member_info','preferred_time_slot',     'VARCHAR(100) DEFAULT NULL COMMENT ''偏好时段JSON'' AFTER `preferred_massage_style`');
CALL add_col('member_info','allergies',               'VARCHAR(500) DEFAULT NULL COMMENT ''过敏禁忌'' AFTER `preferred_time_slot`');
CALL add_col('member_info','special_notes',           'VARCHAR(500) DEFAULT NULL COMMENT ''特殊备注'' AFTER `allergies`');
CALL add_col('member_info','height',                  'SMALLINT DEFAULT NULL COMMENT ''身高cm'' AFTER `special_notes`');
CALL add_col('member_info','weight',                  'SMALLINT DEFAULT NULL COMMENT ''体重kg'' AFTER `height`');
CALL add_col('member_info','favorite_tech_ids',       'JSON DEFAULT NULL COMMENT ''收藏技师ID列表'' AFTER `weight`');
CALL add_col('member_info','review_count',            'INT NOT NULL DEFAULT 0 COMMENT ''发表评价次数'' AFTER `favorite_tech_ids`');
CALL add_col('member_info','referral_count',          'INT NOT NULL DEFAULT 0 COMMENT ''成功邀请人数'' AFTER `review_count`');
CALL add_col('member_info','tags',                    'JSON DEFAULT NULL COMMENT ''系统标签JSON'' AFTER `referral_count`');

-- ② user_account 补充设备/版本/城市字段
CALL add_col('user_account','last_login_ua',          'VARCHAR(500) DEFAULT NULL COMMENT ''最近登录UA'' AFTER `last_login_ip`');
CALL add_col('user_account','last_login_device_id',   'VARCHAR(100) DEFAULT NULL COMMENT ''最近登录设备ID'' AFTER `last_login_ua`');
CALL add_col('user_account','last_login_device_info', 'VARCHAR(500) DEFAULT NULL COMMENT ''最近登录设备JSON'' AFTER `last_login_device_id`');
CALL add_col('user_account','last_login_country',     'VARCHAR(50) DEFAULT NULL COMMENT ''最近登录国家'' AFTER `last_login_device_info`');
CALL add_col('user_account','last_login_city',        'VARCHAR(100) DEFAULT NULL COMMENT ''最近登录城市'' AFTER `last_login_country`');
CALL add_col('user_account','app_version',            'VARCHAR(20) DEFAULT NULL COMMENT ''客户端App版本号'' AFTER `last_login_city`');

DROP PROCEDURE IF EXISTS add_col;

-- ③ 新建登录日志表
CREATE TABLE IF NOT EXISTS `user_login_log` (
    `id`           BIGINT        NOT NULL                           COMMENT '主键（雪花）',
    `user_id`      BIGINT        NOT NULL                           COMMENT '用户ID',
    `user_type`    TINYINT       NOT NULL DEFAULT 1                 COMMENT '1会员 2技师 3商户',
    `login_type`   TINYINT       NOT NULL DEFAULT 1                 COMMENT '1登录 2注册 3退出',
    `ip`           VARCHAR(50)   DEFAULT NULL                       COMMENT 'IP地址',
    `country`      VARCHAR(50)   DEFAULT NULL                       COMMENT '国家',
    `city`         VARCHAR(100)  DEFAULT NULL                       COMMENT '城市',
    `user_agent`   VARCHAR(500)  DEFAULT NULL                       COMMENT 'User-Agent',
    `device_id`    VARCHAR(100)  DEFAULT NULL                       COMMENT '设备唯一ID',
    `device_info`  VARCHAR(500)  DEFAULT NULL                       COMMENT '设备信息JSON',
    `app_version`  VARCHAR(20)   DEFAULT NULL                       COMMENT 'App版本号',
    `status`       TINYINT       NOT NULL DEFAULT 1                 COMMENT '1成功 0失败',
    `fail_reason`  VARCHAR(200)  DEFAULT NULL                       COMMENT '失败原因',
    `create_time`  DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '记录时间',
    PRIMARY KEY (`id`),
    KEY `idx_user_id`    (`user_id`),
    KEY `idx_create_time`(`create_time`),
    KEY `idx_ip`         (`ip`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户登录注册日志';

SELECT 'V2.1 Migration OK' AS result;
