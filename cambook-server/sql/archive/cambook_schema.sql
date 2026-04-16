-- ============================================================
-- CamBook 上门按摩SPA平台 - 数据库建表脚本
-- 数据库: cambook
-- 字符集: utf8mb4
-- 排序规则: utf8mb4_unicode_ci
-- 版本: V2.0.0 | 日期: 2026-04-13
-- ============================================================
-- 表职责说明：
--   user_account  —— 所有前台用户的统一登录账号（会员/技师/商户）
--   member_info   —— 会员扩展信息（会员专属字段，一对一关联 user_account）
--   technician_info —— 技师扩展信息
--   merchant_info —— 商户扩展信息
--   sys_admin     —— 后台管理员账号（与前台完全隔离）
-- ============================================================

CREATE DATABASE IF NOT EXISTS cambook DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE cambook;

-- ============================================================
-- 前台统一账号表（会员 / 技师 / 商户共用）
-- 原名 sys_user，V2.0 更名为 user_account 以区分后台管理员账号
-- ============================================================
CREATE TABLE IF NOT EXISTS `user_account` (
    `id`              BIGINT       NOT NULL COMMENT '用户ID（雪花算法）',
    `phone`           VARCHAR(20)  NOT NULL DEFAULT '' COMMENT '手机号',
    `country_code`    VARCHAR(10)  NOT NULL DEFAULT '+86' COMMENT '国际区号（+86中国/+855柬埔寨/+84越南）',
    `email`           VARCHAR(100) DEFAULT NULL COMMENT '邮箱（可选）',
    `password`        VARCHAR(100) NOT NULL DEFAULT '' COMMENT '登录密码（BCrypt加密）',
    `nickname`        VARCHAR(50)  NOT NULL DEFAULT '' COMMENT '昵称',
    `avatar`          VARCHAR(500) DEFAULT NULL COMMENT '头像URL',
    `user_type`       TINYINT      NOT NULL DEFAULT 1 COMMENT '用户类型：1会员 2技师 3商户',
    `status`          TINYINT      NOT NULL DEFAULT 0 COMMENT '账号状态：0正常 1禁用 2注销申请中',
    `gender`          TINYINT      NOT NULL DEFAULT 0 COMMENT '性别：0未知 1男 2女',
    `birthday`        DATE         DEFAULT NULL COMMENT '生日',
    `language`        VARCHAR(10)  NOT NULL DEFAULT 'zh-CN' COMMENT '语言偏好：zh-CN/en/vi/km',
    `last_login_time` DATETIME     DEFAULT NULL COMMENT '最后登录时间',
    `last_login_ip`   VARCHAR(50)  DEFAULT NULL COMMENT '最后登录IP',
    `fcm_token`       VARCHAR(500) DEFAULT NULL COMMENT 'FCM推送Token',
    `invite_code`     VARCHAR(10)  NOT NULL DEFAULT '' COMMENT '我的邀请码（唯一）',
    `invite_user_id`  BIGINT       DEFAULT NULL COMMENT '我被谁邀请的（邀请人ID）',
    `create_time`     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time`     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `deleted`         TINYINT      NOT NULL DEFAULT 0 COMMENT '逻辑删除：0正常 1已删除',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_phone_country` (`phone`, `country_code`),
    UNIQUE KEY `uk_invite_code` (`invite_code`),
    KEY `idx_email` (`email`),
    KEY `idx_user_type` (`user_type`),
    KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='前台用户账号表（会员/技师/商户共用，不含后台管理员）';

-- ============================================================
-- 后台管理员账号表（与前台用户完全隔离）
-- ============================================================
CREATE TABLE IF NOT EXISTS `sys_admin` (
    `id`              BIGINT       NOT NULL COMMENT '管理员ID',
    `username`        VARCHAR(50)  NOT NULL COMMENT '登录用户名',
    `password`        VARCHAR(100) NOT NULL COMMENT '密码（BCrypt）',
    `real_name`       VARCHAR(50)  DEFAULT NULL COMMENT '真实姓名',
    `avatar`          VARCHAR(500) DEFAULT NULL COMMENT '头像',
    `role`            VARCHAR(50)  NOT NULL DEFAULT 'ADMIN' COMMENT '角色：SUPER_ADMIN/ADMIN/OPERATOR',
    `email`           VARCHAR(100) DEFAULT NULL COMMENT '邮箱',
    `phone`           VARCHAR(20)  DEFAULT NULL COMMENT '手机号',
    `status`          TINYINT      NOT NULL DEFAULT 0 COMMENT '状态：0正常 1禁用',
    `last_login_time` DATETIME     DEFAULT NULL COMMENT '最后登录时间',
    `last_login_ip`   VARCHAR(50)  DEFAULT NULL COMMENT '最后登录IP',
    `create_time`     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time`     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `deleted`         TINYINT      NOT NULL DEFAULT 0 COMMENT '逻辑删除',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_username` (`username`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='后台管理员账号表（独立于前台用户体系）';

-- ============================================================
-- 会员扩展信息表（userType=1 时注册时自动初始化一条记录）
-- ============================================================
CREATE TABLE IF NOT EXISTS `member_info` (
    `id`                      BIGINT        NOT NULL COMMENT '主键ID（雪花）',
    `user_id`                 BIGINT        NOT NULL COMMENT '关联 user_account.id',

    -- 等级与积分
    `member_level`            TINYINT       NOT NULL DEFAULT 1 COMMENT '会员等级：1普通 2白银 3黄金 4铂金 5钻石',
    `points`                  INT           NOT NULL DEFAULT 0 COMMENT '当前积分',
    `total_points`            INT           NOT NULL DEFAULT 0 COMMENT '历史累计积分',
    `membership_expire_time`  DATETIME      DEFAULT NULL COMMENT '付费会员到期时间（NULL=非付费）',

    -- 消费统计
    `total_orders`            INT           NOT NULL DEFAULT 0 COMMENT '累计订单数',
    `completed_orders`        INT           NOT NULL DEFAULT 0 COMMENT '累计完成订单数',
    `cancel_count`            INT           NOT NULL DEFAULT 0 COMMENT '取消次数',
    `total_amount`            DECIMAL(12,2) NOT NULL DEFAULT 0.00 COMMENT '累计消费金额（USD）',
    `last_order_time`         DATETIME      DEFAULT NULL COMMENT '最近一次下单时间',
    `first_order_time`        DATETIME      DEFAULT NULL COMMENT '首次下单时间',

    -- 偏好设置
    `preferred_gender_tech`   TINYINT       NOT NULL DEFAULT 0 COMMENT '技师性别偏好：0无偏好 1男 2女',
    `preferred_massage_style` VARCHAR(50)   DEFAULT NULL COMMENT '偏好按摩风格（如：轻柔/适中/重力）',
    `preferred_time_slot`     VARCHAR(100)  DEFAULT NULL COMMENT '偏好服务时段（JSON：如["09:00-12:00","19:00-22:00"]）',
    `allergies`               VARCHAR(500)  DEFAULT NULL COMMENT '过敏或禁忌（如：花生油过敏）',
    `special_notes`           VARCHAR(500)  DEFAULT NULL COMMENT '特殊备注（如：腰部有伤不可施压）',

    -- 个人健康信息（SPA场景使用）
    `height`                  SMALLINT      DEFAULT NULL COMMENT '身高（cm）',
    `weight`                  SMALLINT      DEFAULT NULL COMMENT '体重（kg）',

    -- 收藏与社交
    `favorite_tech_ids`       JSON          DEFAULT NULL COMMENT '收藏的技师ID列表',
    `review_count`            INT           NOT NULL DEFAULT 0 COMMENT '发表评价次数',
    `referral_count`          INT           NOT NULL DEFAULT 0 COMMENT '成功邀请注册人数',

    -- 标签（CRM运营用）
    `tags`                    JSON          DEFAULT NULL COMMENT '系统打标：高价值/复购/沉默/流失风险等',

    -- 时间戳
    `create_time`             DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time`             DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `deleted`                 TINYINT       NOT NULL DEFAULT 0 COMMENT '逻辑删除',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_user_id` (`user_id`),
    KEY `idx_member_level` (`member_level`),
    KEY `idx_last_order_time` (`last_order_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='会员扩展信息表（与 user_account 一对一，注册时自动初始化）';

-- ============================================================
-- 技师信息表
-- ============================================================
CREATE TABLE IF NOT EXISTS `technician_info` (
    `id`                   BIGINT        NOT NULL COMMENT '主键ID',
    `user_id`              BIGINT        NOT NULL COMMENT '关联 user_account.id',
    `real_name`            VARCHAR(50)   NOT NULL DEFAULT '' COMMENT '真实姓名',
    `age`                  TINYINT       DEFAULT NULL COMMENT '年龄',
    `age_tag`              VARCHAR(20)   DEFAULT NULL COMMENT '年代标签（90后/85后/00后）',
    `cert_status`          TINYINT       NOT NULL DEFAULT 0 COMMENT '认证状态：0待提交 1审核中 2已通过 3已拒绝',
    `skill_tags`           JSON          DEFAULT NULL COMMENT '技能标签JSON数组',
    `introduction`         TEXT          DEFAULT NULL COMMENT '服务简介',
    `service_city`         VARCHAR(100)  DEFAULT NULL COMMENT '服务城市',
    `service_radius`       DECIMAL(5,1)  NOT NULL DEFAULT 5.0 COMMENT '服务半径（公里）',
    `online_status`        TINYINT       NOT NULL DEFAULT 0 COMMENT '在线状态：0离线 1在线 2服务中',
    `latitude`             DECIMAL(10,7) DEFAULT NULL COMMENT '当前纬度',
    `longitude`            DECIMAL(10,7) DEFAULT NULL COMMENT '当前经度',
    `rating`               DECIMAL(3,1)  NOT NULL DEFAULT 5.0 COMMENT '综合评分（1-5）',
    `good_review_count`    INT           NOT NULL DEFAULT 0 COMMENT '好评数',
    `total_order_count`    INT           NOT NULL DEFAULT 0 COMMENT '总接单数',
    `return_customer_count` INT          NOT NULL DEFAULT 0 COMMENT '回头客数量',
    `merchant_id`          BIGINT        DEFAULT NULL COMMENT '所属商户ID（NULL=独立技师）',
    `id_card_front`        VARCHAR(500)  DEFAULT NULL COMMENT '证件照正面URL',
    `id_card_back`         VARCHAR(500)  DEFAULT NULL COMMENT '证件照背面URL',
    `health_cert_url`      VARCHAR(500)  DEFAULT NULL COMMENT '健康证URL',
    `reject_reason`        VARCHAR(500)  DEFAULT NULL COMMENT '审核拒绝原因',
    `free_transport`       TINYINT       NOT NULL DEFAULT 0 COMMENT '是否免车费：0否 1是',
    `earliest_book_hour`   INT           NOT NULL DEFAULT 30 COMMENT '最早可预约（次日几点，默认30=次日9:00）',
    `create_time`          DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time`          DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `deleted`              TINYINT       NOT NULL DEFAULT 0 COMMENT '逻辑删除',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_user_id` (`user_id`),
    KEY `idx_cert_status` (`cert_status`),
    KEY `idx_online_status` (`online_status`),
    KEY `idx_merchant_id` (`merchant_id`),
    KEY `idx_location` (`latitude`, `longitude`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='技师扩展信息表（与 user_account 一对一，注册时自动初始化）';

-- ============================================================
-- 商户信息表
-- ============================================================
CREATE TABLE IF NOT EXISTS `merchant_info` (
    `id`              BIGINT        NOT NULL COMMENT '主键ID',
    `user_id`         BIGINT        NOT NULL COMMENT '关联 user_account.id',
    `merchant_name`   VARCHAR(100)  NOT NULL DEFAULT '' COMMENT '商户名称',
    `logo`            VARCHAR(500)  DEFAULT NULL COMMENT 'Logo URL',
    `description`     TEXT          DEFAULT NULL COMMENT '商户简介',
    `address`         VARCHAR(500)  DEFAULT NULL COMMENT '商户地址',
    `latitude`        DECIMAL(10,7) DEFAULT NULL COMMENT '纬度',
    `longitude`       DECIMAL(10,7) DEFAULT NULL COMMENT '经度',
    `contact_phone`   VARCHAR(20)   DEFAULT NULL COMMENT '联系电话',
    `cert_status`     TINYINT       NOT NULL DEFAULT 0 COMMENT '认证状态：0待提交 1审核中 2已通过 3已拒绝',
    `status`          TINYINT       NOT NULL DEFAULT 0 COMMENT '状态：0正常 1禁用',
    `tech_count`      INT           NOT NULL DEFAULT 0 COMMENT '旗下技师数量',
    `business_hours`  VARCHAR(200)  DEFAULT NULL COMMENT '营业时间（JSON）',
    `service_scope`   JSON          DEFAULT NULL COMMENT '服务范围（服务类目ID列表）',
    `create_time`     DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time`     DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `deleted`         TINYINT       NOT NULL DEFAULT 0 COMMENT '逻辑删除',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='商户扩展信息表（与 user_account 一对一，注册时自动初始化）';

-- ============================================================
-- 服务类目表
-- ============================================================
CREATE TABLE IF NOT EXISTS `service_category` (
    `id`          BIGINT       NOT NULL COMMENT '主键ID',
    `name`        VARCHAR(50)  NOT NULL COMMENT '类目名称',
    `name_en`     VARCHAR(50)  DEFAULT NULL COMMENT '英文名',
    `name_vi`     VARCHAR(50)  DEFAULT NULL COMMENT '越南文名',
    `name_km`     VARCHAR(100) DEFAULT NULL COMMENT '柬埔寨文名',
    `icon`        VARCHAR(500) DEFAULT NULL COMMENT '图标URL',
    `sort_order`  INT          NOT NULL DEFAULT 0 COMMENT '排序',
    `status`      TINYINT      NOT NULL DEFAULT 1 COMMENT '状态：0禁用 1启用',
    `create_time` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `deleted`     TINYINT      NOT NULL DEFAULT 0 COMMENT '逻辑删除',
    PRIMARY KEY (`id`),
    KEY `idx_sort_order` (`sort_order`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='服务类目表';

-- ============================================================
-- 服务套餐表
-- ============================================================
CREATE TABLE IF NOT EXISTS `service_package` (
    `id`           BIGINT        NOT NULL COMMENT '主键ID',
    `technician_id` BIGINT       DEFAULT NULL COMMENT '技师ID（技师套餐）',
    `merchant_id`  BIGINT        DEFAULT NULL COMMENT '商户ID（商户套餐）',
    `category_id`  BIGINT        DEFAULT NULL COMMENT '服务类目ID',
    `name`         VARCHAR(100)  NOT NULL DEFAULT '' COMMENT '套餐名称',
    `description`  TEXT          DEFAULT NULL COMMENT '套餐描述',
    `duration`     INT           NOT NULL COMMENT '服务时长（分钟）',
    `price`        DECIMAL(10,2) NOT NULL COMMENT '原价（USD）',
    `member_price` DECIMAL(10,2) DEFAULT NULL COMMENT '会员价格',
    `cover_image`  VARCHAR(500)  DEFAULT NULL COMMENT '封面图片URL',
    `status`       TINYINT       NOT NULL DEFAULT 1 COMMENT '状态：0下架 1上架',
    `sort_order`   INT           NOT NULL DEFAULT 0 COMMENT '排序',
    `recommended`  TINYINT       NOT NULL DEFAULT 0 COMMENT '是否推荐',
    `hot`          TINYINT       NOT NULL DEFAULT 0 COMMENT '是否热门',
    `sold_count`   INT           NOT NULL DEFAULT 0 COMMENT '已售数量',
    `create_time`  DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time`  DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `deleted`      TINYINT       NOT NULL DEFAULT 0 COMMENT '逻辑删除',
    PRIMARY KEY (`id`),
    KEY `idx_technician_id` (`technician_id`),
    KEY `idx_merchant_id` (`merchant_id`),
    KEY `idx_category_id` (`category_id`),
    KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='服务套餐表';

-- ============================================================
-- 订单表（核心表）
-- ============================================================
CREATE TABLE IF NOT EXISTS `order_info` (
    `id`                     BIGINT        NOT NULL COMMENT '订单ID',
    `order_no`               VARCHAR(30)   NOT NULL COMMENT '订单编号（CB+时间+随机数）',
    `member_id`              BIGINT        NOT NULL COMMENT '下单会员ID（关联 user_account.id）',
    `technician_id`          BIGINT        NOT NULL COMMENT '技师ID（关联 user_account.id）',
    `merchant_id`            BIGINT        DEFAULT NULL COMMENT '商户ID（NULL=独立技师下单）',
    `package_id`             BIGINT        NOT NULL COMMENT '服务套餐ID',
    `package_name`           VARCHAR(100)  NOT NULL DEFAULT '' COMMENT '套餐名称（冗余，防套餐改动影响历史）',
    `duration`               INT           NOT NULL COMMENT '服务时长（分钟）',
    `service_address`        VARCHAR(500)  NOT NULL DEFAULT '' COMMENT '服务地址',
    `address_detail`         VARCHAR(200)  DEFAULT NULL COMMENT '地址详情（门牌号）',
    `address_lat`            DECIMAL(10,7) DEFAULT NULL COMMENT '服务地址纬度',
    `address_lng`            DECIMAL(10,7) DEFAULT NULL COMMENT '服务地址经度',
    `appointment_time`       DATETIME      NOT NULL COMMENT '预约服务时间',
    `start_time`             DATETIME      DEFAULT NULL COMMENT '实际服务开始时间',
    `end_time`               DATETIME      DEFAULT NULL COMMENT '实际服务结束时间',
    `status`                 TINYINT       NOT NULL DEFAULT 0 COMMENT '订单状态：0待支付 1已支付 2已接单 3服务中 4已完成 5已取消 6退款中 7已退款',
    `original_price`         DECIMAL(10,2) NOT NULL COMMENT '订单原价（USD）',
    `discount_amount`        DECIMAL(10,2) NOT NULL DEFAULT 0.00 COMMENT '优惠金额',
    `actual_amount`          DECIMAL(10,2) NOT NULL COMMENT '实际支付金额',
    `coupon_id`              BIGINT        DEFAULT NULL COMMENT '使用的优惠券ID',
    `pay_method`             TINYINT       DEFAULT NULL COMMENT '支付方式：1USDT 2ABA 3余额 4微信 5支付宝',
    `pay_time`               DATETIME      DEFAULT NULL COMMENT '支付时间',
    `payment_no`             VARCHAR(100)  DEFAULT NULL COMMENT '支付单号（关联 payment_record）',
    `remark`                 VARCHAR(500)  DEFAULT NULL COMMENT '用户备注',
    `accept_time`            DATETIME      DEFAULT NULL COMMENT '技师接单时间',
    `reject_reason`          VARCHAR(500)  DEFAULT NULL COMMENT '技师拒单原因',
    `cancel_reason`          VARCHAR(500)  DEFAULT NULL COMMENT '取消原因',
    `cancel_by`              TINYINT       DEFAULT NULL COMMENT '取消人：1会员 2技师 3系统',
    `refund_amount`          DECIMAL(10,2) DEFAULT NULL COMMENT '退款金额',
    `refund_time`            DATETIME      DEFAULT NULL COMMENT '退款时间',
    `reviewed`               TINYINT       NOT NULL DEFAULT 0 COMMENT '是否已评价：0否 1是',
    `pay_expire_time`        DATETIME      DEFAULT NULL COMMENT '支付超时时间',
    `create_time`            DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time`            DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `deleted`                TINYINT       NOT NULL DEFAULT 0 COMMENT '逻辑删除',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_order_no` (`order_no`),
    KEY `idx_member_id` (`member_id`),
    KEY `idx_technician_id` (`technician_id`),
    KEY `idx_status` (`status`),
    KEY `idx_appointment_time` (`appointment_time`),
    KEY `idx_pay_expire` (`pay_expire_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='订单表';

-- ============================================================
-- 支付记录表
-- ============================================================
CREATE TABLE IF NOT EXISTS `payment_record` (
    `id`                  BIGINT        NOT NULL COMMENT '主键ID',
    `payment_no`          VARCHAR(50)   NOT NULL COMMENT '平台支付单号',
    `order_id`            BIGINT        NOT NULL COMMENT '关联订单ID',
    `order_no`            VARCHAR(30)   NOT NULL COMMENT '关联订单编号',
    `user_id`             BIGINT        NOT NULL COMMENT '支付用户ID',
    `pay_method`          TINYINT       NOT NULL COMMENT '支付方式',
    `amount`              DECIMAL(10,2) NOT NULL COMMENT '支付金额（USD）',
    `usdt_rate`           DECIMAL(10,4) DEFAULT NULL COMMENT 'USDT汇率快照',
    `usdt_amount`         DECIMAL(18,6) DEFAULT NULL COMMENT 'USDT实际金额',
    `usdt_network`        VARCHAR(10)   DEFAULT NULL COMMENT 'USDT网络（TRC20/ERC20）',
    `usdt_receive_address` VARCHAR(100) DEFAULT NULL COMMENT 'USDT收款地址',
    `usdt_from_address`   VARCHAR(100)  DEFAULT NULL COMMENT 'USDT付款地址',
    `out_trade_no`        VARCHAR(100)  DEFAULT NULL COMMENT '第三方交易流水号',
    `aba_reference_no`    VARCHAR(50)   DEFAULT NULL COMMENT 'ABA转账参考号',
    `aba_screenshot_url`  VARCHAR(500)  DEFAULT NULL COMMENT 'ABA转账截图URL',
    `status`              TINYINT       NOT NULL DEFAULT 0 COMMENT '支付状态：0待支付 1支付中 2成功 3失败 4已退款',
    `paid_time`           DATETIME      DEFAULT NULL COMMENT '支付完成时间',
    `expire_time`         DATETIME      DEFAULT NULL COMMENT '支付超时时间',
    `remark`              VARCHAR(500)  DEFAULT NULL COMMENT '备注',
    `create_time`         DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time`         DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `deleted`             TINYINT       NOT NULL DEFAULT 0 COMMENT '逻辑删除',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_payment_no` (`payment_no`),
    KEY `idx_order_id` (`order_id`),
    KEY `idx_user_id` (`user_id`),
    KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='支付记录表';

-- ============================================================
-- 钱包表
-- ============================================================
CREATE TABLE IF NOT EXISTS `wallet` (
    `id`               BIGINT        NOT NULL COMMENT '主键ID',
    `user_id`          BIGINT        NOT NULL COMMENT '用户ID',
    `user_type`        TINYINT       NOT NULL COMMENT '用户类型：1会员 2技师 3商户',
    `balance`          DECIMAL(12,2) NOT NULL DEFAULT 0.00 COMMENT '可用余额（USD）',
    `frozen_balance`   DECIMAL(12,2) NOT NULL DEFAULT 0.00 COMMENT '冻结余额',
    `total_recharge`   DECIMAL(12,2) NOT NULL DEFAULT 0.00 COMMENT '累计充值',
    `total_withdraw`   DECIMAL(12,2) NOT NULL DEFAULT 0.00 COMMENT '累计提现',
    `total_income`     DECIMAL(12,2) NOT NULL DEFAULT 0.00 COMMENT '累计收入（技师/商户）',
    `total_consume`    DECIMAL(12,2) NOT NULL DEFAULT 0.00 COMMENT '累计消费（会员）',
    `version`          INT           NOT NULL DEFAULT 0 COMMENT '乐观锁版本号',
    `create_time`      DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time`      DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `deleted`          TINYINT       NOT NULL DEFAULT 0 COMMENT '逻辑删除',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='钱包表（注册时自动初始化）';

-- ============================================================
-- 钱包流水记录表
-- ============================================================
CREATE TABLE IF NOT EXISTS `wallet_record` (
    `id`             BIGINT        NOT NULL COMMENT '主键ID（雪花算法）',
    `wallet_id`      BIGINT        NOT NULL COMMENT '钱包ID',
    `user_id`        BIGINT        NOT NULL COMMENT '用户ID',
    `user_type`      TINYINT       NOT NULL COMMENT '用户类型：1会员 2技师 3商户',
    `record_type`    TINYINT       NOT NULL COMMENT '流水类型：1充值 2消费 3收入 4提现 5退款 6冻结 7解冻',
    `amount`         DECIMAL(12,2) NOT NULL COMMENT '金额（正数收入 负数支出）',
    `before_balance` DECIMAL(12,2) NOT NULL COMMENT '变动前余额',
    `after_balance`  DECIMAL(12,2) NOT NULL COMMENT '变动后余额',
    `order_no`       VARCHAR(64)   DEFAULT NULL COMMENT '关联订单号',
    `remark`         VARCHAR(200)  DEFAULT NULL COMMENT '流水说明',
    `out_trade_no`   VARCHAR(100)  DEFAULT NULL COMMENT '外部流水号',
    `create_time`    DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time`    DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `deleted`        TINYINT       NOT NULL DEFAULT 0 COMMENT '逻辑删除',
    PRIMARY KEY (`id`),
    KEY `idx_wallet_id` (`wallet_id`),
    KEY `idx_user_id` (`user_id`),
    KEY `idx_order_no` (`order_no`),
    KEY `idx_create_time` (`create_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='钱包流水记录表';

-- ============================================================
-- 优惠券模板表
-- ============================================================
CREATE TABLE IF NOT EXISTS `coupon_template` (
    `id`               BIGINT        NOT NULL COMMENT '主键ID',
    `name`             VARCHAR(100)  NOT NULL COMMENT '优惠券名称',
    `description`      VARCHAR(500)  DEFAULT NULL COMMENT '描述',
    `coupon_type`      TINYINT       NOT NULL COMMENT '类型：1满减券 2折扣券 3代金券 4免车费券',
    `min_amount`       DECIMAL(10,2) NOT NULL DEFAULT 0.00 COMMENT '最低使用金额',
    `discount_amount`  DECIMAL(10,2) DEFAULT NULL COMMENT '优惠金额',
    `discount_rate`    DECIMAL(4,2)  DEFAULT NULL COMMENT '折扣比例（0.8=8折）',
    `total_stock`      INT           NOT NULL DEFAULT -1 COMMENT '发行总量（-1无限量）',
    `remain_stock`     INT           NOT NULL DEFAULT 0 COMMENT '剩余库存',
    `limit_per_user`   INT           NOT NULL DEFAULT 1 COMMENT '每人限领数量',
    `valid_type`       TINYINT       NOT NULL DEFAULT 1 COMMENT '有效期类型：1固定日期 2领取后N天',
    `valid_start_time` DATETIME      DEFAULT NULL COMMENT '有效期开始',
    `valid_end_time`   DATETIME      DEFAULT NULL COMMENT '有效期结束',
    `valid_days`       INT           DEFAULT NULL COMMENT '领取后有效天数',
    `status`           TINYINT       NOT NULL DEFAULT 0 COMMENT '状态：0未开始 1进行中 2已结束 3已下架',
    `scope_type`       TINYINT       NOT NULL DEFAULT 1 COMMENT '适用范围：1全平台 2指定商户 3指定类目',
    `new_user_only`    TINYINT       NOT NULL DEFAULT 0 COMMENT '新客专属',
    `sort_order`       INT           NOT NULL DEFAULT 0 COMMENT '排序',
    `create_time`      DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time`      DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `deleted`          TINYINT       NOT NULL DEFAULT 0 COMMENT '逻辑删除',
    PRIMARY KEY (`id`),
    KEY `idx_status` (`status`),
    KEY `idx_coupon_type` (`coupon_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='优惠券模板表';

-- ============================================================
-- 用户优惠券领取记录表
-- ============================================================
CREATE TABLE IF NOT EXISTS `user_coupon` (
    `id`              BIGINT        NOT NULL COMMENT '主键ID',
    `template_id`     BIGINT        NOT NULL COMMENT '优惠券模板ID',
    `user_id`         BIGINT        NOT NULL COMMENT '持有用户ID',
    `status`          TINYINT       NOT NULL DEFAULT 0 COMMENT '状态：0未使用 1已使用 2已过期',
    `valid_start`     DATETIME      NOT NULL COMMENT '有效期开始',
    `valid_end`       DATETIME      NOT NULL COMMENT '有效期结束',
    `used_time`       DATETIME      DEFAULT NULL COMMENT '使用时间',
    `used_order_no`   VARCHAR(64)   DEFAULT NULL COMMENT '使用的订单号',
    `discount_amount` DECIMAL(10,2) DEFAULT NULL COMMENT '实际抵扣金额',
    `create_time`     DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '领取时间',
    `update_time`     DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `deleted`         TINYINT       NOT NULL DEFAULT 0 COMMENT '逻辑删除',
    PRIMARY KEY (`id`),
    KEY `idx_user_id` (`user_id`),
    KEY `idx_template_id` (`template_id`),
    KEY `idx_status` (`status`),
    KEY `idx_valid_end` (`valid_end`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户优惠券领取记录';

-- ============================================================
-- 技师排班表
-- ============================================================
CREATE TABLE IF NOT EXISTS `technician_schedule` (
    `id`              BIGINT    NOT NULL COMMENT '主键ID',
    `technician_id`   BIGINT    NOT NULL COMMENT '技师ID（关联 user_account.id）',
    `week_day`        TINYINT   NOT NULL COMMENT '星期：1-7（周一到周日）',
    `start_time`      TIME      NOT NULL COMMENT '可接单开始时间',
    `end_time`        TIME      NOT NULL COMMENT '可接单结束时间',
    `status`          TINYINT   NOT NULL DEFAULT 1 COMMENT '状态：0禁用 1启用',
    `create_time`     DATETIME  NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time`     DATETIME  NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `deleted`         TINYINT   NOT NULL DEFAULT 0 COMMENT '逻辑删除',
    PRIMARY KEY (`id`),
    KEY `idx_technician_id` (`technician_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='技师排班表';

-- ============================================================
-- 用户收货/服务地址表
-- ============================================================
CREATE TABLE IF NOT EXISTS `user_address` (
    `id`            BIGINT        NOT NULL COMMENT '主键ID',
    `user_id`       BIGINT        NOT NULL COMMENT '用户ID',
    `contact_name`  VARCHAR(50)   NOT NULL DEFAULT '' COMMENT '联系人姓名',
    `contact_phone` VARCHAR(20)   NOT NULL DEFAULT '' COMMENT '联系人手机号',
    `province`      VARCHAR(50)   DEFAULT NULL COMMENT '省/州',
    `city`          VARCHAR(50)   DEFAULT NULL COMMENT '城市',
    `district`      VARCHAR(50)   DEFAULT NULL COMMENT '区/县',
    `address`       VARCHAR(300)  NOT NULL DEFAULT '' COMMENT '详细地址',
    `latitude`      DECIMAL(10,7) DEFAULT NULL COMMENT '纬度',
    `longitude`     DECIMAL(10,7) DEFAULT NULL COMMENT '经度',
    `is_default`    TINYINT       NOT NULL DEFAULT 0 COMMENT '是否默认地址',
    `create_time`   DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time`   DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `deleted`       TINYINT       NOT NULL DEFAULT 0 COMMENT '逻辑删除',
    PRIMARY KEY (`id`),
    KEY `idx_user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户地址表';

-- ============================================================
-- 评价表
-- ============================================================
CREATE TABLE IF NOT EXISTS `review` (
    `id`                BIGINT    NOT NULL COMMENT '主键ID',
    `order_id`          BIGINT    NOT NULL COMMENT '订单ID',
    `user_id`           BIGINT    NOT NULL COMMENT '评价用户ID',
    `technician_id`     BIGINT    NOT NULL COMMENT '技师ID',
    `star_level`        TINYINT   NOT NULL COMMENT '综合星级（1-5）',
    `technique_score`   TINYINT   DEFAULT NULL COMMENT '手法评分',
    `attitude_score`    TINYINT   DEFAULT NULL COMMENT '服务态度评分',
    `punctuality_score` TINYINT   DEFAULT NULL COMMENT '准时评分',
    `content`           TEXT      DEFAULT NULL COMMENT '评价内容',
    `images`            JSON      DEFAULT NULL COMMENT '评价图片JSON数组',
    `tags`              JSON      DEFAULT NULL COMMENT '评价标签JSON数组',
    `anonymous`         TINYINT   NOT NULL DEFAULT 0 COMMENT '是否匿名',
    `status`            TINYINT   NOT NULL DEFAULT 0 COMMENT '状态：0正常 1用户删除 2管理员屏蔽',
    `reply_content`     TEXT      DEFAULT NULL COMMENT '技师回复',
    `reply_time`        DATETIME  DEFAULT NULL COMMENT '技师回复时间',
    `create_time`       DATETIME  NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '评价时间',
    `update_time`       DATETIME  NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `deleted`           TINYINT   NOT NULL DEFAULT 0 COMMENT '逻辑删除',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_order_id` (`order_id`),
    KEY `idx_user_id` (`user_id`),
    KEY `idx_technician_id` (`technician_id`),
    KEY `idx_star_level` (`star_level`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='评价表';

-- ============================================================
-- IM 会话表
-- ============================================================
CREATE TABLE IF NOT EXISTS `im_session` (
    `id`             BIGINT    NOT NULL COMMENT '主键ID',
    `user_id`        BIGINT    NOT NULL COMMENT '用户ID（会员/技师）',
    `target_id`      BIGINT    NOT NULL COMMENT '对方ID',
    `target_type`    TINYINT   NOT NULL COMMENT '对方类型：1会员 2技师 3客服',
    `last_message`   TEXT      DEFAULT NULL COMMENT '最后一条消息',
    `last_msg_time`  DATETIME  DEFAULT NULL COMMENT '最后消息时间',
    `unread_count`   INT       NOT NULL DEFAULT 0 COMMENT '未读消息数',
    `create_time`    DATETIME  NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time`    DATETIME  NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `deleted`        TINYINT   NOT NULL DEFAULT 0 COMMENT '逻辑删除',
    PRIMARY KEY (`id`),
    KEY `idx_user_id` (`user_id`),
    KEY `idx_target_id` (`target_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='IM会话表';

-- ============================================================
-- IM 消息表
-- ============================================================
CREATE TABLE IF NOT EXISTS `im_message` (
    `id`              BIGINT       NOT NULL COMMENT '主键ID',
    `session_id`      BIGINT       NOT NULL COMMENT '会话ID',
    `sender_id`       BIGINT       NOT NULL COMMENT '发送者ID',
    `sender_type`     TINYINT      NOT NULL COMMENT '发送者类型：1会员 2技师 3客服',
    `receiver_id`     BIGINT       NOT NULL COMMENT '接收者ID',
    `receiver_type`   TINYINT      NOT NULL COMMENT '接收者类型',
    `msg_type`        TINYINT      NOT NULL DEFAULT 1 COMMENT '消息类型：1文本 2图片 3语音 4订单卡片 5系统通知',
    `content`         TEXT         NOT NULL COMMENT '消息内容',
    `image_url`       VARCHAR(500) DEFAULT NULL COMMENT '图片URL',
    `read_status`     TINYINT      NOT NULL DEFAULT 0 COMMENT '已读状态：0未读 1已读',
    `recall_status`   TINYINT      NOT NULL DEFAULT 0 COMMENT '撤回状态：0正常 1已撤回',
    `create_time`     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '发送时间',
    `update_time`     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `deleted`         TINYINT      NOT NULL DEFAULT 0 COMMENT '逻辑删除',
    PRIMARY KEY (`id`),
    KEY `idx_session_id` (`session_id`),
    KEY `idx_sender_id` (`sender_id`),
    KEY `idx_receiver_id` (`receiver_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='IM消息表';

-- ============================================================
-- 轮播图表
-- ============================================================
CREATE TABLE IF NOT EXISTS `banner` (
    `id`          BIGINT       NOT NULL COMMENT '主键ID',
    `title`       VARCHAR(100) NOT NULL DEFAULT '' COMMENT '标题',
    `image_url`   VARCHAR(500) NOT NULL COMMENT '图片URL',
    `link_url`    VARCHAR(500) DEFAULT NULL COMMENT '跳转链接',
    `link_type`   TINYINT      DEFAULT NULL COMMENT '跳转类型：1外链 2内部页面',
    `position`    TINYINT      NOT NULL DEFAULT 1 COMMENT '展示位置：1首页 2技师页 3发现页',
    `sort_order`  INT          NOT NULL DEFAULT 0 COMMENT '排序',
    `status`      TINYINT      NOT NULL DEFAULT 1 COMMENT '状态：0禁用 1启用',
    `start_time`  DATETIME     DEFAULT NULL COMMENT '展示开始时间',
    `end_time`    DATETIME     DEFAULT NULL COMMENT '展示结束时间',
    `create_time` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `deleted`     TINYINT      NOT NULL DEFAULT 0 COMMENT '逻辑删除',
    PRIMARY KEY (`id`),
    KEY `idx_position` (`position`),
    KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='轮播图表';

-- ============================================================
-- 系统配置表
-- ============================================================
CREATE TABLE IF NOT EXISTS `sys_config` (
    `id`           BIGINT       NOT NULL COMMENT '主键ID',
    `config_key`   VARCHAR(100) NOT NULL COMMENT '配置键',
    `config_value` TEXT         DEFAULT NULL COMMENT '配置值',
    `description`  VARCHAR(500) DEFAULT NULL COMMENT '配置说明',
    `config_type`  TINYINT      NOT NULL DEFAULT 1 COMMENT '类型：1字符串 2数字 3JSON 4开关',
    `create_time`  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time`  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `deleted`      TINYINT      NOT NULL DEFAULT 0 COMMENT '逻辑删除',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_config_key` (`config_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='系统配置表';

-- ============================================================
-- 初始化数据
-- ============================================================
INSERT IGNORE INTO `service_category` (`id`, `name`, `name_en`, `name_vi`, `name_km`, `sort_order`, `status`) VALUES
(1000000000001, '全身推拿',  'Full Body Massage',    'Massage Toàn Thân',    'ម៉ាស្សាផ្នែករន្ធ', 1, 1),
(1000000000002, '足疗足浴',  'Foot Massage',          'Massage Chân',         'ម៉ាស្សាជើង',        2, 1),
(1000000000003, '精油SPA',   'Aromatherapy SPA',      'SPA Tinh Dầu',         'SPA ប្រេងក្រអូប',   3, 1),
(1000000000004, '热石按摩',  'Hot Stone Massage',     'Massage Đá Nóng',      'ម៉ាស្សាថ្ម',         4, 1),
(1000000000005, '中式推拿',  'Chinese Tuina',         'Tẩm Quất Trung Hoa',  'តុយណា',             5, 1),
(1000000000006, '泰式按摩',  'Thai Massage',          'Massage Thái',         'ម៉ាស្សាថៃ',          6, 1),
(1000000000007, '头颈肩理疗','Head & Neck Therapy',   'Trị Liệu Đầu Cổ',     'ព្យាបាលក',           7, 1),
(1000000000008, '产后恢复',  'Postnatal Recovery',    'Phục Hồi Sau Sinh',   'ងើបឡើងក្រោយសម្រាល', 8, 1);

INSERT IGNORE INTO `sys_config` (`id`, `config_key`, `config_value`, `description`, `config_type`) VALUES
(1,  'platform_name',              'CamBook',          '平台名称',                       1),
(2,  'customer_service_phone',     '+855-12-345-678',  '客服电话',                       1),
(3,  'order_timeout_minutes',      '15',               '订单支付超时时间（分钟）',         2),
(4,  'tech_accept_timeout_seconds','60',               '技师接单超时时间（秒）',           2),
(5,  'platform_commission_rate',   '0.15',             '平台佣金比例（15%）',              2),
(6,  'min_withdraw_amount',        '10.00',            '最低提现金额（USD）',              2),
(7,  'usdt_payment_enabled',       '1',                '是否启用USDT支付',                4),
(8,  'aba_payment_enabled',        '1',                '是否启用ABA支付',                 4),
(9,  'member_level_silver_amount', '500.00',           '白银会员消费门槛（USD）',          2),
(10, 'member_level_gold_amount',   '2000.00',          '黄金会员消费门槛（USD）',          2),
(11, 'member_level_platinum_amount','5000.00',         '铂金会员消费门槛（USD）',          2),
(12, 'member_level_diamond_amount','10000.00',         '钻石会员消费门槛（USD）',          2);
