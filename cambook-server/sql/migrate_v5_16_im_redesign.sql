-- ============================================================
-- CamBook IM 表结构重新设计
-- Version : v5_16
-- Date    : 2026-05-06
-- 说明    :
--   1. 删除旧版简单 IM 表
--   2. 创建 7 张企业级 IM 表，覆盖：
--      im_message        消息主表（雪花ID，支持单/群聊 + 幂等）
--      im_conversation   会话表
--      im_conv_member    会话成员表（未读数 / 已读游标）
--      im_group          群组表
--      im_group_member   群成员表
--      im_msg_ack        消息 ACK 表（复合主键，无冗余 auto_increment）
--      im_media          媒体文件表
-- ============================================================

-- ── 删除旧表（顺序：子表先删） ───────────────────────────────────────────────

DROP TABLE IF EXISTS `cb_im_message`;
DROP TABLE IF EXISTS `cb_im_session`;

-- ── im_message：消息主表 ─────────────────────────────────────────────────────
-- 设计要点：
--   · msg_id 使用雪花算法，天然有序且全局唯一
--   · client_msg_id 用于客户端幂等去重（同一条消息不会重复落库）
--   · status 流转：1(已落库) → 2(已送达) → 3(已读) / 9(重试耗尽)
--   · idx_ack_retry 覆盖索引让定时重试扫描不回表

CREATE TABLE IF NOT EXISTS `im_message` (
    `msg_id`          BIGINT       NOT NULL                       COMMENT '消息ID（雪花算法，全局唯一）',
    `conversation_id` BIGINT       NOT NULL                       COMMENT '所属会话ID',
    `client_msg_id`   VARCHAR(64)  NULL                           COMMENT '客户端幂等ID，防重复发送',
    `sender_type`     VARCHAR(20)  NOT NULL                       COMMENT '发送方类型：member/technician/merchant/system',
    `sender_id`       BIGINT       NOT NULL                       COMMENT '发送方ID',
    `receiver_type`   VARCHAR(20)  NULL                           COMMENT '接收方类型（单聊有效）',
    `receiver_id`     BIGINT       NOT NULL DEFAULT 0             COMMENT '接收方ID（单聊有效；群聊填 0）',
    `is_group`        TINYINT(1)   NOT NULL DEFAULT 0             COMMENT '是否群聊：0=单聊 1=群聊',
    `group_id`        BIGINT       NULL                           COMMENT '群组ID（群聊时有效）',
    `msg_type`        TINYINT      NOT NULL DEFAULT 1             COMMENT '消息类型：1=文本 2=图片 3=语音 4=视频 5=文件 6=系统通知 7=WebRTC信令',
    `content`         TEXT         NOT NULL                       COMMENT '消息内容（JSON字符串）',
    `status`          TINYINT      NOT NULL DEFAULT 1             COMMENT '状态：1=已落库 2=已送达 3=已读 9=发送失败',
    `retry_count`     TINYINT      NOT NULL DEFAULT 0             COMMENT '重试次数（ACK超时重试计数）',
    `create_time`     BIGINT       NOT NULL                       COMMENT '发送时间戳（秒）',
    `update_time`     BIGINT       NOT NULL                       COMMENT '更新时间戳（秒）',

    PRIMARY KEY (`msg_id`),

    -- 幂等键（客户端可不传，传则不重复）
    UNIQUE  KEY `uk_client_msg`    (`client_msg_id`),

    -- 会话历史分页查询：conversation_id + msg_id 倒序
    INDEX `idx_conversation`        (`conversation_id`, `msg_id`),

    -- 单聊离线拉取：receiver + status + msg_id
    INDEX `idx_receiver_offline`    (`receiver_type`, `receiver_id`, `status`, `msg_id`),

    -- 群聊消息查询
    INDEX `idx_group_msg`           (`group_id`, `msg_id`),

    -- ACK 重试扫描（覆盖索引，避免回表）
    INDEX `idx_ack_retry`           (`status`, `is_group`, `update_time`, `retry_count`)

) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='IM消息主表（雪花ID，支持单聊/群聊）';


-- ── im_conversation：会话表 ──────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS `im_conversation` (
    `id`               BIGINT       NOT NULL AUTO_INCREMENT        COMMENT '会话ID',
    `conv_key`         VARCHAR(100) NOT NULL                       COMMENT '会话唯一键（单聊：a_b；群聊：group:{groupId}）',
    `conv_type`        TINYINT      NOT NULL DEFAULT 1             COMMENT '会话类型：1=单聊 2=群聊',
    `group_id`         BIGINT       NULL                           COMMENT '关联群组ID（群聊有效）',
    `last_msg_id`      BIGINT       NULL                           COMMENT '最后一条消息ID',
    `last_msg_preview` VARCHAR(200) NULL                           COMMENT '最后消息预览（≤100字符）',
    `last_msg_time`    BIGINT       NOT NULL DEFAULT 0             COMMENT '最后消息时间戳（秒）',
    `create_time`      BIGINT       NOT NULL                       COMMENT '创建时间戳（秒）',
    `update_time`      BIGINT       NOT NULL                       COMMENT '更新时间戳（秒）',

    PRIMARY KEY (`id`),
    UNIQUE  KEY `uk_conv_key`      (`conv_key`),
    INDEX `idx_last_msg_time`      (`last_msg_time`)

) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='IM会话表';


-- ── im_conv_member：会话成员表 ───────────────────────────────────────────────
-- 记录每个参与方的未读数、已读游标、置顶、免打扰等个人状态

CREATE TABLE IF NOT EXISTS `im_conv_member` (
    `id`               BIGINT       NOT NULL AUTO_INCREMENT        COMMENT '主键',
    `conversation_id`  BIGINT       NOT NULL                       COMMENT '会话ID',
    `user_type`        VARCHAR(20)  NOT NULL                       COMMENT '用户类型：member/technician/merchant',
    `user_id`          BIGINT       NOT NULL                       COMMENT '用户ID',
    `unread_count`     INT          NOT NULL DEFAULT 0             COMMENT '未读消息数',
    `last_read_msg_id` BIGINT       NULL                           COMMENT '最后已读消息ID（已读游标）',
    `is_pinned`        TINYINT(1)   NOT NULL DEFAULT 0             COMMENT '是否置顶',
    `is_muted`         TINYINT(1)   NOT NULL DEFAULT 0             COMMENT '是否免打扰',
    `joined_at`        BIGINT       NOT NULL                       COMMENT '加入时间戳（秒）',
    `update_time`      BIGINT       NOT NULL                       COMMENT '更新时间戳（秒）',

    PRIMARY KEY (`id`),
    UNIQUE  KEY `uk_conv_user`    (`conversation_id`, `user_type`, `user_id`),
    -- 用户维度查询（拉取会话列表）
    INDEX `idx_user_conv`         (`user_type`, `user_id`, `update_time`)

) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='IM会话成员表（未读数/已读游标）';


-- ── im_group：群组表 ─────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS `im_group` (
    `id`           BIGINT       NOT NULL AUTO_INCREMENT            COMMENT '群组ID',
    `name`         VARCHAR(50)  NOT NULL                           COMMENT '群名称',
    `avatar`       VARCHAR(500) NULL                               COMMENT '群头像URL',
    `description`  VARCHAR(200) NULL                               COMMENT '群介绍',
    `owner_type`   VARCHAR(20)  NOT NULL                           COMMENT '群主类型',
    `owner_id`     BIGINT       NOT NULL                           COMMENT '群主ID',
    `member_count` INT          NOT NULL DEFAULT 1                 COMMENT '当前成员数',
    `max_member`   INT          NOT NULL DEFAULT 500               COMMENT '最大成员数',
    `status`       TINYINT      NOT NULL DEFAULT 0                 COMMENT '状态：0=正常 1=已解散',
    `create_time`  BIGINT       NOT NULL                           COMMENT '创建时间戳（秒）',
    `update_time`  BIGINT       NOT NULL                           COMMENT '更新时间戳（秒）',

    PRIMARY KEY (`id`),
    INDEX `idx_owner` (`owner_type`, `owner_id`)

) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='IM群组表';


-- ── im_group_member：群成员表 ────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS `im_group_member` (
    `id`          BIGINT       NOT NULL AUTO_INCREMENT             COMMENT '主键',
    `group_id`    BIGINT       NOT NULL                            COMMENT '群组ID',
    `user_type`   VARCHAR(20)  NOT NULL                            COMMENT '成员类型',
    `user_id`     BIGINT       NOT NULL                            COMMENT '成员ID',
    `group_alias` VARCHAR(50)  NULL                                COMMENT '群内昵称',
    `role`        TINYINT      NOT NULL DEFAULT 0                  COMMENT '角色：0=成员 1=管理员 2=群主',
    `is_muted`    TINYINT(1)   NOT NULL DEFAULT 0                  COMMENT '是否禁言',
    `status`      TINYINT      NOT NULL DEFAULT 0                  COMMENT '状态：0=正常 1=已退群',
    `joined_at`   BIGINT       NOT NULL                            COMMENT '加入时间戳（秒）',
    `update_time` BIGINT       NOT NULL                            COMMENT '更新时间戳（秒）',

    PRIMARY KEY (`id`),
    UNIQUE  KEY `uk_group_user`   (`group_id`, `user_type`, `user_id`),
    -- 用户维度查询（我的群列表）
    INDEX `idx_user_group`        (`user_type`, `user_id`, `status`)

) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='IM群成员表';


-- ── im_msg_ack：消息 ACK 表 ──────────────────────────────────────────────────
-- 设计要点：
--   · 使用复合主键 (msg_id, user_type, user_id) 取代无意义的 auto_increment
--   · 避免 UNIQUE KEY 的额外 B-Tree，节省存储，查询走主键更快
--   · ack_type: 1=已送达 2=已读

CREATE TABLE IF NOT EXISTS `im_msg_ack` (
    `msg_id`    BIGINT       NOT NULL                              COMMENT '消息ID',
    `user_type` VARCHAR(20)  NOT NULL                              COMMENT '接收方类型',
    `user_id`   BIGINT       NOT NULL                              COMMENT '接收方ID',
    `ack_type`  TINYINT      NOT NULL DEFAULT 1                    COMMENT 'ACK类型：1=已送达 2=已读',
    `ack_time`  BIGINT       NOT NULL                              COMMENT 'ACK时间戳（秒）',

    PRIMARY KEY (`msg_id`, `user_type`, `user_id`),
    -- 查询某用户所有消息的 ACK 状态
    INDEX `idx_user_ack` (`user_type`, `user_id`, `ack_type`)

) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='IM消息ACK表（送达/已读双状态）';


-- ── im_media：媒体文件表 ─────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS `im_media` (
    `id`            BIGINT       NOT NULL AUTO_INCREMENT           COMMENT '主键',
    `uploader_type` VARCHAR(20)  NOT NULL                          COMMENT '上传者类型',
    `uploader_id`   BIGINT       NOT NULL                          COMMENT '上传者ID',
    `file_type`     VARCHAR(20)  NOT NULL                          COMMENT '文件类型：image/voice/video/file',
    `original_name` VARCHAR(200) NULL                              COMMENT '原始文件名',
    `storage_type`  VARCHAR(10)  NOT NULL DEFAULT 'local'          COMMENT '存储类型：local/oss',
    `storage_path`  VARCHAR(500) NOT NULL                          COMMENT '存储路径（本地相对路径 or OSS Key）',
    `file_url`      VARCHAR(500) NOT NULL                          COMMENT '访问URL',
    `file_size`     BIGINT       NOT NULL DEFAULT 0                COMMENT '文件大小（字节）',
    `width`         INT          NULL                              COMMENT '图片宽度（px）',
    `height`        INT          NULL                              COMMENT '图片高度（px）',
    `duration`      INT          NULL                              COMMENT '时长（秒，语音/视频有效）',
    `mime_type`     VARCHAR(100) NULL                              COMMENT 'MIME类型',
    `create_time`   BIGINT       NOT NULL                          COMMENT '上传时间戳（秒）',

    PRIMARY KEY (`id`),
    INDEX `idx_uploader` (`uploader_type`, `uploader_id`, `file_type`)

) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='IM媒体文件表（图片/语音/视频/文件）';
