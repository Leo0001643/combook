-- ============================================================
-- CamBook IM 全量建表脚本（生产可直接执行）
-- Version  : v6.1（合并 v5_16 + v6_01）
-- Date     : 2026-05-06
-- Author   : CamBook Team
--
-- 包含内容：
--   1. im_message        消息主表
--   2. im_conversation   会话表
--   3. im_conv_member    会话成员表（未读数 / 已读游标）
--   4. im_group          群组表
--   5. im_group_member   群成员表
--   6. im_msg_ack        消息 ACK 表
--   7. im_media          媒体文件表
--   8. im_org_member     组织成员表（IM 角色映射，无好友通讯录体系）
--   9. im_chat_rule      通信权限规则表 + 平台默认种子数据
--
-- 执行说明：
--   · 所有 DDL 使用 CREATE TABLE IF NOT EXISTS，幂等安全。
--   · 种子数据使用 INSERT ... ON DUPLICATE KEY UPDATE，可重复执行。
--   · 删除旧表 cb_im_message / cb_im_session 仅首次迁移需要，
--     已迁移过的库可注释掉 "删除旧表" 段落。
--
-- 权限矩阵（im_chat_rule 种子数据基准）：
--   SUPER_ADMIN → 所有角色
--   OWNER       → 所有角色
--   MANAGER     → OWNER / MANAGER / STAFF（跨部门由代码层限制）
--   STAFF       → MANAGER（跨部门由代码层限制）
--   OPERATOR    → TECHNICIAN / MEMBER / DRIVER / OPERATOR
--   MARKETING   → TECHNICIAN / MEMBER / MARKETING
--   TECHNICIAN  → MEMBER / OPERATOR / MARKETING / DRIVER
--   DRIVER      → TECHNICIAN / OPERATOR
--   MEMBER      → TECHNICIAN / OPERATOR / MARKETING
-- ============================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ── 删除旧版简单 IM 表（首次迁移时执行，已迁移可跳过）────────────────────────
DROP TABLE IF EXISTS `cb_im_message`;
DROP TABLE IF EXISTS `cb_im_session`;

-- ────────────────────────────────────────────────────────────────────────────
-- 1. im_message：消息主表
--    · msg_id 雪花算法，天然有序且全局唯一
--    · client_msg_id 客户端幂等去重，同一消息不重复落库
--    · status 流转：1(已落库) → 2(已送达) → 3(已读) / 9(重试耗尽)
--    · idx_ack_retry 覆盖索引，定时重试扫描不回表
-- ────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `im_message` (
    `msg_id`          BIGINT       NOT NULL                   COMMENT '消息ID（雪花算法，全局唯一）',
    `conversation_id` BIGINT       NOT NULL                   COMMENT '所属会话ID',
    `client_msg_id`   VARCHAR(64)  NULL                       COMMENT '客户端幂等ID，防重复发送',
    `sender_type`     VARCHAR(20)  NOT NULL                   COMMENT '发送方类型：member / technician / merchant / system',
    `sender_id`       BIGINT       NOT NULL                   COMMENT '发送方ID',
    `receiver_type`   VARCHAR(20)  NULL                       COMMENT '接收方类型（单聊有效）',
    `receiver_id`     BIGINT       NOT NULL DEFAULT 0         COMMENT '接收方ID（单聊有效；群聊填 0）',
    `is_group`        TINYINT(1)   NOT NULL DEFAULT 0         COMMENT '是否群聊：0=单聊 1=群聊',
    `group_id`        BIGINT       NULL                       COMMENT '群组ID（群聊时有效）',
    `msg_type`        TINYINT      NOT NULL DEFAULT 1         COMMENT '消息类型：1=文本 2=图片 3=语音 4=视频 5=文件 6=系统通知 7=WebRTC信令',
    `content`         TEXT         NOT NULL                   COMMENT '消息内容（JSON字符串）',
    `status`          TINYINT      NOT NULL DEFAULT 1         COMMENT '状态：1=已落库 2=已送达 3=已读 9=发送失败',
    `retry_count`     TINYINT      NOT NULL DEFAULT 0         COMMENT '重试次数（ACK超时重试计数）',
    `create_time`     BIGINT       NOT NULL                   COMMENT '发送时间戳（秒）',
    `update_time`     BIGINT       NOT NULL                   COMMENT '更新时间戳（秒）',

    PRIMARY KEY (`msg_id`),
    UNIQUE  KEY `uk_client_msg`      (`client_msg_id`),                          -- 幂等去重
    INDEX `idx_conversation`         (`conversation_id`, `msg_id`),              -- 会话历史分页
    INDEX `idx_receiver_offline`     (`receiver_type`, `receiver_id`, `status`, `msg_id`), -- 单聊离线拉取
    INDEX `idx_group_msg`            (`group_id`, `msg_id`),                     -- 群聊消息查询
    INDEX `idx_ack_retry`            (`status`, `is_group`, `update_time`, `retry_count`) -- ACK重试扫描（覆盖索引）

) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='IM消息主表（雪花ID，支持单聊/群聊）';


-- ────────────────────────────────────────────────────────────────────────────
-- 2. im_conversation：会话表
-- ────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `im_conversation` (
    `id`               BIGINT       NOT NULL AUTO_INCREMENT   COMMENT '会话ID',
    `conv_key`         VARCHAR(100) NOT NULL                  COMMENT '会话唯一键（单聊：typeA:idA_typeB:idB；群聊：group:{groupId}）',
    `conv_type`        TINYINT      NOT NULL DEFAULT 1        COMMENT '会话类型：1=单聊 2=群聊',
    `group_id`         BIGINT       NULL                      COMMENT '关联群组ID（群聊有效）',
    `last_msg_id`      BIGINT       NULL                      COMMENT '最后一条消息ID',
    `last_msg_preview` VARCHAR(200) NULL                      COMMENT '最后消息预览（≤100字符）',
    `last_msg_time`    BIGINT       NOT NULL DEFAULT 0        COMMENT '最后消息时间戳（秒）',
    `create_time`      BIGINT       NOT NULL                  COMMENT '创建时间戳（秒）',
    `update_time`      BIGINT       NOT NULL                  COMMENT '更新时间戳（秒）',

    PRIMARY KEY (`id`),
    UNIQUE  KEY `uk_conv_key`        (`conv_key`),            -- 防止重复建会话
    INDEX `idx_last_msg_time`        (`last_msg_time`)        -- 会话列表排序

) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='IM会话表';


-- ────────────────────────────────────────────────────────────────────────────
-- 3. im_conv_member：会话成员表
--    记录每个参与方的未读数、已读游标、置顶、免打扰等个人状态
-- ────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `im_conv_member` (
    `id`               BIGINT       NOT NULL AUTO_INCREMENT   COMMENT '主键',
    `conversation_id`  BIGINT       NOT NULL                  COMMENT '会话ID',
    `user_type`        VARCHAR(20)  NOT NULL                  COMMENT '用户类型：member / technician / merchant',
    `user_id`          BIGINT       NOT NULL                  COMMENT '用户ID',
    `unread_count`     INT          NOT NULL DEFAULT 0        COMMENT '未读消息数',
    `last_read_msg_id` BIGINT       NULL                      COMMENT '最后已读消息ID（已读游标）',
    `is_pinned`        TINYINT(1)   NOT NULL DEFAULT 0        COMMENT '是否置顶',
    `is_muted`         TINYINT(1)   NOT NULL DEFAULT 0        COMMENT '是否免打扰',
    `joined_at`        BIGINT       NOT NULL                  COMMENT '加入时间戳（秒）',
    `update_time`      BIGINT       NOT NULL                  COMMENT '更新时间戳（秒）',

    PRIMARY KEY (`id`),
    UNIQUE  KEY `uk_conv_user`       (`conversation_id`, `user_type`, `user_id`),
    INDEX `idx_user_conv`            (`user_type`, `user_id`, `update_time`) -- 拉取会话列表

) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='IM会话成员表（未读数 / 已读游标）';


-- ────────────────────────────────────────────────────────────────────────────
-- 4. im_group：群组表
-- ────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `im_group` (
    `id`           BIGINT       NOT NULL AUTO_INCREMENT       COMMENT '群组ID',
    `name`         VARCHAR(50)  NOT NULL                      COMMENT '群名称',
    `avatar`       VARCHAR(500) NULL                          COMMENT '群头像URL',
    `description`  VARCHAR(200) NULL                          COMMENT '群介绍',
    `owner_type`   VARCHAR(20)  NOT NULL                      COMMENT '群主类型',
    `owner_id`     BIGINT       NOT NULL                      COMMENT '群主ID',
    `member_count` INT          NOT NULL DEFAULT 1            COMMENT '当前成员数',
    `max_member`   INT          NOT NULL DEFAULT 500          COMMENT '最大成员数',
    `status`       TINYINT      NOT NULL DEFAULT 0            COMMENT '状态：0=正常 1=已解散',
    `create_time`  BIGINT       NOT NULL                      COMMENT '创建时间戳（秒）',
    `update_time`  BIGINT       NOT NULL                      COMMENT '更新时间戳（秒）',

    PRIMARY KEY (`id`),
    INDEX `idx_owner`                (`owner_type`, `owner_id`)

) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='IM群组表';


-- ────────────────────────────────────────────────────────────────────────────
-- 5. im_group_member：群成员表
-- ────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `im_group_member` (
    `id`          BIGINT       NOT NULL AUTO_INCREMENT        COMMENT '主键',
    `group_id`    BIGINT       NOT NULL                       COMMENT '群组ID',
    `user_type`   VARCHAR(20)  NOT NULL                       COMMENT '成员类型',
    `user_id`     BIGINT       NOT NULL                       COMMENT '成员ID',
    `group_alias` VARCHAR(50)  NULL                           COMMENT '群内昵称',
    `role`        TINYINT      NOT NULL DEFAULT 0             COMMENT '角色：0=成员 1=管理员 2=群主',
    `is_muted`    TINYINT(1)   NOT NULL DEFAULT 0             COMMENT '是否禁言',
    `status`      TINYINT      NOT NULL DEFAULT 0             COMMENT '状态：0=正常 1=已退群',
    `joined_at`   BIGINT       NOT NULL                       COMMENT '加入时间戳（秒）',
    `update_time` BIGINT       NOT NULL                       COMMENT '更新时间戳（秒）',

    PRIMARY KEY (`id`),
    UNIQUE  KEY `uk_group_user`      (`group_id`, `user_type`, `user_id`),
    INDEX `idx_user_group`           (`user_type`, `user_id`, `status`) -- 我的群列表

) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='IM群成员表';


-- ────────────────────────────────────────────────────────────────────────────
-- 6. im_msg_ack：消息 ACK 表
--    · 复合主键 (msg_id, user_type, user_id)，无额外 UNIQUE B-Tree，查询更快
--    · ack_type：1=已送达 2=已读
-- ────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `im_msg_ack` (
    `msg_id`    BIGINT       NOT NULL                         COMMENT '消息ID',
    `user_type` VARCHAR(20)  NOT NULL                         COMMENT '接收方类型',
    `user_id`   BIGINT       NOT NULL                         COMMENT '接收方ID',
    `ack_type`  TINYINT      NOT NULL DEFAULT 1               COMMENT 'ACK类型：1=已送达 2=已读',
    `ack_time`  BIGINT       NOT NULL                         COMMENT 'ACK时间戳（秒）',

    PRIMARY KEY (`msg_id`, `user_type`, `user_id`),
    INDEX `idx_user_ack`             (`user_type`, `user_id`, `ack_type`) -- 查询某用户的ACK状态

) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='IM消息ACK表（送达 / 已读双状态）';


-- ────────────────────────────────────────────────────────────────────────────
-- 7. im_media：媒体文件表
-- ────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `im_media` (
    `id`            BIGINT       NOT NULL AUTO_INCREMENT      COMMENT '主键',
    `uploader_type` VARCHAR(20)  NOT NULL                     COMMENT '上传者类型',
    `uploader_id`   BIGINT       NOT NULL                     COMMENT '上传者ID',
    `file_type`     VARCHAR(20)  NOT NULL                     COMMENT '文件类型：image / voice / video / file',
    `original_name` VARCHAR(200) NULL                         COMMENT '原始文件名',
    `storage_type`  VARCHAR(10)  NOT NULL DEFAULT 'local'     COMMENT '存储类型：local / oss',
    `storage_path`  VARCHAR(500) NOT NULL                     COMMENT '存储路径（本地相对路径 或 OSS Key）',
    `file_url`      VARCHAR(500) NOT NULL                     COMMENT '访问URL',
    `file_size`     BIGINT       NOT NULL DEFAULT 0           COMMENT '文件大小（字节）',
    `width`         INT          NULL                         COMMENT '图片宽度（px）',
    `height`        INT          NULL                         COMMENT '图片高度（px）',
    `duration`      INT          NULL                         COMMENT '时长（秒，语音/视频有效）',
    `mime_type`     VARCHAR(100) NULL                         COMMENT 'MIME类型',
    `create_time`   BIGINT       NOT NULL                     COMMENT '上传时间戳（秒）',

    PRIMARY KEY (`id`),
    INDEX `idx_uploader`             (`uploader_type`, `uploader_id`, `file_type`)

) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='IM媒体文件表（图片 / 语音 / 视频 / 文件）';


-- ────────────────────────────────────────────────────────────────────────────
-- 8. im_org_member：组织成员表
--    · 将各类业务用户（admin / merchant / staff / technician / member）
--      映射到 IM 角色，构建"无好友，基于关系"的通讯录体系
--    · merchant_id = 0 表示平台超管
-- ────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `im_org_member` (
    `id`           BIGINT       NOT NULL AUTO_INCREMENT       COMMENT '主键',
    `merchant_id`  BIGINT       NOT NULL DEFAULT 0            COMMENT '所属商户ID；0 = 平台超管',
    `user_type`    VARCHAR(20)  NOT NULL                      COMMENT '用户类型：admin / merchant / staff / technician / member',
    `user_id`      BIGINT       NOT NULL                      COMMENT '用户ID（对应各业务表主键）',
    `im_role`      VARCHAR(20)  NOT NULL                      COMMENT 'IM角色：SUPER_ADMIN / OWNER / MANAGER / STAFF / OPERATOR / MARKETING / TECHNICIAN / DRIVER / MEMBER',
    `dept_id`      BIGINT       DEFAULT NULL                  COMMENT '所属部门ID（MANAGER / STAFF 同部门过滤用）',
    `display_name` VARCHAR(100) DEFAULT NULL                  COMMENT '自定义显示名称（覆盖用户表原名）',
    `status`       TINYINT      NOT NULL DEFAULT 0            COMMENT '状态：0=启用 1=禁用',
    `create_time`  BIGINT       NOT NULL                      COMMENT '创建时间（Unix秒）',
    `update_time`  BIGINT       NOT NULL                      COMMENT '更新时间（Unix秒）',

    PRIMARY KEY (`id`),
    -- ON DUPLICATE KEY UPDATE（setRole 幂等更新）依赖此唯一索引
    UNIQUE KEY `uk_user`             (`user_type`, `user_id`, `merchant_id`),
    -- 通讯录核心查询：WHERE merchant_id=? AND status=0 AND im_role IN (?)
    INDEX `idx_merchant_status_role` (`merchant_id`, `status`, `im_role`),
    -- 部门过滤查询：WHERE merchant_id=? AND dept_id=?
    INDEX `idx_merchant_dept`        (`merchant_id`, `dept_id`)

) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='IM组织成员表：用户 → IM角色 映射，构建无好友通讯录体系';


-- ────────────────────────────────────────────────────────────────────────────
-- 9. im_chat_rule：通信权限规则表
--    · merchant_id = 0 为平台默认规则，商户可用自己的 merchant_id 覆盖
--    · allowed：1=允许 0=禁止
-- ────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `im_chat_rule` (
    `id`            BIGINT      NOT NULL AUTO_INCREMENT       COMMENT '主键',
    `merchant_id`   BIGINT      NOT NULL DEFAULT 0            COMMENT '商户ID；0 = 平台默认规则',
    `sender_role`   VARCHAR(20) NOT NULL                      COMMENT '发送方IM角色',
    `receiver_role` VARCHAR(20) NOT NULL                      COMMENT '接收方IM角色',
    `allowed`       TINYINT     NOT NULL DEFAULT 1            COMMENT '1=允许 0=禁止',
    `create_time`   BIGINT      NOT NULL                      COMMENT '创建时间（Unix秒）',
    `update_time`   BIGINT      NOT NULL                      COMMENT '更新时间（Unix秒）',

    PRIMARY KEY (`id`),
    -- canChat() 单条精确查询
    UNIQUE KEY `uk_rule`             (`merchant_id`, `sender_role`, `receiver_role`),
    -- getAllowedReceiverRoles() 批量查询：WHERE merchant_id IN (0,?) AND sender_role=?
    INDEX `idx_sender_allowed`       (`merchant_id`, `sender_role`, `allowed`)

) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='IM通信权限规则表：角色粒度，商户可在平台默认规则上覆盖';


-- ────────────────────────────────────────────────────────────────────────────
-- 9-seed. im_chat_rule 平台默认种子数据（merchant_id = 0）
--   · 时间戳 1746547200 ≈ 2026-05-07 00:00:00 UTC
--   · ON DUPLICATE KEY UPDATE 幂等，可重复执行
-- ────────────────────────────────────────────────────────────────────────────
INSERT INTO `im_chat_rule`
    (`merchant_id`, `sender_role`, `receiver_role`, `allowed`, `create_time`, `update_time`)
VALUES
    -- SUPER_ADMIN：可与所有角色通信
    (0, 'SUPER_ADMIN', 'SUPER_ADMIN', 1, 1746547200, 1746547200),
    (0, 'SUPER_ADMIN', 'OWNER',       1, 1746547200, 1746547200),
    (0, 'SUPER_ADMIN', 'MANAGER',     1, 1746547200, 1746547200),
    (0, 'SUPER_ADMIN', 'STAFF',       1, 1746547200, 1746547200),
    (0, 'SUPER_ADMIN', 'OPERATOR',    1, 1746547200, 1746547200),
    (0, 'SUPER_ADMIN', 'MARKETING',   1, 1746547200, 1746547200),
    (0, 'SUPER_ADMIN', 'TECHNICIAN',  1, 1746547200, 1746547200),
    (0, 'SUPER_ADMIN', 'DRIVER',      1, 1746547200, 1746547200),
    (0, 'SUPER_ADMIN', 'MEMBER',      1, 1746547200, 1746547200),
    -- OWNER（商户户主）：可与所有角色通信
    (0, 'OWNER', 'SUPER_ADMIN',  1, 1746547200, 1746547200),
    (0, 'OWNER', 'OWNER',        1, 1746547200, 1746547200),
    (0, 'OWNER', 'MANAGER',      1, 1746547200, 1746547200),
    (0, 'OWNER', 'STAFF',        1, 1746547200, 1746547200),
    (0, 'OWNER', 'OPERATOR',     1, 1746547200, 1746547200),
    (0, 'OWNER', 'MARKETING',    1, 1746547200, 1746547200),
    (0, 'OWNER', 'TECHNICIAN',   1, 1746547200, 1746547200),
    (0, 'OWNER', 'DRIVER',       1, 1746547200, 1746547200),
    (0, 'OWNER', 'MEMBER',       1, 1746547200, 1746547200),
    -- MANAGER（部门主管）：上级 + 本部门（跨部门限制由代码层执行）
    (0, 'MANAGER', 'OWNER',      1, 1746547200, 1746547200),
    (0, 'MANAGER', 'MANAGER',    1, 1746547200, 1746547200),
    (0, 'MANAGER', 'STAFF',      1, 1746547200, 1746547200),
    -- STAFF（普通员工）：仅本部门主管（跨部门限制由代码层执行）
    (0, 'STAFF', 'MANAGER',      1, 1746547200, 1746547200),
    -- OPERATOR（运营）：技师 / 会员 / 司机 / 同组运营互聊
    (0, 'OPERATOR', 'TECHNICIAN', 1, 1746547200, 1746547200),
    (0, 'OPERATOR', 'MEMBER',     1, 1746547200, 1746547200),
    (0, 'OPERATOR', 'DRIVER',     1, 1746547200, 1746547200),
    (0, 'OPERATOR', 'OPERATOR',   1, 1746547200, 1746547200),
    -- MARKETING（营销）：技师 / 会员 / 同组营销互聊
    (0, 'MARKETING', 'TECHNICIAN', 1, 1746547200, 1746547200),
    (0, 'MARKETING', 'MEMBER',     1, 1746547200, 1746547200),
    (0, 'MARKETING', 'MARKETING',  1, 1746547200, 1746547200),
    -- TECHNICIAN（技师）：会员 / 运营 / 营销 / 司机
    (0, 'TECHNICIAN', 'MEMBER',    1, 1746547200, 1746547200),
    (0, 'TECHNICIAN', 'OPERATOR',  1, 1746547200, 1746547200),
    (0, 'TECHNICIAN', 'MARKETING', 1, 1746547200, 1746547200),
    (0, 'TECHNICIAN', 'DRIVER',    1, 1746547200, 1746547200),
    -- DRIVER（司机/车队）：技师 / 运营
    (0, 'DRIVER', 'TECHNICIAN',   1, 1746547200, 1746547200),
    (0, 'DRIVER', 'OPERATOR',     1, 1746547200, 1746547200),
    -- MEMBER（会员）：技师 / 运营 / 营销
    (0, 'MEMBER', 'TECHNICIAN',   1, 1746547200, 1746547200),
    (0, 'MEMBER', 'OPERATOR',     1, 1746547200, 1746547200),
    (0, 'MEMBER', 'MARKETING',    1, 1746547200, 1746547200)
ON DUPLICATE KEY UPDATE
    `allowed`     = VALUES(`allowed`),
    `update_time` = VALUES(`update_time`);

-- ────────────────────────────────────────────────────────────────────────────
-- 验证
-- ────────────────────────────────────────────────────────────────────────────
SELECT
    (SELECT COUNT(*) FROM information_schema.tables
     WHERE table_schema = DATABASE()
       AND table_name IN (
           'im_message','im_conversation','im_conv_member',
           'im_group','im_group_member','im_msg_ack','im_media',
           'im_org_member','im_chat_rule'
       )
    )                                    AS tables_created,   -- 预期：9
    (SELECT COUNT(*) FROM `im_chat_rule` WHERE merchant_id = 0) AS default_rules; -- 预期：38

SET FOREIGN_KEY_CHECKS = 1;

SELECT '✅ migrate_im_full 执行完成，共创建 9 张 IM 表，写入 38 条默认权限规则' AS result;
