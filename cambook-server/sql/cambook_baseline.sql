-- ═══════════════════════════════════════════════════════════════════════════
-- CamBook 全量基线 SQL（含 Schema + 全部历史 Migration v5.0 ~ v5.13）
--
-- 此文件用于全新环境部署，包含：
--   1. 完整表结构
--   2. 历史 migration（v2 ~ v4 archive）
--   3. v5.0 ~ v5.13 全部 migration
--
-- 部署顺序：
--   1. 执行本文件（cambook_baseline.sql）
--   2. 执行 migrate_v5_14_i18n_errors.sql（多语言错误码：zh/en/vi/km/th）
--
-- ⚠️  生产部署前请先在测试环境验证！
-- ═══════════════════════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════════════════════
-- SECTION 1: 完整表结构（schema_v3.sql）
-- ═══════════════════════════════════════════════════════════════════════════
-- ================================================================================
-- 项目名称：CamBook 上门 SPA 服务平台
-- 文件描述：完整数据库建表脚本（v3.0）
-- 字符集  ：utf8mb4（支持 Emoji 及东南亚多国字符）
-- 排序规则：utf8mb4_unicode_ci
-- 存储引擎：InnoDB（支持事务、行锁、外键）
-- 目标数据库：cambook
-- 作者    ：CamBook Team
-- 创建时间：2026-04-13
-- 修订记录：
--   v1.0  2026-01-01  初始版本
--   v2.0  2026-02-15  拆分 admin / app 模块，统一命名前缀
--   v3.0  2026-04-13  重构全部表结构；新增 cb_driver / cb_vehicle / cb_dispatch_order
-- ================================================================================
--
-- 【命名规范】
--   sys_   后台管理类：管理员、角色、权限、字典、配置、操作日志、国际化
--   cb_    业务数据类：会员、技师、商户、订单、评价、钱包、优惠券、IM、通知等
--
-- 【设计原则】
--   1. 避免频繁连表：业务主体信息在单表内合并存储（如会员钱包字段合入 cb_member）
--   2. 多语言字段策略：
--      · 展示类文本（名称/地址/简介）直接在表中存 _zh / _en / _vi / _km 列
--      · 接口响应消息通过 sys_i18n 枚举驱动，启动时加载入内存
--   3. 逻辑删除：业务主表统一使用 deleted TINYINT（0=正常 1=已删除）
--   4. 审计字段：create_time / update_time 由 MyBatis-Plus 自动填充
--   5. RBAC 权限粒度：菜单 → 按钮级别，每个操作项均可独立配置开关
--   6. 金额字段：统一使用 DECIMAL(12,2) 或 DECIMAL(10,2)，单位 USD
--   7. 坐标字段：使用 DECIMAL(10,7)，精度约为 ±1.1cm
-- ================================================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- --------------------------------------------------------------------------------
-- 清理全部旧表（保证脚本幂等，可重复执行）
-- 注意：生产环境执行前请务必备份数据！
-- --------------------------------------------------------------------------------
DROP TABLE IF EXISTS `cb_login_log`;
DROP TABLE IF EXISTS `cb_notification`;
DROP TABLE IF EXISTS `cb_im_message`;
DROP TABLE IF EXISTS `cb_im_session`;
DROP TABLE IF EXISTS `cb_tag`;
DROP TABLE IF EXISTS `cb_icon`;
DROP TABLE IF EXISTS `cb_nav`;
DROP TABLE IF EXISTS `cb_banner`;
DROP TABLE IF EXISTS `cb_technician_schedule`;
DROP TABLE IF EXISTS `cb_address`;
DROP TABLE IF EXISTS `cb_member_coupon`;
DROP TABLE IF EXISTS `cb_coupon_template`;
DROP TABLE IF EXISTS `cb_wallet_record`;
DROP TABLE IF EXISTS `cb_wallet`;
DROP TABLE IF EXISTS `cb_payment`;
DROP TABLE IF EXISTS `cb_review`;
DROP TABLE IF EXISTS `cb_order`;
DROP TABLE IF EXISTS `cb_service_item`;
DROP TABLE IF EXISTS `cb_service_category`;
DROP TABLE IF EXISTS `cb_merchant`;
DROP TABLE IF EXISTS `cb_technician`;
DROP TABLE IF EXISTS `cb_member`;
DROP TABLE IF EXISTS `cb_dispatch_order`;
DROP TABLE IF EXISTS `cb_driver`;
DROP TABLE IF EXISTS `cb_vehicle`;
DROP TABLE IF EXISTS `sys_operation_log`;
DROP TABLE IF EXISTS `sys_user_role`;
DROP TABLE IF EXISTS `sys_role_permission`;
DROP TABLE IF EXISTS `sys_permission`;
DROP TABLE IF EXISTS `sys_role`;
DROP TABLE IF EXISTS `sys_user`;
DROP TABLE IF EXISTS `sys_config`;
DROP TABLE IF EXISTS `sys_dict`;
DROP TABLE IF EXISTS `sys_dict_type`;
DROP TABLE IF EXISTS `sys_i18n`;


-- ================================================================================
-- 一、系统管理模块（sys_ 前缀）
-- ================================================================================


-- --------------------------------------------------------------------------------
-- sys_i18n：国际化枚举消息表
-- 描述：存储所有接口响应枚举的多语言消息，支持中/英/越/柬/日/韩六种语言。
--       系统启动时由 I18nMessageLoader（ApplicationRunner）一次性加载至
--       CbCodeEnum.messages（volatile Map），后续通过 I18nContext（ThreadLocal）
--       根据请求的 Accept-Language 头动态返回对应语言消息。
-- 唯一键：enum_code + lang 联合唯一，防止重复录入
-- --------------------------------------------------------------------------------
CREATE TABLE `sys_i18n` (
    `id`          BIGINT       NOT NULL AUTO_INCREMENT          COMMENT '主键，自增',
    `enum_code`   VARCHAR(100) NOT NULL                        COMMENT '枚举常量名，与 CbCodeEnum 枚举值一一对应，如 SUCCESS / PARAM_ERROR',
    `lang`        VARCHAR(10)  NOT NULL                        COMMENT '语言标识：zh=中文 en=英文 vi=越南文 km=柬埔寨文 ja=日文 ko=韩文',
    `message`     VARCHAR(500) NOT NULL                        COMMENT '对应语言的消息文本',
    `create_time` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间，自动填充',
    `update_time` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '最后修改时间，自动更新',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_enum_lang`  (`enum_code`, `lang`) COMMENT '枚举+语言联合唯一，防止重复',
    KEY           `idx_enum_code` (`enum_code`)      COMMENT '按枚举码快速检索'
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci
  COMMENT = '国际化枚举消息表：存储接口响应消息的多语言内容，启动时加载入内存';


-- --------------------------------------------------------------------------------
-- sys_dict_type：字典类型表
-- 描述：用于管理系统内各类枚举类型的元数据，如订单状态、支付方式等。
--       与 sys_dict 配合使用，实现无代码扩展字典项。
-- --------------------------------------------------------------------------------
CREATE TABLE `sys_dict_type` (
    `id`          BIGINT       NOT NULL AUTO_INCREMENT          COMMENT '主键，自增',
    `dict_type`   VARCHAR(100) NOT NULL                        COMMENT '字典类型唯一标识（英文小写+下划线），如 order_status / pay_type',
    `dict_name`   VARCHAR(100) NOT NULL                        COMMENT '字典类型名称（中文可读），如 订单状态',
    `status`      TINYINT      NOT NULL DEFAULT 1              COMMENT '状态：1=启用 0=停用',
    `remark`      VARCHAR(500)                                 COMMENT '备注说明，可为空',
    `create_time` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '最后修改时间',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_dict_type` (`dict_type`) COMMENT '字典类型标识全局唯一'
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci
  COMMENT = '字典类型表：管理所有枚举类型的元信息';


-- --------------------------------------------------------------------------------
-- sys_dict：字典数据表
-- 描述：存储各字典类型下的具体字典项，支持六种语言标签，前端可直接映射展示。
--       多语言标签按需填写，缺省时前端降级展示 label_zh（中文）。
-- --------------------------------------------------------------------------------
CREATE TABLE `sys_dict` (
    `id`          BIGINT       NOT NULL AUTO_INCREMENT          COMMENT '主键，自增',
    `dict_type`   VARCHAR(100) NOT NULL                        COMMENT '所属字典类型，关联 sys_dict_type.dict_type',
    `dict_value`  VARCHAR(100) NOT NULL                        COMMENT '字典值（程序使用的实际值），如 1 / PENDING / ABA',
    `label_zh`    VARCHAR(200) NOT NULL                        COMMENT '中文标签，必填',
    `label_en`    VARCHAR(200)                                 COMMENT '英文标签',
    `label_vi`    VARCHAR(200)                                 COMMENT '越南文标签',
    `label_km`    VARCHAR(200)                                 COMMENT '柬埔寨文标签',
    `label_ja`    VARCHAR(200)                                 COMMENT '日文标签',
    `label_ko`    VARCHAR(200)                                 COMMENT '韩文标签',
    `sort`        INT          NOT NULL DEFAULT 0              COMMENT '排序权重，值越小越靠前',
    `status`      TINYINT      NOT NULL DEFAULT 1              COMMENT '状态：1=启用 0=停用',
    `remark`      VARCHAR(200)                                 COMMENT '附加信息：Ant Design Tag color / 品牌色 hex / 国旗 emoji 等',
    `create_time` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '最后修改时间',
    PRIMARY KEY (`id`),
    KEY `idx_dict_type` (`dict_type`) COMMENT '按字典类型检索字典项'
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci
  COMMENT = '字典数据表：存储各字典类型的字典项及其多语言标签';


-- --------------------------------------------------------------------------------
-- sys_config：系统配置表
-- 描述：KV 结构的系统参数配置，支持分组管理。值支持纯字符串和 JSON 格式，
--       适用于存储短信签名、支付密钥前缀、APP 开关等运营配置项。
--       注意：涉及密钥等敏感配置请加密存储，不可明文。
-- --------------------------------------------------------------------------------
CREATE TABLE `sys_config` (
    `id`           BIGINT       NOT NULL AUTO_INCREMENT          COMMENT '主键，自增',
    `config_group` VARCHAR(100) NOT NULL                        COMMENT '配置分组，用于逻辑归类，如 sms / payment / app / oss',
    `config_key`   VARCHAR(200) NOT NULL                        COMMENT '配置键名（分组内唯一），如 sms.sign / payment.aba.merchant_id',
    `config_value` TEXT                                         COMMENT '配置值，支持纯文本和 JSON 字符串',
    `remark`       VARCHAR(500)                                 COMMENT '配置项说明，建议填写用途和格式说明',
    `create_time`  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time`  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '最后修改时间',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_group_key` (`config_group`, `config_key`) COMMENT '分组+键名联合唯一'
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci
  COMMENT = '系统配置表：KV 格式，支持分组，适用于动态运营参数配置';


-- --------------------------------------------------------------------------------
-- sys_user：后台管理员账号表
-- 描述：存储后台管理系统的操作账号，支持账号密码登录。
--       密码使用 BCrypt 加密存储，禁止明文。
--       一个管理员可关联多个角色（sys_user_role）。
-- --------------------------------------------------------------------------------
CREATE TABLE `sys_user` (
    `id`              BIGINT       NOT NULL AUTO_INCREMENT          COMMENT '主键，自增',
    `username`        VARCHAR(50)  NOT NULL                        COMMENT '登录账号（全局唯一，4-32位，字母/数字/下划线）',
    `password`        VARCHAR(100) NOT NULL                        COMMENT '登录密码（BCrypt 哈希，禁止明文存储）',
    `real_name`       VARCHAR(50)                                  COMMENT '真实姓名，用于后台日志展示',
    `avatar`          VARCHAR(500)                                 COMMENT '头像图片 URL',
    `email`           VARCHAR(100)                                 COMMENT '邮箱地址，可用于找回密码',
    `mobile`          VARCHAR(20)                                  COMMENT '手机号，可用于告警通知',
    `status`          TINYINT      NOT NULL DEFAULT 1              COMMENT '账号状态：1=正常可用 0=已停用',
    `last_login_time` DATETIME                                     COMMENT '最后一次登录时间',
    `last_login_ip`   VARCHAR(50)                                  COMMENT '最后一次登录 IP 地址',
    `deleted`         TINYINT      NOT NULL DEFAULT 0              COMMENT '逻辑删除标识：0=正常 1=已删除',
    `create_time`     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '账号创建时间',
    `update_time`     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '最后修改时间',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_username` (`username`) COMMENT '登录账号全局唯一',
    KEY `idx_mobile`   (`mobile`)         COMMENT '按手机号快速查询'
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci
  COMMENT = '后台管理员账号表：支持账号密码登录，关联角色进行 RBAC 权限控制';


-- --------------------------------------------------------------------------------
-- sys_role：角色表
-- 描述：定义后台管理系统的角色，每个角色可关联一组权限。
--       系统预置角色：SUPER_ADMIN（超级管理员，拥有所有权限，不受 RBAC 限制）。
--       普通角色通过 sys_role_permission 关联具体权限项。
-- --------------------------------------------------------------------------------
CREATE TABLE `sys_role` (
    `id`          BIGINT       NOT NULL AUTO_INCREMENT          COMMENT '主键，自增',
    `role_code`   VARCHAR(100) NOT NULL                        COMMENT '角色编码（全局唯一，大写字母+下划线），如 SUPER_ADMIN / OPERATOR / AUDITOR',
    `role_name`   VARCHAR(100) NOT NULL                        COMMENT '角色名称（中文可读），如 超级管理员 / 运营人员',
    `remark`      VARCHAR(500)                                 COMMENT '角色说明，描述该角色的职责范围',
    `sort`        INT          NOT NULL DEFAULT 0              COMMENT '排序权重，值越小越靠前',
    `status`      TINYINT      NOT NULL DEFAULT 1              COMMENT '状态：1=启用 0=停用',
    `deleted`     TINYINT      NOT NULL DEFAULT 0              COMMENT '逻辑删除：0=正常 1=已删除',
    `create_time` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '最后修改时间',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_role_code` (`role_code`) COMMENT '角色编码全局唯一'
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci
  COMMENT = '角色表：定义 RBAC 角色，一角色可关联多个权限，一管理员可持有多个角色';


-- --------------------------------------------------------------------------------
-- sys_permission：权限 / 菜单表
-- 描述：采用树形结构存储权限项，通过 parent_id 自关联构建三级树：
--         目录（type=1）→ 菜单（type=2）→ 按钮/操作（type=3）
--       code 字段定义权限标识，格式为 "模块:操作"，如 member:list / order:delete。
--       type=3 的按钮级权限用于控制 API 接口访问，由 @RequirePermission 注解引用。
-- --------------------------------------------------------------------------------
CREATE TABLE `sys_permission` (
    `id`          BIGINT       NOT NULL AUTO_INCREMENT          COMMENT '主键，自增',
    `parent_id`   BIGINT       NOT NULL DEFAULT 0              COMMENT '父节点 ID；0 表示顶级目录，即根节点',
    `name`        VARCHAR(100) NOT NULL                        COMMENT '权限/菜单名称，如 会员管理 / 查看列表',
    `code`        VARCHAR(200)                                 COMMENT '权限标识（格式 模块:操作，如 member:list / order:delete），按钮级权限必填，目录/菜单可为空',
    `type`        TINYINT      NOT NULL                        COMMENT '节点类型：1=目录（仅分组，无路由） 2=菜单（有页面路由） 3=按钮/操作权限（控制接口）',
    `path`        VARCHAR(500)                                 COMMENT '前端路由路径，type=2 时必填，如 /member/list',
    `component`   VARCHAR(500)                                 COMMENT '前端组件相对路径，type=2 时必填，如 member/MemberList',
    `icon`        VARCHAR(100)                                 COMMENT '菜单图标名或图标 URL，前端展示使用',
    `sort`        INT          NOT NULL DEFAULT 0              COMMENT '同级节点排序权重，值越小越靠前',
    `portal_type` TINYINT      NOT NULL DEFAULT 0              COMMENT '所属门户：0=管理端 1=商户端',
    `visible`     TINYINT      NOT NULL DEFAULT 1              COMMENT '是否在侧边菜单中显示：1=显示 0=隐藏（如详情页路由）',
    `status`      TINYINT      NOT NULL DEFAULT 1              COMMENT '状态：1=启用 0=停用（停用后角色无法使用该权限）',
    `deleted`     TINYINT      NOT NULL DEFAULT 0              COMMENT '逻辑删除：0=正常 1=已删除',
    `create_time` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '最后修改时间',
    PRIMARY KEY (`id`),
    KEY `idx_parent_id` (`parent_id`) COMMENT '按父节点 ID 查询子节点，构建权限树'
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci
  COMMENT = '权限菜单表：树形结构，三级（目录/菜单/按钮），实现 RBAC 到按钮级粒度';


-- --------------------------------------------------------------------------------
-- sys_role_permission：角色权限关联表
-- 描述：多对多关联，记录角色与权限项的绑定关系。
--       当管理员登录时，根据其角色聚合权限编码列表，存入 Redis 缓存。
-- --------------------------------------------------------------------------------
CREATE TABLE `sys_role_permission` (
    `id`            BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键，自增',
    `role_id`       BIGINT NOT NULL               COMMENT '角色 ID，关联 sys_role.id',
    `permission_id` BIGINT NOT NULL               COMMENT '权限 ID，关联 sys_permission.id',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_role_perm` (`role_id`, `permission_id`) COMMENT '角色与权限联合唯一，防止重复授权'
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci
  COMMENT = '角色权限关联表：多对多，记录角色拥有的权限项';


-- --------------------------------------------------------------------------------
-- sys_user_role：管理员角色关联表
-- 描述：多对多关联，记录管理员账号与角色的绑定关系。
--       一个管理员可同时拥有多个角色，权限取所有角色权限的并集。
-- --------------------------------------------------------------------------------
CREATE TABLE `sys_user_role` (
    `id`      BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键，自增',
    `user_id` BIGINT NOT NULL               COMMENT '管理员 ID，关联 sys_user.id',
    `role_id` BIGINT NOT NULL               COMMENT '角色 ID，关联 sys_role.id',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_user_role` (`user_id`, `role_id`) COMMENT '管理员与角色联合唯一，防止重复绑定'
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci
  COMMENT = '管理员角色关联表：多对多，记录管理员所持有的角色';


-- --------------------------------------------------------------------------------
-- sys_operation_log：后台操作日志表
-- 描述：记录管理员在后台系统中的每一次操作，用于审计追溯。
--       由切面（OperationLogAspect）自动拦截并异步写入，不影响接口性能。
-- --------------------------------------------------------------------------------
CREATE TABLE `sys_operation_log` (
    `id`            BIGINT        NOT NULL AUTO_INCREMENT COMMENT '主键，自增',
    `user_id`       BIGINT                               COMMENT '操作管理员 ID，关联 sys_user.id',
    `username`      VARCHAR(100)                         COMMENT '操作管理员账号（冗余快照，防关联查询）',
    `module`        VARCHAR(100)                         COMMENT '所属功能模块，如 会员管理 / 订单管理',
    `action`        VARCHAR(200)                         COMMENT '操作描述，如 封禁会员 / 审核通过技师',
    `method`        VARCHAR(300)                         COMMENT '目标方法全限定名，如 com.cambook.app.controller.admin.MemberController.updateStatus',
    `request_url`   VARCHAR(500)                         COMMENT '请求 URL，如 /admin/member/123/status',
    `request_param` TEXT                                 COMMENT '请求参数（JSON 格式，敏感字段如密码应脱敏后记录）',
    `response_code` INT                                  COMMENT '接口响应 HTTP 状态码',
    `cost_ms`       INT                                  COMMENT '接口执行耗时（毫秒），用于性能监控',
    `ip`            VARCHAR(50)                          COMMENT '操作者 IP 地址',
    `create_time`   DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '操作发生时间',
    PRIMARY KEY (`id`),
    KEY `idx_user_id`    (`user_id`)    COMMENT '按管理员查询操作历史',
    KEY `idx_create_time`(`create_time`) COMMENT '按时间区间检索，支持定期清理历史日志'
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci
  COMMENT = '后台操作日志：记录管理员所有操作行为，用于安全审计';


-- ================================================================================
-- 二、业务核心模块（cb_ 前缀）
-- ================================================================================


-- --------------------------------------------------------------------------------
-- cb_member：会员表
-- 描述：平台 C 端用户主表，采用"账号 + 钱包 + 等级"三合一设计，
--       避免频繁 JOIN 导致查询性能下降。
--       手机号作为唯一登录账号，短信验证码方式认证（无需密码）。
--       member_no 格式建议：CB + yyyyMMdd + 6位序列，如 CB202604130001。
-- --------------------------------------------------------------------------------
CREATE TABLE `cb_member` (
    `id`              BIGINT        NOT NULL AUTO_INCREMENT          COMMENT '主键，自增',
    `member_no`       VARCHAR(32)   NOT NULL                        COMMENT '会员编号，业务唯一标识，格式 CB+日期+序号，如 CB202604130001',
    `mobile`          VARCHAR(20)   NOT NULL                        COMMENT '手机号（国际格式，含国家代码，如 +85512345678），全局唯一，作为登录账号',
    `password`        VARCHAR(100)                                  COMMENT '密码（BCrypt 哈希，预留字段，当前使用短信验证码登录可不填）',
    `nickname`        VARCHAR(50)                                   COMMENT '昵称，用户设置的展示名称',
    `avatar`          VARCHAR(500)                                  COMMENT '头像图片 URL，默认使用系统默认头像',
    `gender`          TINYINT       NOT NULL DEFAULT 0              COMMENT '性别：0=未知 1=男 2=女',
    `birthday`        DATE                                          COMMENT '生日（yyyy-MM-dd），用于会员营销和生日特权',
    `real_name`       VARCHAR(50)                                   COMMENT '真实姓名（实名认证后填写）',
    `id_card`         VARCHAR(50)                                   COMMENT '证件号（护照/身份证，建议加密存储）',
    `lang`            VARCHAR(10)   NOT NULL DEFAULT 'zh'           COMMENT '首选语言：zh=中文 en=英文 vi=越南文 km=柬埔寨文 ja=日文 ko=韩文',
    `level`           TINYINT       NOT NULL DEFAULT 0              COMMENT '会员等级：0=普通 1=银卡 2=金卡 3=钻石',
    `points`          INT           NOT NULL DEFAULT 0              COMMENT '积分余额（消费/活动累积，可用于兑换）',
    `inviter_id`      BIGINT                                        COMMENT '邀请人会员 ID（注册时填写邀请码关联），关联 cb_member.id',
    `invite_code`     VARCHAR(20)                                   COMMENT '我的邀请码（随机生成，唯一），用于分享拉新',
    `balance`         DECIMAL(12,2) NOT NULL DEFAULT 0.00           COMMENT '钱包余额（USD，保留两位小数），充值/退款增加，消费减少',
    `total_recharge`  DECIMAL(12,2) NOT NULL DEFAULT 0.00           COMMENT '累计充值金额（USD，只增不减，用于等级评定和活动门槛）',
    `total_spend`     DECIMAL(12,2) NOT NULL DEFAULT 0.00           COMMENT '累计消费金额（USD，只增不减，用于分析用户价值）',
    `order_count`     INT           NOT NULL DEFAULT 0              COMMENT '累计完成订单数量（status=6 已完成才计入）',
    `status`          TINYINT       NOT NULL DEFAULT 1              COMMENT '账号状态：1=正常 2=封禁（禁止登录和下单） 3=注销申请中',
    `register_source` TINYINT       NOT NULL DEFAULT 1              COMMENT '注册来源：1=APP 2=H5',
    `register_ip`     VARCHAR(50)                                   COMMENT '注册时的 IP 地址，用于反欺诈分析',
    `register_time`   DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '注册时间',
    `last_login_time` DATETIME                                      COMMENT '最后一次登录时间',
    `last_login_ip`   VARCHAR(50)                                   COMMENT '最后一次登录 IP',
    `deleted`         TINYINT       NOT NULL DEFAULT 0              COMMENT '逻辑删除：0=正常 1=已注销删除',
    `create_time`     DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '记录创建时间（同 register_time，由 MyBatis-Plus 自动填充）',
    `update_time`     DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '记录最后修改时间，自动更新',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_mobile`     (`mobile`)     COMMENT '手机号全局唯一，保证一号一账号',
    UNIQUE KEY `uk_member_no`  (`member_no`)  COMMENT '会员编号全局唯一',
    KEY `idx_invite_code`      (`invite_code`) COMMENT '按邀请码检索，用于注册时关联邀请人'
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci
  COMMENT = '会员表：账号+钱包+等级三合一设计，避免频繁连表';


-- --------------------------------------------------------------------------------
-- cb_technician：技师表
-- 描述：技师入驻信息主表，包含认证资料、服务能力、收入统计等完整信息。
--       技师可以是独立技师（merchant_id 为空）或隶属某商户。
--       intro_*  字段存储多语言简介，前端根据用户语言偏好展示对应版本。
--       audit_status 由审核员在后台操作，通过后方可接单。
-- --------------------------------------------------------------------------------
CREATE TABLE `cb_technician` (
    `id`               BIGINT        NOT NULL AUTO_INCREMENT          COMMENT '主键，自增',
    `tech_no`          VARCHAR(32)   NOT NULL                        COMMENT '技师编号，业务唯一标识，格式 T+日期+序号',
    `member_id`        BIGINT                                        COMMENT '关联会员 ID（若技师同时是会员则关联，否则为空），关联 cb_member.id',
    `mobile`           VARCHAR(20)   NOT NULL                        COMMENT '手机号（国际格式），作为技师端登录账号',
    `password`         VARCHAR(100)                                  COMMENT '技师端登录密码（BCrypt，预留字段）',
    `real_name`        VARCHAR(50)   NOT NULL                        COMMENT '真实姓名（与证件一致，必填）',
    `nickname`         VARCHAR(50)                                   COMMENT '展示昵称（技师对外展示的名称）',
    `avatar`           VARCHAR(500)                                  COMMENT '头像图片 URL',
    `photos`           JSON                                          COMMENT '相册图片 URL 列表（JSON Array），展示在技师详情页',
    `gender`           TINYINT       NOT NULL DEFAULT 2              COMMENT '性别：1=男 2=女（服务项目常有性别要求）',
    `birthday`         DATE                                          COMMENT '生日（yyyy-MM-dd）',
    `id_card`          VARCHAR(50)                                   COMMENT '证件号（护照/身份证，建议加密存储）',
    `id_card_front`    VARCHAR(500)                                  COMMENT '证件正面照片 URL（审核用）',
    `id_card_back`     VARCHAR(500)                                  COMMENT '证件背面照片 URL（审核用）',
    `lang`             VARCHAR(10)   NOT NULL DEFAULT 'zh'           COMMENT '技师首选语言，同 cb_member.lang 定义',
    `intro_zh`         TEXT                                          COMMENT '个人简介（中文版）',
    `intro_en`         TEXT                                          COMMENT '个人简介（英文版）',
    `intro_vi`         TEXT                                          COMMENT '个人简介（越南文版）',
    `intro_km`         TEXT                                          COMMENT '个人简介（柬埔寨文版）',
    `service_city`     VARCHAR(100)                                  COMMENT '服务城市，用于按城市筛选技师',
    `lat`              DECIMAL(10,7)                                 COMMENT '当前位置纬度（GPS 实时定位，精度约 ±1cm）',
    `lng`              DECIMAL(10,7)                                 COMMENT '当前位置经度（GPS 实时定位，精度约 ±1cm）',
    `rating`           DECIMAL(3,2)  NOT NULL DEFAULT 5.00           COMMENT '综合评分（1.00-5.00），由历史评价加权计算',
    `review_count`     INT           NOT NULL DEFAULT 0              COMMENT '累计收到的评价数量',
    `order_count`      INT           NOT NULL DEFAULT 0              COMMENT '累计完成订单数量',
    `good_review_rate` DECIMAL(5,2)  NOT NULL DEFAULT 100.00         COMMENT '好评率（百分比，如 98.50 表示 98.5%）',
    `balance`          DECIMAL(12,2) NOT NULL DEFAULT 0.00           COMMENT '钱包余额（USD），接单收入累积，可申请提现',
    `total_income`     DECIMAL(12,2) NOT NULL DEFAULT 0.00           COMMENT '累计总收入（USD，只增不减）',
    `audit_status`     TINYINT       NOT NULL DEFAULT 0              COMMENT '入驻审核状态：0=待审核 1=审核通过 2=审核拒绝',
    `reject_reason`    VARCHAR(500)                                  COMMENT '审核拒绝原因（audit_status=2 时填写）',
    `online_status`    TINYINT       NOT NULL DEFAULT 0              COMMENT '在线状态：0=离线 1=在线待单 2=服务中（不可接新单）',
    `merchant_id`      BIGINT                                        COMMENT '所属商户 ID（关联 cb_merchant.id），独立技师此字段为空',
    `commission_rate`  DECIMAL(5,2)  NOT NULL DEFAULT 70.00          COMMENT '技师分成比例（百分比），如 70.00 表示技师得 70%，平台得 30%',
    `skill_tags`       JSON                                          COMMENT '技能标签 ID 列表（JSON Array，关联 cb_tag.id），如 [1,3,5]',
    `height`           SMALLINT                                      COMMENT '身高（cm）',
    `weight`           DECIMAL(5,2)                                  COMMENT '体重（kg）',
    `age`              TINYINT UNSIGNED                              COMMENT '年龄',
    `bust`             VARCHAR(10)                                   COMMENT '罩杯（如 A、B、C、D、E、F）',
    `province`         VARCHAR(50)                                   COMMENT '所在省份',
    `is_featured`      TINYINT       NOT NULL DEFAULT 0              COMMENT '是否首页推荐：1=是（精选技师） 0=否',
    `status`           TINYINT       NOT NULL DEFAULT 1              COMMENT '账号状态：1=正常 2=停用（被平台停用，无法接单）',
    `deleted`          TINYINT       NOT NULL DEFAULT 0              COMMENT '逻辑删除：0=正常 1=已删除',
    `create_time`      DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '申请入驻时间',
    `update_time`      DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '最后修改时间',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_mobile`       (`mobile`)        COMMENT '手机号全局唯一',
    UNIQUE KEY `uk_tech_no`      (`tech_no`)       COMMENT '技师编号全局唯一',
    KEY `idx_member_id`          (`member_id`)     COMMENT '按关联会员 ID 查询',
    KEY `idx_online_status`      (`online_status`) COMMENT '按在线状态快速筛选（首页推荐在线技师）',
    KEY `idx_service_city`       (`service_city`)  COMMENT '按服务城市检索（附近技师查询）'
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci
  COMMENT = '技师表：包含认证资料/多语言简介/服务能力/收入统计，合并设计避免连表';


-- --------------------------------------------------------------------------------
-- cb_merchant：商户表
-- 描述：入驻平台的实体商家（SPA 馆、洗浴中心、美容院等）。
--       商户可管理多名技师，并在商户端查看订单统计、提现收益。
--       merchant_name_* / address_* 多语言字段，用于多语种 APP 展示。
--       business_type 区分商户业务类型，features 用于控制特殊功能模块开关。
-- --------------------------------------------------------------------------------
CREATE TABLE `cb_merchant` (
    `id`               BIGINT        NOT NULL AUTO_INCREMENT          COMMENT '主键，自增',
    `merchant_no`      VARCHAR(32)   NOT NULL                        COMMENT '商户编号，业务唯一标识，格式 M+日期+序号',
    `mobile`           VARCHAR(20)   NOT NULL                        COMMENT '商户端登录手机号（国际格式），全局唯一',
    `password`         VARCHAR(100)                                  COMMENT '商户端登录密码（BCrypt，可选）',
    `merchant_name_zh` VARCHAR(200)  NOT NULL                        COMMENT '商户名称（中文），必填',
    `merchant_name_en` VARCHAR(200)                                  COMMENT '商户名称（英文）',
    `merchant_name_vi` VARCHAR(200)                                  COMMENT '商户名称（越南文）',
    `merchant_name_km` VARCHAR(200)                                  COMMENT '商户名称（柬埔寨文）',
    `logo`             VARCHAR(500)                                  COMMENT '商户 Logo 图片 URL（独立 Logo，区别于通用图标）',
    `photos`           JSON                                          COMMENT '商户相册图片 URL 列表（JSON Array）',
    `contact_person`   VARCHAR(50)                                   COMMENT '联系人姓名（对接运营的负责人）',
    `contact_mobile`   VARCHAR(20)                                   COMMENT '联系人手机号（运营沟通用，可与登录手机不同）',
    `province`         VARCHAR(100)                                  COMMENT '所在省/邦（如 Phnom Penh Province）',
    `city`             VARCHAR(100)                                  COMMENT '所在城市（如 Phnom Penh），用于城市维度筛选',
    `address_zh`       VARCHAR(500)                                  COMMENT '详细地址（中文）',
    `address_en`       VARCHAR(500)                                  COMMENT '详细地址（英文）',
    `address_vi`       VARCHAR(500)                                  COMMENT '详细地址（越南文）',
    `address_km`       VARCHAR(500)                                  COMMENT '详细地址（柬埔寨文）',
    `lat`              DECIMAL(10,7)                                 COMMENT '商户地址纬度（高德/Google 地图坐标）',
    `lng`              DECIMAL(10,7)                                 COMMENT '商户地址经度',
    `business_hours`   JSON                                          COMMENT '营业时间配置（JSON Array，格式: [{day:1,open:"09:00",close:"22:00"}]）',
    `tech_count`       INT           NOT NULL DEFAULT 0              COMMENT '旗下在职技师数量（冗余统计，避免实时 count）',
    `balance`          DECIMAL(12,2) NOT NULL DEFAULT 0.00           COMMENT '商户钱包余额（USD，来自平台分成），可申请提现',
    `commission_rate`  DECIMAL(5,2)  NOT NULL DEFAULT 20.00          COMMENT '平台向商户收取的佣金比例（百分比），如 20.00 表示平台抽 20%',
    `business_type`    TINYINT       NOT NULL DEFAULT 1              COMMENT '商户业务类型：1=综合 SPA 2=洗浴中心 3=美容美体 4=足疗',
    `features`         JSON                                          COMMENT '特色功能开关（JSON Object），如 {"driver_dispatch":true,"logo_custom":true}，控制商户专属功能',
    `audit_status`     TINYINT       NOT NULL DEFAULT 0              COMMENT '入驻审核状态：0=待审核 1=审核通过 2=审核拒绝',
    `reject_reason`    VARCHAR(500)                                  COMMENT '拒绝原因（audit_status=2 时填写）',
    `status`           TINYINT       NOT NULL DEFAULT 1              COMMENT '账号状态：1=正常 2=停用',
    `deleted`          TINYINT       NOT NULL DEFAULT 0              COMMENT '逻辑删除：0=正常 1=已删除',
    `create_time`      DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '入驻申请时间',
    `update_time`      DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '最后修改时间',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_mobile`      (`mobile`)      COMMENT '登录手机号全局唯一',
    UNIQUE KEY `uk_merchant_no` (`merchant_no`) COMMENT '商户编号全局唯一',
    KEY `idx_city`              (`city`)        COMMENT '按城市快速筛选商户列表'
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci
  COMMENT = '商户表：多语言名称/地址，含业务类型和特色功能开关';


-- --------------------------------------------------------------------------------
-- cb_service_category：服务分类表
-- 描述：服务项目的分类，支持两级树结构（parent_id=0 为一级分类）。
--       name_* 多语言字段，前端根据用户语言展示对应版本。
-- --------------------------------------------------------------------------------
CREATE TABLE `cb_service_category` (
    `id`          BIGINT       NOT NULL AUTO_INCREMENT          COMMENT '主键，自增',
    `parent_id`   BIGINT       NOT NULL DEFAULT 0              COMMENT '父分类 ID；0 表示一级分类（无父节点）',
    `name_zh`     VARCHAR(100) NOT NULL                        COMMENT '分类名称（中文），必填',
    `name_en`     VARCHAR(100)                                 COMMENT '分类名称（英文）',
    `name_vi`     VARCHAR(100)                                 COMMENT '分类名称（越南文）',
    `name_km`     VARCHAR(100)                                 COMMENT '分类名称（柬埔寨文）',
    `name_ja`     VARCHAR(100)                                 COMMENT '分类名称（日文）',
    `name_ko`     VARCHAR(100)                                 COMMENT '分类名称（韩文）',
    `icon`        VARCHAR(500)                                 COMMENT '分类图标 URL',
    `sort`        INT          NOT NULL DEFAULT 0              COMMENT '同级排序权重，值越小越靠前',
    `status`      TINYINT      NOT NULL DEFAULT 1              COMMENT '状态：1=启用 0=停用（停用后不在 APP 展示）',
    `deleted`     TINYINT      NOT NULL DEFAULT 0              COMMENT '逻辑删除：0=正常 1=已删除',
    `create_time` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '最后修改时间',
    PRIMARY KEY (`id`),
    KEY `idx_parent_id` (`parent_id`) COMMENT '按父分类 ID 查询子分类，构建分类树'
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci
  COMMENT = '服务分类表：两级树形结构，支持六语言名称';


-- --------------------------------------------------------------------------------
-- cb_service_item：服务项目表
-- 描述：平台提供的具体服务项，如"全身精油按摩 60分钟"。
--       name_* / desc_* 多语言字段；duration 用于时间预约冲突检测；
--       base_price 为普通用户价，member_price 为会员专属优惠价（可选）。
-- --------------------------------------------------------------------------------
CREATE TABLE `cb_service_item` (
    `id`           BIGINT        NOT NULL AUTO_INCREMENT          COMMENT '主键，自增',
    `category_id`  BIGINT        NOT NULL                        COMMENT '所属服务分类 ID，关联 cb_service_category.id',
    `name_zh`      VARCHAR(200)  NOT NULL                        COMMENT '服务项名称（中文），必填',
    `name_en`      VARCHAR(200)                                  COMMENT '服务项名称（英文）',
    `name_vi`      VARCHAR(200)                                  COMMENT '服务项名称（越南文）',
    `name_km`      VARCHAR(200)                                  COMMENT '服务项名称（柬埔寨文）',
    `name_ja`      VARCHAR(200)                                  COMMENT '服务项名称（日文）',
    `name_ko`      VARCHAR(200)                                  COMMENT '服务项名称（韩文）',
    `desc_zh`      TEXT                                          COMMENT '服务详情描述（中文，富文本或纯文本）',
    `desc_en`      TEXT                                          COMMENT '服务详情描述（英文）',
    `duration`     INT           NOT NULL DEFAULT 60             COMMENT '服务时长（分钟），用于排班冲突检测和展示',
    `base_price`   DECIMAL(10,2) NOT NULL                        COMMENT '普通用户价格（USD）',
    `member_price` DECIMAL(10,2)                                 COMMENT '会员优惠价格（USD），为空则不区分等级',
    `cover`        VARCHAR(500)                                  COMMENT '服务封面图片 URL',
    `sort`         INT           NOT NULL DEFAULT 0              COMMENT '排序权重，值越小越靠前',
    `status`       TINYINT       NOT NULL DEFAULT 1              COMMENT '状态：1=上架 0=下架',
    `deleted`      TINYINT       NOT NULL DEFAULT 0              COMMENT '逻辑删除：0=正常 1=已删除',
    `create_time`  DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time`  DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '最后修改时间',
    PRIMARY KEY (`id`),
    KEY `idx_category_id` (`category_id`) COMMENT '按分类 ID 查询服务项列表'
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci
  COMMENT = '服务项目表：含多语言名称/描述、时长、分级定价';


-- --------------------------------------------------------------------------------
-- cb_order：订单表
-- 描述：平台核心业务表，记录会员预约服务的完整生命周期。
--       关键字段快照：service_name / address_detail 在下单时写入快照，
--       防止后续修改服务项或地址导致历史订单数据不准确。
--       状态流转：0=待支付 → 1=已支付 → 2=已派单 → 3=技师前往 → 4=服务中
--                → 5=待评价 → 6=已完成 → 7=取消中 → 8=已取消 → 9=已退款
-- --------------------------------------------------------------------------------
CREATE TABLE `cb_order` (
    `id`               BIGINT        NOT NULL AUTO_INCREMENT          COMMENT '主键，自增',
    `order_no`         VARCHAR(32)   NOT NULL                        COMMENT '订单号（业务唯一标识，格式 OD+yyyyMMddHHmmss+6位随机，如 OD20260413153012AB3F21）',
    `member_id`        BIGINT        NOT NULL                        COMMENT '下单会员 ID，关联 cb_member.id',
    `technician_id`    BIGINT        NOT NULL                        COMMENT '服务技师 ID，关联 cb_technician.id',
    `merchant_id`      BIGINT                                        COMMENT '所属商户 ID，独立技师订单为空，关联 cb_merchant.id',
    `service_item_id`  BIGINT        NOT NULL                        COMMENT '服务项目 ID，关联 cb_service_item.id',
    `service_name`     VARCHAR(200)  NOT NULL                        COMMENT '下单时服务项名称快照（防止服务项改名后历史订单名称错乱）',
    `service_duration` INT           NOT NULL                        COMMENT '服务时长快照（分钟，防止服务项修改后历史订单时长变化）',
    `address_id`       BIGINT        NOT NULL                        COMMENT '服务地址 ID，关联 cb_address.id',
    `address_detail`   VARCHAR(500)  NOT NULL                        COMMENT '下单时地址详情快照（防止用户后续修改地址）',
    `address_lat`      DECIMAL(10,7)                                 COMMENT '下单时服务地址纬度快照',
    `address_lng`      DECIMAL(10,7)                                 COMMENT '下单时服务地址经度快照',
    `appoint_time`     DATETIME      NOT NULL                        COMMENT '预约服务开始时间（会员选择的上门时间）',
    `start_time`       DATETIME                                      COMMENT '实际开始服务时间（技师操作开始）',
    `end_time`         DATETIME                                      COMMENT '实际结束服务时间（技师操作完成）',
    `original_amount`  DECIMAL(10,2) NOT NULL                        COMMENT '原始应付金额（USD，服务单价 × 数量）',
    `discount_amount`  DECIMAL(10,2) NOT NULL DEFAULT 0.00           COMMENT '优惠减免金额（USD，含优惠券/活动优惠）',
    `transport_fee`    DECIMAL(10,2) NOT NULL DEFAULT 0.00           COMMENT '上门交通费（USD，距离超出一定范围时收取）',
    `pay_amount`       DECIMAL(10,2) NOT NULL                        COMMENT '实付金额（USD，= original_amount - discount_amount + transport_fee）',
    `coupon_id`        BIGINT                                        COMMENT '使用的优惠券 ID，关联 cb_member_coupon.id，未使用为空',
    `pay_type`         TINYINT                                       COMMENT '支付方式：1=ABA Pay 2=USDT 3=钱包余额 4=现金',
    `pay_time`         DATETIME                                      COMMENT '实际支付完成时间',
    `tech_income`      DECIMAL(10,2)                                 COMMENT '技师实际获得收入（USD，= pay_amount × 技师分成比例）',
    `platform_income`  DECIMAL(10,2)                                 COMMENT '平台实际获得收入（USD，= pay_amount - tech_income - merchant_income）',
    `status`           TINYINT       NOT NULL DEFAULT 0              COMMENT '订单状态：0=待支付 1=已支付 2=已派单 3=技师前往 4=服务中 5=待评价 6=已完成 7=取消中 8=已取消 9=已退款',
    `cancel_reason`    VARCHAR(500)                                  COMMENT '取消原因（status=8 时填写）',
    `remark`           VARCHAR(500)                                  COMMENT '会员下单备注（如有特殊要求）',
    `is_reviewed`      TINYINT       NOT NULL DEFAULT 0              COMMENT '是否已评价：0=未评价 1=已评价',
    `deleted`          TINYINT       NOT NULL DEFAULT 0              COMMENT '逻辑删除：0=正常 1=已删除',
    `create_time`      DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '下单时间',
    `update_time`      DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '最后修改时间',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_order_no`       (`order_no`)      COMMENT '订单号全局唯一',
    KEY `idx_member_id`            (`member_id`)     COMMENT '按会员查询订单历史',
    KEY `idx_technician_id`        (`technician_id`) COMMENT '按技师查询接单记录',
    KEY `idx_status`               (`status`)        COMMENT '按订单状态筛选（Admin 统计常用）',
    KEY `idx_appoint_time`         (`appoint_time`)  COMMENT '按预约时间检索（排班冲突检测）'
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci
  COMMENT = '订单表：核心业务表，含金额快照/状态流转/收益分配，全生命周期记录';


-- --------------------------------------------------------------------------------
-- cb_review：订单评价表
-- 描述：会员对已完成订单的评价记录，包含多维度评分和文字评价。
--       每笔订单只能评价一次（uk_order_id 保证）。
--       overall_score 综合评分影响技师的 rating 字段（触发异步更新）。
-- --------------------------------------------------------------------------------
CREATE TABLE `cb_review` (
    `id`              BIGINT    NOT NULL AUTO_INCREMENT          COMMENT '主键，自增',
    `order_id`        BIGINT    NOT NULL                        COMMENT '关联订单 ID，关联 cb_order.id（一单只能评一次）',
    `member_id`       BIGINT    NOT NULL                        COMMENT '评价的会员 ID，关联 cb_member.id',
    `technician_id`   BIGINT    NOT NULL                        COMMENT '被评价的技师 ID，关联 cb_technician.id',
    `overall_score`   TINYINT   NOT NULL                        COMMENT '综合评分（1-5星，影响技师总评分 rating）',
    `technique_score` TINYINT   NOT NULL                        COMMENT '技术手法评分（1-5星）',
    `attitude_score`  TINYINT   NOT NULL                        COMMENT '服务态度评分（1-5星）',
    `punctual_score`  TINYINT   NOT NULL                        COMMENT '准时到达评分（1-5星）',
    `content`         TEXT                                      COMMENT '文字评价内容（可为空，允许只评星）',
    `tags`            JSON                                      COMMENT '评价标签 ID 列表（JSON Array，快捷标签如 技术专业/态度好）',
    `is_anonymous`    TINYINT   NOT NULL DEFAULT 0              COMMENT '是否匿名评价：0=展示昵称 1=匿名显示',
    `reply`           TEXT                                      COMMENT '技师回复内容',
    `reply_time`      DATETIME                                  COMMENT '技师回复时间',
    `status`          TINYINT   NOT NULL DEFAULT 1              COMMENT '状态：1=正常显示 0=已屏蔽（违规评价由运营屏蔽）',
    `deleted`         TINYINT   NOT NULL DEFAULT 0              COMMENT '逻辑删除：0=正常 1=已删除',
    `create_time`     DATETIME  NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '评价发布时间',
    `update_time`     DATETIME  NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '最后修改时间',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_order_id`       (`order_id`)      COMMENT '每笔订单只能评价一次',
    KEY `idx_technician_id`        (`technician_id`) COMMENT '按技师查询收到的评价',
    KEY `idx_member_id`            (`member_id`)     COMMENT '按会员查询发出的评价'
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci
  COMMENT = '订单评价表：多维度评分+文字评价，每单一次，支持技师回复';


-- --------------------------------------------------------------------------------
-- cb_payment：支付记录表
-- 描述：记录每次支付行为的详细流水，与订单通过 order_no 关联。
--       一笔订单可能对应多条支付记录（如首次失败后重试）。
--       third_trade_no 为三方支付平台（ABA、USDT）的交易流水号。
--       notify_data 保存支付平台的原始回调报文，用于对账和问题排查。
-- --------------------------------------------------------------------------------
CREATE TABLE `cb_payment` (
    `id`              BIGINT        NOT NULL AUTO_INCREMENT          COMMENT '主键，自增',
    `payment_no`      VARCHAR(64)   NOT NULL                        COMMENT '支付单号（平台内部唯一，格式 PAY+时间戳+随机）',
    `order_no`        VARCHAR(32)   NOT NULL                        COMMENT '关联订单号，对应 cb_order.order_no',
    `member_id`       BIGINT        NOT NULL                        COMMENT '支付会员 ID，关联 cb_member.id',
    `pay_type`        TINYINT       NOT NULL                        COMMENT '支付方式：1=ABA Pay 2=USDT 3=钱包余额 4=现金',
    `pay_channel`     VARCHAR(50)                                   COMMENT '支付渠道标识（三方渠道代码，如 ABA / BINANCE_PAY）',
    `amount`          DECIMAL(10,2) NOT NULL                        COMMENT '支付金额（USD）',
    `currency`        VARCHAR(10)   NOT NULL DEFAULT 'USD'          COMMENT '货币类型（ISO 4217，如 USD / KHR）',
    `third_trade_no`  VARCHAR(200)                                  COMMENT '三方支付平台交易流水号（用于对账，ABA/USDT 回调时写入）',
    `notify_data`     TEXT                                          COMMENT '三方支付平台原始回调报文（JSON，保留完整用于事后对账和纠纷处理）',
    `status`          TINYINT       NOT NULL DEFAULT 0              COMMENT '支付状态：0=待支付 1=支付成功 2=支付失败 3=已退款',
    `refund_amount`   DECIMAL(10,2)                                 COMMENT '退款金额（USD，部分退款时填写实际退款额）',
    `refund_time`     DATETIME                                      COMMENT '退款完成时间',
    `create_time`     DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '支付记录创建时间',
    `update_time`     DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '最后修改时间',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_payment_no` (`payment_no`) COMMENT '支付单号全局唯一',
    KEY `idx_order_no`         (`order_no`)   COMMENT '按订单号查询支付记录',
    KEY `idx_member_id`        (`member_id`)  COMMENT '按会员查询支付历史'
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci
  COMMENT = '支付记录表：记录每次支付行为，保存三方回调原始报文，用于对账';


-- --------------------------------------------------------------------------------
-- cb_wallet：钱包主表
-- 描述：每个用户（会员/技师/商户）持有一个钱包，记录实时余额和累计统计数据。
--       流水明细见 cb_wallet_record，两表联合使用支持完整账务体系。
-- --------------------------------------------------------------------------------
CREATE TABLE `cb_wallet` (
  `id`              BIGINT       NOT NULL AUTO_INCREMENT    COMMENT '主键，雪花ID',
  `member_id`       BIGINT       NOT NULL                   COMMENT '用户ID（关联 cb_member.id）',
  `user_type`       TINYINT      NOT NULL DEFAULT 1         COMMENT '用户类型：1-会员  2-技师  3-商户',
  `balance`         DECIMAL(12,2) NOT NULL DEFAULT 0.00     COMMENT '当前余额（USD），最小单位0.01，使用乐观锁保证高并发安全',
  `total_recharge`  DECIMAL(12,2) NOT NULL DEFAULT 0.00     COMMENT '累计充值总额（USD）',
  `total_withdraw`  DECIMAL(12,2) NOT NULL DEFAULT 0.00     COMMENT '累计提现总额（USD）',
  `total_consume`   DECIMAL(12,2) NOT NULL DEFAULT 0.00     COMMENT '累计消费总额（USD）',
  `status`          TINYINT      NOT NULL DEFAULT 1         COMMENT '钱包状态：1-正常  0-冻结（被风控锁定）',
  `created_at`      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `updated_at`      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '最后更新时间（用作乐观锁版本号）',
  `deleted`         TINYINT      NOT NULL DEFAULT 0         COMMENT '逻辑删除：0-正常  1-已删',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_member_id` (`member_id`)  COMMENT '每个用户仅有唯一钱包，防止重复开户',
  KEY `idx_user_type` (`user_type`)         COMMENT '按用户类型检索（技师/商户提现统计对账）'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='钱包主表：记录会员/技师/商户实时余额和统计数据，与 cb_wallet_record 流水表联合构成完整账务体系';

-- --------------------------------------------------------------------------------
-- cb_wallet_record：钱包流水表
-- 描述：记录会员、技师、商户的钱包每一笔资金变动明细。
--       amount 正数表示收入，负数表示支出。
--       balance 记录变动后的实时余额快照（便于对账，无需累加历史流水）。
--       owner_type + owner_id 关联三种不同的主体，无需分表。
-- --------------------------------------------------------------------------------
CREATE TABLE `cb_wallet_record` (
    `id`          BIGINT        NOT NULL AUTO_INCREMENT          COMMENT '主键，自增',
    `owner_type`  TINYINT       NOT NULL                        COMMENT '资产归属方类型：1=会员 2=技师 3=商户',
    `owner_id`    BIGINT        NOT NULL                        COMMENT '资产归属方 ID（根据 owner_type 关联对应主表）',
    `type`        TINYINT       NOT NULL                        COMMENT '流水类型：1=充值 2=消费扣款 3=退款到账 4=接单收入 5=申请提现 6=平台佣金',
    `amount`      DECIMAL(12,2) NOT NULL                        COMMENT '变动金额（USD，正数=入账/收入，负数=出账/支出）',
    `balance`     DECIMAL(12,2) NOT NULL                        COMMENT '变动后余额快照（USD，便于对账，无需累加历史数据）',
    `order_no`    VARCHAR(32)                                   COMMENT '关联订单号（消费/退款/收入场景填写，关联 cb_order.order_no）',
    `remark`      VARCHAR(500)                                  COMMENT '流水备注（如 下单消费 / 充值入账 / 手动退款等）',
    `create_time` DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '流水产生时间',
    PRIMARY KEY (`id`),
    KEY `idx_owner`       (`owner_type`, `owner_id`) COMMENT '按持有人查询流水明细（复合索引覆盖两个维度）',
    KEY `idx_create_time` (`create_time`)             COMMENT '按时间检索，支持对账和定期清理'
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci
  COMMENT = '钱包流水表：记录会员/技师/商户每笔资金变动，含余额快照';


-- --------------------------------------------------------------------------------
-- cb_coupon_template：优惠券模板表
-- 描述：平台发放的优惠券定义，支持三种类型：现金满减、折扣、免交通费。
--       total_count=-1 表示不限量发放；valid_days 设置领取后有效期，
--       与 start_time/end_time 二选一（valid_days 优先）。
-- --------------------------------------------------------------------------------
CREATE TABLE `cb_coupon_template` (
    `id`           BIGINT        NOT NULL AUTO_INCREMENT          COMMENT '主键，自增',
    `name_zh`      VARCHAR(200)  NOT NULL                        COMMENT '优惠券名称（中文，如 新人专享立减$10）',
    `name_en`      VARCHAR(200)                                  COMMENT '优惠券名称（英文）',
    `name_vi`      VARCHAR(200)                                  COMMENT '优惠券名称（越南文）',
    `name_km`      VARCHAR(200)                                  COMMENT '优惠券名称（柬埔寨文）',
    `type`         TINYINT       NOT NULL                        COMMENT '券类型：1=现金满减券（满 min_amount 减 value 元）2=折扣券（折扣比例 value，如 0.8=8折）3=免交通费券',
    `value`        DECIMAL(10,2) NOT NULL                        COMMENT '优惠值（type=1 时为减免金额 USD，type=2 时为折扣率如 0.80，type=3 时为 0）',
    `min_amount`   DECIMAL(10,2) NOT NULL DEFAULT 0.00           COMMENT '使用门槛（订单实付金额需满足此金额才可使用，0=无门槛）',
    `total_count`  INT           NOT NULL                        COMMENT '总发放数量（-1=不限量，>=1=有限量）',
    `issued_count` INT           NOT NULL DEFAULT 0              COMMENT '已发放数量（每次领取时 +1，用于限量控制）',
    `valid_days`   INT                                           COMMENT '领取后有效天数（如 30=领取起30天内有效，与 start/end_time 二选一）',
    `start_time`   DATETIME                                      COMMENT '绝对有效期开始时间（与 valid_days 二选一）',
    `end_time`     DATETIME                                      COMMENT '绝对有效期结束时间（与 valid_days 二选一）',
    `status`       TINYINT       NOT NULL DEFAULT 1              COMMENT '状态：1=启用（可领取）0=停用',
    `deleted`      TINYINT       NOT NULL DEFAULT 0              COMMENT '逻辑删除：0=正常 1=已删除',
    `create_time`  DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time`  DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '最后修改时间',
    PRIMARY KEY (`id`)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci
  COMMENT = '优惠券模板表：定义券类型/面值/门槛/有效期，支持限量发放';


-- --------------------------------------------------------------------------------
-- cb_member_coupon：会员持有优惠券表（领取记录）
-- 描述：记录会员领取优惠券后的持有状态，与模板为多对一关系。
--       status 变化：0（未使用）→ 1（使用中，下单锁定）→ 2（已使用）或 3（已过期）。
-- --------------------------------------------------------------------------------
CREATE TABLE `cb_member_coupon` (
    `id`           BIGINT    NOT NULL AUTO_INCREMENT          COMMENT '主键，自增',
    `member_id`    BIGINT    NOT NULL                        COMMENT '持有会员 ID，关联 cb_member.id',
    `template_id`  BIGINT    NOT NULL                        COMMENT '优惠券模板 ID，关联 cb_coupon_template.id',
    `status`       TINYINT   NOT NULL DEFAULT 0              COMMENT '使用状态：0=未使用 1=已使用 2=已过期',
    `use_order_no` VARCHAR(32)                               COMMENT '使用时关联的订单号（status=1时填写，关联 cb_order.order_no）',
    `use_time`     DATETIME                                  COMMENT '实际使用时间（status=1时填写）',
    `expire_time`  DATETIME  NOT NULL                        COMMENT '过期时间（根据模板 valid_days 或 end_time 计算后写入）',
    `create_time`  DATETIME  NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '领取时间',
    PRIMARY KEY (`id`),
    KEY `idx_member_id`   (`member_id`)   COMMENT '按会员查询持有的优惠券',
    KEY `idx_template_id` (`template_id`) COMMENT '按模板统计发放情况'
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci
  COMMENT = '会员持有优惠券表：记录领取和使用状态，关联模板';


-- --------------------------------------------------------------------------------
-- cb_address：用户收货/服务地址表
-- 描述：会员保存的常用服务地址，支持多地址管理，一个默认地址。
--       下单时选择地址后，地址信息会快照到 cb_order.address_detail，
--       后续修改地址不影响历史订单。
-- --------------------------------------------------------------------------------
CREATE TABLE `cb_address` (
    `id`            BIGINT        NOT NULL AUTO_INCREMENT          COMMENT '主键，自增',
    `member_id`     BIGINT        NOT NULL                        COMMENT '所属会员 ID，关联 cb_member.id',
    `label`         VARCHAR(50)                                   COMMENT '地址标签（如 家/公司/酒店/星级酒店），方便快速识别',
    `contact_name`  VARCHAR(50)   NOT NULL                        COMMENT '收件/服务联系人姓名',
    `contact_phone` VARCHAR(20)   NOT NULL                        COMMENT '联系人手机号（国际格式）',
    `province`      VARCHAR(100)                                  COMMENT '省/邦',
    `city`          VARCHAR(100)                                  COMMENT '市/县',
    `district`      VARCHAR(100)                                  COMMENT '区/镇',
    `detail`        VARCHAR(500)  NOT NULL                        COMMENT '详细地址（门牌号/楼栋/房间号等）',
    `lat`           DECIMAL(10,7)                                 COMMENT '地址纬度（高精度，7位小数约 ±1cm）',
    `lng`           DECIMAL(10,7)                                 COMMENT '地址经度',
    `is_default`    TINYINT       NOT NULL DEFAULT 0              COMMENT '是否默认地址：1=是（同一会员仅允许一个默认地址） 0=否',
    `deleted`       TINYINT       NOT NULL DEFAULT 0              COMMENT '逻辑删除：0=正常 1=已删除（软删除，历史订单快照不受影响）',
    `create_time`   DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time`   DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '最后修改时间',
    PRIMARY KEY (`id`),
    KEY `idx_member_id` (`member_id`) COMMENT '按会员查询地址列表'
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci
  COMMENT = '用户服务地址表：支持多地址管理，下单时快照至订单';


-- --------------------------------------------------------------------------------
-- cb_technician_schedule：技师排班表
-- 描述：技师设置的可接单时间段，用于前端展示可预约时间和排班冲突检测。
--       唯一键 (technician_id, schedule_date, start_time) 防止同一技师同一时段重复排班。
-- --------------------------------------------------------------------------------
CREATE TABLE `cb_technician_schedule` (
    `id`            BIGINT    NOT NULL AUTO_INCREMENT          COMMENT '主键，自增',
    `technician_id` BIGINT    NOT NULL                        COMMENT '技师 ID，关联 cb_technician.id',
    `schedule_date` DATE      NOT NULL                        COMMENT '排班日期（yyyy-MM-dd）',
    `start_time`    TIME      NOT NULL                        COMMENT '班次开始时间（HH:mm:ss，如 09:00:00）',
    `end_time`      TIME      NOT NULL                        COMMENT '班次结束时间（HH:mm:ss，如 21:00:00）',
    `is_available`  TINYINT   NOT NULL DEFAULT 1              COMMENT '是否可接单：1=可预约 0=不可预约（如临时有事则标记为不可用）',
    `create_time`   DATETIME  NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_tech_date_time` (`technician_id`, `schedule_date`, `start_time`) COMMENT '同一技师同一时段不可重复排班',
    KEY `idx_tech_date`            (`technician_id`, `schedule_date`)               COMMENT '按技师+日期查询排班，用于预约时展示可选时段'
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci
  COMMENT = '技师排班表：记录技师可接单时间段，用于冲突检测和前端展示';


-- --------------------------------------------------------------------------------
-- cb_banner：Banner 轮播图表
-- 描述：APP / H5 各位置的轮播广告图配置，支持多语言标题和三种跳转类型。
--       position 定义展示位置（如 home_top=首页顶部），前端按位置拉取对应 Banner。
--       start_time / end_time 控制展示有效期，过期自动不展示。
-- --------------------------------------------------------------------------------
CREATE TABLE `cb_banner` (
    `id`          BIGINT       NOT NULL AUTO_INCREMENT          COMMENT '主键，自增',
    `position`    VARCHAR(50)  NOT NULL                        COMMENT 'Banner 展示位置标识（小写+下划线），如 home_top=首页顶部 / tech_detail=技师详情页',
    `title_zh`    VARCHAR(200)                                 COMMENT 'Banner 标题（中文，可不填）',
    `title_en`    VARCHAR(200)                                 COMMENT 'Banner 标题（英文）',
    `title_vi`    VARCHAR(200)                                 COMMENT 'Banner 标题（越南文）',
    `title_km`    VARCHAR(200)                                 COMMENT 'Banner 标题（柬埔寨文）',
    `image_url`   VARCHAR(500) NOT NULL                        COMMENT 'Banner 图片 URL（建议尺寸 750×300px）',
    `link_type`   TINYINT      NOT NULL DEFAULT 0              COMMENT '点击跳转类型：0=无跳转 1=内部路由（如 /order/detail）2=外部链接（HTTP URL）',
    `link_value`  VARCHAR(500)                                 COMMENT '跳转目标（link_type=1时为路由路径，link_type=2时为完整 URL）',
    `sort`        INT          NOT NULL DEFAULT 0              COMMENT '同位置排序权重，值越小越靠前',
    `status`      TINYINT      NOT NULL DEFAULT 1              COMMENT '状态：1=启用 0=停用',
    `start_time`  DATETIME                                     COMMENT '生效开始时间（为空则立即生效）',
    `end_time`    DATETIME                                     COMMENT '生效结束时间（为空则永久有效）',
    `deleted`     TINYINT      NOT NULL DEFAULT 0              COMMENT '逻辑删除：0=正常 1=已删除',
    `create_time` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '最后修改时间',
    PRIMARY KEY (`id`),
    KEY `idx_position` (`position`) COMMENT '按展示位置检索 Banner 列表'
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci
  COMMENT = 'Banner 轮播图：支持多位置、多语言标题、有效期和三种跳转方式';


-- --------------------------------------------------------------------------------
-- cb_nav：APP/H5 导航栏配置表
-- 描述：不同客户端底部导航菜单的配置，支持四类客户端（会员APP/技师APP/商户APP/H5）。
--       运营人员可在后台动态调整导航项目顺序和可见状态，无需发版。
-- --------------------------------------------------------------------------------
CREATE TABLE `cb_nav` (
    `id`          BIGINT       NOT NULL AUTO_INCREMENT          COMMENT '主键，自增',
    `client_type` TINYINT      NOT NULL                        COMMENT '所属客户端：1=会员 APP 2=技师 APP 3=商户 APP 4=H5',
    `nav_key`     VARCHAR(50)  NOT NULL                        COMMENT '导航项唯一标识（英文小写，如 home / order / profile）',
    `label_zh`    VARCHAR(50)  NOT NULL                        COMMENT '导航项标签（中文），必填',
    `label_en`    VARCHAR(50)                                  COMMENT '导航项标签（英文）',
    `label_vi`    VARCHAR(50)                                  COMMENT '导航项标签（越南文）',
    `label_km`    VARCHAR(50)                                  COMMENT '导航项标签（柬埔寨文）',
    `icon_normal` VARCHAR(500)                                 COMMENT '未选中状态图标 URL',
    `icon_active` VARCHAR(500)                                 COMMENT '选中激活状态图标 URL',
    `route_path`  VARCHAR(200)                                 COMMENT '前端路由路径（如 /home / /order/list）',
    `sort`        INT          NOT NULL DEFAULT 0              COMMENT '显示排序，值越小越靠左',
    `status`      TINYINT      NOT NULL DEFAULT 1              COMMENT '状态：1=显示 0=隐藏',
    `create_time` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '最后修改时间',
    PRIMARY KEY (`id`),
    KEY `idx_client_type` (`client_type`) COMMENT '按客户端类型拉取对应导航配置'
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci
  COMMENT = 'APP/H5 底部导航配置：支持多端动态配置，无需发版调整';


-- --------------------------------------------------------------------------------
-- cb_icon：图标资源表
-- 描述：统一管理平台所使用的图标资源，支持三种形式（URL/Base64/字体图标）。
--       icon_key 为全局唯一标识，前端/后端按 key 引用，便于统一替换。
-- --------------------------------------------------------------------------------
CREATE TABLE `cb_icon` (
    `id`          BIGINT       NOT NULL AUTO_INCREMENT          COMMENT '主键，自增',
    `icon_key`    VARCHAR(100) NOT NULL                        COMMENT '图标唯一标识键（全局唯一，英文小写+下划线，如 icon_home / icon_order）',
    `icon_type`   TINYINT      NOT NULL DEFAULT 1              COMMENT '图标类型：1=图片 URL 2=Base64 内嵌 3=字体图标类名（如 iconfont icon-home）',
    `icon_url`    VARCHAR(500)                                 COMMENT '图标图片 URL（icon_type=1 时填写）',
    `icon_font`   VARCHAR(100)                                 COMMENT '字体图标类名（icon_type=3 时填写）',
    `remark`      VARCHAR(200)                                 COMMENT '图标用途说明',
    `create_time` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '最后修改时间',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_icon_key` (`icon_key`) COMMENT '图标标识全局唯一'
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci
  COMMENT = '图标资源表：统一管理 URL/Base64/字体图标，按 key 引用';


-- --------------------------------------------------------------------------------
-- cb_tag：标签表
-- 描述：用于标注技师、服务、商户的特征标签（如 专业推拿/女技师/豪华会所）。
--       tag_type 区分标签所属类型；name_* 多语言，APP 按语言展示。
-- --------------------------------------------------------------------------------
CREATE TABLE `cb_tag` (
    `id`          BIGINT       NOT NULL AUTO_INCREMENT          COMMENT '主键，自增',
    `tag_type`    TINYINT      NOT NULL                        COMMENT '标签类型：1=技师标签 2=服务标签 3=商户标签',
    `name_zh`     VARCHAR(100) NOT NULL                        COMMENT '标签名称（中文），必填',
    `name_en`     VARCHAR(100)                                 COMMENT '标签名称（英文）',
    `name_vi`     VARCHAR(100)                                 COMMENT '标签名称（越南文）',
    `name_km`     VARCHAR(100)                                 COMMENT '标签名称（柬埔寨文）',
    `color`       VARCHAR(20)                                  COMMENT '标签展示颜色（十六进制，如 #FF6B6B），用于前端渲染彩色标签',
    `sort`        INT          NOT NULL DEFAULT 0              COMMENT '排序权重，值越小越靠前',
    `status`      TINYINT      NOT NULL DEFAULT 1              COMMENT '状态：1=启用 0=停用',
    `create_time` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    PRIMARY KEY (`id`),
    KEY `idx_tag_type` (`tag_type`) COMMENT '按标签类型检索（技师/服务/商户分类查询）'
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci
  COMMENT = '标签表：多语言标签，区分技师/服务/商户类型，支持彩色展示';


-- --------------------------------------------------------------------------------
-- cb_im_session：IM 会话表
-- 描述：记录用户与技师/商户/客服之间的 IM 会话元数据。
--       session_key 由两端 ID 拼接生成（如 member_{id}_tech_{id}），保证唯一。
--       last_msg / last_msg_time 用于会话列表排序和消息预览展示。
--       unread_count / peer_unread 分别记录双方未读数，推送红点提示。
-- --------------------------------------------------------------------------------
CREATE TABLE `cb_im_session` (
    `id`            BIGINT       NOT NULL AUTO_INCREMENT          COMMENT '主键，自增',
    `session_key`   VARCHAR(100) NOT NULL                        COMMENT '会话唯一键（由双方类型+ID 拼接，如 m_123_t_456），用于查找或创建会话',
    `member_id`     BIGINT       NOT NULL                        COMMENT '发起方会员 ID，关联 cb_member.id',
    `peer_type`     TINYINT      NOT NULL                        COMMENT '对方类型：1=技师 2=商户 3=客服',
    `peer_id`       BIGINT       NOT NULL                        COMMENT '对方 ID（根据 peer_type 关联对应主表）',
    `last_msg`      VARCHAR(500)                                 COMMENT '最后一条消息内容预览（图片显示[图片]，文字截取前50字）',
    `last_msg_time` DATETIME                                     COMMENT '最后一条消息发送时间（用于会话列表按时间倒序）',
    `unread_count`  INT          NOT NULL DEFAULT 0              COMMENT '会员侧未读消息数量（对方发送给我方的未读数）',
    `peer_unread`   INT          NOT NULL DEFAULT 0              COMMENT '对方侧未读消息数量（我方发送给对方的未读数）',
    `create_time`   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '会话创建时间',
    `update_time`   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '最后消息更新时间',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_session_key` (`session_key`) COMMENT '会话唯一键全局唯一，防止重复会话',
    KEY `idx_member_id`         (`member_id`)   COMMENT '按会员查询会话列表'
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci
  COMMENT = 'IM 会话表：记录会话元数据，含双向未读计数';


-- --------------------------------------------------------------------------------
-- cb_im_message：IM 消息表
-- 描述：存储 IM 会话中的每条消息记录。
--       sender_type + sender_id 标识发送方，支持四种身份。
--       msg_type 区分文字/图片/系统通知，前端按类型差异化渲染。
--       is_read 标识对方是否已读，驱动已读回执展示。
-- --------------------------------------------------------------------------------
CREATE TABLE `cb_im_message` (
    `id`          BIGINT       NOT NULL AUTO_INCREMENT          COMMENT '主键，自增',
    `session_id`  BIGINT       NOT NULL                        COMMENT '所属会话 ID，关联 cb_im_session.id',
    `sender_type` TINYINT      NOT NULL                        COMMENT '发送方类型：1=会员 2=技师 3=商户 4=系统（自动消息）',
    `sender_id`   BIGINT       NOT NULL                        COMMENT '发送方 ID（根据 sender_type 关联对应主表）',
    `msg_type`    TINYINT      NOT NULL                        COMMENT '消息类型：1=文字 2=图片 3=系统通知（如订单状态变更）',
    `content`     TEXT         NOT NULL                        COMMENT '消息内容（文字时为纯文本，图片时为 URL，系统通知时为 JSON 结构）',
    `is_read`     TINYINT      NOT NULL DEFAULT 0              COMMENT '对方已读标识：0=未读 1=已读（实现已读回执）',
    `create_time` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '消息发送时间',
    PRIMARY KEY (`id`),
    KEY `idx_session_id`  (`session_id`)  COMMENT '按会话 ID 分页查询消息历史',
    KEY `idx_create_time` (`create_time`) COMMENT '按时间检索，支持历史消息清理'
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci
  COMMENT = 'IM 消息表：记录每条聊天消息，支持已读回执';


-- --------------------------------------------------------------------------------
-- cb_notification：站内通知消息表
-- 描述：系统主动推送给用户的通知，如订单状态变更、活动提醒等。
--       owner_type + owner_id 支持向三种身份推送。
--       title_* / content_* 多语言，推送时按用户语言偏好取对应字段。
--       relate_id 关联相关业务 ID（如订单 ID），前端点击通知可直接跳转。
-- --------------------------------------------------------------------------------
CREATE TABLE `cb_notification` (
    `id`          BIGINT       NOT NULL AUTO_INCREMENT          COMMENT '主键，自增',
    `owner_type`  TINYINT      NOT NULL                        COMMENT '消息接收方类型：1=会员 2=技师 3=商户',
    `owner_id`    BIGINT       NOT NULL                        COMMENT '消息接收方 ID（根据 owner_type 关联对应主表）',
    `type`        TINYINT      NOT NULL                        COMMENT '通知类型：1=系统公告 2=订单相关 3=活动营销',
    `title_zh`    VARCHAR(200)                                 COMMENT '通知标题（中文）',
    `title_en`    VARCHAR(200)                                 COMMENT '通知标题（英文）',
    `title_vi`    VARCHAR(200)                                 COMMENT '通知标题（越南文）',
    `title_km`    VARCHAR(200)                                 COMMENT '通知标题（柬埔寨文）',
    `content_zh`  TEXT                                         COMMENT '通知内容（中文，支持富文本）',
    `content_en`  TEXT                                         COMMENT '通知内容（英文）',
    `content_vi`  TEXT                                         COMMENT '通知内容（越南文）',
    `content_km`  TEXT                                         COMMENT '通知内容（柬埔寨文）',
    `relate_id`   BIGINT                                       COMMENT '关联业务 ID（如订单 ID、活动 ID），前端用于跳转目标页面',
    `is_read`     TINYINT      NOT NULL DEFAULT 0              COMMENT '是否已读：0=未读 1=已读',
    `create_time` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '通知推送时间',
    PRIMARY KEY (`id`),
    KEY `idx_owner`       (`owner_type`, `owner_id`) COMMENT '按接收方查询通知列表（复合索引）',
    KEY `idx_create_time` (`create_time`)             COMMENT '按时间检索，支持定期清理历史通知'
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci
  COMMENT = '站内通知表：系统主动推送，多语言内容，含关联业务跳转';


-- --------------------------------------------------------------------------------
-- cb_login_log：用户登录日志表
-- 描述：记录会员、技师、商户的每次登录行为，用于安全监控和异常告警。
--       status=0 时记录失败原因（暂存在 device_info 最后一段或另设字段）。
-- --------------------------------------------------------------------------------
CREATE TABLE `cb_login_log` (
    `id`          BIGINT    NOT NULL AUTO_INCREMENT          COMMENT '主键，自增',
    `user_type`   TINYINT   NOT NULL                        COMMENT '用户类型：1=会员 2=技师 3=商户',
    `user_id`     BIGINT    NOT NULL                        COMMENT '用户 ID（根据 user_type 关联对应主表，登录失败时可为 0）',
    `mobile`      VARCHAR(20)                               COMMENT '登录手机号（冗余快照，便于直接查询无需关联）',
    `login_type`  TINYINT   NOT NULL                        COMMENT '登录方式：1=短信验证码 2=账号密码',
    `login_ip`    VARCHAR(50)                               COMMENT '登录来源 IP 地址',
    `device_info` VARCHAR(500)                              COMMENT '设备信息快照（JSON，含 os/device/app_version 等，用于安全分析）',
    `status`      TINYINT   NOT NULL DEFAULT 1              COMMENT '登录结果：1=成功 0=失败',
    `create_time` DATETIME  NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '登录时间',
    PRIMARY KEY (`id`),
    KEY `idx_user`        (`user_type`, `user_id`) COMMENT '按用户查询登录历史',
    KEY `idx_create_time` (`create_time`)           COMMENT '按时间检索，支持定期清理'
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci
  COMMENT = '用户登录日志：记录所有用户登录行为，用于安全审计和异常监控';


-- ================================================================================
-- 三、sys_i18n 初始化数据（对应 CbCodeEnum 全部 32 个枚举，6种语言）
-- 注意：使用 ON DUPLICATE KEY UPDATE 保证脚本重复执行时不会报错
-- ================================================================================

INSERT INTO `sys_i18n` (`enum_code`, `lang`, `message`) VALUES
-- ── 通用响应 ────────────────────────────────────────────────────────────────────
('SUCCESS','zh','操作成功'),
('SUCCESS','en','Success'),
('SUCCESS','vi','Thành công'),
('SUCCESS','km','ជោគជ័យ'),
('SUCCESS','ja','成功'),
('SUCCESS','ko','성공'),
-- SERVER_ERROR
('SERVER_ERROR','zh','系统异常，请稍后重试'),
('SERVER_ERROR','en','System error, please try again later'),
('SERVER_ERROR','vi','Lỗi hệ thống, vui lòng thử lại'),
('SERVER_ERROR','km','កំហុសប្រព័ន្ធ សូមព្យាយាមម្ដងទៀត'),
('SERVER_ERROR','ja','システムエラーが発生しました'),
('SERVER_ERROR','ko','시스템 오류, 잠시 후 다시 시도하세요'),
-- PARAM_ERROR
('PARAM_ERROR','zh','请求参数不合法，请检查后重试'),
('PARAM_ERROR','en','Invalid request parameters, please check and retry'),
('PARAM_ERROR','vi','Tham số yêu cầu không hợp lệ'),
('PARAM_ERROR','km','ប៉ារ៉ាម៉ែត្រស្នើសុំមិនត្រឹមត្រូវ'),
('PARAM_ERROR','ja','リクエストパラメータが不正です'),
('PARAM_ERROR','ko','잘못된 요청 매개변수입니다'),
-- DATA_NOT_FOUND
('DATA_NOT_FOUND','zh','数据不存在或已被删除'),
('DATA_NOT_FOUND','en','Data not found or has been deleted'),
('DATA_NOT_FOUND','vi','Dữ liệu không tồn tại hoặc đã bị xóa'),
('DATA_NOT_FOUND','km','រកមិនឃើញទិន្នន័យ ឬបានលុបហើយ'),
('DATA_NOT_FOUND','ja','データが見つかりません'),
('DATA_NOT_FOUND','ko','데이터를 찾을 수 없습니다'),
-- ── 认证 / 权限 ──────────────────────────────────────────────────────────────────
-- TOKEN_INVALID
('TOKEN_INVALID','zh','登录已过期，请重新登录'),
('TOKEN_INVALID','en','Session expired, please log in again'),
('TOKEN_INVALID','vi','Phiên đăng nhập hết hạn, vui lòng đăng nhập lại'),
('TOKEN_INVALID','km','វគ្គផុតកំណត់ សូមចូលប្រើប្រាស់ម្ដងទៀត'),
('TOKEN_INVALID','ja','セッションの有効期限が切れました。再ログインしてください'),
('TOKEN_INVALID','ko','세션이 만료되었습니다. 다시 로그인해 주세요'),
-- TOKEN_EXPIRED
('TOKEN_EXPIRED','zh','登录已过期，请重新登录'),
('TOKEN_EXPIRED','en','Token expired, please log in again'),
('TOKEN_EXPIRED','vi','Token đã hết hạn, vui lòng đăng nhập lại'),
('TOKEN_EXPIRED','km','Token ផុតកំណត់ សូមចូលម្ដងទៀត'),
('TOKEN_EXPIRED','ja','トークンの有効期限が切れました'),
('TOKEN_EXPIRED','ko','토큰이 만료되었습니다'),
-- NO_PERMISSION
('NO_PERMISSION','zh','暂无操作权限，请联系管理员'),
('NO_PERMISSION','en','Permission denied, please contact your administrator'),
('NO_PERMISSION','vi','Không có quyền thực hiện, liên hệ quản trị viên'),
('NO_PERMISSION','km','គ្មានការអនុញ្ញាត សូមទាក់ទងអ្នកគ្រប់គ្រង'),
('NO_PERMISSION','ja','操作権限がありません。管理者にお問い合わせください'),
('NO_PERMISSION','ko','권한이 없습니다. 관리자에게 문의하세요'),
-- REPEAT_SUBMIT
('REPEAT_SUBMIT','zh','请勿重复提交，请稍候再试'),
('REPEAT_SUBMIT','en','Duplicate request detected, please wait a moment'),
('REPEAT_SUBMIT','vi','Vui lòng không gửi lại, hãy chờ một lúc'),
('REPEAT_SUBMIT','km','កុំបញ្ជូនម្ដងទៀត សូមរង់ចាំ'),
('REPEAT_SUBMIT','ja','重複送信です。しばらくお待ちください'),
('REPEAT_SUBMIT','ko','중복 제출입니다. 잠시 후 다시 시도하세요'),
-- ── 短信验证码 ───────────────────────────────────────────────────────────────────
-- SMS_CODE_EXPIRED
('SMS_CODE_EXPIRED','zh','验证码已过期，请重新获取'),
('SMS_CODE_EXPIRED','en','Verification code has expired, please request a new one'),
('SMS_CODE_EXPIRED','vi','Mã xác minh đã hết hạn, vui lòng yêu cầu mã mới'),
('SMS_CODE_EXPIRED','km','លេខកូដផ្ទៀងផ្ទាត់ផុតកំណត់ សូមស្នើសុំម្ដងទៀត'),
('SMS_CODE_EXPIRED','ja','認証コードの有効期限が切れました。再取得してください'),
('SMS_CODE_EXPIRED','ko','인증 코드가 만료되었습니다. 새 코드를 요청하세요'),
-- SMS_CODE_WRONG
('SMS_CODE_WRONG','zh','验证码错误，请重新输入'),
('SMS_CODE_WRONG','en','Incorrect verification code, please try again'),
('SMS_CODE_WRONG','vi','Mã xác minh không đúng, vui lòng thử lại'),
('SMS_CODE_WRONG','km','លេខកូដផ្ទៀងផ្ទាត់មិនត្រឹមត្រូវ សូមព្យាយាមម្ដងទៀត'),
('SMS_CODE_WRONG','ja','認証コードが間違っています。再入力してください'),
('SMS_CODE_WRONG','ko','인증 코드가 올바르지 않습니다'),
-- ── 账号 ────────────────────────────────────────────────────────────────────────
-- ACCOUNT_BANNED
('ACCOUNT_BANNED','zh','账号已被封禁，请联系客服处理'),
('ACCOUNT_BANNED','en','Account has been banned, please contact customer support'),
('ACCOUNT_BANNED','vi','Tài khoản đã bị khóa, vui lòng liên hệ bộ phận hỗ trợ'),
('ACCOUNT_BANNED','km','គណនីត្រូវបានហាមឃាត់ សូមទំនាក់ទំនងផ្នែកបម្រើអតិថិជន'),
('ACCOUNT_BANNED','ja','アカウントが停止されました。カスタマーサポートにお問い合わせください'),
('ACCOUNT_BANNED','ko','계정이 정지되었습니다. 고객 지원팀에 문의하세요'),
-- ACCOUNT_NOT_FOUND
('ACCOUNT_NOT_FOUND','zh','账号不存在或密码错误'),
('ACCOUNT_NOT_FOUND','en','Account not found or password is incorrect'),
('ACCOUNT_NOT_FOUND','vi','Tài khoản không tồn tại hoặc mật khẩu sai'),
('ACCOUNT_NOT_FOUND','km','រកមិនឃើញគណនី ឬពាក្យសម្ងាត់មិនត្រឹមត្រូវ'),
('ACCOUNT_NOT_FOUND','ja','アカウントが見つかりません、またはパスワードが正しくありません'),
('ACCOUNT_NOT_FOUND','ko','계정을 찾을 수 없거나 비밀번호가 올바르지 않습니다'),
-- ── 会员 ────────────────────────────────────────────────────────────────────────
-- MEMBER_NOT_FOUND
('MEMBER_NOT_FOUND','zh','会员信息不存在'),
('MEMBER_NOT_FOUND','en','Member not found'),
('MEMBER_NOT_FOUND','vi','Không tìm thấy thông tin thành viên'),
('MEMBER_NOT_FOUND','km','រកមិនឃើញព័ត៌មានសមាជិក'),
('MEMBER_NOT_FOUND','ja','会員情報が見つかりません'),
('MEMBER_NOT_FOUND','ko','회원 정보를 찾을 수 없습니다'),
-- ── 技师 ────────────────────────────────────────────────────────────────────────
-- TECHNICIAN_NOT_FOUND
-- TECHNICIAN_ALREADY_APPLIED
('TECHNICIAN_ALREADY_APPLIED','zh','您已提交过入驻申请，请耐心等待审核'),
('TECHNICIAN_ALREADY_APPLIED','en','You have already submitted an application, please wait for review'),
('TECHNICIAN_ALREADY_APPLIED','vi','Bạn đã nộp đơn đăng ký, vui lòng chờ xét duyệt'),
('TECHNICIAN_ALREADY_APPLIED','km','អ្នកបានដាក់ពាក្យស្នើសុំហើយ សូមរង់ចាំការពិនិត្យ'),
('TECHNICIAN_ALREADY_APPLIED','ja','すでに申請を提出しました。審査をお待ちください'),
('TECHNICIAN_ALREADY_APPLIED','ko','이미 신청서를 제출했습니다. 심사를 기다려 주세요'),
-- TECHNICIAN_AUDIT_PENDING
-- TECHNICIAN_OFFLINE
('TECHNICIAN_OFFLINE','zh','技师当前不在线，请稍后再预约'),
('TECHNICIAN_OFFLINE','en','Technician is currently offline, please try booking later'),
('TECHNICIAN_OFFLINE','vi','Kỹ thuật viên hiện ngoại tuyến, vui lòng đặt lịch sau'),
('TECHNICIAN_OFFLINE','km','បច្ចេកទេសមិននៅអនឡាញ សូមកក់ម្ដងទៀតនៅពេលក្រោយ'),
('TECHNICIAN_OFFLINE','ja','技師は現在オフラインです。後ほど予約してください'),
('TECHNICIAN_OFFLINE','ko','기술자가 현재 오프라인입니다. 나중에 예약해 주세요'),
-- TECHNICIAN_BUSY
('TECHNICIAN_BUSY','zh','技师当前繁忙，暂不接受新预约'),
('TECHNICIAN_BUSY','en','Technician is currently busy and not accepting new bookings'),
('TECHNICIAN_BUSY','vi','Kỹ thuật viên đang bận, không nhận đặt lịch mới'),
('TECHNICIAN_BUSY','km','បច្ចេកទេសរវល់ មិនទទួលការកក់ថ្មី'),
('TECHNICIAN_BUSY','ja','技師は現在多忙です。新規予約は受け付けていません'),
('TECHNICIAN_BUSY','ko','기술자가 바빠서 새 예약을 받지 않습니다'),
-- ── 商户 ────────────────────────────────────────────────────────────────────────
-- MERCHANT_NOT_FOUND
('MERCHANT_NOT_FOUND','zh','商户信息不存在'),
('MERCHANT_NOT_FOUND','en','Merchant not found'),
('MERCHANT_NOT_FOUND','vi','Không tìm thấy thông tin đối tác'),
('MERCHANT_NOT_FOUND','km','រកមិនឃើញព័ត៌មានឈ្មួញ'),
('MERCHANT_NOT_FOUND','ja','加盟店情報が見つかりません'),
('MERCHANT_NOT_FOUND','ko','가맹점 정보를 찾을 수 없습니다'),
-- MERCHANT_AUDIT_PENDING
('MERCHANT_AUDIT_PENDING','zh','商户资料审核中，请耐心等待'),
('MERCHANT_AUDIT_PENDING','en','Merchant application is under review, please wait'),
('MERCHANT_AUDIT_PENDING','vi','Đơn đăng ký đối tác đang được xem xét'),
('MERCHANT_AUDIT_PENDING','km','ពាក្យស្នើសុំឈ្មួញកំពុងត្រូវបានពិនិត្យ'),
('MERCHANT_AUDIT_PENDING','ja','加盟店審査中です'),
('MERCHANT_AUDIT_PENDING','ko','가맹점 신청서 심사 중입니다'),
-- ── 订单 ────────────────────────────────────────────────────────────────────────
-- ORDER_NOT_FOUND
('ORDER_NOT_FOUND','zh','订单不存在'),
('ORDER_NOT_FOUND','en','Order not found'),
('ORDER_NOT_FOUND','vi','Không tìm thấy đơn hàng'),
('ORDER_NOT_FOUND','km','រកមិនឃើញការបញ្ជាទិញ'),
('ORDER_NOT_FOUND','ja','注文が見つかりません'),
('ORDER_NOT_FOUND','ko','주문을 찾을 수 없습니다'),
-- ORDER_STATUS_ILLEGAL
('ORDER_STATUS_ILLEGAL','zh','订单当前状态不允许此操作'),
('ORDER_STATUS_ILLEGAL','en','This operation is not allowed in the current order status'),
('ORDER_STATUS_ILLEGAL','vi','Thao tác không được phép ở trạng thái đơn hàng hiện tại'),
('ORDER_STATUS_ILLEGAL','km','ប្រតិបត្តិការនេះមិនត្រូវបានអនុញ្ញាតក្នុងស្ថានភាពការបញ្ជាទិញបច្ចុប្បន្ន'),
('ORDER_STATUS_ILLEGAL','ja','現在の注文状態ではこの操作は許可されていません'),
('ORDER_STATUS_ILLEGAL','ko','현재 주문 상태에서는 이 작업이 허용되지 않습니다'),
-- ORDER_CANNOT_CANCEL
('ORDER_CANNOT_CANCEL','zh','当前阶段无法取消订单，如有需要请联系客服'),
('ORDER_CANNOT_CANCEL','en','Order cannot be cancelled at this stage, please contact support'),
('ORDER_CANNOT_CANCEL','vi','Không thể hủy đơn hàng ở giai đoạn này'),
('ORDER_CANNOT_CANCEL','km','មិនអាចលុបចោលការបញ្ជាទិញនៅដំណាក់កាលនេះ'),
('ORDER_CANNOT_CANCEL','ja','現在の段階では注文をキャンセルできません'),
('ORDER_CANNOT_CANCEL','ko','현재 단계에서는 주문을 취소할 수 없습니다'),
-- ORDER_ALREADY_REVIEWED
('ORDER_ALREADY_REVIEWED','zh','该订单已评价，不可重复提交'),
('ORDER_ALREADY_REVIEWED','en','This order has already been reviewed and cannot be submitted again'),
('ORDER_ALREADY_REVIEWED','vi','Đơn hàng này đã được đánh giá'),
('ORDER_ALREADY_REVIEWED','km','ការបញ្ជាទិញនេះបានវាយតម្លៃរួចហើយ'),
('ORDER_ALREADY_REVIEWED','ja','この注文はすでにレビュー済みです'),
('ORDER_ALREADY_REVIEWED','ko','이 주문은 이미 리뷰되었습니다'),
-- ── 支付 / 钱包 ─────────────────────────────────────────────────────────────────
-- BALANCE_INSUFFICIENT
('BALANCE_INSUFFICIENT','zh','余额不足，请先充值'),
('BALANCE_INSUFFICIENT','en','Insufficient balance, please top up first'),
('BALANCE_INSUFFICIENT','vi','Số dư không đủ, vui lòng nạp tiền trước'),
('BALANCE_INSUFFICIENT','km','សមតុល្យមិនគ្រប់គ្រាន់ សូមបញ្ចូលប្រាក់ជាមុន'),
('BALANCE_INSUFFICIENT','ja','残高不足です。先にチャージしてください'),
('BALANCE_INSUFFICIENT','ko','잔액이 부족합니다. 먼저 충전해 주세요'),
-- PAYMENT_FAILED
('PAYMENT_FAILED','zh','支付失败，请检查支付方式后重试'),
('PAYMENT_FAILED','en','Payment failed, please check your payment method and try again'),
('PAYMENT_FAILED','vi','Thanh toán thất bại, vui lòng kiểm tra phương thức thanh toán'),
('PAYMENT_FAILED','km','ការទូទាត់បរាជ័យ សូមពិនិត្យវិធីទូទាត់'),
('PAYMENT_FAILED','ja','支払いが失敗しました。お支払い方法を確認して再試行してください'),
('PAYMENT_FAILED','ko','결제에 실패했습니다. 결제 방법을 확인하고 다시 시도하세요'),
-- WITHDRAW_MIN_AMOUNT
('WITHDRAW_MIN_AMOUNT','zh','提现金额低于最低限额（$10）'),
('WITHDRAW_MIN_AMOUNT','en','Withdrawal amount is below the minimum limit ($10)'),
('WITHDRAW_MIN_AMOUNT','vi','Số tiền rút thấp hơn giới hạn tối thiểu ($10)'),
('WITHDRAW_MIN_AMOUNT','km','ចំនួនដកលុយទាបជាងដែនកំណត់អប្បបរមា ($10)'),
('WITHDRAW_MIN_AMOUNT','ja','出金額が最低限度額（$10）を下回っています'),
('WITHDRAW_MIN_AMOUNT','ko','출금액이 최소 한도($10)보다 낮습니다'),
-- ── 优惠券 ──────────────────────────────────────────────────────────────────────
-- COUPON_NOT_FOUND
('COUPON_NOT_FOUND','zh','优惠券不存在或已失效'),
('COUPON_NOT_FOUND','en','Coupon not found or has become invalid'),
('COUPON_NOT_FOUND','vi','Không tìm thấy mã giảm giá hoặc đã hết hiệu lực'),
('COUPON_NOT_FOUND','km','រកមិនឃើញប័ណ្ណបញ្ចុះតម្លៃ ឬបានផុតសុពលភាព'),
('COUPON_NOT_FOUND','ja','クーポンが見つかりません、または無効になっています'),
('COUPON_NOT_FOUND','ko','쿠폰을 찾을 수 없거나 유효하지 않습니다'),
-- COUPON_EXPIRED
('COUPON_EXPIRED','zh','优惠券已过期，无法使用'),
('COUPON_EXPIRED','en','Coupon has expired and cannot be used'),
('COUPON_EXPIRED','vi','Mã giảm giá đã hết hạn, không thể sử dụng'),
('COUPON_EXPIRED','km','ប័ណ្ណបញ្ចុះតម្លៃផុតកំណត់ មិនអាចប្រើ'),
('COUPON_EXPIRED','ja','クーポンの有効期限が切れており、使用できません'),
('COUPON_EXPIRED','ko','쿠폰이 만료되어 사용할 수 없습니다'),
-- COUPON_USED
('COUPON_USED','zh','该优惠券已使用过，不可重复使用'),
('COUPON_USED','en','This coupon has already been used'),
('COUPON_USED','vi','Mã giảm giá này đã được sử dụng'),
('COUPON_USED','km','ប័ណ្ណបញ្ចុះតម្លៃនេះបានប្រើប្រាស់ហើយ'),
('COUPON_USED','ja','このクーポンはすでに使用されています'),
('COUPON_USED','ko','이 쿠폰은 이미 사용되었습니다'),
-- COUPON_NOT_APPLICABLE
('COUPON_NOT_APPLICABLE','zh','订单不满足优惠券使用条件'),
('COUPON_NOT_APPLICABLE','en','The order does not meet the coupon usage conditions'),
('COUPON_NOT_APPLICABLE','vi','Đơn hàng không đáp ứng điều kiện sử dụng mã giảm giá'),
('COUPON_NOT_APPLICABLE','km','ការបញ្ជាទិញមិនបំពេញលក្ខខណ្ឌប្រើប្រាស់ប័ណ្ណ'),
('COUPON_NOT_APPLICABLE','ja','注文がクーポンの使用条件を満たしていません'),
('COUPON_NOT_APPLICABLE','ko','주문이 쿠폰 사용 조건을 충족하지 않습니다'),
-- COUPON_STOCK_EMPTY
('COUPON_STOCK_EMPTY','zh','优惠券已发放完毕，敬请关注下次活动'),
('COUPON_STOCK_EMPTY','en','Coupon stock is exhausted, stay tuned for next event'),
('COUPON_STOCK_EMPTY','vi','Mã giảm giá đã hết, hãy theo dõi sự kiện tiếp theo'),
('COUPON_STOCK_EMPTY','km','ប័ណ្ណបញ្ចុះតម្លៃអស់ ចូរតាមដានព្រឹត្តិការណ៍បន្ទាប់'),
('COUPON_STOCK_EMPTY','ja','クーポンの在庫が尽きました。次回のイベントをお楽しみに'),
('COUPON_STOCK_EMPTY','ko','쿠폰 재고가 소진되었습니다. 다음 이벤트를 기대해 주세요')
ON DUPLICATE KEY UPDATE `message` = VALUES(`message`);


-- ================================================================================
-- 四、初始化数据：超级管理员账号 & 角色
-- 注意：
--   · 超级管理员账号：admin  密码：admin123（已 BCrypt 加密）
--   · 生产环境部署后请立即修改默认密码
--   · ON DUPLICATE KEY UPDATE 保证重复执行安全
-- ================================================================================

INSERT INTO `sys_user` (`username`, `password`, `real_name`, `status`) VALUES
('admin', '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iAt6Zm', '超级管理员', 1)
ON DUPLICATE KEY UPDATE `username` = `username`;

INSERT INTO `sys_role` (`role_code`, `role_name`, `sort`, `remark`) VALUES
('SUPER_ADMIN', '超级管理员', 0, '拥有全部权限，不受 RBAC 约束，仅限系统管理员使用')
ON DUPLICATE KEY UPDATE `role_code` = `role_code`;


-- ================================================================================
-- 五、派车模块扩展 DDL（cambook-module-driver）
-- 说明：本节 DDL 仅在启用派车功能时需要执行（Maven profile: -P with-driver）。
--       适用场景：洗浴中心、SPA 会所等有接送服务需求的商户。
--       表前缀：cb_（与核心业务模块统一）
-- ================================================================================


-- --------------------------------------------------------------------------------
-- cb_driver：司机表
-- 描述：平台注册的司机信息，负责接送会员往返商户/服务地点。
--       司机需通过审核（status）方可接单。
--       vehicle_id 绑定司机的常用车辆（也可每次派单时临时指定）。
--       current_lat / current_lng 由司机 APP 实时上报，用于就近分配。
-- --------------------------------------------------------------------------------
CREATE TABLE `cb_driver` (
    `id`                    BIGINT        NOT NULL AUTO_INCREMENT   COMMENT '主键，自增',
    `member_id`             BIGINT        NOT NULL                  COMMENT '关联会员 ID（司机同时是会员时关联），关联 cb_member.id',
    `real_name`             VARCHAR(30)   NOT NULL                  COMMENT '真实姓名（与驾照一致）',
    `avatar`                VARCHAR(500)                            COMMENT '头像图片 URL',
    `mobile`                VARCHAR(20)                             COMMENT '联系手机号（冗余快照，国际格式）',
    `id_card`               VARCHAR(30)                             COMMENT '证件号（护照/身份证，建议加密存储）',
    `driving_license_front` VARCHAR(500)                            COMMENT '驾照正面照片 URL（审核材料）',
    `driving_license_back`  VARCHAR(500)                            COMMENT '驾照背面照片 URL（审核材料）',
    `license_type`          VARCHAR(10)   NOT NULL DEFAULT 'KH'     COMMENT '驾照类型：KH=柬埔寨驾照 INT=国际驾照',
    `vehicle_id`            BIGINT                                  COMMENT '默认绑定车辆 ID，关联 cb_vehicle.id（可为空，每次派单时再指定）',
    `status`                TINYINT       NOT NULL DEFAULT 0        COMMENT '审核/状态：0=待审核 1=在职（可接单）2=停职（禁止接单）',
    `online_status`         TINYINT       NOT NULL DEFAULT 0        COMMENT '在线状态：0=离线 1=待命（可接单）2=执行任务中（不可接新单）',
    `current_lat`           DECIMAL(10,6)                           COMMENT '当前位置纬度（司机 APP 实时上报，用于就近分配）',
    `current_lng`           DECIMAL(10,6)                           COMMENT '当前位置经度（司机 APP 实时上报）',
    `total_dispatch`        INT           NOT NULL DEFAULT 0         COMMENT '累计完成派单次数（只增不减）',
    `rating`                DECIMAL(3,2)  NOT NULL DEFAULT 5.00      COMMENT '综合评分（1.00-5.00，由完成订单评价加权计算）',
    `reject_reason`         VARCHAR(200)                            COMMENT '审核拒绝原因（status=停职 或 审核不通过时填写）',
    `deleted`               TINYINT       NOT NULL DEFAULT 0         COMMENT '逻辑删除：0=正常 1=已删除',
    `create_time`           DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '申请注册时间',
    `update_time`           DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '最后修改时间',
    PRIMARY KEY (`id`),
    KEY `idx_member_id` (`member_id`)            COMMENT '按关联会员 ID 查询司机信息',
    KEY `idx_status`    (`status`, `online_status`) COMMENT '按状态+在线状态筛选可接单司机（复合索引）'
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci
  COMMENT = '司机表：记录司机认证信息/实时位置/接单统计，支持派车功能';


-- --------------------------------------------------------------------------------
-- cb_vehicle：车辆表
-- 描述：平台管理的车辆资产，可与司机绑定。
--       vehicle 状态由系统根据派单情况自动维护。
--       inspection_expiry 年检到期时，系统应提前告警提醒续检。
-- --------------------------------------------------------------------------------
CREATE TABLE `cb_vehicle` (
    `id`                BIGINT       NOT NULL AUTO_INCREMENT   COMMENT '主键，自增',
    `plate_number`      VARCHAR(20)  NOT NULL                  COMMENT '车牌号（全局唯一，格式按所在国家规范，如 2A-1234 柬埔寨格式）',
    `brand`             VARCHAR(50)  NOT NULL                  COMMENT '车辆品牌，如 Toyota / Honda / Lexus',
    `model`             VARCHAR(50)  NOT NULL                  COMMENT '车辆型号，如 Camry / Accord / ES300h',
    `color`             VARCHAR(20)                            COMMENT '车辆颜色（中文描述，如 珍珠白 / 深灰）',
    `seats`             TINYINT      NOT NULL DEFAULT 4        COMMENT '核定座位数（含驾驶员，最少2，最多50）',
    `inspection_code`   VARCHAR(30)                            COMMENT '年检合格证编号',
    `inspection_expiry` DATE                                   COMMENT '年检到期日（yyyy-MM-dd，提前30天告警）',
    `photo`             VARCHAR(500)                           COMMENT '车辆图片 URL（建议展示车牌清晰的正面照）',
    `status`            TINYINT      NOT NULL DEFAULT 0        COMMENT '车辆状态：0=空闲（可派单）1=使用中（已派出）2=维修中（暂不可派）',
    `remark`            VARCHAR(300)                           COMMENT '备注（如车辆特殊说明，残障设施等）',
    `deleted`           TINYINT      NOT NULL DEFAULT 0        COMMENT '逻辑删除：0=正常 1=已报废/删除',
    `create_time`       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '车辆录入时间',
    `update_time`       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '最后修改时间',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_plate_number` (`plate_number`) COMMENT '车牌号全局唯一',
    KEY `idx_status`             (`status`)       COMMENT '按状态快速筛选空闲车辆（派单选车）'
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci
  COMMENT = '车辆表：记录车辆资产信息，状态跟踪，支持派单车辆管理';


-- --------------------------------------------------------------------------------
-- cb_dispatch_order：派车单表
-- 描述：记录每次用车服务的完整生命周期，与主业务订单（cb_order）关联。
--       一条订单可能对应一条或多条派车单（如去程+回程）。
--       状态流转：0=待接单 → 1=司机已接单 → 2=前往接客 → 3=已到达等待
--                → 4=服务中（乘客已上车）→ 5=已完成 → 9=已取消
--       driver_id / vehicle_id 可在创建时指定，也可由系统自动分配后回填。
-- --------------------------------------------------------------------------------
CREATE TABLE `cb_dispatch_order` (
    `id`                 BIGINT        NOT NULL AUTO_INCREMENT   COMMENT '主键，自增',
    `dispatch_no`        VARCHAR(32)   NOT NULL                  COMMENT '派车单号（业务唯一，格式 DS+yyyyMMddHHmmss+6位随机，如 DS20260413154501AB3F）',
    `order_id`           BIGINT        NOT NULL                  COMMENT '关联主订单 ID，关联 cb_order.id',
    `driver_id`          BIGINT                                  COMMENT '执行司机 ID，关联 cb_driver.id（系统自动分配后填入，创建时可为空）',
    `vehicle_id`         BIGINT                                  COMMENT '使用车辆 ID，关联 cb_vehicle.id（确认司机后填入）',
    `pickup_lat`         DECIMAL(10,6) NOT NULL                  COMMENT '上车地点纬度（会员选择的接送位置）',
    `pickup_lng`         DECIMAL(10,6) NOT NULL                  COMMENT '上车地点经度',
    `dest_lat`           DECIMAL(10,6) NOT NULL                  COMMENT '目的地纬度（商户/服务地点坐标）',
    `dest_lng`           DECIMAL(10,6) NOT NULL                  COMMENT '目的地经度',
    `dest_address`       VARCHAR(300)                            COMMENT '目的地详细地址描述（供司机导航参考）',
    `pickup_time`        DATETIME      NOT NULL                  COMMENT '预约接送时间（会员选择的上车时间）',
    `actual_pickup_time` DATETIME                                COMMENT '实际接到乘客时间（司机操作"已接到"时记录）',
    `finish_time`        DATETIME                                COMMENT '行程完成时间（司机操作"已送达"时记录）',
    `status`             TINYINT       NOT NULL DEFAULT 0        COMMENT '派车单状态：0=待接单 1=司机已接单 2=前往接客 3=已到达等待 4=乘客已上车 5=已完成 9=已取消',
    `cancel_reason`      VARCHAR(200)                            COMMENT '取消原因（status=9 时填写）',
    `remark`             VARCHAR(300)                            COMMENT '特殊备注（如 VIP 接待要求、需准备瓶装水等）',
    `deleted`            TINYINT       NOT NULL DEFAULT 0        COMMENT '逻辑删除：0=正常 1=已删除',
    `create_time`        DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '派车单创建时间',
    `update_time`        DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '最后修改时间',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_dispatch_no` (`dispatch_no`)  COMMENT '派车单号全局唯一',
    KEY `idx_order_id`          (`order_id`)     COMMENT '按订单 ID 查询关联派车单',
    KEY `idx_driver_id`         (`driver_id`)    COMMENT '按司机查询接单历史',
    KEY `idx_status`            (`status`)       COMMENT '按状态筛选待处理派车单（运营监控）'
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci
  COMMENT = '派车单表：记录接送服务完整生命周期，关联主订单，含司机/车辆/坐标信息';


SET FOREIGN_KEY_CHECKS = 1;
-- ================================================================================
-- END OF SCRIPT
-- 合计：10张系统表（sys_） + 24张业务表（cb_） = 34张
-- ================================================================================

-- ═══════════════════════════════════════════════════════════════════════════
-- SECTION 2: 历史 Migration（archive: v2.x ~ v4.x）
-- ═══════════════════════════════════════════════════════════════════════════

-- ── migrate_v2_1.sql ─────────────────────────────────────────────────────────
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

-- ── migrate_v2_2.sql ─────────────────────────────────────────────────────────
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

-- ── migrate_v2_3.sql ─────────────────────────────────────────────────────────
-- ============================================================
-- Migration v2.3 — 技师表新增身高/体重/年龄/胸围字段
-- ============================================================
ALTER TABLE `cb_technician`
    ADD COLUMN `height`    SMALLINT          NULL COMMENT '身高（cm）'           AFTER `skill_tags`,
    ADD COLUMN `weight`    DECIMAL(5,2)      NULL COMMENT '体重（kg）'           AFTER `height`,
    ADD COLUMN `age`       TINYINT UNSIGNED  NULL COMMENT '年龄'                 AFTER `weight`,
    ADD COLUMN `bust`      VARCHAR(10)       NULL COMMENT '罩杯（A/B/C/D/E/F/G）'       AFTER `age`,
    ADD COLUMN `province`  VARCHAR(50)       NULL COMMENT '所在省份'             AFTER `bust`;

-- ── migrate_v3_4.sql ─────────────────────────────────────────────────────────
-- ============================================================
-- migrate_v3_4: 商户端菜单动态化
-- 1. 为 sys_permission 增加 portal_type 区分管理端/商户端
-- 2. 写入初始商户端菜单数据
-- ============================================================

-- Step 1: 新增 portal_type 字段（0=管理端 1=商户端）
ALTER TABLE sys_permission
    ADD COLUMN portal_type TINYINT NOT NULL DEFAULT 0
    COMMENT '0=管理端 1=商户端'
    AFTER sort;

-- Step 2: 写入商户端菜单（id 使用 1000-1099 区间，避免与管理端冲突）
INSERT INTO sys_permission (id, parent_id, name, code, type, path, component, icon, sort, portal_type, visible, status)
VALUES
-- ── 顶级菜单 ──────────────────────────────────────────────
(1010, 0, '数据看板',  NULL, 2, '/merchant/dashboard',            NULL, 'DashboardOutlined',   1,  1, 1, 1),
(1011, 0, '订单管理',  NULL, 2, '/merchant/orders',               NULL, 'OrderedListOutlined', 2,  1, 1, 1),
(1019, 0, '商户设置',  NULL, 2, '/merchant/profile',              NULL, 'SettingOutlined',     9,  1, 1, 1),

-- ── 公告管理 ─────────────────────────────────────────────
(1000, 0, '公告管理',  NULL, 1, NULL, NULL, 'SoundOutlined',      3,  1, 1, 1),
(1020, 1000, '内部公告', NULL, 2, '/merchant/announce/internal',  NULL, 'TeamOutlined',        1,  1, 1, 1),
(1021, 1000, '客户公告', NULL, 2, '/merchant/announce/customer',  NULL, 'UserOutlined',        2,  1, 1, 1),

-- ── 运营管理 ─────────────────────────────────────────────
(1001, 0, '运营管理',  NULL, 1, NULL, NULL, 'AppstoreOutlined',   4,  1, 1, 1),
(1030, 1001, '会员管理',   NULL, 2, '/merchant/members',                  NULL, 'UserOutlined',        1,  1, 1, 1),
(1031, 1001, '技师管理',   NULL, 2, '/merchant/technicians',              NULL, 'TeamOutlined',        2,  1, 1, 1),
(1032, 1001, '车辆管理',   NULL, 2, '/merchant/vehicles',                 NULL, 'CarOutlined',         3,  1, 1, 1),
(1033, 1001, '服务项目',   NULL, 2, '/merchant/operation/category',       NULL, 'AppstoreOutlined',    4,  1, 1, 1),
(1034, 1001, '评价管理',   NULL, 2, '/merchant/operation/reviews',        NULL, 'StarOutlined',        5,  1, 1, 1),
(1035, 1001, '通知公告',   NULL, 2, '/merchant/operation/notices',        NULL, 'BellOutlined',        6,  1, 1, 1),

-- ── 营销管理 ─────────────────────────────────────────────
(1002, 0, '营销管理',  NULL, 1, NULL, NULL, 'RocketOutlined',     5,  1, 1, 1),
(1040, 1002, '首页轮播',   NULL, 2, '/merchant/operation/banner',         NULL, 'PictureOutlined',     1,  1, 1, 1),
(1041, 1002, '优惠券管理', NULL, 2, '/merchant/coupons',                  NULL, 'TagsOutlined',        2,  1, 1, 1),

-- ── 财务管理 ─────────────────────────────────────────────
(1003, 0, '财务管理',  NULL, 1, NULL, NULL, 'DollarOutlined',     6,  1, 1, 1),
(1050, 1003, '收入统计',   NULL, 2, '/merchant/finance',                  NULL, 'BankOutlined',        1,  1, 1, 1),
(1051, 1003, '提现审核',   NULL, 2, '/merchant/finance/withdraw',         NULL, 'AuditOutlined',       2,  1, 1, 1),

-- ── 权限管理 ─────────────────────────────────────────────
(1004, 0, '权限管理',  NULL, 1, NULL, NULL, 'LockOutlined',       7,  1, 1, 1),
(1060, 1004, '员工管理',   NULL, 2, '/merchant/perm/staff',               NULL, 'IdcardOutlined',      1,  1, 1, 1),
(1061, 1004, '角色权限',   NULL, 2, '/merchant/perm/roles',               NULL, 'KeyOutlined',         2,  1, 1, 1),
(1062, 1004, '部门管理',   NULL, 2, '/merchant/perm/dept',                NULL, 'ApartmentOutlined',   3,  1, 1, 1),
(1063, 1004, '职位管理',   NULL, 2, '/merchant/perm/positions',           NULL, 'SolutionOutlined',    4,  1, 1, 1);

-- ── migrate_v3_5.sql ─────────────────────────────────────────────────────────
-- ============================================================
-- migrate_v3_5.sql  按钮级操作权限（type=3）
--
-- 说明：
--   type=3  操作权限，不在侧边栏显示（visible=0）
--   portal_type=0  管理端
--   parent_id 通过子查询动态关联对应菜单，找不到则挂在根节点(0)
-- ============================================================

-- 防止重复执行
DELETE FROM sys_permission WHERE type = 3 AND portal_type = 0 AND deleted = 0;

-- ─── 辅助变量：各菜单 ID ───────────────────────────────────
SET @p_tech       = IFNULL((SELECT id FROM sys_permission WHERE path LIKE '%/admin/technician%' AND type = 2 AND portal_type = 0 AND deleted = 0 LIMIT 1), 0);
SET @p_order      = IFNULL((SELECT id FROM sys_permission WHERE path LIKE '%/admin/order%'      AND type = 2 AND portal_type = 0 AND deleted = 0 LIMIT 1), 0);
SET @p_merchant   = IFNULL((SELECT id FROM sys_permission WHERE path LIKE '%/admin/merchant%'   AND type = 2 AND portal_type = 0 AND deleted = 0 LIMIT 1), 0);
SET @p_member     = IFNULL((SELECT id FROM sys_permission WHERE path LIKE '%/admin/member%'     AND type = 2 AND portal_type = 0 AND deleted = 0 LIMIT 1), 0);
SET @p_role       = IFNULL((SELECT id FROM sys_permission WHERE path LIKE '%/admin/role%'       AND type = 2 AND portal_type = 0 AND deleted = 0 LIMIT 1), 0);
SET @p_staff      = IFNULL((SELECT id FROM sys_permission WHERE path LIKE '%/admin/staff%'      AND type = 2 AND portal_type = 0 AND deleted = 0 LIMIT 1), 0);
SET @p_position   = IFNULL((SELECT id FROM sys_permission WHERE path LIKE '%/admin/position%'   AND type = 2 AND portal_type = 0 AND deleted = 0 LIMIT 1), 0);
SET @p_perm       = IFNULL((SELECT id FROM sys_permission WHERE path LIKE '%/admin/permission%' AND type = 2 AND portal_type = 0 AND deleted = 0 LIMIT 1), 0);
SET @p_menu       = IFNULL((SELECT id FROM sys_permission WHERE path LIKE '%/admin/menu%'       AND type = 2 AND portal_type = 0 AND deleted = 0 LIMIT 1), 0);
SET @p_dept       = IFNULL((SELECT id FROM sys_permission WHERE path LIKE '%/admin/dept%'       AND type = 2 AND portal_type = 0 AND deleted = 0 LIMIT 1), 0);
SET @p_vehicle    = IFNULL((SELECT id FROM sys_permission WHERE path LIKE '%/admin/vehicle%'    AND type = 2 AND portal_type = 0 AND deleted = 0 LIMIT 1), 0);
SET @p_coupon     = IFNULL((SELECT id FROM sys_permission WHERE path LIKE '%/admin/coupon%'     AND type = 2 AND portal_type = 0 AND deleted = 0 LIMIT 1), 0);
SET @p_category   = IFNULL((SELECT id FROM sys_permission WHERE path LIKE '%/admin/category%'   AND type = 2 AND portal_type = 0 AND deleted = 0 LIMIT 1), 0);
SET @p_banner     = IFNULL((SELECT id FROM sys_permission WHERE path LIKE '%/admin/banner%'     AND type = 2 AND portal_type = 0 AND deleted = 0 LIMIT 1), 0);
SET @p_notice     = IFNULL((SELECT id FROM sys_permission WHERE path LIKE '%/admin/notice%'     AND type = 2 AND portal_type = 0 AND deleted = 0 LIMIT 1), 0);
SET @p_dict       = IFNULL((SELECT id FROM sys_permission WHERE path LIKE '%/admin/dict%'       AND type = 2 AND portal_type = 0 AND deleted = 0 LIMIT 1), 0);
SET @p_sysconfig  = IFNULL((SELECT id FROM sys_permission WHERE path LIKE '%/admin/sysconfig%'  AND type = 2 AND portal_type = 0 AND deleted = 0 LIMIT 1), 0);
SET @p_log        = IFNULL((SELECT id FROM sys_permission WHERE path LIKE '%/admin/log%'        AND type = 2 AND portal_type = 0 AND deleted = 0 LIMIT 1), 0);
SET @p_review     = IFNULL((SELECT id FROM sys_permission WHERE path LIKE '%/admin/review%'     AND type = 2 AND portal_type = 0 AND deleted = 0 LIMIT 1), 0);
SET @p_announce   = IFNULL((SELECT id FROM sys_permission WHERE path LIKE '%/admin/announce%'   AND type = 2 AND portal_type = 0 AND deleted = 0 LIMIT 1), 0);

-- ─── 技师管理 ─────────────────────────────────────────────
INSERT INTO sys_permission (parent_id, name, code, type, sort, portal_type, visible, status, deleted) VALUES
(@p_tech, '查看技师列表',   'technician:list',   3, 1, 0, 0, 1, 0),
(@p_tech, '新增技师',       'technician:add',    3, 2, 0, 0, 1, 0),
(@p_tech, '编辑技师',       'technician:edit',   3, 3, 0, 0, 1, 0),
(@p_tech, '删除技师',       'technician:delete', 3, 4, 0, 0, 1, 0),
(@p_tech, '审核技师',       'technician:audit',  3, 5, 0, 0, 1, 0),
(@p_tech, '切换技师状态',   'technician:toggle', 3, 6, 0, 0, 1, 0),
(@p_tech, '设置推荐技师',   'technician:feature',3, 7, 0, 0, 1, 0);

-- ─── 订单管理 ─────────────────────────────────────────────
INSERT INTO sys_permission (parent_id, name, code, type, sort, portal_type, visible, status, deleted) VALUES
(@p_order, '查看订单列表', 'order:list',   3, 1, 0, 0, 1, 0),
(@p_order, '取消订单',     'order:cancel', 3, 2, 0, 0, 1, 0),
(@p_order, '删除订单',     'order:delete', 3, 3, 0, 0, 1, 0);

-- ─── 会员管理 ─────────────────────────────────────────────
INSERT INTO sys_permission (parent_id, name, code, type, sort, portal_type, visible, status, deleted) VALUES
(@p_member, '查看会员列表', 'member:list', 3, 1, 0, 0, 1, 0),
(@p_member, '封禁/解封会员','member:ban',  3, 2, 0, 0, 1, 0);

-- ─── 商户管理 ─────────────────────────────────────────────
INSERT INTO sys_permission (parent_id, name, code, type, sort, portal_type, visible, status, deleted) VALUES
(@p_merchant, '查看商户列表', 'merchant:list',       3, 1, 0, 0, 1, 0),
(@p_merchant, '新增商户',     'merchant:add',        3, 2, 0, 0, 1, 0),
(@p_merchant, '审核商户',     'merchant:audit',      3, 3, 0, 0, 1, 0),
(@p_merchant, '设置佣金',     'merchant:commission', 3, 4, 0, 0, 1, 0),
(@p_merchant, '切换商户状态', 'merchant:toggle',     3, 5, 0, 0, 1, 0);

-- ─── 角色管理 ─────────────────────────────────────────────
INSERT INTO sys_permission (parent_id, name, code, type, sort, portal_type, visible, status, deleted) VALUES
(@p_role, '查看角色列表', 'role:list',       3, 1, 0, 0, 1, 0),
(@p_role, '新增角色',     'role:add',        3, 2, 0, 0, 1, 0),
(@p_role, '编辑角色',     'role:edit',       3, 3, 0, 0, 1, 0),
(@p_role, '删除角色',     'role:delete',     3, 4, 0, 0, 1, 0),
(@p_role, '分配角色权限', 'role:permission', 3, 5, 0, 0, 1, 0);

-- ─── 员工管理 ─────────────────────────────────────────────
INSERT INTO sys_permission (parent_id, name, code, type, sort, portal_type, visible, status, deleted) VALUES
(@p_staff, '查看员工列表', 'staff:list',   3, 1, 0, 0, 1, 0),
(@p_staff, '新增员工',     'staff:add',    3, 2, 0, 0, 1, 0),
(@p_staff, '编辑员工',     'staff:edit',   3, 3, 0, 0, 1, 0),
(@p_staff, '删除员工',     'staff:delete', 3, 4, 0, 0, 1, 0),
(@p_staff, '切换员工状态', 'staff:toggle', 3, 5, 0, 0, 1, 0);

-- ─── 岗位管理 ─────────────────────────────────────────────
INSERT INTO sys_permission (parent_id, name, code, type, sort, portal_type, visible, status, deleted) VALUES
(@p_position, '查看岗位列表', 'position:list',   3, 1, 0, 0, 1, 0),
(@p_position, '新增岗位',     'position:add',    3, 2, 0, 0, 1, 0),
(@p_position, '编辑岗位',     'position:edit',   3, 3, 0, 0, 1, 0),
(@p_position, '删除岗位',     'position:delete', 3, 4, 0, 0, 1, 0),
(@p_position, '切换岗位状态', 'position:toggle', 3, 5, 0, 0, 1, 0);

-- ─── 权限管理 ─────────────────────────────────────────────
INSERT INTO sys_permission (parent_id, name, code, type, sort, portal_type, visible, status, deleted) VALUES
(@p_perm, '查看权限树',   'permission:list',   3, 1, 0, 0, 1, 0),
(@p_perm, '新增权限节点', 'permission:add',    3, 2, 0, 0, 1, 0),
(@p_perm, '编辑权限节点', 'permission:edit',   3, 3, 0, 0, 1, 0),
(@p_perm, '删除权限节点', 'permission:delete', 3, 4, 0, 0, 1, 0);

-- ─── 菜单管理 ─────────────────────────────────────────────
INSERT INTO sys_permission (parent_id, name, code, type, sort, portal_type, visible, status, deleted) VALUES
(@p_menu, '查看菜单列表', 'menu:list',   3, 1, 0, 0, 1, 0),
(@p_menu, '新增菜单',     'menu:add',    3, 2, 0, 0, 1, 0),
(@p_menu, '编辑菜单',     'menu:edit',   3, 3, 0, 0, 1, 0),
(@p_menu, '删除菜单',     'menu:delete', 3, 4, 0, 0, 1, 0);

-- ─── 部门管理（管理端） ───────────────────────────────────
INSERT INTO sys_permission (parent_id, name, code, type, sort, portal_type, visible, status, deleted) VALUES
(@p_dept, '查看部门列表', 'dept:list',   3, 1, 0, 0, 1, 0),
(@p_dept, '新增部门',     'dept:add',    3, 2, 0, 0, 1, 0),
(@p_dept, '编辑部门',     'dept:edit',   3, 3, 0, 0, 1, 0),
(@p_dept, '删除部门',     'dept:delete', 3, 4, 0, 0, 1, 0),
(@p_dept, '切换部门状态', 'dept:toggle', 3, 5, 0, 0, 1, 0);

-- ─── 车辆管理 ─────────────────────────────────────────────
INSERT INTO sys_permission (parent_id, name, code, type, sort, portal_type, visible, status, deleted) VALUES
(@p_vehicle, '查看车辆列表', 'vehicle:list',   3, 1, 0, 0, 1, 0),
(@p_vehicle, '新增车辆',     'vehicle:add',    3, 2, 0, 0, 1, 0),
(@p_vehicle, '编辑车辆',     'vehicle:edit',   3, 3, 0, 0, 1, 0),
(@p_vehicle, '删除车辆',     'vehicle:delete', 3, 4, 0, 0, 1, 0),
(@p_vehicle, '修改车辆状态', 'vehicle:status', 3, 5, 0, 0, 1, 0);

-- ─── 优惠券管理 ───────────────────────────────────────────
INSERT INTO sys_permission (parent_id, name, code, type, sort, portal_type, visible, status, deleted) VALUES
(@p_coupon, '查看优惠券列表', 'coupon:list',   3, 1, 0, 0, 1, 0),
(@p_coupon, '新增优惠券',     'coupon:add',    3, 2, 0, 0, 1, 0),
(@p_coupon, '编辑优惠券',     'coupon:edit',   3, 3, 0, 0, 1, 0),
(@p_coupon, '删除优惠券',     'coupon:delete', 3, 4, 0, 0, 1, 0);

-- ─── 类目管理 ─────────────────────────────────────────────
INSERT INTO sys_permission (parent_id, name, code, type, sort, portal_type, visible, status, deleted) VALUES
(@p_category, '查看类目列表', 'category:list',   3, 1, 0, 0, 1, 0),
(@p_category, '新增类目',     'category:add',    3, 2, 0, 0, 1, 0),
(@p_category, '编辑类目',     'category:edit',   3, 3, 0, 0, 1, 0),
(@p_category, '删除类目',     'category:delete', 3, 4, 0, 0, 1, 0);

-- ─── 横幅管理 ─────────────────────────────────────────────
INSERT INTO sys_permission (parent_id, name, code, type, sort, portal_type, visible, status, deleted) VALUES
(@p_banner, '查看横幅列表', 'banner:list',   3, 1, 0, 0, 1, 0),
(@p_banner, '新增横幅',     'banner:add',    3, 2, 0, 0, 1, 0),
(@p_banner, '编辑横幅',     'banner:edit',   3, 3, 0, 0, 1, 0),
(@p_banner, '删除横幅',     'banner:delete', 3, 4, 0, 0, 1, 0);

-- ─── 公告管理 ─────────────────────────────────────────────
INSERT INTO sys_permission (parent_id, name, code, type, sort, portal_type, visible, status, deleted) VALUES
(@p_notice, '查看公告列表', 'notice:list',   3, 1, 0, 0, 1, 0),
(@p_notice, '新增公告',     'notice:add',    3, 2, 0, 0, 1, 0),
(@p_notice, '编辑公告',     'notice:edit',   3, 3, 0, 0, 1, 0),
(@p_notice, '删除公告',     'notice:delete', 3, 4, 0, 0, 1, 0);

-- ─── 字典管理 ─────────────────────────────────────────────
INSERT INTO sys_permission (parent_id, name, code, type, sort, portal_type, visible, status, deleted) VALUES
(@p_dict, '查看字典列表', 'dict:list',   3, 1, 0, 0, 1, 0),
(@p_dict, '新增字典',     'dict:add',    3, 2, 0, 0, 1, 0),
(@p_dict, '编辑字典',     'dict:edit',   3, 3, 0, 0, 1, 0),
(@p_dict, '删除字典',     'dict:delete', 3, 4, 0, 0, 1, 0);

-- ─── 系统参数 ─────────────────────────────────────────────
INSERT INTO sys_permission (parent_id, name, code, type, sort, portal_type, visible, status, deleted) VALUES
(@p_sysconfig, '查看系统参数', 'sysconfig:list',   3, 1, 0, 0, 1, 0),
(@p_sysconfig, '新增系统参数', 'sysconfig:add',    3, 2, 0, 0, 1, 0),
(@p_sysconfig, '编辑系统参数', 'sysconfig:edit',   3, 3, 0, 0, 1, 0),
(@p_sysconfig, '删除系统参数', 'sysconfig:delete', 3, 4, 0, 0, 1, 0);

-- ─── 操作日志 ─────────────────────────────────────────────
INSERT INTO sys_permission (parent_id, name, code, type, sort, portal_type, visible, status, deleted) VALUES
(@p_log, '查看操作日志', 'log:list',   3, 1, 0, 0, 1, 0),
(@p_log, '删除操作日志', 'log:delete', 3, 2, 0, 0, 1, 0);

-- ─── 评价管理 ─────────────────────────────────────────────
INSERT INTO sys_permission (parent_id, name, code, type, sort, portal_type, visible, status, deleted) VALUES
(@p_review, '查看评价列表', 'review:list',   3, 1, 0, 0, 1, 0),
(@p_review, '隐藏/显示评价','review:toggle', 3, 2, 0, 0, 1, 0),
(@p_review, '删除评价',     'review:delete', 3, 3, 0, 0, 1, 0),
(@p_review, '回复评价',     'review:reply',  3, 4, 0, 0, 1, 0);

-- ─── 通知公告（商户端） ───────────────────────────────────
INSERT INTO sys_permission (parent_id, name, code, type, sort, portal_type, visible, status, deleted) VALUES
(@p_announce, '查看通知列表', 'announce:list',   3, 1, 0, 0, 1, 0),
(@p_announce, '新增通知',     'announce:add',    3, 2, 0, 0, 1, 0),
(@p_announce, '编辑通知',     'announce:edit',   3, 3, 0, 0, 1, 0),
(@p_announce, '删除通知',     'announce:delete', 3, 4, 0, 0, 1, 0);

-- ─── 运维监控 ─────────────────────────────────────────────
SET @p_monitor_job    = IFNULL((SELECT id FROM sys_permission WHERE path LIKE '%/admin/monitor/job%'    AND portal_type = 0 AND deleted = 0 LIMIT 1), 0);
SET @p_monitor_online = IFNULL((SELECT id FROM sys_permission WHERE path LIKE '%/admin/monitor/online%' AND portal_type = 0 AND deleted = 0 LIMIT 1), 0);
SET @p_monitor_cache  = IFNULL((SELECT id FROM sys_permission WHERE path LIKE '%/admin/monitor/cache%'  AND portal_type = 0 AND deleted = 0 LIMIT 1), 0);

INSERT INTO sys_permission (parent_id, name, code, type, sort, portal_type, visible, status, deleted) VALUES
(@p_monitor_job,    '查看定时任务',     'monitor:job:list',   3, 1, 0, 0, 1, 0),
(@p_monitor_job,    '暂停/恢复任务',    'monitor:job:toggle', 3, 2, 0, 0, 1, 0),
(@p_monitor_job,    '立即执行任务',     'monitor:job:run',    3, 3, 0, 0, 1, 0),
(@p_monitor_online, '查看在线用户',     'monitor:online',     3, 1, 0, 0, 1, 0),
(@p_monitor_online, '强制下线用户',     'monitor:online:kick',3, 2, 0, 0, 1, 0),
(@p_monitor_cache,  '查看缓存',         'monitor:cache',      3, 1, 0, 0, 1, 0),
(@p_monitor_cache,  '清除缓存',         'monitor:cache:clear',3, 2, 0, 0, 1, 0);

-- ═══════════════════════════════════════════════════════════════════════════
-- 商户端（portal_type=1）按钮级操作权限
-- 注：商户用户登录后前端默认持有 ["*"]，此处权限用于商户端 PermissionTreePage
--     展示及未来精细化授权扩展，不影响现有功能
-- ═══════════════════════════════════════════════════════════════════════════

-- 删除旧的商户端 type=3 操作权限（防止重复）
DELETE FROM sys_permission WHERE type = 3 AND portal_type = 1 AND deleted = 0;

-- 商户端父菜单 ID 变量
SET @m_dashboard  = IFNULL((SELECT id FROM sys_permission WHERE path LIKE '%/merchant/dashboard%'    AND portal_type = 1 AND deleted = 0 LIMIT 1), 0);
SET @m_order      = IFNULL((SELECT id FROM sys_permission WHERE path LIKE '%/merchant/order%'        AND portal_type = 1 AND deleted = 0 LIMIT 1), 0);
SET @m_tech       = IFNULL((SELECT id FROM sys_permission WHERE path LIKE '%/merchant/technician%'   AND portal_type = 1 AND deleted = 0 LIMIT 1), 0);
SET @m_review     = IFNULL((SELECT id FROM sys_permission WHERE path LIKE '%/merchant/review%'       AND portal_type = 1 AND deleted = 0 LIMIT 1), 0);
SET @m_coupon     = IFNULL((SELECT id FROM sys_permission WHERE path LIKE '%/merchant/coupon%'       AND portal_type = 1 AND deleted = 0 LIMIT 1), 0);
SET @m_announce   = IFNULL((SELECT id FROM sys_permission WHERE path LIKE '%/merchant/announce%'     AND portal_type = 1 AND deleted = 0 LIMIT 1), 0);
SET @m_staff      = IFNULL((SELECT id FROM sys_permission WHERE path LIKE '%/merchant/perm/staff%'   AND portal_type = 1 AND deleted = 0 LIMIT 1), 0);
SET @m_dept       = IFNULL((SELECT id FROM sys_permission WHERE path LIKE '%/merchant/perm/dept%'    AND portal_type = 1 AND deleted = 0 LIMIT 1), 0);
SET @m_position   = IFNULL((SELECT id FROM sys_permission WHERE path LIKE '%/merchant/perm/position%' AND portal_type = 1 AND deleted = 0 LIMIT 1), 0);
SET @m_role       = IFNULL((SELECT id FROM sys_permission WHERE path LIKE '%/merchant/perm/role%'    AND portal_type = 1 AND deleted = 0 LIMIT 1), 0);
SET @m_member     = IFNULL((SELECT id FROM sys_permission WHERE path LIKE '%/merchant/member%'       AND portal_type = 1 AND deleted = 0 LIMIT 1), 0);
SET @m_finance    = IFNULL((SELECT id FROM sys_permission WHERE path LIKE '%/merchant/finance%'      AND portal_type = 1 AND deleted = 0 LIMIT 1), 0);

-- 商户端：订单管理
INSERT INTO sys_permission (parent_id, name, code, type, sort, portal_type, visible, status, deleted) VALUES
(@m_order, '查看订单列表', 'order:list',   3, 1, 1, 0, 1, 0),
(@m_order, '取消订单',     'order:cancel', 3, 2, 1, 0, 1, 0),
(@m_order, '删除订单',     'order:delete', 3, 3, 1, 0, 1, 0);

-- 商户端：技师管理
INSERT INTO sys_permission (parent_id, name, code, type, sort, portal_type, visible, status, deleted) VALUES
(@m_tech, '查看技师列表',   'technician:list',    3, 1, 1, 0, 1, 0),
(@m_tech, '新增技师',       'technician:add',     3, 2, 1, 0, 1, 0),
(@m_tech, '编辑技师',       'technician:edit',    3, 3, 1, 0, 1, 0),
(@m_tech, '删除技师',       'technician:delete',  3, 4, 1, 0, 1, 0),
(@m_tech, '切换技师状态',   'technician:toggle',  3, 5, 1, 0, 1, 0),
(@m_tech, '设置推荐技师',   'technician:feature', 3, 6, 1, 0, 1, 0);

-- 商户端：评价管理
INSERT INTO sys_permission (parent_id, name, code, type, sort, portal_type, visible, status, deleted) VALUES
(@m_review, '查看评价列表', 'review:list',   3, 1, 1, 0, 1, 0),
(@m_review, '隐藏/显示评价','review:toggle', 3, 2, 1, 0, 1, 0),
(@m_review, '回复评价',     'review:reply',  3, 3, 1, 0, 1, 0),
(@m_review, '删除评价',     'review:delete', 3, 4, 1, 0, 1, 0);

-- 商户端：优惠券管理
INSERT INTO sys_permission (parent_id, name, code, type, sort, portal_type, visible, status, deleted) VALUES
(@m_coupon, '查看优惠券列表', 'coupon:list',   3, 1, 1, 0, 1, 0),
(@m_coupon, '申请/新增优惠券','coupon:add',    3, 2, 1, 0, 1, 0),
(@m_coupon, '编辑优惠券',     'coupon:edit',   3, 3, 1, 0, 1, 0),
(@m_coupon, '删除优惠券',     'coupon:delete', 3, 4, 1, 0, 1, 0);

-- 商户端：通知公告
INSERT INTO sys_permission (parent_id, name, code, type, sort, portal_type, visible, status, deleted) VALUES
(@m_announce, '查看通知列表', 'announce:list',   3, 1, 1, 0, 1, 0),
(@m_announce, '发布通知',     'announce:add',    3, 2, 1, 0, 1, 0),
(@m_announce, '编辑通知',     'announce:edit',   3, 3, 1, 0, 1, 0),
(@m_announce, '删除通知',     'announce:delete', 3, 4, 1, 0, 1, 0);

-- 商户端：员工管理
INSERT INTO sys_permission (parent_id, name, code, type, sort, portal_type, visible, status, deleted) VALUES
(@m_staff, '查看员工列表', 'staff:list',   3, 1, 1, 0, 1, 0),
(@m_staff, '新增员工',     'staff:add',    3, 2, 1, 0, 1, 0),
(@m_staff, '编辑员工',     'staff:edit',   3, 3, 1, 0, 1, 0),
(@m_staff, '删除员工',     'staff:delete', 3, 4, 1, 0, 1, 0),
(@m_staff, '切换员工状态', 'staff:toggle', 3, 5, 1, 0, 1, 0);

-- 商户端：部门管理
INSERT INTO sys_permission (parent_id, name, code, type, sort, portal_type, visible, status, deleted) VALUES
(@m_dept, '查看部门列表', 'dept:list',   3, 1, 1, 0, 1, 0),
(@m_dept, '新增部门',     'dept:add',    3, 2, 1, 0, 1, 0),
(@m_dept, '编辑部门',     'dept:edit',   3, 3, 1, 0, 1, 0),
(@m_dept, '删除部门',     'dept:delete', 3, 4, 1, 0, 1, 0),
(@m_dept, '切换部门状态', 'dept:toggle', 3, 5, 1, 0, 1, 0);

-- 商户端：岗位管理
INSERT INTO sys_permission (parent_id, name, code, type, sort, portal_type, visible, status, deleted) VALUES
(@m_position, '查看岗位列表', 'position:list',   3, 1, 1, 0, 1, 0),
(@m_position, '新增岗位',     'position:add',    3, 2, 1, 0, 1, 0),
(@m_position, '编辑岗位',     'position:edit',   3, 3, 1, 0, 1, 0),
(@m_position, '删除岗位',     'position:delete', 3, 4, 1, 0, 1, 0),
(@m_position, '切换岗位状态', 'position:toggle', 3, 5, 1, 0, 1, 0);

-- 商户端：角色权限管理
INSERT INTO sys_permission (parent_id, name, code, type, sort, portal_type, visible, status, deleted) VALUES
(@m_role, '查看角色列表', 'role:list',       3, 1, 1, 0, 1, 0),
(@m_role, '新增角色',     'role:add',        3, 2, 1, 0, 1, 0),
(@m_role, '编辑角色',     'role:edit',       3, 3, 1, 0, 1, 0),
(@m_role, '删除角色',     'role:delete',     3, 4, 1, 0, 1, 0),
(@m_role, '分配角色权限', 'role:permission', 3, 5, 1, 0, 1, 0);

-- 商户端：会员列表（只读）
INSERT INTO sys_permission (parent_id, name, code, type, sort, portal_type, visible, status, deleted) VALUES
(@m_member, '查看会员列表', 'member:list', 3, 1, 1, 0, 1, 0);

-- ─── 为 SUPER_ADMIN 角色分配所有新增操作权限（管理端 + 商户端） ──────────
INSERT INTO sys_role_permission (role_id, permission_id)
SELECT r.id, p.id
FROM sys_role r
JOIN sys_permission p ON p.type = 3 AND p.deleted = 0
WHERE r.role_code = 'SUPER_ADMIN'
  AND NOT EXISTS (
    SELECT 1 FROM sys_role_permission rp
    WHERE rp.role_id = r.id AND rp.permission_id = p.id
  );

-- ── migrate_v3_6.sql ─────────────────────────────────────────────────────────
-- ============================================================
-- v3.6  会员地址字段
-- ============================================================

-- 1. cb_member 新增 address 字段（放在 last_login_ip 之后）
ALTER TABLE cb_member
    ADD COLUMN address VARCHAR(255) NULL COMMENT '会员地址' AFTER last_login_ip;

-- ── migrate_v3_7.sql ─────────────────────────────────────────────────────────
-- ============================================================
-- v3.7  车辆支持多图
-- ============================================================

-- cb_vehicle：新增多图字段（JSON 数组字符串）
--   原 photo 字段保留，兼容旧数据；photos 存多张图 URL JSON 数组
ALTER TABLE cb_vehicle
    ADD COLUMN photos TEXT NULL COMMENT '车辆多图（JSON数组，如 ["url1","url2"]）' AFTER photo;

-- ── migrate_v4_0.sql ─────────────────────────────────────────────────────────
-- ================================================================================
-- CamBook 数据库迁移脚本 v4.0
-- 描述：新增散客接待、多支付、派车记录、财务管理核心表
-- 版本：v4.0.0
-- 日期：2026-04-13
-- ================================================================================

-- ── 1. cb_order 扩展：支持散客/在线两种客户类型 ──────────────────────────────
ALTER TABLE `cb_order`
    ADD COLUMN `order_type`    TINYINT      NOT NULL DEFAULT 1  COMMENT '订单类型：1=在线预约 2=散客上门' AFTER `id`,
    ADD COLUMN `session_id`    BIGINT                           COMMENT '散客接待 session ID（order_type=2 时有值），关联 cb_walkin_session.id' AFTER `order_type`,
    ADD COLUMN `wristband_no`  VARCHAR(20)                      COMMENT '手环编号（散客上门时的识别号，如 0928）' AFTER `session_id`;

-- ── 2. cb_walkin_session：散客接待（手环）Session ──────────────────────────────
CREATE TABLE IF NOT EXISTS `cb_walkin_session` (
    `id`              BIGINT        NOT NULL AUTO_INCREMENT          COMMENT '主键',
    `session_no`      VARCHAR(32)   NOT NULL                        COMMENT '接待流水号（系统生成，格式 WK+yyyyMMdd+4位序号）',
    `wristband_no`    VARCHAR(20)   NOT NULL                        COMMENT '手环编号（前台发放，当日唯一，如 0928）',
    `merchant_id`     BIGINT        NOT NULL                        COMMENT '所属商户 ID',
    `member_id`       BIGINT                                        COMMENT '关联会员 ID（若客户已注册则关联，散客可为空）',
    `member_name`     VARCHAR(100)                                  COMMENT '客户姓名/称呼（散客登记名，可为空）',
    `member_mobile`   VARCHAR(30)                                   COMMENT '客户手机号（散客登记，可为空）',
    `staff_id`        BIGINT                                        COMMENT '接待员工 ID',
    `status`          TINYINT       NOT NULL DEFAULT 0              COMMENT '状态：0=接待中 1=服务中 2=待结算 3=已结算 4=已取消',
    `total_amount`    DECIMAL(10,2) NOT NULL DEFAULT 0.00           COMMENT '消费总金额',
    `paid_amount`     DECIMAL(10,2) NOT NULL DEFAULT 0.00           COMMENT '已结算金额',
    `remark`          VARCHAR(500)                                  COMMENT '接待备注',
    `check_in_time`   DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '到店时间',
    `check_out_time`  DATETIME                                      COMMENT '离店/结算时间',
    `create_time`     DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `update_time`     DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_session_no` (`session_no`),
    KEY `idx_wristband`   (`merchant_id`, `wristband_no`, `check_in_time`),
    KEY `idx_merchant_status` (`merchant_id`, `status`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci
  COMMENT = '散客接待 Session：一次到店对应一个 session，手环是识别载体';

-- ── 3. cb_payment_record：支付流水（支持多种支付方式混合结算）─────────────────
CREATE TABLE IF NOT EXISTS `cb_payment_record` (
    `id`              BIGINT        NOT NULL AUTO_INCREMENT          COMMENT '主键',
    `merchant_id`     BIGINT        NOT NULL                        COMMENT '所属商户 ID',
    `session_id`      BIGINT                                        COMMENT '关联散客 session ID（散客结算时有值）',
    `order_id`        BIGINT                                        COMMENT '关联订单 ID（在线预约时有值）',
    `pay_method`      TINYINT       NOT NULL                        COMMENT '支付方式：1=现金 2=微信 3=支付宝 4=银行转账 5=USDT 6=ABA Pay 7=Wing 8=其它',
    `amount`          DECIMAL(10,2) NOT NULL                        COMMENT '本次支付金额',
    `currency`        VARCHAR(10)   NOT NULL DEFAULT 'USD'          COMMENT '货币类型：USD/CNY/KHR',
    `exchange_rate`   DECIMAL(10,4) NOT NULL DEFAULT 1.0000         COMMENT '对 USD 汇率',
    `usd_amount`      DECIMAL(10,2) NOT NULL                        COMMENT '折算 USD 金额',
    `reference_no`    VARCHAR(100)                                  COMMENT '支付参考号/交易流水（转账凭证号）',
    `remark`          VARCHAR(200)                                  COMMENT '备注',
    `operator_id`     BIGINT                                        COMMENT '操作员工 ID',
    `pay_time`        DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '收款时间',
    `create_time`     DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_session`   (`session_id`),
    KEY `idx_order`     (`order_id`),
    KEY `idx_merchant_time` (`merchant_id`, `pay_time`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci
  COMMENT = '支付流水：支持多种支付方式，一次结算可拆分多笔支付';

-- ── 4. cb_vehicle_dispatch：派车记录 ──────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `cb_vehicle_dispatch` (
    `id`              BIGINT        NOT NULL AUTO_INCREMENT          COMMENT '主键',
    `dispatch_no`     VARCHAR(32)   NOT NULL                        COMMENT '派车单号',
    `merchant_id`     BIGINT        NOT NULL                        COMMENT '所属商户 ID',
    `vehicle_id`      BIGINT        NOT NULL                        COMMENT '车辆 ID，关联 cb_vehicle.id',
    `vehicle_plate`   VARCHAR(30)   NOT NULL                        COMMENT '车牌号快照',
    `driver_id`       BIGINT                                        COMMENT '驾驶员员工 ID',
    `driver_name`     VARCHAR(50)                                   COMMENT '驾驶员姓名快照',
    `purpose`         TINYINT       NOT NULL DEFAULT 1              COMMENT '用途：1=接送客户 2=采购 3=员工通勤 4=业务出行 5=其它',
    `destination`     VARCHAR(200)                                  COMMENT '目的地',
    `passenger_info`  VARCHAR(200)                                  COMMENT '乘客/随行人员信息',
    `order_id`        BIGINT                                        COMMENT '关联订单 ID（接送客户时）',
    `depart_time`     DATETIME                                      COMMENT '出发时间',
    `return_time`     DATETIME                                      COMMENT '返回时间',
    `mileage`         DECIMAL(8,2)                                  COMMENT '行驶里程（km）',
    `fuel_cost`       DECIMAL(8,2)                                  COMMENT '油费（USD）',
    `other_cost`      DECIMAL(8,2)                                  COMMENT '其它费用（USD）',
    `total_cost`      DECIMAL(8,2)  NOT NULL DEFAULT 0.00           COMMENT '本次用车总费用（USD）',
    `status`          TINYINT       NOT NULL DEFAULT 0              COMMENT '状态：0=待出发 1=行程中 2=已返回 3=已取消',
    `remark`          VARCHAR(500)                                  COMMENT '备注',
    `operator_id`     BIGINT                                        COMMENT '派车操作人 ID',
    `create_time`     DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `update_time`     DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_dispatch_no` (`dispatch_no`),
    KEY `idx_vehicle`   (`vehicle_id`, `create_time`),
    KEY `idx_driver`    (`driver_id`),
    KEY `idx_merchant`  (`merchant_id`, `create_time`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci
  COMMENT = '派车记录：记录每次车辆使用情况，支持多维度查询';

-- ── 5. cb_finance_expense：支出记录 ───────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `cb_finance_expense` (
    `id`              BIGINT        NOT NULL AUTO_INCREMENT          COMMENT '主键',
    `merchant_id`     BIGINT        NOT NULL                        COMMENT '所属商户 ID',
    `expense_no`      VARCHAR(32)   NOT NULL                        COMMENT '支出单号',
    `category`        TINYINT       NOT NULL                        COMMENT '支出类型：1=店租/场地 2=车辆费用 3=水电费 4=员工工资 5=采购进货 6=营销推广 7=设备维修 8=其它',
    `amount`          DECIMAL(10,2) NOT NULL                        COMMENT '支出金额（USD）',
    `currency`        VARCHAR(10)   NOT NULL DEFAULT 'USD'          COMMENT '原始货币',
    `exchange_rate`   DECIMAL(10,4) NOT NULL DEFAULT 1.0000         COMMENT '汇率',
    `usd_amount`      DECIMAL(10,2) NOT NULL                        COMMENT '折算 USD 金额',
    `pay_method`      TINYINT       NOT NULL DEFAULT 1              COMMENT '支付方式：1=现金 2=微信 3=支付宝 4=银行 5=USDT 8=其它',
    `title`           VARCHAR(200)  NOT NULL                        COMMENT '支出标题/摘要',
    `description`     VARCHAR(500)                                  COMMENT '详细说明',
    `voucher_images`  TEXT                                          COMMENT '凭证图片 URL（JSON 数组）',
    `expense_date`    DATE          NOT NULL                        COMMENT '支出日期',
    `operator_id`     BIGINT                                        COMMENT '经办人员工 ID',
    `approver_id`     BIGINT                                        COMMENT '审核人 ID',
    `status`          TINYINT       NOT NULL DEFAULT 1              COMMENT '状态：0=草稿 1=已确认 2=已作废',
    `create_time`     DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `update_time`     DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_expense_no` (`expense_no`),
    KEY `idx_merchant_date` (`merchant_id`, `expense_date`),
    KEY `idx_category`      (`merchant_id`, `category`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci
  COMMENT = '支出记录：覆盖店租、车辆、水电、工资、采购、营销等全类目';

-- ── 6. cb_finance_salary：薪资单 ──────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `cb_finance_salary` (
    `id`              BIGINT        NOT NULL AUTO_INCREMENT          COMMENT '主键',
    `merchant_id`     BIGINT        NOT NULL                        COMMENT '所属商户 ID',
    `salary_month`    VARCHAR(7)    NOT NULL                        COMMENT '薪资月份（格式 yyyy-MM）',
    `staff_id`        BIGINT                                        COMMENT '员工 ID（关联 sys_user 或技师）',
    `staff_type`      TINYINT       NOT NULL DEFAULT 1              COMMENT '人员类型：1=员工 2=技师',
    `staff_name`      VARCHAR(50)   NOT NULL                        COMMENT '姓名快照',
    `base_salary`     DECIMAL(10,2) NOT NULL DEFAULT 0.00           COMMENT '基本工资（USD）',
    `commission`      DECIMAL(10,2) NOT NULL DEFAULT 0.00           COMMENT '提成金额（USD，技师按订单分成）',
    `bonus`           DECIMAL(10,2) NOT NULL DEFAULT 0.00           COMMENT '绩效奖金（USD）',
    `deduction`       DECIMAL(10,2) NOT NULL DEFAULT 0.00           COMMENT '扣款（USD，迟到/违规等）',
    `total_amount`    DECIMAL(10,2) NOT NULL DEFAULT 0.00           COMMENT '实发工资（USD，= base_salary + commission + bonus - deduction）',
    `order_count`     INT           NOT NULL DEFAULT 0              COMMENT '本月完成订单数（技师）',
    `order_revenue`   DECIMAL(10,2) NOT NULL DEFAULT 0.00           COMMENT '本月服务营收（技师）',
    `pay_method`      TINYINT                                       COMMENT '发薪方式：1=现金 2=银行 3=USDT',
    `pay_time`        DATETIME                                      COMMENT '实际发薪时间',
    `status`          TINYINT       NOT NULL DEFAULT 0              COMMENT '状态：0=待发放 1=已发放 2=已作废',
    `remark`          VARCHAR(300)                                  COMMENT '备注',
    `create_time`     DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `update_time`     DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_merchant_month` (`merchant_id`, `salary_month`),
    KEY `idx_staff`          (`staff_id`, `staff_type`, `salary_month`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci
  COMMENT = '薪资单：覆盖员工工资和技师提成，支持按月汇总发放';

-- ── migrate_v4_1.sql ─────────────────────────────────────────────────────────
-- ================================================================================
-- CamBook 数据库迁移脚本 v4.1
-- 描述：多币种支持 — 全局币种注册表 + 商户币种配置
-- 日期：2026-04-13
-- ================================================================================

-- ── 1. sys_currency：全平台支持的币种注册表 ──────────────────────────────────
CREATE TABLE IF NOT EXISTS `sys_currency` (
    `id`                   BIGINT        NOT NULL AUTO_INCREMENT          COMMENT '主键',
    `currency_code`        VARCHAR(10)   NOT NULL                        COMMENT '货币代码（ISO 4217）：USD / CNY / USDT / PHP / THB / KRW / AED / MYR',
    `currency_name`        VARCHAR(50)   NOT NULL                        COMMENT '货币中文名：美元 / 人民币 / USDT',
    `currency_name_en`     VARCHAR(50)   NOT NULL                        COMMENT '货币英文名：US Dollar / Chinese Yuan',
    `symbol`               VARCHAR(10)   NOT NULL                        COMMENT '货币符号：$ / ¥ / ₱ / ฿ / ₩ / د.إ / RM / ₮',
    `flag`                 VARCHAR(10)                                   COMMENT '国旗 Emoji：🇺🇸 / 🇨🇳 / 🇵🇭 / 🇹🇭 / 🇰🇷 / 🇦🇪 / 🇲🇾',
    `is_crypto`            TINYINT       NOT NULL DEFAULT 0              COMMENT '是否加密货币：0=法币 1=加密货币（USDT等）',
    `rate_to_usd`          DECIMAL(20,8) NOT NULL DEFAULT 1.00000000     COMMENT '对 USD 汇率（1 单位本币 = X USD），USDT=1',
    `rate_update_time`     DATETIME                                      COMMENT '汇率最后更新时间',
    `decimal_places`       TINYINT       NOT NULL DEFAULT 2              COMMENT '小数位数（KRW=0, USDT=6）',
    `sort_order`           INT           NOT NULL DEFAULT 0              COMMENT '排序（越小越靠前）',
    `status`               TINYINT       NOT NULL DEFAULT 1              COMMENT '状态：0=停用 1=启用',
    `remark`               VARCHAR(200)                                  COMMENT '备注',
    `create_time`          DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `update_time`          DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_currency_code` (`currency_code`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci
  COMMENT = '币种注册表：平台支持的所有结算货币及实时汇率';

-- ── 2. 初始化内置币种数据 ────────────────────────────────────────────────────
INSERT INTO `sys_currency`
    (`currency_code`, `currency_name`, `currency_name_en`, `symbol`, `flag`, `is_crypto`, `rate_to_usd`, `decimal_places`, `sort_order`, `status`, `remark`)
VALUES
    ('USD',  '美元',       'US Dollar',         '$',    '🇺🇸', 0, 1.00000000,    2, 1,  1, '平台基准货币'),
    ('USDT', 'USDT',      'Tether USD',         '₮',    '💵', 1, 1.00000000,    6, 2,  1, '加密稳定币，1:1 锚定 USD'),
    ('CNY',  '人民币',     'Chinese Yuan',       '¥',    '🇨🇳', 0, 0.13800000,    2, 3,  1, '中国人民币'),
    ('PHP',  '菲律宾比索', 'Philippine Peso',    '₱',    '🇵🇭', 0, 0.01700000,    2, 4,  1, '菲律宾官方货币'),
    ('THB',  '泰铢',       'Thai Baht',          '฿',    '🇹🇭', 0, 0.02800000,    2, 5,  1, '泰国官方货币'),
    ('KRW',  '韩元',       'Korean Won',         '₩',    '🇰🇷', 0, 0.00073000,    0, 6,  1, '韩国官方货币，无小数'),
    ('AED',  '迪拜迪拉姆', 'UAE Dirham',         'د.إ',  '🇦🇪', 0, 0.27200000,    2, 7,  1, '阿联酋官方货币'),
    ('MYR',  '马来西亚林吉特', 'Malaysian Ringgit', 'RM', '🇲🇾', 0, 0.22000000,   2, 8,  1, '马来西亚官方货币'),
    ('KHR',  '柬埔寨瑞尔', 'Cambodian Riel',     '៛',    '🇰🇭', 0, 0.00024000,    0, 9,  1, '柬埔寨官方货币'),
    ('SGD',  '新加坡元',   'Singapore Dollar',   'S$',   '🇸🇬', 0, 0.74000000,    2, 10, 1, '新加坡官方货币'),
    ('EUR',  '欧元',       'Euro',               '€',    '🇪🇺', 0, 1.08000000,    2, 11, 1, '欧元区货币'),
    ('GBP',  '英镑',       'British Pound',       '£',    '🇬🇧', 0, 1.26000000,    2, 12, 1, '英国官方货币'),
    ('JPY',  '日元',       'Japanese Yen',        '¥',    '🇯🇵', 0, 0.00660000,    0, 13, 1, '日本官方货币'),
    ('BTC',  'Bitcoin',   'Bitcoin',             '₿',    '🪙',  1, 65000.00000000, 8, 20, 1, '比特币，汇率每日更新'),
    ('ETH',  'Ethereum',  'Ethereum',            'Ξ',    '💎',  1, 3200.00000000,  8, 21, 1, '以太坊，汇率每日更新');

-- ── 3. cb_merchant_currency：商户启用的币种配置 ──────────────────────────────
CREATE TABLE IF NOT EXISTS `cb_merchant_currency` (
    `id`             BIGINT        NOT NULL AUTO_INCREMENT          COMMENT '主键',
    `merchant_id`    BIGINT        NOT NULL                        COMMENT '商户 ID，关联 cb_merchant.id',
    `currency_code`  VARCHAR(10)   NOT NULL                        COMMENT '货币代码，关联 sys_currency.currency_code',
    `is_default`     TINYINT       NOT NULL DEFAULT 0              COMMENT '是否默认收款币种：0=否 1=是（每个商户只能有一个默认）',
    `custom_rate`    DECIMAL(20,8)                                 COMMENT '商户自定义汇率（优先级高于 sys_currency.rate_to_usd，为空则用全局汇率）',
    `display_name`   VARCHAR(50)                                   COMMENT '商户自定义显示名（如 空=使用全局名）',
    `sort_order`     INT           NOT NULL DEFAULT 0              COMMENT '商户侧排序',
    `status`         TINYINT       NOT NULL DEFAULT 1              COMMENT '状态：0=停用 1=启用',
    `create_time`    DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `update_time`    DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_merchant_currency` (`merchant_id`, `currency_code`),
    KEY `idx_merchant_id` (`merchant_id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci
  COMMENT = '商户币种配置：每家商户可独立启用不同结算货币，支持自定义汇率';

-- ── 4. 补充 cb_payment_record 字段（若已存在则跳过）──────────────────────────
-- 支付流水已有 currency / exchange_rate / usd_amount，无需新增
-- 仅补充 original_amount（本币金额）字段的注释统一
-- ALTER TABLE `cb_payment_record` 已在 migrate_v4_0.sql 定义，此处无需重复

-- ── 5. 汇率历史记录表（支持汇率走势查询）────────────────────────────────────
CREATE TABLE IF NOT EXISTS `sys_currency_rate_log` (
    `id`             BIGINT        NOT NULL AUTO_INCREMENT          COMMENT '主键',
    `currency_code`  VARCHAR(10)   NOT NULL                        COMMENT '货币代码',
    `rate_to_usd`    DECIMAL(20,8) NOT NULL                        COMMENT '对 USD 汇率',
    `source`         VARCHAR(50)                                   COMMENT '汇率来源：manual=手动 / api=自动拉取',
    `create_time`    DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '记录时间',
    PRIMARY KEY (`id`),
    KEY `idx_currency_time` (`currency_code`, `create_time`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci
  COMMENT = '汇率变动历史：支持查看某币种汇率走势';

-- ── migrate_v4_2.sql ─────────────────────────────────────────────────────────
-- ================================================================================
-- CamBook 数据库迁移脚本 v4.2
-- 描述：技师工资结算体系（每笔/日结/周结/月结）+ 越南盾 VND 币种
-- 日期：2026-04-13
-- ================================================================================

-- ── 1. 补充越南盾到全局币种表 ────────────────────────────────────────────────
INSERT IGNORE INTO `sys_currency`
    (`currency_code`, `currency_name`, `currency_name_en`, `symbol`, `flag`, `is_crypto`, `rate_to_usd`, `decimal_places`, `sort_order`, `status`, `remark`)
VALUES
    ('VND', '越南盾', 'Vietnamese Dong', '₫', '🇻🇳', 0, 0.000039000, 0, 9, 1, '越南官方货币，无小数位');

-- ── 2. 技师表扩展结算配置字段 ────────────────────────────────────────────────
-- settlement_mode: 0=每笔结算 1=日结 2=周结 3=月结
-- commission_type: 0=按比例提成 1=固定金额/单
-- 注意：ADD COLUMN IF NOT EXISTS 仅 MySQL 8.0.3+ 支持，此处改为标准写法。
-- 若字段已存在会报错，重复执行时请跳过或手动注释掉本段。
ALTER TABLE `cb_technician`
    ADD COLUMN `settlement_mode`     TINYINT      NOT NULL DEFAULT 3     COMMENT '结算方式：0=每笔结算 1=日结 2=周结 3=月结',
    ADD COLUMN `commission_type`     TINYINT      NOT NULL DEFAULT 0     COMMENT '提成类型：0=按比例(%) 1=固定金额/单',
    ADD COLUMN `commission_rate`     DECIMAL(8,2) NOT NULL DEFAULT 60.00 COMMENT '提成比例(%) 或 固定金额/单（取决于 commission_type）',
    ADD COLUMN `commission_currency` VARCHAR(10)  NOT NULL DEFAULT 'USD' COMMENT '固定金额类型时的结算币种';

-- ── 3. 技师结算批次主表 ──────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `cb_technician_settlement` (
    `id`                BIGINT        NOT NULL AUTO_INCREMENT COMMENT '主键',
    `merchant_id`       BIGINT        NOT NULL               COMMENT '所属商户 ID',
    `technician_id`     BIGINT        NOT NULL               COMMENT '技师 ID',
    `technician_name`   VARCHAR(50)                          COMMENT '技师姓名（冗余，防止联表）',
    `settlement_no`     VARCHAR(32)   NOT NULL               COMMENT '结算单号（唯一）',
    `settlement_mode`   TINYINT       NOT NULL               COMMENT '结算方式：0=每笔 1=日结 2=周结 3=月结',
    `period_start`      DATE                                 COMMENT '结算周期开始日期',
    `period_end`        DATE                                 COMMENT '结算周期结束日期',
    `order_count`       INT           NOT NULL DEFAULT 0     COMMENT '本批次订单数量',
    `total_revenue`     DECIMAL(12,2) NOT NULL DEFAULT 0     COMMENT '本批次总营业额',
    `commission_rate`   DECIMAL(8,2)  NOT NULL DEFAULT 0     COMMENT '提成比例(%) 或 固定金额',
    `commission_type`   TINYINT       NOT NULL DEFAULT 0     COMMENT '0=按比例 1=固定',
    `commission_amount` DECIMAL(12,2) NOT NULL DEFAULT 0     COMMENT '基础提成金额',
    `bonus_amount`      DECIMAL(12,2) NOT NULL DEFAULT 0     COMMENT '奖励金额（好评奖、达标奖等）',
    `deduction_amount`  DECIMAL(12,2) NOT NULL DEFAULT 0     COMMENT '扣款金额（违规、损耗等）',
    `final_amount`      DECIMAL(12,2) NOT NULL DEFAULT 0     COMMENT '最终应付金额 = 提成+奖励-扣款',
    `currency_code`     VARCHAR(10)   NOT NULL DEFAULT 'USD' COMMENT '结算币种',
    `currency_symbol`   VARCHAR(10)                          COMMENT '货币符号（冗余展示）',
    `payment_method`    VARCHAR(30)                          COMMENT '支付方式：cash/bank/usdt/wechat/...',
    `payment_ref`       VARCHAR(100)                         COMMENT '转账/流水号',
    `status`            TINYINT       NOT NULL DEFAULT 0     COMMENT '状态：0=待结算 1=已结算 2=争议/暂扣',
    `paid_time`         DATETIME                             COMMENT '实际打款时间',
    `remark`            VARCHAR(500)                         COMMENT '结算备注',
    `operator`          VARCHAR(50)                          COMMENT '操作人',
    `create_time`       DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `update_time`       DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_settlement_no` (`settlement_no`),
    KEY `idx_merchant_tech`  (`merchant_id`, `technician_id`),
    KEY `idx_status`         (`status`),
    KEY `idx_period`         (`period_start`, `period_end`),
    KEY `idx_mode`           (`settlement_mode`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci
  COMMENT = '技师结算批次：支持每笔/日结/周结/月结四种方式';

-- ── 4. 结算明细表：记录哪些订单被纳入本次结算 ───────────────────────────────
CREATE TABLE IF NOT EXISTS `cb_technician_settlement_item` (
    `id`                BIGINT        NOT NULL AUTO_INCREMENT COMMENT '主键',
    `settlement_id`     BIGINT        NOT NULL               COMMENT '关联结算批次 ID',
    `order_id`          BIGINT        NOT NULL               COMMENT '关联订单 ID',
    `order_no`          VARCHAR(32)                          COMMENT '订单号（冗余）',
    `service_name`      VARCHAR(100)                         COMMENT '服务项目名称（冗余）',
    `order_amount`      DECIMAL(12,2)                        COMMENT '订单金额',
    `commission_rate`   DECIMAL(8,2)                         COMMENT '本单适用提成比例/金额',
    `commission_amount` DECIMAL(12,2)                        COMMENT '本单提成金额',
    `service_time`      DATETIME                             COMMENT '服务时间',
    PRIMARY KEY (`id`),
    KEY `idx_settlement_id` (`settlement_id`),
    KEY `idx_order_id`      (`order_id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci
  COMMENT = '技师结算明细：本次结算包含的订单及各自提成';

-- ── 5. 结算配置模板表（可选：商户级别默认提成规则）────────────────────────────
CREATE TABLE IF NOT EXISTS `cb_commission_rule` (
    `id`               BIGINT        NOT NULL AUTO_INCREMENT COMMENT '主键',
    `merchant_id`      BIGINT        NOT NULL               COMMENT '商户 ID（0=平台默认）',
    `rule_name`        VARCHAR(50)   NOT NULL               COMMENT '规则名称',
    `settlement_mode`  TINYINT       NOT NULL DEFAULT 3     COMMENT '默认结算方式',
    `commission_type`  TINYINT       NOT NULL DEFAULT 0     COMMENT '0=按比例 1=固定金额',
    `commission_value` DECIMAL(8,2)  NOT NULL DEFAULT 60    COMMENT '提成比例(%) 或 固定金额',
    `currency_code`    VARCHAR(10)   NOT NULL DEFAULT 'USD' COMMENT '固定金额时的币种',
    `bonus_threshold`  DECIMAL(12,2)                        COMMENT '奖励达标门槛（月营业额超过此值触发奖励）',
    `bonus_amount`     DECIMAL(12,2)                        COMMENT '奖励金额',
    `is_default`       TINYINT       NOT NULL DEFAULT 0     COMMENT '是否商户默认规则',
    `status`           TINYINT       NOT NULL DEFAULT 1,
    `remark`           VARCHAR(200),
    `create_time`      DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `update_time`      DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_merchant` (`merchant_id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci
  COMMENT = '提成规则配置：商户可设置不同技师群体的提成模板';

-- ── migrate_v4_3.sql ─────────────────────────────────────────────────────────
-- ============================================================
-- migrate_v4_3.sql
-- 1. 补全商户端菜单树（散客接待、历史订单、派车记录、完整财务、货币设置）
-- 2. 重构订单管理/车辆管理/财务管理/商户设置为目录，添加子菜单
-- 3. 写入完整商户测试数据（会员、技师、订单、财务记录等）
-- ============================================================

-- ─────────────────────────────────────────────────────────────
-- PART 1: 商户端菜单重构
-- ─────────────────────────────────────────────────────────────

-- ── Step 1: 调整现有顶级菜单 sort 为 10x 档位（留出插入空间）
UPDATE sys_permission SET sort = 10  WHERE id = 1010 AND portal_type = 1; -- 数据看板
UPDATE sys_permission SET sort = 20  WHERE id = 1011 AND portal_type = 1; -- 订单管理
UPDATE sys_permission SET sort = 40  WHERE id = 1000 AND portal_type = 1; -- 公告管理
UPDATE sys_permission SET sort = 50  WHERE id = 1001 AND portal_type = 1; -- 运营管理
UPDATE sys_permission SET sort = 60  WHERE id = 1002 AND portal_type = 1; -- 营销管理
UPDATE sys_permission SET sort = 70  WHERE id = 1003 AND portal_type = 1; -- 财务管理
UPDATE sys_permission SET sort = 80  WHERE id = 1004 AND portal_type = 1; -- 权限管理
UPDATE sys_permission SET sort = 90  WHERE id = 1019 AND portal_type = 1; -- 商户设置

-- ── Step 2: 将 "订单管理" 从 type=2(页面) 改为 type=1(目录)，清空 path
UPDATE sys_permission
SET type = 1, path = NULL, component = NULL
WHERE id = 1011 AND portal_type = 1;

-- ── Step 3: 将 "车辆管理" 从 type=2(页面) 改为 type=1(目录)，清空 path
UPDATE sys_permission
SET type = 1, path = NULL, component = NULL
WHERE id = 1032 AND portal_type = 1;

-- ── Step 4: 将 "商户设置" 从 type=2(页面) 改为 type=1(目录)，清空 path
UPDATE sys_permission
SET type = 1, path = NULL, component = NULL
WHERE id = 1019 AND portal_type = 1;

-- ── Step 5: 将 "财务管理" 下旧的两条菜单隐藏（不删除，兼容旧路由）
UPDATE sys_permission SET visible = 0 WHERE id IN (1050, 1051) AND portal_type = 1;

-- ── Step 6: 新增所有缺失菜单（id 从 1100 开始）
-- 防重复：先删再插
DELETE FROM sys_permission WHERE id BETWEEN 1100 AND 1130 AND portal_type = 1;

INSERT INTO sys_permission
    (id, parent_id, name, code, type, path, component, icon, sort, portal_type, visible, status, deleted)
VALUES
-- ── 订单管理子菜单（parent=1011）────────────────────────────
(1100, 1011, '在线订单',   NULL, 2, '/merchant/orders',          NULL, 'OrderedListOutlined', 1, 1, 1, 1, 0),
(1101, 1011, '历史记录',   NULL, 2, '/merchant/orders/history',  NULL, 'FileTextOutlined',    2, 1, 1, 1, 0),

-- ── 散客接待（顶级，sort=30）────────────────────────────────
(1102, 0,    '散客接待',   NULL, 2, '/merchant/walkin',          NULL, 'IdcardOutlined',     30, 1, 1, 1, 0),

-- ── 车辆管理子菜单（parent=1032）────────────────────────────
(1103, 1032, '车辆列表',   NULL, 2, '/merchant/vehicles',          NULL, 'CarOutlined',       1, 1, 1, 1, 0),
(1104, 1032, '派车记录',   NULL, 2, '/merchant/vehicles/dispatch', NULL, 'FileTextOutlined',  2, 1, 1, 1, 0),

-- ── 财务管理完整子菜单（parent=1003）────────────────────────
(1105, 1003, '财务概览',   NULL, 2, '/merchant/finance/overview',    NULL, 'BarChartOutlined',   1, 1, 1, 1, 0),
(1106, 1003, '收入记录',   NULL, 2, '/merchant/finance/income',      NULL, 'DollarOutlined',     2, 1, 1, 1, 0),
(1107, 1003, '支出管理',   NULL, 2, '/merchant/finance/expense',     NULL, 'MinusCircleOutlined',3, 1, 1, 1, 0),
(1108, 1003, '工资管理',   NULL, 2, '/merchant/finance/salary',      NULL, 'TeamOutlined',       4, 1, 1, 1, 0),
(1109, 1003, '技师结算',   NULL, 2, '/merchant/finance/settlement',  NULL, 'BankOutlined',       5, 1, 1, 1, 0),
(1110, 1003, '提现审核',   NULL, 2, '/merchant/finance/withdraw',    NULL, 'AuditOutlined',      6, 1, 1, 1, 0),

-- ── 商户设置子菜单（parent=1019）────────────────────────────
(1111, 1019, '基本资料',   NULL, 2, '/merchant/profile',               NULL, 'UserOutlined',      1, 1, 1, 1, 0),
(1112, 1019, '结算币种',   NULL, 2, '/merchant/settings/currency',     NULL, 'GlobalOutlined',    2, 1, 1, 1, 0);

-- ── Step 7: 为 SUPER_ADMIN 角色分配所有新增操作权限
INSERT IGNORE INTO sys_role_permission (role_id, permission_id)
SELECT r.id, p.id
FROM sys_role r
JOIN sys_permission p ON p.id BETWEEN 1100 AND 1130 AND p.deleted = 0
WHERE r.role_code = 'SUPER_ADMIN'
  AND NOT EXISTS (
    SELECT 1 FROM sys_role_permission rp
    WHERE rp.role_id = r.id AND rp.permission_id = p.id
  );

-- ─────────────────────────────────────────────────────────────
-- PART 2: 商户测试数据
-- ─────────────────────────────────────────────────────────────

-- 取第一个商户 ID 备用
SET @merchant_id = (SELECT id FROM cb_merchant WHERE deleted = 0 ORDER BY id LIMIT 1);

-- ── 会员测试数据 ───────────────────────────────────────────────
-- member_no 唯一，mobile 唯一；字段按实际 schema 对齐
INSERT IGNORE INTO cb_member
    (id, member_no, mobile, nickname, avatar, gender, balance,
     total_recharge, total_spend, order_count, level, points,
     status, deleted, register_time, create_time, update_time)
VALUES
(10001,'CB202603170001','+8613800001001','张伟', 'https://api.dicebear.com/7.x/avataaars/svg?seed=10001',1, 580.00,1000.00, 420.00,5,1,520,1,0,NOW()-INTERVAL 90 DAY,NOW()-INTERVAL 90 DAY,NOW()),
(10002,'CB202603180001','+8613800001002','李娜', 'https://api.dicebear.com/7.x/avataaars/svg?seed=10002',2,1200.00,2000.00, 800.00,8,2,800,1,0,NOW()-INTERVAL 75 DAY,NOW()-INTERVAL 75 DAY,NOW()),
(10003,'CB202603190001','+8613800001003','王芳', 'https://api.dicebear.com/7.x/avataaars/svg?seed=10003',2, 350.00, 500.00, 150.00,2,0,150,1,0,NOW()-INTERVAL 60 DAY,NOW()-INTERVAL 60 DAY,NOW()),
(10004,'CB202603200001','+8613800001004','赵强', 'https://api.dicebear.com/7.x/avataaars/svg?seed=10004',1,   0.00, 800.00, 800.00,6,1,800,1,0,NOW()-INTERVAL 50 DAY,NOW()-INTERVAL 50 DAY,NOW()),
(10005,'CB202603210001','+8613800001005','陈洁', 'https://api.dicebear.com/7.x/avataaars/svg?seed=10005',2,2500.00,3000.00, 500.00,4,3,500,1,0,NOW()-INTERVAL 40 DAY,NOW()-INTERVAL 40 DAY,NOW()),
(10006,'CB202603220001','+8613800001006','刘磊', 'https://api.dicebear.com/7.x/avataaars/svg?seed=10006',1, 100.00, 600.00, 500.00,3,1,500,1,0,NOW()-INTERVAL 35 DAY,NOW()-INTERVAL 35 DAY,NOW()),
(10007,'CB202603230001','+8613800001007','周梅', 'https://api.dicebear.com/7.x/avataaars/svg?seed=10007',2, 700.00,1200.00, 500.00,3,1,500,1,0,NOW()-INTERVAL 28 DAY,NOW()-INTERVAL 28 DAY,NOW()),
(10008,'CB202603240001','+8613800001008','吴昊', 'https://api.dicebear.com/7.x/avataaars/svg?seed=10008',1,  50.00, 300.00, 250.00,2,0,250,1,0,NOW()-INTERVAL 20 DAY,NOW()-INTERVAL 20 DAY,NOW()),
(10009,'CB202603250001','+8613800001009','郑丽', 'https://api.dicebear.com/7.x/avataaars/svg?seed=10009',2,   0.00, 100.00, 100.00,1,0,100,2,0,NOW()-INTERVAL 15 DAY,NOW()-INTERVAL 15 DAY,NOW()),
(10010,'CB202603260001','+8613800001010','孙博', 'https://api.dicebear.com/7.x/avataaars/svg?seed=10010',1,3200.00,4000.00, 800.00,5,3,800,1,0,NOW()-INTERVAL 10 DAY,NOW()-INTERVAL 10 DAY,NOW());

-- ── 技师测试数据（补全现有技师的 merchant_id）────────────────
UPDATE cb_technician SET merchant_id = @merchant_id
WHERE (merchant_id IS NULL OR merchant_id = 0) AND deleted = 0;

-- 新增测试技师（tech_no/mobile 必须唯一）
INSERT IGNORE INTO cb_technician
    (id, tech_no, merchant_id, mobile, real_name, nickname, avatar,
     gender, rating, order_count, audit_status, online_status,
     commission_rate, settlement_mode, commission_type,
     intro_zh, deleted, create_time, update_time)
VALUES
(2001,'T20260101001',@merchant_id,'+8613900002001','李小美','小美',
 'https://api.dicebear.com/7.x/avataaars/svg?seed=t2001',
 2, 4.90, 312, 1, 1, 60.00, 3, 0,
 '专业推拿技师，5年经验，擅长全身放松按摩', 0, NOW()-INTERVAL 180 DAY, NOW()),

(2002,'T20260101002',@merchant_id,'+8613900002002','陈小雨','小雨',
 'https://api.dicebear.com/7.x/avataaars/svg?seed=t2002',
 2, 4.80, 256, 1, 1, 60.00, 3, 0,
 '泰式按摩专家，精通传统泰式手法', 0, NOW()-INTERVAL 150 DAY, NOW()),

(2003,'T20260101003',@merchant_id,'+8613900002003','王小阳','小阳',
 'https://api.dicebear.com/7.x/avataaars/svg?seed=t2003',
 1, 4.70, 198, 1, 0, 55.00, 2, 0,
 '中医推拿专业，擅长颈肩腰腿痛调理', 0, NOW()-INTERVAL 120 DAY, NOW()),

(2004,'T20260101004',@merchant_id,'+8613900002004','赵小珊','小珊',
 'https://api.dicebear.com/7.x/avataaars/svg?seed=t2004',
 2, 4.60, 145, 1, 0, 60.00, 3, 0,
 '面部护理与美容养生专家，手法细腻', 0, NOW()-INTERVAL 90 DAY, NOW()),

(2005,'T20260101005',@merchant_id,'+8613900002005','孙小龙','小龙',
 'https://api.dicebear.com/7.x/avataaars/svg?seed=t2005',
 1, 4.95, 421, 1, 2, 70.00, 1, 1,
 '足部反射理疗专家，擅长经络调理，日结提成制度', 0, NOW()-INTERVAL 365 DAY, NOW());

-- ── 服务大类测试数据 ──────────────────────────────────────────
INSERT IGNORE INTO cb_service_category
    (id, parent_id, name_zh, name_en, icon, sort, status, deleted, create_time, update_time)
VALUES
(3001, 0, '按摩养生', 'Massage & Wellness', '', 1, 1, 0, NOW(), NOW()),
(3002, 0, '足浴足疗', 'Foot Spa',           '', 2, 1, 0, NOW(), NOW()),
(3003, 0, '面部护理', 'Facial Care',         '', 3, 1, 0, NOW(), NOW()),
(3004, 0, '芳香SPA',  'Aroma SPA',           '', 4, 1, 0, NOW(), NOW());

-- ── 服务项目测试数据 ──────────────────────────────────────────
INSERT IGNORE INTO cb_service_item
    (id, category_id, name_zh, name_en, desc_zh, base_price, duration, sort, status, deleted, create_time, update_time)
VALUES
(4001, 3001, '全身经络疏通', 'Full Body Meridian',     '全身经络梳理，促进血液循环，释放身体疲劳', 298.00, 90, 1, 1, 0, NOW(), NOW()),
(4002, 3001, '肩颈舒缓按摩', 'Neck & Shoulder Relief', '专注肩颈部位，缓解颈椎压力',               168.00, 60, 2, 1, 0, NOW(), NOW()),
(4003, 3001, '泰式传统按摩', 'Thai Traditional',       '正宗泰式手法，拉伸筋骨，舒经活络',           258.00, 90, 3, 1, 0, NOW(), NOW()),
(4004, 3002, '精油足底按摩', 'Foot Reflex Oil',        '精选植物精油配合穴位按摩',                  128.00, 60, 1, 1, 0, NOW(), NOW()),
(4005, 3002, '泡脚足疗套餐', 'Foot Bath Package',      '中药泡脚+专业足疗，去湿气排寒毒',            198.00, 90, 2, 1, 0, NOW(), NOW()),
(4006, 3003, '深层清洁护肤', 'Deep Cleansing Facial',  '深层清洁毛孔，补水保湿，提亮肤色',           188.00, 75, 1, 1, 0, NOW(), NOW()),
(4007, 3004, '薰衣草全身SPA','Lavender Full SPA',      '薰衣草精油全身包裹护理，深度放松解压',        388.00,120, 1, 1, 0, NOW(), NOW()),
(4008, 3004, '玫瑰浴盐去角质','Rose Salt Scrub',        '玫瑰浴盐全身去角质+保湿精华涂抹',            268.00, 90, 2, 1, 0, NOW(), NOW());

-- ── 历史订单测试数据（字段按实际 cb_order schema 对齐）────────
-- 注：address_id/address_detail/appoint_time/service_name/service_duration 均为必填
INSERT IGNORE INTO cb_order
    (id, order_no, merchant_id, member_id, technician_id, service_item_id,
     service_name, service_duration,
     address_id, address_detail,
     appoint_time, start_time, end_time,
     original_amount, pay_amount,
     pay_type, pay_time, status,
     remark, deleted, create_time, update_time)
VALUES
-- ─ 近30天完成订单 ─
(5001,'OD20260317153001',@merchant_id,10001,2001,4001,'全身经络疏通',90,0,'店内服务',NOW()-INTERVAL 30 DAY+INTERVAL 2 HOUR,NOW()-INTERVAL 30 DAY+INTERVAL 3 HOUR,NOW()-INTERVAL 30 DAY+INTERVAL 4 HOUR+INTERVAL 30 MINUTE,298.00,298.00,4,NOW()-INTERVAL 30 DAY+INTERVAL 2 HOUR,6,'',0,NOW()-INTERVAL 30 DAY,NOW()),
(5002,'OD20260318153002',@merchant_id,10002,2002,4003,'泰式传统按摩',90,0,'店内服务',NOW()-INTERVAL 29 DAY+INTERVAL 2 HOUR,NOW()-INTERVAL 29 DAY+INTERVAL 3 HOUR,NOW()-INTERVAL 29 DAY+INTERVAL 4 HOUR+INTERVAL 30 MINUTE,258.00,258.00,3,NOW()-INTERVAL 29 DAY+INTERVAL 2 HOUR,6,'',0,NOW()-INTERVAL 29 DAY,NOW()),
(5003,'OD20260319153003',@merchant_id,10003,2003,4002,'肩颈舒缓按摩',60,0,'店内服务',NOW()-INTERVAL 28 DAY+INTERVAL 2 HOUR,NOW()-INTERVAL 28 DAY+INTERVAL 3 HOUR,NOW()-INTERVAL 28 DAY+INTERVAL 4 HOUR,168.00,168.00,4,NOW()-INTERVAL 28 DAY+INTERVAL 2 HOUR,6,'',0,NOW()-INTERVAL 28 DAY,NOW()),
(5004,'OD20260320153004',@merchant_id,10004,2005,4004,'精油足底按摩',60,0,'店内服务',NOW()-INTERVAL 27 DAY+INTERVAL 2 HOUR,NOW()-INTERVAL 27 DAY+INTERVAL 3 HOUR,NOW()-INTERVAL 27 DAY+INTERVAL 4 HOUR,128.00,128.00,4,NOW()-INTERVAL 27 DAY+INTERVAL 2 HOUR,6,'',0,NOW()-INTERVAL 27 DAY,NOW()),
(5005,'OD20260321153005',@merchant_id,10005,2001,4007,'薰衣草全身SPA',120,0,'店内服务',NOW()-INTERVAL 26 DAY+INTERVAL 2 HOUR,NOW()-INTERVAL 26 DAY+INTERVAL 3 HOUR,NOW()-INTERVAL 26 DAY+INTERVAL 5 HOUR,388.00,388.00,2,NOW()-INTERVAL 26 DAY+INTERVAL 2 HOUR,6,'',0,NOW()-INTERVAL 26 DAY,NOW()),
(5006,'OD20260322153006',@merchant_id,10006,2004,4006,'深层清洁护肤',75,0,'店内服务',NOW()-INTERVAL 25 DAY+INTERVAL 2 HOUR,NOW()-INTERVAL 25 DAY+INTERVAL 3 HOUR,NOW()-INTERVAL 25 DAY+INTERVAL 4 HOUR+INTERVAL 15 MINUTE,188.00,188.00,4,NOW()-INTERVAL 25 DAY+INTERVAL 2 HOUR,6,'',0,NOW()-INTERVAL 25 DAY,NOW()),
(5007,'OD20260323153007',@merchant_id,10007,2002,4005,'泡脚足疗套餐',90,0,'店内服务',NOW()-INTERVAL 24 DAY+INTERVAL 2 HOUR,NOW()-INTERVAL 24 DAY+INTERVAL 3 HOUR,NOW()-INTERVAL 24 DAY+INTERVAL 4 HOUR+INTERVAL 30 MINUTE,198.00,198.00,3,NOW()-INTERVAL 24 DAY+INTERVAL 2 HOUR,6,'',0,NOW()-INTERVAL 24 DAY,NOW()),
(5008,'OD20260324153008',@merchant_id,10008,2003,4008,'玫瑰浴盐去角质',90,0,'店内服务',NOW()-INTERVAL 23 DAY+INTERVAL 2 HOUR,NOW()-INTERVAL 23 DAY+INTERVAL 3 HOUR,NOW()-INTERVAL 23 DAY+INTERVAL 4 HOUR+INTERVAL 30 MINUTE,268.00,268.00,4,NOW()-INTERVAL 23 DAY+INTERVAL 2 HOUR,6,'',0,NOW()-INTERVAL 23 DAY,NOW()),
(5009,'OD20260325153009',@merchant_id,10001,2005,4001,'全身经络疏通',90,0,'店内服务',NOW()-INTERVAL 22 DAY+INTERVAL 2 HOUR,NOW()-INTERVAL 22 DAY+INTERVAL 3 HOUR,NOW()-INTERVAL 22 DAY+INTERVAL 4 HOUR+INTERVAL 30 MINUTE,298.00,298.00,4,NOW()-INTERVAL 22 DAY+INTERVAL 2 HOUR,6,'',0,NOW()-INTERVAL 22 DAY,NOW()),
(5010,'OD20260326153010',@merchant_id,10010,2001,4007,'薰衣草全身SPA',120,0,'店内服务',NOW()-INTERVAL 21 DAY+INTERVAL 2 HOUR,NOW()-INTERVAL 21 DAY+INTERVAL 3 HOUR,NOW()-INTERVAL 21 DAY+INTERVAL 5 HOUR,388.00,388.00,2,NOW()-INTERVAL 21 DAY+INTERVAL 2 HOUR,6,'',0,NOW()-INTERVAL 21 DAY,NOW()),
-- ─ 本周完成订单 ─
(5011,'OD20260410153011',@merchant_id,10002,2002,4003,'泰式传统按摩',90,0,'店内服务',NOW()-INTERVAL 7 DAY+INTERVAL 10 HOUR,NOW()-INTERVAL 7 DAY+INTERVAL 11 HOUR,NOW()-INTERVAL 7 DAY+INTERVAL 12 HOUR+INTERVAL 30 MINUTE,258.00,258.00,4,NOW()-INTERVAL 7 DAY+INTERVAL 10 HOUR,6,'',0,NOW()-INTERVAL 7 DAY,NOW()),
(5012,'OD20260411153012',@merchant_id,10003,2003,4002,'肩颈舒缓按摩',60,0,'店内服务',NOW()-INTERVAL 6 DAY+INTERVAL 10 HOUR,NOW()-INTERVAL 6 DAY+INTERVAL 11 HOUR,NOW()-INTERVAL 6 DAY+INTERVAL 12 HOUR,168.00,168.00,3,NOW()-INTERVAL 6 DAY+INTERVAL 10 HOUR,6,'',0,NOW()-INTERVAL 6 DAY,NOW()),
(5013,'OD20260412153013',@merchant_id,10005,2001,4007,'薰衣草全身SPA',120,0,'店内服务',NOW()-INTERVAL 5 DAY+INTERVAL 10 HOUR,NOW()-INTERVAL 5 DAY+INTERVAL 11 HOUR,NOW()-INTERVAL 5 DAY+INTERVAL 13 HOUR,388.00,388.00,2,NOW()-INTERVAL 5 DAY+INTERVAL 10 HOUR,6,'',0,NOW()-INTERVAL 5 DAY,NOW()),
(5014,'OD20260413153014',@merchant_id,10007,2004,4006,'深层清洁护肤',75,0,'店内服务',NOW()-INTERVAL 4 DAY+INTERVAL 14 HOUR,NOW()-INTERVAL 4 DAY+INTERVAL 15 HOUR,NOW()-INTERVAL 4 DAY+INTERVAL 16 HOUR+INTERVAL 15 MINUTE,188.00,188.00,4,NOW()-INTERVAL 4 DAY+INTERVAL 14 HOUR,6,'',0,NOW()-INTERVAL 4 DAY,NOW()),
(5015,'OD20260414153015',@merchant_id,10009,2005,4004,'精油足底按摩',60,0,'店内服务',NOW()-INTERVAL 3 DAY+INTERVAL 14 HOUR,NULL,NULL,128.00,128.00,NULL,NULL,8,'客户临时取消',0,NOW()-INTERVAL 3 DAY,NOW()),
(5016,'OD20260415153016',@merchant_id,10010,2002,4003,'泰式传统按摩',90,0,'店内服务',NOW()-INTERVAL 2 DAY+INTERVAL 10 HOUR,NOW()-INTERVAL 2 DAY+INTERVAL 11 HOUR,NOW()-INTERVAL 2 DAY+INTERVAL 12 HOUR+INTERVAL 30 MINUTE,258.00,258.00,4,NOW()-INTERVAL 2 DAY+INTERVAL 10 HOUR,6,'',0,NOW()-INTERVAL 2 DAY,NOW()),
(5017,'OD20260416153017',@merchant_id,10006,2001,4001,'全身经络疏通',90,0,'店内服务',NOW()-INTERVAL 1 DAY+INTERVAL 10 HOUR,NOW()-INTERVAL 1 DAY+INTERVAL 11 HOUR,NOW()-INTERVAL 1 DAY+INTERVAL 12 HOUR+INTERVAL 30 MINUTE,298.00,298.00,4,NOW()-INTERVAL 1 DAY+INTERVAL 10 HOUR,6,'',0,NOW()-INTERVAL 1 DAY,NOW()),
-- ─ 今日订单 ─
(5018,'OD20260417153018',@merchant_id,10001,2003,4002,'肩颈舒缓按摩',60,0,'店内服务',NOW()-INTERVAL 2 HOUR,NOW()-INTERVAL 1 HOUR,NULL,168.00,168.00,4,NOW()-INTERVAL 1 HOUR,4,'服务中',0,NOW()-INTERVAL 2 HOUR,NOW()),
(5019,'OD20260417153019',@merchant_id,10004,2005,4005,'泡脚足疗套餐',90,0,'店内服务',NOW()+INTERVAL 30 MINUTE,NULL,NULL,198.00,198.00,NULL,NULL,2,'',0,NOW()-INTERVAL 30 MINUTE,NOW()),
(5020,'OD20260417153020',@merchant_id,10002,2001,4007,'薰衣草全身SPA',120,0,'店内服务',NOW()+INTERVAL 1 HOUR,NULL,NULL,388.00,388.00,NULL,NULL,1,'待接单',0,NOW()-INTERVAL 10 MINUTE,NOW());

-- ── 车辆测试数据（字段按实际 cb_vehicle schema 对齐）────────
INSERT IGNORE INTO cb_vehicle
    (id, plate_number, brand, model, color, seats, status, remark, deleted, create_time, update_time)
VALUES
(6001,'粤A12345','丰田','埃尔法','白色',7,0,'VIP接送专用车',   0,NOW(),NOW()),
(6002,'粤A67890','奔驰','V260', '黑色',6,0,'商务接送车辆',    0,NOW(),NOW()),
(6003,'粤B54321','别克','GL8',  '银色',7,2,'维修中，预计3天后恢复',0,NOW(),NOW());

-- ─────────────────────────────────────────────────────────────
-- PART 3: 币种测试数据（若 sys_currency 存在且为空）
-- ─────────────────────────────────────────────────────────────

INSERT IGNORE INTO sys_currency
    (id, currency_code, currency_name, currency_name_en, symbol, flag, is_crypto, rate_to_usd, decimal_places, sort_order, status, remark, create_time, update_time)
VALUES
(1,  'USD',  '美元',   'US Dollar',       '$',   '🇺🇸', 0, 1.000000,    2, 1,  1, '全球储备货币',     NOW(), NOW()),
(2,  'USDT', '泰达币', 'Tether USD',      '₮',   '💎', 1, 1.000000,    6, 2,  1, '稳定币，与USD 1:1',NOW(), NOW()),
(3,  'CNY',  '人民币', 'Chinese Yuan',    '¥',   '🇨🇳', 0, 0.138000,    2, 3,  1, '中国法币',         NOW(), NOW()),
(4,  'PHP',  '菲律宾比索','Philippine Peso','₱', '🇵🇭', 0, 0.017500,    2, 4,  1, '菲律宾法币',       NOW(), NOW()),
(5,  'THB',  '泰铢',   'Thai Baht',       '฿',   '🇹🇭', 0, 0.027800,    2, 5,  1, '泰国法币',         NOW(), NOW()),
(6,  'KRW',  '韩元',   'Korean Won',      '₩',   '🇰🇷', 0, 0.000730,    0, 6,  1, '韩国法币',         NOW(), NOW()),
(7,  'AED',  '迪拜币', 'UAE Dirham',      'د.إ', '🇦🇪', 0, 0.272200,    2, 7,  1, '阿联酋法币',       NOW(), NOW()),
(8,  'MYR',  '马来西亚令吉','Malaysian Ringgit','RM','🇲🇾',0,0.213000,  2, 8,  1, '马来西亚法币',     NOW(), NOW()),
(9,  'VND',  '越南盾', 'Vietnamese Dong', '₫',   '🇻🇳', 0, 0.000039,    0, 9,  1, '越南法币',         NOW(), NOW()),
(10, 'SGD',  '新加坡元','Singapore Dollar','S$',  '🇸🇬', 0, 0.740000,    2, 10, 1, '新加坡法币',       NOW(), NOW()),
(11, 'EUR',  '欧元',   'Euro',            '€',   '🇪🇺', 0, 1.080000,    2, 11, 1, '欧盟法币',         NOW(), NOW()),
(12, 'GBP',  '英镑',   'British Pound',   '£',   '🇬🇧', 0, 1.270000,    2, 12, 1, '英国法币',         NOW(), NOW()),
(13, 'JPY',  '日元',   'Japanese Yen',    '¥',   '🇯🇵', 0, 0.006500,    0, 13, 1, '日本法币',         NOW(), NOW()),
(14, 'BTC',  '比特币', 'Bitcoin',         '₿',   '🟠', 1, 67000.000000, 8, 14, 1, '数字黄金',         NOW(), NOW()),
(15, 'ETH',  '以太坊', 'Ethereum',        'Ξ',   '⬡',  1, 3500.000000,  8, 15, 1, '智能合约平台币',   NOW(), NOW());

-- ── 为测试商户配置币种 ────────────────────────────────────────
INSERT IGNORE INTO cb_merchant_currency
    (merchant_id, currency_code, is_default, custom_rate, display_name, sort_order, status, create_time, update_time)
VALUES
(@merchant_id, 'CNY',  1, NULL, NULL, 1, 1, NOW(), NOW()),
(@merchant_id, 'USDT', 0, NULL, NULL, 2, 1, NOW(), NOW()),
(@merchant_id, 'USD',  0, NULL, NULL, 3, 1, NOW(), NOW());

-- ─────────────────────────────────────────────────────────────
-- 完成提示
-- ─────────────────────────────────────────────────────────────
SELECT '✅ migrate_v4_3 执行完成：菜单已补全，测试数据已写入' AS result;

-- ── migrate_v4_4.sql ─────────────────────────────────────────────────────────
-- ================================================================================
-- CamBook 数据库迁移脚本 v4.4
-- 描述：散客接待闭环 — 补全 cb_walkin_session 字段 + 写入完整测试数据
-- 日期：2026-04-13
-- ================================================================================
-- ── 2. cb_order 散客接待关联字段 ──────────────────────────────────────────────────
-- ⚠️ migrate_v4_0.sql 已包含 order_type / session_id / wristband_no，
--    若已执行过 v4_0，此段已无需重复执行，保留注释仅作说明。
-- ALTER TABLE `cb_order`
--     ADD COLUMN `order_type`   TINYINT     NOT NULL DEFAULT 1 COMMENT '订单类型：1=在线预约 2=散客上门' AFTER `id`,
--     ADD COLUMN `session_id`   BIGINT                         COMMENT '散客接待 session ID'             AFTER `order_type`,
--     ADD COLUMN `wristband_no` VARCHAR(20)                    COMMENT '手环编号'                         AFTER `session_id`;

-- ── 3. 取测试商户 ID ────────────────────────────────────────────────────────────
SET @merchant_id = (SELECT id FROM cb_merchant WHERE deleted = 0 ORDER BY id LIMIT 1);

-- ── 4. 写入散客接待 Session 测试数据 ────────────────────────────────────────────
-- 场景覆盖：接待中(0)、服务中(1)、待结算(2)、已结算(3)、已取消(4)
DELETE FROM `cb_walkin_session` WHERE id BETWEEN 7001 AND 7010;

INSERT INTO `cb_walkin_session`
    (id, session_no, wristband_no, merchant_id,
     member_id, member_name, member_mobile,
     technician_id, technician_name, technician_no, technician_mobile,
     status, total_amount, paid_amount, remark,
     check_in_time, check_out_time,
     deleted, create_time, update_time)
VALUES
-- ── 接待中（刚登记，尚未开始任何服务）─────────────────────────────────────────
(7001, 'WK20260413001', '0317', @merchant_id,
 NULL, '张先生', '139****6666',
 2001, '李小美', 'T001', '138****1001',
 0, 0.00, 0.00, '',
 NOW() - INTERVAL 15 MINUTE, NULL,
 0, NOW() - INTERVAL 15 MINUTE, NOW()),

-- ── 服务中（已录入2项服务，1项正在进行，1项排队待服务）─────────────────────────
(7002, 'WK20260413002', '0928', @merchant_id,
 10001, '王先生', '138****8888',
 2001, '李小美', 'T001', '138****1001',
 1, 466.00, 0.00, '',
 NOW() - INTERVAL 55 MINUTE, NULL,
 0, NOW() - INTERVAL 55 MINUTE, NOW()),

-- ── 服务中（2项服务，1项完成，1项正在进行）─────────────────────────────────────
(7003, 'WK20260413003', '1024', @merchant_id,
 10002, '李女士', '',
 2002, '陈小雨', 'T002', '138****1002',
 1, 456.00, 0.00, '',
 NOW() - INTERVAL 100 MINUTE, NULL,
 0, NOW() - INTERVAL 100 MINUTE, NOW()),

-- ── 待结算（所有服务已完成，等待前台结算）────────────────────────────────────────
(7004, 'WK20260413004', '0512', @merchant_id,
 NULL, '', '',
 2003, '王小阳', 'T003', '138****1003',
 2, 388.00, 0.00, '',
 NOW() - INTERVAL 150 MINUTE, NULL,
 0, NOW() - INTERVAL 150 MINUTE, NOW()),

-- ── 已结算（今日已完成）────────────────────────────────────────────────────────
(7005, 'WK20260413005', '0781', @merchant_id,
 10003, '王芳', '138****1003',
 2001, '李小美', 'T001', '138****1001',
 3, 298.00, 298.00, '',
 NOW() - INTERVAL 4 HOUR, NOW() - INTERVAL 2 HOUR,
 0, NOW() - INTERVAL 4 HOUR, NOW()),

-- ── 已取消 ──────────────────────────────────────────────────────────────────────
(7006, 'WK20260413006', '0256', @merchant_id,
 NULL, '散客', '',
 NULL, '', '', '',
 4, 0.00, 0.00, '客户临时离开',
 NOW() - INTERVAL 3 HOUR, NOW() - INTERVAL 3 HOUR + INTERVAL 5 MINUTE,
 0, NOW() - INTERVAL 3 HOUR, NOW());

-- ── 5. 写入散客接待关联订单（cb_order，order_type=2） ───────────────────────────
-- 状态说明（cb_order.status）：1=待接单 2=已确认 5=服务中 6=已完成 7=已取消
-- 前端映射：svcStatus: 0=待服务(status 1/2), 1=服务中(status 5), 2=已完成(status 6)
DELETE FROM `cb_order` WHERE id BETWEEN 8001 AND 8020;

INSERT INTO `cb_order`
    (id, order_no, order_type, session_id, wristband_no,
     merchant_id, member_id, technician_id,
     service_item_id, service_name, service_duration,
     address_id, address_detail,
     appoint_time, start_time, end_time,
     original_amount, pay_amount,
     pay_type, pay_time, status, remark,
     deleted, create_time, update_time)
VALUES
-- ── Session 7002（手环 0928，服务中）──────────────────────────────────────────
-- 服务1：全身经络疏通 90min — 服务中（进行了42min）
(8001, 'WK20260413001-01', 2, 7002, '0928',
 @merchant_id, 10001, 2001,
 4001, '全身经络疏通', 90,
 0, '店内服务',
 NOW() - INTERVAL 55 MINUTE,
 NOW() - INTERVAL 42 MINUTE,
 NULL,
 298.00, 298.00,
 NULL, NULL, 5, '',
 0, NOW() - INTERVAL 55 MINUTE, NOW()),

-- 服务2：肩颈舒缓按摩 60min — 待服务（排队等候）
(8002, 'WK20260413001-02', 2, 7002, '0928',
 @merchant_id, 10001, 2001,
 4002, '肩颈舒缓按摩', 60,
 0, '店内服务',
 NOW() - INTERVAL 55 MINUTE,
 NULL,
 NULL,
 168.00, 168.00,
 NULL, NULL, 2, '',
 0, NOW() - INTERVAL 55 MINUTE, NOW()),

-- ── Session 7003（手环 1024，多项服务，1完成1服务中）─────────────────────────
-- 服务1：足底精油按摩 60min — 已完成（75min前开始，60min后结束）
(8003, 'WK20260413002-01', 2, 7003, '1024',
 @merchant_id, 10002, 2002,
 4004, '精油足底按摩', 60,
 0, '店内服务',
 NOW() - INTERVAL 100 MINUTE,
 NOW() - INTERVAL 95 MINUTE,
 NOW() - INTERVAL 35 MINUTE,
 128.00, 128.00,
 NULL, NULL, 6, '',
 0, NOW() - INTERVAL 100 MINUTE, NOW()),

-- 服务2：SPA 护理套餐 90min — 服务中（10min前开始）
(8004, 'WK20260413002-02', 2, 7003, '1024',
 @merchant_id, 10002, 2002,
 4007, '薰衣草全身SPA', 120,
 0, '店内服务',
 NOW() - INTERVAL 100 MINUTE,
 NOW() - INTERVAL 10 MINUTE,
 NULL,
 388.00, 388.00,
 NULL, NULL, 5, '',
 0, NOW() - INTERVAL 100 MINUTE, NOW()),

-- ── Session 7004（手环 0512，待结算，全部完成）────────────────────────────────
(8005, 'WK20260413003-01', 2, 7004, '0512',
 @merchant_id, 0, 2003,
 4007, '薰衣草全身SPA', 120,
 0, '店内服务',
 NOW() - INTERVAL 150 MINUTE,
 NOW() - INTERVAL 140 MINUTE,
 NOW() - INTERVAL 20 MINUTE,
 388.00, 388.00,
 NULL, NULL, 6, '',
 0, NOW() - INTERVAL 150 MINUTE, NOW()),

-- ── Session 7005（手环 0781，已结算）─────────────────────────────────────────
(8006, 'WK20260413004-01', 2, 7005, '0781',
 @merchant_id, 10003, 2001,
 4001, '全身经络疏通', 90,
 0, '店内服务',
 NOW() - INTERVAL 4 HOUR,
 NOW() - INTERVAL 3 HOUR - INTERVAL 50 MINUTE,
 NOW() - INTERVAL 2 HOUR - INTERVAL 20 MINUTE,
 298.00, 298.00,
 4, NOW() - INTERVAL 2 HOUR, 6, '',
 0, NOW() - INTERVAL 4 HOUR, NOW());

-- ── 6. 更新 session 的 total_amount（从关联订单汇总）───────────────────────────
UPDATE `cb_walkin_session` s
SET s.total_amount = (
    SELECT COALESCE(SUM(o.pay_amount), 0)
    FROM `cb_order` o
    WHERE o.session_id = s.id AND o.deleted = 0 AND o.status != 7
)
WHERE s.id BETWEEN 7001 AND 7010;

SELECT '✅ migrate_v4_4 执行完成：散客接待闭环测试数据已写入' AS result;

-- ── 7. 修复：恢复车辆管理目录及相关菜单的图标（排序操作后可能被清空）────────────
-- id=1032: 车辆管理（目录）
UPDATE `sys_permission` SET `icon` = 'CarOutlined'       WHERE `id` = 1032 AND `portal_type` = 1;
-- id=1103: 车辆列表（菜单）
UPDATE `sys_permission` SET `icon` = 'CarOutlined'       WHERE `id` = 1103 AND `portal_type` = 1;
-- id=1104: 派车记录（菜单）
UPDATE `sys_permission` SET `icon` = 'FileTextOutlined'  WHERE `id` = 1104 AND `portal_type` = 1;

-- 顺便修复其他可能漏掉图标的菜单
UPDATE `sys_permission` SET `icon` = 'IdcardOutlined'       WHERE `id` = 1102 AND `portal_type` = 1 AND (`icon` IS NULL OR `icon` = '');
UPDATE `sys_permission` SET `icon` = 'BarChartOutlined'     WHERE `id` = 1105 AND `portal_type` = 1 AND (`icon` IS NULL OR `icon` = '');
UPDATE `sys_permission` SET `icon` = 'DollarOutlined'       WHERE `id` = 1106 AND `portal_type` = 1 AND (`icon` IS NULL OR `icon` = '');
UPDATE `sys_permission` SET `icon` = 'MinusCircleOutlined'  WHERE `id` = 1107 AND `portal_type` = 1 AND (`icon` IS NULL OR `icon` = '');
UPDATE `sys_permission` SET `icon` = 'TeamOutlined'         WHERE `id` = 1108 AND `portal_type` = 1 AND (`icon` IS NULL OR `icon` = '');
UPDATE `sys_permission` SET `icon` = 'BankOutlined'         WHERE `id` = 1109 AND `portal_type` = 1 AND (`icon` IS NULL OR `icon` = '');

SELECT '✅ 图标修复完成' AS result;

-- ── 8. 菜单重命名：散客接待 → 门店订单 ────────────────────────────────────────
UPDATE `sys_permission` SET `name` = '门店订单' WHERE `id` = 1102 AND `portal_type` = 1;

SELECT '✅ 菜单重命名完成：散客接待 → 门店订单' AS result;

-- ── 9. 技师服务类目字段 ────────────────────────────────────────────────────────
-- 存储技师可提供的服务类目 ID 列表（JSON 数组，如 [1,2,3]），对应 cb_service_category.id
ALTER TABLE `cb_technician`
    ADD COLUMN `service_item_ids` VARCHAR(1000) NULL COMMENT '可提供服务类目ID列表(JSON)' AFTER `skill_tags`;

SELECT '✅ cb_technician.service_item_ids 字段添加完成' AS result;

-- ── 10. 服务类目扩展字段：价格 / 时长 / 是否特殊项目 ────────────────────────────
-- price      : 服务基础指导价（常规项系统统一配置，特殊项可由技师覆盖）
-- duration   : 服务标准时长（分钟）
-- is_special : 0=常规项目（价格统一）  1=特殊项目（技师可自行定价）
ALTER TABLE `cb_service_category`
    ADD COLUMN `price`      DECIMAL(10,2) NULL    COMMENT '服务基础指导价'        AFTER `icon`,
    ADD COLUMN `duration`   INT           NULL    COMMENT '标准服务时长（分钟）'   AFTER `price`,
    ADD COLUMN `is_special` TINYINT(1)    NOT NULL DEFAULT 0 COMMENT '是否特殊项目(0=常规,1=特殊)' AFTER `duration`;

SELECT '✅ cb_service_category 扩展字段添加完成' AS result;

-- ── 11. 技师服务专属定价表 ──────────────────────────────────────────────────────
-- 特殊项目支持技师自行定价；普通项目沿用 cb_service_category.price
CREATE TABLE IF NOT EXISTS `cb_technician_service_price` (
    `id`              BIGINT       NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `merchant_id`     BIGINT       NOT NULL COMMENT '商户ID',
    `technician_id`   BIGINT       NOT NULL COMMENT '技师ID',
    `service_item_id` BIGINT       NOT NULL COMMENT '服务类目ID (cb_service_category.id)',
    `price`           DECIMAL(10,2) NOT NULL COMMENT '技师专属价格',
    `create_time`     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `update_time`     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY `uniq_tech_svc` (`technician_id`, `service_item_id`),
    KEY `idx_merchant_id` (`merchant_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='技师服务专属定价表';

SELECT '✅ cb_technician_service_price 表创建完成' AS result;

-- ── migrate_v4_5.sql ─────────────────────────────────────────────────────────
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

-- ── migrate_v4_6_dict_seed.sql ─────────────────────────────────────────────────────────
-- ══════════════════════════════════════════════════════════════════════════════
-- Migration v4.6 — 数据字典全量初始化
--
-- 覆盖系统全部可配置枚举字段，写入 sys_dict_type + sys_dict
-- 幂等设计：INSERT IGNORE，可安全重复执行（已存在的行自动跳过）
--
-- ┌─────────────────────────────────────────────────────────────────────────┐
-- │  字典类型速查                                                           │
-- ├────────────────────────────┬────────────────────────────────────────────┤
-- │ 系统/通用                  │                                            │
-- │   common_status            │ 通用启用/停用                              │
-- │   gender                   │ 性别                                       │
-- │   user_type                │ 用户身份类型                               │
-- │   login_type               │ 登录方式                                   │
-- │   menu_type                │ 菜单节点类型                               │
-- │   portal_type              │ 所属门户                                   │
-- │   notice_type              │ 推送通知类型                               │
-- │   announce_status          │ 公告状态                                   │
-- │   announce_target          │ 公告发送对象                               │
-- │   msg_type                 │ 即时消息类型                               │
-- │   sender_type              │ 消息发送方类型                             │
-- │   client_type              │ 客户端类型                                 │
-- │   banner_link_type         │ Banner 跳转类型                            │
-- │   tag_type                 │ 标签类型                                   │
-- ├────────────────────────────┬────────────────────────────────────────────┤
-- │ 地理/语言                  │                                            │
-- │   service_city             │ 服务城市（柬埔寨）                         │
-- │   nationality              │ 国籍                                       │
-- │   language                 │ 常用语言                                   │
-- ├────────────────────────────┬────────────────────────────────────────────┤
-- │ 会员                       │                                            │
-- │   member_status            │ 会员账号状态                               │
-- │   member_level             │ 会员等级                                   │
-- │   register_source          │ 注册来源                                   │
-- ├────────────────────────────┬────────────────────────────────────────────┤
-- │ 技师                       │                                            │
-- │   technician_status        │ 技师账号状态                               │
-- │   technician_audit         │ 入驻审核状态（技师&商户共用）              │
-- │   technician_online        │ 技师在线状态                               │
-- │   bust_size                │ 罩杯尺码                                   │
-- │   settlement_mode          │ 技师结算方式                               │
-- │   commission_type          │ 技师提成类型                               │
-- ├────────────────────────────┬────────────────────────────────────────────┤
-- │ 商户                       │                                            │
-- │   merchant_status          │ 商户账号状态                               │
-- │   merchant_business_type   │ 商户业务类型                               │
-- │   dept_category            │ 部门类别                                   │
-- │   job_grade                │ 职级等级                                   │
-- │   staff_status             │ 员工/司机状态                              │
-- ├────────────────────────────┬────────────────────────────────────────────┤
-- │ 服务/订单                  │                                            │
-- │   service_type             │ 服务项目类型（常规/特殊）                  │
-- │   order_status             │ 订单状态（在线预约）                       │
-- │   walkin_status            │ 门店散客会话状态                           │
-- │   walkin_pay_type          │ 门店收银支付方式                           │
-- ├────────────────────────────┬────────────────────────────────────────────┤
-- │ 支付/财务                  │                                            │
-- │   pay_type                 │ 在线支付方式                               │
-- │   pay_status               │ 支付状态                                   │
-- │   currency                 │ 结算货币                                   │
-- │   coupon_type              │ 优惠券类型                                 │
-- │   coupon_use_status        │ 优惠券使用状态                             │
-- │   wallet_status            │ 钱包状态                                   │
-- │   wallet_flow_type         │ 钱包流水类型                               │
-- │   settlement_status        │ 结算单状态                                 │
-- │   salary_status            │ 薪资发放状态                               │
-- │   staff_type               │ 薪资员工类型                               │
-- │   expense_category         │ 支出类别                                   │
-- ├────────────────────────────┬────────────────────────────────────────────┤
-- │ 车辆                       │                                            │
-- │   vehicle_status           │ 车辆状态                                   │
-- │   vehicle_brand            │ 车辆品牌                                   │
-- │   vehicle_color            │ 车辆颜色                                   │
-- │   vehicle_purpose          │ 出行目的                                   │
-- │   dispatch_status          │ 派车单状态                                 │
-- └────────────────────────────┴────────────────────────────────────────────┘
-- ══════════════════════════════════════════════════════════════════════════════

-- ── 0. 幂等添加 sys_dict.remark 列（存储 Tag 颜色 / 品牌色 / 国旗 emoji）──────
DROP PROCEDURE IF EXISTS _add_dict_remark;
DELIMITER $$
CREATE PROCEDURE _add_dict_remark()
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME   = 'sys_dict'
          AND COLUMN_NAME  = 'remark'
    ) THEN
        ALTER TABLE `sys_dict`
            ADD COLUMN `remark` VARCHAR(200) NULL COMMENT '附加信息：Ant Design Tag color / 品牌色 hex / 国旗 emoji 等' AFTER `status`;
        SELECT '✅ sys_dict.remark 字段已添加' AS msg;
    ELSE
        SELECT '⏭️  sys_dict.remark 已存在，跳过' AS msg;
    END IF;
END$$
DELIMITER ;
CALL _add_dict_remark();
DROP PROCEDURE IF EXISTS _add_dict_remark;

-- ── 一、字典类型表 ────────────────────────────────────────────────────────────
INSERT IGNORE INTO `sys_dict_type` (`dict_type`, `dict_name`, `status`, `remark`) VALUES
-- 系统/通用
('common_status',          '通用状态',           1, '通用启用/停用，适用于大多数实体的 status 字段'),
('gender',                 '性别',               1, 'cb_member.gender / cb_technician.gender'),
('user_type',              '用户身份类型',        1, 'cb_wallet.user_type / cb_wallet_flow.owner_type'),
('login_type',             '登录方式',            1, 'cb_login_log.login_type'),
('menu_type',              '菜单节点类型',        1, 'sys_menu.type：目录/菜单/按钮'),
('portal_type',            '所属门户',            1, 'sys_menu.portal_type：管理端/商户端'),
('notice_type',            '推送通知类型',        1, 'cb_notice.type'),
('announce_status',        '公告状态',            1, 'cb_announce.status'),
('announce_target',        '公告发送对象',        1, 'cb_announce.target'),
('msg_type',               '即时消息类型',        1, 'cb_chat_message.msg_type'),
('sender_type',            '消息发送方类型',      1, 'cb_chat_message.sender_type'),
('client_type',            '客户端类型',          1, 'cb_notice.client_type，推送目标客户端'),
('banner_link_type',       'Banner 跳转类型',     1, 'cb_banner.link_type'),
('tag_type',               '标签类型',            1, 'cb_tag.tag_type：技师/服务/商户'),
-- 地理/语言
('service_city',           '服务城市',            1, '技师/商户服务城市（柬埔寨城市）'),
('nationality',            '国籍',                1, '技师/会员国籍，含国旗 emoji 存 remark'),
('language',               '常用语言',            1, '技师/会员常用语言'),
-- 会员
('member_status',          '会员账号状态',        1, 'cb_member.status'),
('member_level',           '会员等级',            1, 'cb_member.level'),
('register_source',        '注册来源',            1, 'cb_member.register_source'),
-- 技师
('technician_status',      '技师账号状态',        1, 'cb_technician.status'),
('technician_audit',       '入驻审核状态',        1, '技师与商户共用，audit_status'),
('technician_online',      '技师在线状态',        1, 'cb_technician.online_status'),
('bust_size',              '罩杯尺码',            1, '技师罩杯尺码，A~G'),
('settlement_mode',        '技师结算方式',        1, 'cb_technician.settlement_mode'),
('commission_type',        '技师提成类型',        1, 'cb_technician.commission_type'),
-- 商户
('merchant_status',        '商户账号状态',        1, 'cb_merchant.status'),
('merchant_business_type', '商户业务类型',        1, 'cb_merchant.business_type'),
('dept_category',          '部门类别',            1, '组织架构部门分类'),
('job_grade',              '职级等级',            1, '员工职级，P序列技术/M序列管理'),
('staff_status',           '员工/司机状态',       1, 'cb_staff.status'),
-- 服务/订单
('service_type',           '服务项目类型',        1, 'cb_service_category.is_special：0常规 1特殊'),
('order_status',           '订单状态',            1, 'cb_order.status，完整预约订单生命周期'),
('walkin_status',          '门店散客会话状态',    1, 'cb_walkin_session.status，散客上门服务状态'),
('walkin_pay_type',        '门店收银支付方式',    1, '散客上门收款方式，含现金/转账/扫码等'),
-- 支付/财务
('pay_type',               '在线支付方式',        1, 'cb_order.pay_type / cb_payment.pay_type'),
('pay_status',             '支付状态',            1, 'cb_payment.status'),
('currency',               '结算货币',            1, '支付/结算使用的货币，含汇率参考'),
('coupon_type',            '优惠券类型',          1, 'cb_coupon.type'),
('coupon_use_status',      '优惠券使用状态',      1, 'cb_member_coupon.status'),
('wallet_status',          '钱包状态',            1, 'cb_wallet.status'),
('wallet_flow_type',       '钱包流水类型',        1, 'cb_wallet_flow.type'),
('settlement_status',      '结算单状态',          1, '技师结算单审核/打款状态'),
('salary_status',          '薪资发放状态',        1, '员工薪资单状态'),
('staff_type',             '薪资员工类型',        1, '薪资管理中的员工类型分类'),
('expense_category',       '支出类别',            1, '门店运营支出分类'),
-- 车辆
('vehicle_status',         '车辆状态',            1, 'cb_vehicle.status'),
('vehicle_brand',          '车辆品牌',            1, '车辆品牌列表，remark 存品牌标志色'),
('vehicle_color',          '车辆颜色',            1, '车辆常见颜色，remark 存 hex 色值'),
('vehicle_purpose',        '出行目的',            1, '派车单出行目的分类'),
('dispatch_status',        '派车单状态',          1, 'cb_vehicle_dispatch.status'),
('vehicle_dispatch_purpose','内部派车用途',        1, 'VehicleDispatch 页面用途分类，remark JSON {c:颜色,i:emoji}'),
('vehicle_dispatch_status', '内部车辆调度状态',   1, 'VehicleDispatch 页面使用状态，remark JSON {c:颜色,b:badge}'),
('walkin_session_status',   '门店会话状态',        1, 'WalkinSessionPage SESSION_STATUS，remark JSON {c:颜色,b:badge}'),
('walkin_svc_status',       '服务项目进度',        1, 'WalkinSessionPage 服务行项目状态，remark JSON {c:颜色,i:emoji}'),
('income_type',             '收入类型',            1, '门店收入来源类型，IncomeRecordPage INCOME_TYPES');


-- ── 二、字典数据项 ────────────────────────────────────────────────────────────
-- 格式：(dict_type, dict_value, label_zh, label_en, label_vi, label_km, label_ja, label_ko, sort, status, remark)

INSERT IGNORE INTO `sys_dict` (`dict_type`, `dict_value`, `label_zh`, `label_en`, `label_vi`, `label_km`, `label_ja`, `label_ko`, `sort`, `status`, `remark`) VALUES

-- ── 通用状态 ─────────────────────────────────────────────────────────────────
('common_status', '1', '启用',  'Enabled',  'Đang hoạt động', 'ដំណើរការ', '有効', '활성',   1, 1, 'green'),
('common_status', '0', '停用',  'Disabled', 'Tạm dừng',       'បិទ',      '無効', '비활성', 2, 1, 'default'),

-- ── 性别 ─────────────────────────────────────────────────────────────────────
('gender', '0', '未知', 'Unknown', 'Không rõ', 'មិនដឹង', '不明', '미상', 1, 1, 'default'),
('gender', '1', '男',   'Male',    'Nam',      'ប្រុស',   '男性', '남성', 2, 1, 'blue'),
('gender', '2', '女',   'Female',  'Nữ',       'ស្រី',    '女性', '여성', 3, 1, 'pink'),

-- ── 用户身份类型 ──────────────────────────────────────────────────────────────
('user_type', '1', '会员',   'Member',     'Thành viên',      'សមាជិក',          '会員',   '회원',   1, 1, 'cyan'),
('user_type', '2', '技师',   'Technician', 'Kỹ thuật viên',   'អ្នកបច្ចេកទេស',   '技師',   '기술자', 2, 1, 'purple'),
('user_type', '3', '商户',   'Merchant',   'Thương gia',       'ពាណិជ្ជករ',      '商店',   '가맹점', 3, 1, 'orange'),

-- ── 登录方式 ─────────────────────────────────────────────────────────────────
('login_type', '1', '短信验证码', 'SMS Code', 'Mã SMS',    'លេខកូដ SMS',   'SMSコード', 'SMS 코드', 1, 1, NULL),
('login_type', '2', '账号密码',   'Password', 'Mật khẩu', 'ពាក្យសម្ងាត់', 'パスワード', '비밀번호',  2, 1, NULL),

-- ── 菜单节点类型 ──────────────────────────────────────────────────────────────
('menu_type', '1', '目录', 'Directory', 'Thư mục',     'ថតឯកសារ', 'ディレクトリ', '디렉토리', 1, 1, NULL),
('menu_type', '2', '菜单', 'Menu',      'Menu',        'ម៉ឺនុយ',   'メニュー',    '메뉴',     2, 1, NULL),
('menu_type', '3', '按钮', 'Button',    'Nút thao tác','ប៊ូតុង',   'ボタン',      '버튼',     3, 1, NULL),

-- ── 所属门户 ─────────────────────────────────────────────────────────────────
('portal_type', '0', '管理端', 'Admin',    'Quản trị',  'ទំព័រគ្រប់គ្រង', '管理ポータル', '관리자', 1, 1, NULL),
('portal_type', '1', '商户端', 'Merchant', 'Thương gia','ពាណិជ្ជករ',       '商店ポータル', '가맹점', 2, 1, NULL),

-- ── 推送通知类型 ──────────────────────────────────────────────────────────────
('notice_type', '1', '系统公告', 'System',    'Thông báo hệ thống', 'ការជូនដំណឹង', 'システム通知',  '시스템',   1, 1, 'blue'),
('notice_type', '2', '订单通知', 'Order',     'Thông báo đơn hàng', 'ការជូនដំណឹងការបញ្ជាទិញ', '注文通知', '주문',    2, 1, 'green'),
('notice_type', '3', '活动营销', 'Promotion', 'Khuyến mãi',         'ការផ្សព្វផ្សាយ', 'プロモーション', '프로모션', 3, 1, 'orange'),

-- ── 公告状态 ─────────────────────────────────────────────────────────────────
('announce_status', '0', '草稿',   'Draft',     'Nháp',          'សំណាង',      '下書き', '초안',     1, 1, 'default'),
('announce_status', '1', '已发布', 'Published', 'Đã xuất bản',   'បានផ្សព្វផ្សាយ','公開済み', '게시됨', 2, 1, 'green'),
('announce_status', '2', '已撤回', 'Recalled',  'Đã thu hồi',    'បានដកវិញ',    '撤回済み', '회수됨', 3, 1, 'red'),

-- ── 公告发送对象 ──────────────────────────────────────────────────────────────
('announce_target', '0', '全部成员', 'All',        'Tất cả',       'ទាំងអស់',          '全員',   '전체',     1, 1, NULL),
('announce_target', '1', '本部门',   'Department', 'Phòng ban',    'នាយកដ្ឋាន',        '部署',   '부서',     2, 1, NULL),
('announce_target', '2', '指定人员', 'Specific',   'Chỉ định',     'បញ្ជាក់ជាក់លាក់',  '指定',   '지정',     3, 1, NULL),

-- ── 即时消息类型 ──────────────────────────────────────────────────────────────
('msg_type', '1', '文字',     'Text',                'Văn bản', 'អក្សរ',      'テキスト',   '텍스트',   1, 1, NULL),
('msg_type', '2', '图片',     'Image',               'Hình ảnh','រូបភាព',     '画像',       '이미지',   2, 1, NULL),
('msg_type', '3', '系统通知', 'System Notification', 'Hệ thống','ការជូនដំណឹង','システム通知','시스템 알림', 3, 1, NULL),

-- ── 消息发送方类型 ────────────────────────────────────────────────────────────
('sender_type', '1', '会员', 'Member',     'Thành viên',    'សមាជិក',          '会員',   '회원',    1, 1, NULL),
('sender_type', '2', '技师', 'Technician', 'Kỹ thuật viên', 'អ្នកបច្ចេកទេស',   '技師',   '기술자',  2, 1, NULL),
('sender_type', '3', '商户', 'Merchant',   'Thương gia',    'ពាណិជ្ជករ',       '商店',   '가맹점',  3, 1, NULL),
('sender_type', '4', '系统', 'System',     'Hệ thống',      'ប្រព័ន្ធ',        'システム','시스템',  4, 1, NULL),

-- ── 客户端类型 ────────────────────────────────────────────────────────────────
('client_type', '1', '会员 APP',  'Member APP',     'APP Thành viên', 'APP សមាជិក',          '会員APP',  '회원 앱',   1, 1, NULL),
('client_type', '2', '技师 APP',  'Technician APP', 'APP Kỹ thuật',   'APP អ្នកបច្ចេកទេស',  '技師APP',  '기술자 앱', 2, 1, NULL),
('client_type', '3', '商户 APP',  'Merchant APP',   'APP Thương gia', 'APP ពាណិជ្ជករ',      '商店APP',  '가맹점 앱', 3, 1, NULL),
('client_type', '4', 'H5',        'H5',             'H5',             'H5',                  'H5',       'H5',        4, 1, NULL),

-- ── Banner 跳转类型 ───────────────────────────────────────────────────────────
('banner_link_type', '0', '无跳转',   'No Link',       'Không liên kết', 'គ្មានតំណ',          'リンクなし',   '링크 없음', 1, 1, NULL),
('banner_link_type', '1', '内部路由', 'Internal Route','Trang nội bộ',   'ទំព័រខាងក្នុង',     '内部リンク',   '내부 링크', 2, 1, NULL),
('banner_link_type', '2', '外部链接', 'External URL',  'Liên kết ngoài', 'តំណខ្សែខាងក្រៅ',   '外部リンク',   '외부 링크', 3, 1, NULL),

-- ── 标签类型 ─────────────────────────────────────────────────────────────────
('tag_type', '1', '技师标签', 'Technician', 'Nhãn kỹ thuật viên', 'ស្លាក​អ្នក​បច្ចេកទេស', '技師タグ',    '기술자 태그', 1, 1, NULL),
('tag_type', '2', '服务标签', 'Service',    'Nhãn dịch vụ',       'ស្លាក​សេវាកម្ម',       'サービスタグ', '서비스 태그', 2, 1, NULL),
('tag_type', '3', '商户标签', 'Merchant',   'Nhãn thương gia',    'ស្លាក​ពាណិជ្ជករ',      '商店タグ',    '가맹점 태그', 3, 1, NULL),

-- ── 服务城市（柬埔寨）────────────────────────────────────────────────────────
-- dict_value 使用中文名，与数据库已有存储值保持一致（前端 serviceCity 字段直接存储中文）
('service_city', '金边',     '金边',     'Phnom Penh',      'Phnom Penh',      'ភ្នំពេញ',    '金辺',           '프놈펜',     1,  1, NULL),
('service_city', '暹粒',     '暹粒',     'Siem Reap',       'Siem Reap',       'សៀមរាប',     'シェムリアップ', '시엠립',     2,  1, NULL),
('service_city', '西哈努克', '西哈努克', 'Sihanoukville',   'Sihanoukville',   'ព្រះសីហនុ',  'シアヌークビル', '시아누크빌',  3,  1, NULL),
('service_city', '贡布',     '贡布',     'Kampot',          'Kampot',          'កំពត',        'カンポット',    '캄폿',        4,  1, NULL),
('service_city', '白马',     '白马',     'Kep',             'Kep',             'កែប',         'ケップ',        '켑',          5,  1, NULL),
('service_city', '磅湛',     '磅湛',     'Kampong Cham',    'Kampong Cham',    'កំពង់ចាម',    'コンポンチャム','콤퐁참',      6,  1, NULL),
('service_city', '菩萨',     '菩萨',     'Pursat',          'Pursat',          'ពោធិ៍សាត់',   'プルサット',    '뿌르삿',      7,  1, NULL),
('service_city', '磅通',     '磅通',     'Kampong Thom',    'Kampong Thom',    'កំពង់ធំ',     'コンポントム',  '콤퐁톰',      8,  1, NULL),
('service_city', '茶胶',     '茶胶',     'Takeo',           'Takeo',           'តាកែវ',        'タケオ',        '따께오',      9,  1, NULL),
('service_city', '柴桢',     '柴桢',     'Svay Rieng',      'Svay Rieng',      'ស្វាយរៀង',   'スヴァイリエン','스바이리엥',  10, 1, NULL),
('service_city', '磅清扬',   '磅清扬',   'Kampong Chhnang', 'Kampong Chhnang', 'កំពង់ឆ្នាំង', 'コンポンチュナン','콤퐁츠낭',  11, 1, NULL),
('service_city', '其他',     '其他',     'Other',           'Khác',            'ផ្សេងទៀត',   'その他',        '기타',        99, 1, NULL),

-- ── 国籍 ─────────────────────────────────────────────────────────────────────
('nationality', 'CN', '中国',      'China',       'Trung Quốc',   'ចិន',         '中国',      '중국',    1,  1, '🇨🇳'),
('nationality', 'KH', '柬埔寨',    'Cambodia',    'Campuchia',    'កម្ពុជា',     'カンボジア','캄보디아',2,  1, '🇰🇭'),
('nationality', 'VN', '越南',      'Vietnam',     'Việt Nam',     'វៀតណាម',     'ベトナム',  '베트남',  3,  1, '🇻🇳'),
('nationality', 'TH', '泰国',      'Thailand',    'Thái Lan',     'ថៃ',          'タイ',      '태국',    4,  1, '🇹🇭'),
('nationality', 'MY', '马来西亚',  'Malaysia',    'Malaysia',     'មាឡេស៊ី',    'マレーシア','말레이시아',5,1,'🇲🇾'),
('nationality', 'SG', '新加坡',    'Singapore',   'Singapore',    'សិង្ហបុរី', 'シンガポール','싱가포르',6,1,'🇸🇬'),
('nationality', 'MM', '缅甸',      'Myanmar',     'Myanmar',      'មីយ៉ាន់ម៉ា', 'ミャンマー','미얀마',   7,  1, '🇲🇲'),
('nationality', 'LA', '老挝',      'Laos',        'Lào',          'ឡាវ',         'ラオス',    '라오스',  8,  1, '🇱🇦'),
('nationality', 'PH', '菲律宾',    'Philippines', 'Philippines',  'ហ្វីលីពីន',  'フィリピン','필리핀',  9,  1, '🇵🇭'),
('nationality', 'KR', '韩国',      'Korea',       'Hàn Quốc',     'កូរ៉េ',       '韓国',      '한국',    10, 1, '🇰🇷'),
('nationality', 'JP', '日本',      'Japan',       'Nhật Bản',     'ជប៉ុន',       '日本',      '일본',    11, 1, '🇯🇵'),
('nationality', 'RU', '俄罗斯',    'Russia',      'Nga',          'រូស្ស៊ី',    'ロシア',    '러시아',  12, 1, '🇷🇺'),
('nationality', 'US', '美国',      'USA',         'Mỹ',           'អាមេរិក',    'アメリカ',  '미국',    13, 1, '🇺🇸'),
('nationality', 'GB', '英国',      'UK',          'Anh',          'អង់គ្លេស',   'イギリス',  '영국',    14, 1, '🇬🇧'),
('nationality', 'OT', '其他',      'Other',       'Khác',         'ផ្សេងទៀត',   'その他',    '기타',    99, 1, NULL),

-- ── 常用语言 ─────────────────────────────────────────────────────────────────
('language', 'zh', '中文',   'Chinese',    'Tiếng Trung',  'ភាសាចិន',      '中国語',     '중국어',  1, 1, NULL),
('language', 'km', '柬埔寨语','Khmer',     'Tiếng Khmer',  'ភាសាខ្មែរ',    'クメール語', '크메르어',2, 1, NULL),
('language', 'en', '英语',   'English',    'Tiếng Anh',    'ភាសាអង់គ្លេស', '英語',       '영어',    3, 1, NULL),
('language', 'vi', '越南语', 'Vietnamese', 'Tiếng Việt',   'ភាសាវៀតណាម',  'ベトナム語', '베트남어',4, 1, NULL),
('language', 'ko', '韩语',   'Korean',     'Tiếng Hàn',    'ភាសាកូរ៉េ',    '韓国語',     '한국어',  5, 1, NULL),
('language', 'ja', '日语',   'Japanese',   'Tiếng Nhật',   'ភាសាជប៉ុន',    '日本語',     '일본어',  6, 1, NULL),
('language', 'th', '泰语',   'Thai',       'Tiếng Thái',   'ភាសាថៃ',       'タイ語',     '태국어',  7, 1, NULL),
('language', 'ru', '俄语',   'Russian',    'Tiếng Nga',    'ភាសារូស្ស៊ី',  'ロシア語',   '러시아어',8, 1, NULL),

-- ── 会员账号状态 ──────────────────────────────────────────────────────────────
('member_status', '1', '正常',       'Normal',     'Bình thường', 'ធម្មតា',          '正常',       '정상',      1, 1, 'green'),
('member_status', '2', '已封禁',     'Banned',     'Bị cấm',      'ត្រូវបានហាម',     '停止',       '정지',      2, 1, 'red'),
('member_status', '3', '注销申请中', 'Cancelling', 'Đang hủy',    'កំពុងលុប',        '退会申請中', '탈퇴 신청중',3, 1, 'orange'),

-- ── 会员等级 ─────────────────────────────────────────────────────────────────
('member_level', '0', '普通会员', 'Regular', 'Thường',   'ធម្មតា', 'レギュラー', '일반', 1, 1, 'default'),
('member_level', '1', '银卡会员', 'Silver',  'Bạc',      'ប្រាក់', 'シルバー',   '실버', 2, 1, 'silver'),
('member_level', '2', '金卡会员', 'Gold',    'Vàng',     'មាស',    'ゴールド',   '골드', 3, 1, 'gold'),
('member_level', '3', '钻石会员', 'Diamond', 'Kim cương','ماس',    'ダイヤモンド','다이아',4, 1, 'cyan'),

-- ── 注册来源 ─────────────────────────────────────────────────────────────────
('register_source', '1', 'APP',  'APP', 'APP', 'APP', 'APP', 'APP', 1, 1, NULL),
('register_source', '2', 'H5',   'H5',  'H5',  'H5',  'H5',  'H5',  2, 1, NULL),

-- ── 技师账号状态 ──────────────────────────────────────────────────────────────
('technician_status', '1', '正常', 'Active',    'Hoạt động', 'ដំណើរការ',      '有効', '활성', 1, 1, 'green'),
('technician_status', '2', '停用', 'Suspended', 'Tạm dừng',  'ផ្អាកការ',       '停止', '정지', 2, 1, 'red'),

-- ── 入驻审核状态（技师 & 商户共用）───────────────────────────────────────────
('technician_audit', '0', '待审核',   'Pending',  'Đang chờ',  'កំពុងរង់ចាំ',     '審査待ち', '심사 중', 1, 1, 'orange'),
('technician_audit', '1', '审核通过', 'Approved', 'Đã duyệt',  'បានអនុម័ត',       '承認済み', '승인됨',  2, 1, 'green'),
('technician_audit', '2', '审核拒绝', 'Rejected', 'Từ chối',   'ត្រូវបានបដិសេធ',  '拒否',     '거절됨',  3, 1, 'red'),

-- ── 技师在线状态 ──────────────────────────────────────────────────────────────
('technician_online', '0', '离线',    'Offline',    'Ngoại tuyến', 'គ្មានអ៊ីនធ័ណ',  'オフライン',  '오프라인', 1, 1, 'default'),
('technician_online', '1', '在线待单','Online',      'Trực tuyến',  'អ៊ីនធ័ណ',        'オンライン',  '온라인',   2, 1, 'green'),
('technician_online', '2', '服务中',  'In Service',  'Đang phục vụ','កំពុងបម្រើ',     'サービス中', '서비스 중',3, 1, 'blue'),

-- ── 罩杯尺码 ─────────────────────────────────────────────────────────────────
('bust_size', 'A', 'A 杯', 'Cup A', NULL, NULL, NULL, NULL, 1, 1, NULL),
('bust_size', 'B', 'B 杯', 'Cup B', NULL, NULL, NULL, NULL, 2, 1, NULL),
('bust_size', 'C', 'C 杯', 'Cup C', NULL, NULL, NULL, NULL, 3, 1, NULL),
('bust_size', 'D', 'D 杯', 'Cup D', NULL, NULL, NULL, NULL, 4, 1, NULL),
('bust_size', 'E', 'E 杯', 'Cup E', NULL, NULL, NULL, NULL, 5, 1, NULL),
('bust_size', 'F', 'F 杯', 'Cup F', NULL, NULL, NULL, NULL, 6, 1, NULL),
('bust_size', 'G', 'G 杯', 'Cup G', NULL, NULL, NULL, NULL, 7, 1, NULL),

-- ── 技师结算方式 ──────────────────────────────────────────────────────────────
('settlement_mode', '0', '每笔结算', 'Per Order', 'Theo đơn',   'តាមការបញ្ជាទិញ', '都度精算', '건별', 1, 1, NULL),
('settlement_mode', '1', '日结',     'Daily',     'Hàng ngày',  'ប្រចាំថ្ងៃ',      '日次',     '일별', 2, 1, NULL),
('settlement_mode', '2', '周结',     'Weekly',    'Hàng tuần',  'ប្រចាំសប្ដាហ៍',   '週次',     '주별', 3, 1, NULL),
('settlement_mode', '3', '月结',     'Monthly',   'Hàng tháng', 'ប្រចាំខែ',        '月次',     '월별', 4, 1, NULL),

-- ── 技师提成类型 ──────────────────────────────────────────────────────────────
('commission_type', '0', '按比例(%)', 'Percentage', 'Theo %',     'តាមភាគរយ', '歩合制', '비율제', 1, 1, NULL),
('commission_type', '1', '固定金额',  'Fixed',      'Cố định',    'ចំនួនថេរ',  '固定額', '고정액', 2, 1, NULL),

-- ── 商户账号状态 ──────────────────────────────────────────────────────────────
('merchant_status', '1', '正常营业', 'Open',   'Đang mở cửa', 'បើក',  '営業中', '영업 중', 1, 1, 'green'),
('merchant_status', '2', '已停业',   'Closed', 'Đóng cửa',    'បិទ',   '休業中', '휴업',    2, 1, 'default'),

-- ── 商户业务类型 ──────────────────────────────────────────────────────────────
('merchant_business_type', '1', '综合SPA',  'Spa',          'Spa Tổng Hợp', 'ស្ប៉ារួម',     'スパ総合', '종합 스파', 1, 1, 'purple'),
('merchant_business_type', '2', '洗浴中心', 'Bath Center',  'Tắm hơi',      'មជ្ឈមណ្ឌលងូត', '入浴施設', '목욕탕',    2, 1, 'blue'),
('merchant_business_type', '3', '美容美体', 'Beauty Salon', 'Làm đẹp',      'សាឡីត្រូវ',    '美容',     '미용실',    3, 1, 'pink'),
('merchant_business_type', '4', '足疗',     'Foot Massage', 'Massage chân', 'គីមីជើង',      '足療',     '발마사지',  4, 1, 'cyan'),

-- ── 部门类别 ─────────────────────────────────────────────────────────────────
('dept_category', '1', '业务',   'Business',   'Nghiệp vụ', 'ជំនួញ',  '事業',       '영업',  1, 1, 'blue'),
('dept_category', '2', '技术',   'Technical',  'Kỹ thuật',  'បច្ចេកទេស','技術',      '기술',  2, 1, 'purple'),
('dept_category', '3', '职能',   'Operations', 'Vận hành',  'ប្រតិបត្តិការ','管理',  '운영',  3, 1, 'cyan'),
('dept_category', '4', '管理',   'Management', 'Quản lý',   'គ្រប់គ្រង','経営',      '경영',  4, 1, 'gold'),

-- ── 职级等级 ─────────────────────────────────────────────────────────────────
('job_grade', 'P1', 'P1 初级',   'Junior',     NULL, NULL, NULL, NULL, 1, 1, NULL),
('job_grade', 'P2', 'P2 中级',   'Mid',        NULL, NULL, NULL, NULL, 2, 1, NULL),
('job_grade', 'P3', 'P3 高级',   'Senior',     NULL, NULL, NULL, NULL, 3, 1, NULL),
('job_grade', 'P4', 'P4 专家',   'Expert',     NULL, NULL, NULL, NULL, 4, 1, NULL),
('job_grade', 'P5', 'P5 首席',   'Principal',  NULL, NULL, NULL, NULL, 5, 1, NULL),
('job_grade', 'M1', 'M1 组长',   'Team Lead',  NULL, NULL, NULL, NULL, 6, 1, NULL),
('job_grade', 'M2', 'M2 主管',   'Supervisor', NULL, NULL, NULL, NULL, 7, 1, NULL),
('job_grade', 'M3', 'M3 经理',   'Manager',    NULL, NULL, NULL, NULL, 8, 1, NULL),
('job_grade', 'M4', 'M4 总监',   'Director',   NULL, NULL, NULL, NULL, 9, 1, NULL),
('job_grade', 'M5', 'M5 VP',     'VP',         NULL, NULL, NULL, NULL, 10,1, NULL),

-- ── 员工/司机状态 ─────────────────────────────────────────────────────────────
('staff_status', '0', '待审核', 'Pending',   'Đang chờ', 'រង់ចាំ',   '審査待ち', '심사 중', 1, 1, 'orange'),
('staff_status', '1', '在职',   'Active',    'Đang làm', 'ធ្វើការ',   '在職',     '재직',    2, 1, 'green'),
('staff_status', '2', '停职',   'Suspended', 'Tạm dừng', 'ផ្អាកការ',  '停職',     '정직',    3, 1, 'red'),

-- ── 服务项目类型 ──────────────────────────────────────────────────────────────
('service_type', '0', '常规项目', 'Regular', 'Thông thường', 'ធម្មតា', '通常',      '일반',   1, 1, 'blue'),
('service_type', '1', '特殊项目', 'Special', 'Đặc biệt',     'ពិសេស',  'スペシャル','스페셜', 2, 1, 'gold'),

-- ── 订单状态（在线预约）──────────────────────────────────────────────────────
('order_status', '0', '待支付',   'Pending Payment', 'Chờ TT',     'រង់ចាំ',         '支払待ち',   '결제 대기',  1, 1, 'default'),
('order_status', '1', '已支付',   'Paid',            'Đã TT',      'បានទូទាត់',      '支払済み',   '결제 완료',  2, 1, 'cyan'),
('order_status', '2', '已派单',   'Dispatched',      'Đã phân',    'បានបញ្ជូន',      '配車済み',   '배차 완료',  3, 1, 'blue'),
('order_status', '3', '技师前往', 'On Way',          'Đang đến',   'កំពុងទៅ',        '向かっています','이동 중', 4, 1, 'purple'),
('order_status', '4', '服务中',   'In Service',      'Đang phục vụ','កំពុងបម្រើ',    'サービス中', '서비스 중',  5, 1, 'blue'),
('order_status', '5', '待评价',   'Pending Review',  'Chờ đánh giá','រង់ចាំ',        '評価待ち',   '평가 대기',  6, 1, 'orange'),
('order_status', '6', '已完成',   'Completed',       'Hoàn thành',  'បានបញ្ចប់',     '完了',       '완료',       7, 1, 'green'),
('order_status', '7', '取消中',   'Cancelling',      'Đang hủy',    'កំពុងលុប',      'キャンセル中','취소 중',   8, 1, 'orange'),
('order_status', '8', '已取消',   'Cancelled',       'Đã hủy',      'បានលុបចោល',     'キャンセル済','취소됨',    9, 1, 'red'),
('order_status', '9', '已退款',   'Refunded',        'Đã hoàn',     'បានសងប្រាក់',   '返金済み',   '환불됨',     10,1, 'volcano'),

-- ── 门店散客会话状态 ──────────────────────────────────────────────────────────
('walkin_status', '0', '待分配',   'Waiting',   'Đang chờ',     'រង់ចាំ',        '待機中',     '대기 중',   1, 1, 'default'),
('walkin_status', '1', '服务中',   'Serving',   'Đang phục vụ', 'កំពុងបម្រើ',   'サービス中', '서비스 중', 2, 1, 'blue'),
('walkin_status', '2', '已结账',   'Settled',   'Đã thanh toán','បានទូទាត់',     '会計済み',   '정산 완료', 3, 1, 'green'),
('walkin_status', '3', '已取消',   'Cancelled', 'Đã hủy',       'បានលុបចោល',    'キャンセル', '취소됨',    4, 1, 'red'),

-- ── 门店散客支付方式 ──────────────────────────────────────────────────────────
('walkin_pay_type', '1', '现金',   'Cash',           'Tiền mặt',     'សាច់ប្រាក់',     '現金',      '현금',      1, 1, 'green'),
('walkin_pay_type', '2', 'ABA Pay','ABA Pay',         'ABA Pay',      'ABA Pay',         'ABA Pay',   'ABA Pay',   2, 1, 'blue'),
('walkin_pay_type', '3', 'USDT',   'USDT',            'USDT',         'USDT',            'USDT',      'USDT',      3, 1, 'orange'),
('walkin_pay_type', '4', '微信支付','WeChat Pay',      'WeChat',       'WeChat',          'WeChat',    'WeChat',    4, 1, 'green'),
('walkin_pay_type', '5', '支付宝', 'Alipay',          'Alipay',       'Alipay',          'Alipay',    'Alipay',    5, 1, 'blue'),
('walkin_pay_type', '6', '挂账',   'On Account',      'Chịu nợ',      'ខ្ចីប្រាក់',    '付け',      '외상',      6, 1, 'default'),

-- ── 在线支付方式 ──────────────────────────────────────────────────────────────
('pay_type', '1', 'ABA Pay',  'ABA Pay', 'ABA Pay', 'ABA Pay', 'ABA Pay', 'ABA Pay', 1, 1, 'blue'),
('pay_type', '2', 'USDT',     'USDT',    'USDT',    'USDT',    'USDT',    'USDT',    2, 1, 'green'),
('pay_type', '3', '钱包余额', 'Wallet',  'Ví điện tử','កាបូបអេឡិចត្រូនិក','ウォレット','지갑', 3, 1, 'purple'),
('pay_type', '4', '现金',     'Cash',   'Tiền mặt', 'សាច់ប្រាក់',      '現金',     '현금', 4, 1, 'default'),

-- ── 支付状态 ─────────────────────────────────────────────────────────────────
('pay_status', '0', '待支付',   'Pending',  'Chờ TT',        'រង់ចាំ',       '支払待ち', '결제 대기', 1, 1, 'default'),
('pay_status', '1', '支付成功', 'Success',  'Thành công',     'ជោគជ័យ',      '支払成功', '결제 성공', 2, 1, 'green'),
('pay_status', '2', '支付失败', 'Failed',   'Thất bại',       'បរាជ័យ',       '支払失敗', '결제 실패', 3, 1, 'red'),
('pay_status', '3', '已退款',   'Refunded', 'Đã hoàn tiền',   'បានសងប្រាក់', '返金済み', '환불됨',    4, 1, 'volcano'),

-- ── 结算货币 ─────────────────────────────────────────────────────────────────
('currency', 'USD',  'USD 美元',   'USD', NULL, NULL, NULL, NULL, 1, 1, '#3b82f6'),
('currency', 'USDT', 'USDT 泰达币','USDT',NULL, NULL, NULL, NULL, 2, 1, '#26a17b'),
('currency', 'KHR',  'KHR 瑞尔',   'KHR', NULL, NULL, NULL, NULL, 3, 1, '#dc2626'),
('currency', 'CNY',  'CNY 人民币', 'CNY', NULL, NULL, NULL, NULL, 4, 1, '#ef4444'),
('currency', 'THB',  'THB 泰铢',   'THB', NULL, NULL, NULL, NULL, 5, 1, '#a855f7'),
('currency', 'SGD',  'SGD 新元',   'SGD', NULL, NULL, NULL, NULL, 6, 1, '#f59e0b'),

-- ── 优惠券类型 ────────────────────────────────────────────────────────────────
('coupon_type', '1', '满减券',     'Cash Discount',  'Phiếu giảm giá', 'គូប៉ុងបញ្ចុះ', '割引クーポン', '할인 쿠폰',   1, 1, 'red'),
('coupon_type', '2', '折扣券',     'Percentage Off', 'Giảm phần trăm', 'ប័ណ្ណ%',         '割引券',       '% 할인권',    2, 1, 'purple'),
('coupon_type', '3', '免交通费券', 'Free Delivery',  'Miễn phí đi lại','ឥតគិតថ្លៃ',    '交通費無料券', '교통비 무료', 3, 1, 'cyan'),

-- ── 优惠券使用状态 ────────────────────────────────────────────────────────────
('coupon_use_status', '0', '未使用', 'Unused',  'Chưa dùng', 'មិនទាន់ប្រើ', '未使用', '미사용', 1, 1, 'green'),
('coupon_use_status', '1', '已使用', 'Used',    'Đã dùng',   'បានប្រើ',      '使用済み','사용됨', 2, 1, 'default'),
('coupon_use_status', '2', '已过期', 'Expired', 'Đã hết hạn','ផុតកំណត់',     '期限切れ','만료됨', 3, 1, 'red'),

-- ── 钱包状态 ─────────────────────────────────────────────────────────────────
('wallet_status', '1', '正常', 'Normal', 'Bình thường', 'ធម្មតា', '正常', '정상', 1, 1, 'green'),
('wallet_status', '0', '冻结', 'Frozen', 'Bị đóng băng','凍結',   '凍結', '동결', 2, 1, 'blue'),

-- ── 钱包流水类型 ──────────────────────────────────────────────────────────────
('wallet_flow_type', '1', '充值',     'Top Up',         'Nạp tiền',       'បញ្ចូល',        'チャージ',     '충전',         1, 1, 'green'),
('wallet_flow_type', '2', '消费扣款', 'Deduction',      'Thanh toán',     'ការផ្ទេរ',       '支払い',       '결제',         2, 1, 'red'),
('wallet_flow_type', '3', '退款到账', 'Refund',         'Hoàn tiền',      'ការស្ដារ',       '返金',         '환불',         3, 1, 'volcano'),
('wallet_flow_type', '4', '接单收入', 'Service Income', 'Thu nhập DV',    'ប្រាក់ចំណូល',   '収入',         '서비스 수입',  4, 1, 'blue'),
('wallet_flow_type', '5', '申请提现', 'Withdrawal',     'Rút tiền',       'ដកប្រាក់',       '出金',         '출금',         5, 1, 'orange'),
('wallet_flow_type', '6', '平台佣金', 'Platform Fee',   'Hoa hồng',       'ផ្ដល់ជូនវេទិកា', '手数料',       '플랫폼 수수료',6, 1, 'purple'),

-- ── 结算单状态 ────────────────────────────────────────────────────────────────
('settlement_status', '0', '待结算', 'Pending',  'Chờ thanh lý', 'រង់ចាំ',         '精算待ち', '정산 대기', 1, 1, 'orange'),
('settlement_status', '1', '已结算', 'Settled',  'Đã thanh lý',  'បានបញ្ចប់',      '精算済み', '정산 완료', 2, 1, 'green'),
('settlement_status', '2', '争议暂扣','Disputed','Đang tranh chấp','ជំទាស់',         '係争中',   '분쟁 중',   3, 1, 'red'),

-- ── 薪资发放状态 ──────────────────────────────────────────────────────────────
('salary_status', '0', '待发放', 'Pending',   'Chờ phát',  'រង់ចាំ',     '支給待ち', '지급 대기', 1, 1, 'orange'),
('salary_status', '1', '已发放', 'Paid',      'Đã phát',   'បានផ្ដល់',   '支給済み', '지급 완료', 2, 1, 'green'),
('salary_status', '2', '已作废', 'Voided',    'Đã hủy',    'បានបោះបង់',  '無効',     '무효',      3, 1, 'red'),

-- ── 薪资员工类型 ──────────────────────────────────────────────────────────────
('staff_type', '1', '员工',   'Staff',      'Nhân viên', 'បុគ្គលិក', 'スタッフ', '직원', 1, 1, NULL),
('staff_type', '2', '技师',   'Technician', 'Kỹ thuật',  'អ្នកបច្ចេកទេស','技師', '기술자',2, 1, NULL),

-- ── 支出类别 ─────────────────────────────────────────────────────────────────
('expense_category', '1', '房租水电', 'Utilities',   'Tiện ích',       'ឧបករណ៍',         '光熱費',   '공과금',    1, 1, NULL),
('expense_category', '2', '耗材采购', 'Supplies',    'Vật tư',         'ជ្រើសរើស',       '消耗品',   '소모품',    2, 1, NULL),
('expense_category', '3', '员工工资', 'Payroll',     'Lương',          'ប្រាក់ខែ',        '給与',     '급여',      3, 1, NULL),
('expense_category', '4', '市场营销', 'Marketing',   'Tiếp thị',       'ទីផ្សារ',         '広告費',   '마케팅',    4, 1, NULL),
('expense_category', '5', '设备维修', 'Maintenance', 'Bảo trì',        'ថែទាំ',           '保守費',   '유지보수',  5, 1, NULL),
('expense_category', '6', '其他支出', 'Others',      'Khác',           'ផ្សេងទៀត',        'その他',   '기타',      6, 1, NULL),

-- ── 车辆状态 ─────────────────────────────────────────────────────────────────
('vehicle_status', '0', '空闲',   'Idle',        'Rảnh',           'ទំនេរ',     '空車',   '대기',    1, 1, 'green'),
('vehicle_status', '1', '使用中', 'In Use',      'Đang sử dụng',   'កំពុងប្រើ', '使用中', '사용 중', 2, 1, 'blue'),
('vehicle_status', '2', '维修中', 'Maintenance', 'Đang sửa chữa',  'ជួសជុល',    '整備中', '정비 중', 3, 1, 'orange'),

-- ── 车辆品牌 ─────────────────────────────────────────────────────────────────
-- remark 字段存储品牌主色（用于前端 Tag 颜色）
('vehicle_brand', 'Toyota',     'Toyota 丰田',     'Toyota',     NULL, NULL, NULL, NULL, 1,  1, '#eb0a1e'),
('vehicle_brand', 'Honda',      'Honda 本田',      'Honda',      NULL, NULL, NULL, NULL, 2,  1, '#cc0000'),
('vehicle_brand', 'Mazda',      'Mazda 马自达',    'Mazda',      NULL, NULL, NULL, NULL, 3,  1, '#c00000'),
('vehicle_brand', 'Mitsubishi', 'Mitsubishi 三菱', 'Mitsubishi', NULL, NULL, NULL, NULL, 4,  1, '#e60012'),
('vehicle_brand', 'Hyundai',    'Hyundai 现代',    'Hyundai',    NULL, NULL, NULL, NULL, 5,  1, '#002c5f'),
('vehicle_brand', 'Kia',        'Kia 起亚',        'Kia',        NULL, NULL, NULL, NULL, 6,  1, '#05141f'),
('vehicle_brand', 'Lexus',      'Lexus 雷克萨斯',  'Lexus',      NULL, NULL, NULL, NULL, 7,  1, '#1a1a1a'),
('vehicle_brand', 'BMW',        'BMW 宝马',        'BMW',        NULL, NULL, NULL, NULL, 8,  1, '#1c69d4'),
('vehicle_brand', 'Mercedes',   'Mercedes 奔驰',   'Mercedes',   NULL, NULL, NULL, NULL, 9,  1, '#222222'),
('vehicle_brand', 'Audi',       'Audi 奥迪',       'Audi',       NULL, NULL, NULL, NULL, 10, 1, '#bb0a14'),
('vehicle_brand', 'Nissan',     'Nissan 日产',     'Nissan',     NULL, NULL, NULL, NULL, 11, 1, '#c3002f'),
('vehicle_brand', 'Ford',       'Ford 福特',       'Ford',       NULL, NULL, NULL, NULL, 12, 1, '#003499'),
('vehicle_brand', 'Suzuki',     'Suzuki 铃木',     'Suzuki',     NULL, NULL, NULL, NULL, 13, 1, '#1e4ea3'),
('vehicle_brand', 'Isuzu',      'Isuzu 五十铃',    'Isuzu',      NULL, NULL, NULL, NULL, 14, 1, '#e8141f'),
('vehicle_brand', 'Other',      '其他品牌',        'Other',      NULL, NULL, NULL, NULL, 99, 1, '#667eea'),

-- ── 车辆颜色 ─────────────────────────────────────────────────────────────────
-- remark 字段存储颜色 hex 值，前端可直接用于色块展示
('vehicle_color', 'pearl_white',   '珍珠白', 'Pearl White',    NULL, NULL, NULL, NULL, 1,  1, '#f0ede8'),
('vehicle_color', 'deep_black',    '深空黑', 'Deep Black',     NULL, NULL, NULL, NULL, 2,  1, '#1a1a1a'),
('vehicle_color', 'silver_gray',   '银灰色', 'Silver Gray',    NULL, NULL, NULL, NULL, 3,  1, '#c0c0c0'),
('vehicle_color', 'magnetic_gray', '磁性灰', 'Magnetic Gray',  NULL, NULL, NULL, NULL, 4,  1, '#757575'),
('vehicle_color', 'soul_red',      '魂动红', 'Soul Red',       NULL, NULL, NULL, NULL, 5,  1, '#c1121f'),
('vehicle_color', 'nebula_blue',   '星云蓝', 'Nebula Blue',    NULL, NULL, NULL, NULL, 6,  1, '#2563eb'),
('vehicle_color', 'olive_green',   '橄榄绿', 'Olive Green',    NULL, NULL, NULL, NULL, 7,  1, '#4d7c0f'),
('vehicle_color', 'crystal_black', '水晶黑', 'Crystal Black',  NULL, NULL, NULL, NULL, 8,  1, '#0f172a'),
('vehicle_color', 'crystal_white', '晶石白', 'Crystal White',  NULL, NULL, NULL, NULL, 9,  1, '#f8fafc'),
('vehicle_color', 'rock_gray',     '岩石灰', 'Rock Gray',      NULL, NULL, NULL, NULL, 10, 1, '#6b7280'),
('vehicle_color', 'zircon_silver', '锆沙银', 'Zircon Silver',  NULL, NULL, NULL, NULL, 11, 1, '#94a3b8'),
('vehicle_color', 'polar_white',   '极地白', 'Polar White',    NULL, NULL, NULL, NULL, 12, 1, '#f1f5f9'),
('vehicle_color', 'champagne',     '香槟金', 'Champagne Gold', NULL, NULL, NULL, NULL, 13, 1, '#c5a028'),

-- ── 出行目的 ─────────────────────────────────────────────────────────────────
('vehicle_purpose', '1', '接送技师',  'Tech Transport', 'Đón kỹ thuật viên', 'ដឹកអ្នកបច្ចេកទេស','技師送迎', '기술자 이동', 1, 1, NULL),
('vehicle_purpose', '2', '接送客户',  'Client Transfer','Đón khách hàng',    'ដឹកភ្ញៀវ',         '顧客送迎', '고객 이동',   2, 1, NULL),
('vehicle_purpose', '3', '采购物资',  'Procurement',    'Mua sắm',           'ទិញទំនិញ',          '仕入れ',   '구매',        3, 1, NULL),
('vehicle_purpose', '4', '办公出行',  'Business',       'Công vụ',           'ការងារ',             '業務',     '업무',        4, 1, NULL),
('vehicle_purpose', '9', '其他',      'Other',          'Khác',              'ផ្សេងទៀត',          'その他',   '기타',        99,1, NULL),

-- ── 派车单状态 ────────────────────────────────────────────────────────────────
('dispatch_status', '0', '待接单',   'Waiting',   'Chờ nhận',     'រង់ចាំ',          '受注待ち',       '배차 대기', 1, 1, 'default'),
('dispatch_status', '1', '已接单',   'Accepted',  'Đã nhận',      'បានទទួល',         '受注済み',       '수락됨',    2, 1, 'blue'),
('dispatch_status', '2', '前往接客', 'En Route',  'Đang đến',     'កំពុងទៅ',         '向かっています', '이동 중',   3, 1, 'purple'),
('dispatch_status', '3', '已到达',   'Arrived',   'Đã đến',       'បានមកដល់',        '到着',           '도착',      4, 1, 'cyan'),
('dispatch_status', '4', '已上车',   'Picked Up', 'Đã lên xe',    'ឡើងរថយន្ត',      '乗車済み',       '탑승됨',    5, 1, 'geekblue'),
('dispatch_status', '5', '已完成',   'Completed', 'Hoàn thành',   'បានបញ្ចប់',       '完了',           '완료',      6, 1, 'green'),
('dispatch_status', '9', '已取消',   'Cancelled', 'Đã hủy',       'បានលុបចោល',       'キャンセル',     '취소됨',    7, 1, 'red'),

-- ── 内部派车用途（含颜色/图标，remark JSON: {"c":"hex","i":"emoji"}）──────────
('vehicle_dispatch_purpose', '1', '接送客户', 'Client Transfer', 'Đón khách',   'ដឹកភ្ញៀវ',       '顧客送迎', '고객 이동',   1, 1, '{"c":"#6366f1","i":"🚕"}'),
('vehicle_dispatch_purpose', '2', '采购物资', 'Procurement',     'Mua sắm',     'ទិញទំនិញ',        '仕入れ',   '구매',        2, 1, '{"c":"#f59e0b","i":"🛒"}'),
('vehicle_dispatch_purpose', '3', '员工通勤', 'Commute',         'Đi làm',      'ធ្វើដំណើរ',       '通勤',     '출퇴근',      3, 1, '{"c":"#3b82f6","i":"🚌"}'),
('vehicle_dispatch_purpose', '4', '业务出行', 'Business Trip',   'Công vụ',     'ការងារ',           '業務',     '업무',        4, 1, '{"c":"#10b981","i":"💼"}'),
('vehicle_dispatch_purpose', '5', '其它',     'Other',           'Khác',        'ផ្សេងទៀត',        'その他',   '기타',        9, 1, '{"c":"#94a3b8","i":"🚗"}'),

-- ── 内部车辆调度状态（remark JSON: {"c":"hex","b":"badge"}）──────────────────
('vehicle_dispatch_status', '0', '待出发', 'Pending',   'Chờ khởi hành', 'រង់ចាំ',         '出発待ち', '출발 대기', 1, 1, '{"c":"#3b82f6","b":"default"}'),
('vehicle_dispatch_status', '1', '行程中', 'In Transit','Đang trên đường','កំពុងធ្វើដំណើរ', '移動中',   '이동 중',   2, 1, '{"c":"#f97316","b":"processing"}'),
('vehicle_dispatch_status', '2', '已返回', 'Returned',  'Đã trở về',     'បានត្រឡប់',       '帰還済み', '복귀 완료', 3, 1, '{"c":"#10b981","b":"success"}'),
('vehicle_dispatch_status', '3', '已取消', 'Cancelled', 'Đã hủy',        'បានលុបចោល',      'キャンセル','취소됨',    4, 1, '{"c":"#94a3b8","b":"default"}'),

-- ── 门店散客会话状态（remark JSON: {"c":"hex","b":"badge"}）──────────────────
('walkin_session_status', '0', '待服务', 'Waiting',  'Chờ phục vụ',  'រង់ចាំ',          '待機中',       '대기 중',   1, 1, '{"c":"#3b82f6","b":"processing"}'),
('walkin_session_status', '1', '服务中', 'Serving',  'Đang phục vụ', 'កំពុងបម្រើ',      'サービス中',   '서비스 중', 2, 1, '{"c":"#f97316","b":"processing"}'),
('walkin_session_status', '2', '待结算', 'Settling', 'Chờ thanh toán','រង់ចាំ',          '精算待ち',     '정산 대기', 3, 1, '{"c":"#f59e0b","b":"warning"}'),
('walkin_session_status', '3', '已结算', 'Settled',  'Đã thanh toán','បានទូទាត់',        '精算済み',     '정산 완료', 4, 1, '{"c":"#10b981","b":"success"}'),
('walkin_session_status', '4', '已取消', 'Cancelled','Đã hủy',       'បានលុបចោល',        'キャンセル',   '취소됨',    5, 1, '{"c":"#94a3b8","b":"default"}'),

-- ── 服务项目进度状态（remark JSON: {"c":"hex","i":"emoji"}）──────────────────
('walkin_svc_status', '0', '待服务', 'Pending',   'Chờ phục vụ',  'រង់ចាំ',     '待機中',   '대기 중',   1, 1, '{"c":"#9ca3af","i":"⏳"}'),
('walkin_svc_status', '1', '服务中', 'In Service','Đang phục vụ', 'កំពុងបម្រើ', 'サービス中','서비스 중', 2, 1, '{"c":"#f97316","i":"🔄"}'),
('walkin_svc_status', '2', '已完成', 'Completed', 'Hoàn thành',   'បានបញ្ចប់',   '完了',     '완료',      3, 1, '{"c":"#10b981","i":"✅"}'),

-- ── 收入类型 ─────────────────────────────────────────────────────────────────
('income_type', '1', '订单收入', 'Order Income',  'Thu từ đơn hàng',  'ប្រាក់ចំណូល',     '注文収入',  '주문 수입',  1, 1, '#6366f1'),
('income_type', '2', '散客结算', 'Walk-in',       'Thanh toán trực',  'ការទូទាត់',        '散客精算',  '산발 정산',  2, 1, '#F5A623'),
('income_type', '3', '会员充值', 'Top-up',        'Nạp tiền thành',   'ការបញ្ចូល',        '会員チャージ','회원 충전', 3, 1, '#10b981'),
('income_type', '4', '其它收入', 'Other',         'Khác',             'ផ្សេងទៀត',         'その他',    '기타',       4, 1, '#94a3b8');


-- ── 三、验证输出 ──────────────────────────────────────────────────────────────
SELECT CONCAT(
    '✅ Migration v4.6 完成：写入字典类型 ',
    (SELECT COUNT(*) FROM sys_dict_type),
    ' 种，字典数据项 ',
    (SELECT COUNT(*) FROM sys_dict),
    ' 条'
) AS result;

-- ── migrate_v4_7.sql ─────────────────────────────────────────────────────────
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

-- ── migrate_v4_8.sql ─────────────────────────────────────────────────────────
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

-- ── migrate_v4_9.sql ─────────────────────────────────────────────────────────
-- ============================================================
-- migrate_v4_9.sql  在线订单增强：服务方式 / 组合支付 / 多服务项
-- 本脚本幂等：重复执行不报错，使用存储过程判断列是否存在
-- ============================================================

-- ─────────────────────────────────────────────────────────────
-- 1. cb_order: 新增 service_mode / pay_records / technician_no
-- ─────────────────────────────────────────────────────────────
DROP PROCEDURE IF EXISTS _add_col_order_service_mode;
DELIMITER $$
CREATE PROCEDURE _add_col_order_service_mode()
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = DATABASE()
          AND table_name   = 'cb_order'
          AND column_name  = 'service_mode'
    ) THEN
        ALTER TABLE cb_order
            ADD COLUMN service_mode TINYINT(1) NOT NULL DEFAULT 2
                COMMENT '服务方式：1=上门服务 2=到店服务'
                AFTER order_type;
    END IF;
END$$
DELIMITER ;
CALL _add_col_order_service_mode();
DROP PROCEDURE IF EXISTS _add_col_order_service_mode;

DROP PROCEDURE IF EXISTS _add_col_order_pay_records;
DELIMITER $$
CREATE PROCEDURE _add_col_order_pay_records()
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = DATABASE()
          AND table_name   = 'cb_order'
          AND column_name  = 'pay_records'
    ) THEN
        ALTER TABLE cb_order
            ADD COLUMN pay_records TEXT DEFAULT NULL
                COMMENT '组合支付明细 JSON（[{method,currency,amount}]）'
                AFTER pay_type;
    END IF;
END$$
DELIMITER ;
CALL _add_col_order_pay_records();
DROP PROCEDURE IF EXISTS _add_col_order_pay_records;

DROP PROCEDURE IF EXISTS _add_col_order_technician_no;
DELIMITER $$
CREATE PROCEDURE _add_col_order_technician_no()
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = DATABASE()
          AND table_name   = 'cb_order'
          AND column_name  = 'technician_no'
    ) THEN
        ALTER TABLE cb_order
            ADD COLUMN technician_no VARCHAR(32) DEFAULT NULL
                COMMENT '技师编号快照（上门服务时用于识别身份）'
                AFTER technician_id;
    END IF;
END$$
DELIMITER ;
CALL _add_col_order_technician_no();
DROP PROCEDURE IF EXISTS _add_col_order_technician_no;

DROP PROCEDURE IF EXISTS _add_col_order_technician_mobile;
DELIMITER $$
CREATE PROCEDURE _add_col_order_technician_mobile()
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = DATABASE()
          AND table_name   = 'cb_order'
          AND column_name  = 'technician_mobile'
    ) THEN
        ALTER TABLE cb_order
            ADD COLUMN technician_mobile VARCHAR(20) DEFAULT NULL
                COMMENT '技师手机快照'
                AFTER technician_no;
    END IF;
END$$
DELIMITER ;
CALL _add_col_order_technician_mobile();
DROP PROCEDURE IF EXISTS _add_col_order_technician_mobile;

-- ─────────────────────────────────────────────────────────────
-- 2. cb_order_item: 多服务项（一单多项）
-- ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS cb_order_item (
    id               BIGINT       NOT NULL AUTO_INCREMENT PRIMARY KEY,
    order_id         BIGINT       NOT NULL           COMMENT '关联订单ID',
    service_item_id  BIGINT       DEFAULT NULL        COMMENT '服务项ID',
    service_name     VARCHAR(100) NOT NULL            COMMENT '服务名称快照',
    service_duration INT          NOT NULL DEFAULT 60 COMMENT '时长(分钟)',
    unit_price       DECIMAL(10,2) NOT NULL           COMMENT '单价',
    qty              INT          NOT NULL DEFAULT 1  COMMENT '数量',
    svc_status       TINYINT(1)   NOT NULL DEFAULT 0  COMMENT '0=待服务 1=服务中 2=已完成',
    start_time       DATETIME     DEFAULT NULL        COMMENT '服务开始时间',
    end_time         DATETIME     DEFAULT NULL        COMMENT '服务结束时间',
    remark           VARCHAR(200) DEFAULT NULL,
    deleted          TINYINT(1)   NOT NULL DEFAULT 0  COMMENT '逻辑删除：0正常 1删除',
    create_time      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    update_time      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_order_id (order_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='在线订单服务项明细';

-- ─────────────────────────────────────────────────────────────
-- 3. 修复 walkin_pay_type 字典 remark — 从简单颜色名改为 JSON 格式
--    格式：{"c":"颜色hex","i":"emoji图标","nc":1(可选,银行转账需选币种)}
--    使用 INSERT ... ON DUPLICATE KEY UPDATE 幂等更新
-- ─────────────────────────────────────────────────────────────
INSERT INTO `sys_dict`
  (`dict_type`,`dict_value`,`label_zh`,`label_en`,`label_vi`,`label_km`,`label_ja`,`label_ko`,`sort`,`status`,`remark`)
VALUES
  ('walkin_pay_type','1','现金',   'Cash',        'Tiền mặt',  'សាច់ប្រាក់', '現金',    '현금',    1,1,'{"c":"#10b981","i":"💵"}'),
  ('walkin_pay_type','2','ABA Pay','ABA Pay',     'ABA Pay',   'ABA Pay',     'ABA Pay', 'ABA Pay', 2,1,'{"c":"#2563eb","i":"🏦","nc":1}'),
  ('walkin_pay_type','3','USDT',   'USDT',        'USDT',      'USDT',        'USDT',    'USDT',    3,1,'{"c":"#f59e0b","i":"₮"}'),
  ('walkin_pay_type','4','微信支付','WeChat Pay',  'WeChat',    'WeChat',      'WeChat',  'WeChat',  4,1,'{"c":"#07C160","i":"💚"}'),
  ('walkin_pay_type','5','支付宝', 'Alipay',      'Alipay',    'Alipay',      'Alipay',  'Alipay',  5,1,'{"c":"#1677FF","i":"💙"}'),
  ('walkin_pay_type','6','挂账',   'On Account',  'Chịu nợ',   'ខ្ចីប្រាក់', '付け',   '외상',    6,1,'{"c":"#94a3b8","i":"📝"}')
ON DUPLICATE KEY UPDATE
  `remark` = VALUES(`remark`);

-- 同步修复 pay_type（在线订单支付方式）
INSERT INTO `sys_dict`
  (`dict_type`,`dict_value`,`label_zh`,`label_en`,`label_vi`,`label_km`,`label_ja`,`label_ko`,`sort`,`status`,`remark`)
VALUES
  ('pay_type','1','ABA Pay',  'ABA Pay', 'ABA Pay',    'ABA Pay',              'ABA Pay',    'ABA Pay', 1,1,'{"c":"#2563eb","i":"🏦"}'),
  ('pay_type','2','USDT',     'USDT',    'USDT',        'USDT',                'USDT',       'USDT',    2,1,'{"c":"#f59e0b","i":"₮"}'),
  ('pay_type','3','钱包余额', 'Wallet',  'Ví điện tử',  'កាបូបអេឡិចត្រូនិក',  'ウォレット', '지갑',    3,1,'{"c":"#8b5cf6","i":"👛"}'),
  ('pay_type','4','现金',     'Cash',    'Tiền mặt',    'សាច់ប្រាក់',          '現金',       '현금',    4,1,'{"c":"#10b981","i":"💵"}')
ON DUPLICATE KEY UPDATE
  `remark` = VALUES(`remark`);

-- 修复 walkin_session_status（确保 remark 格式正确）
INSERT INTO `sys_dict`
  (`dict_type`,`dict_value`,`label_zh`,`label_en`,`label_vi`,`label_km`,`label_ja`,`label_ko`,`sort`,`status`,`remark`)
VALUES
  ('walkin_session_status','0','待服务','Waiting',    'Chờ',    'រង់ចាំ',     '待ち',   '대기',   1,1,'{"c":"#3b82f6","b":"processing"}'),
  ('walkin_session_status','1','服务中','In Service', 'Đang',   'ដំណើរការ',   '進行中', '진행중', 2,1,'{"c":"#f97316","b":"processing"}'),
  ('walkin_session_status','2','待结算','Pending Pay','Chờ TT', 'រង់ចាំ TT',  '精算待ち','정산대기',3,1,'{"c":"#f59e0b","b":"warning"}'),
  ('walkin_session_status','3','已结算','Settled',    'Đã TT',  'បានទូទាត់',  '精算済み','정산완료',4,1,'{"c":"#10b981","b":"success"}'),
  ('walkin_session_status','4','已取消','Cancelled',  'Hủy',    'បោះបង់',     'キャンセル','취소',  5,1,'{"c":"#94a3b8","b":"default"}')
ON DUPLICATE KEY UPDATE
  `remark` = VALUES(`remark`);

-- 修复 walkin_svc_status（服务项进度状态）
INSERT INTO `sys_dict`
  (`dict_type`,`dict_value`,`label_zh`,`label_en`,`label_vi`,`label_km`,`label_ja`,`label_ko`,`sort`,`status`,`remark`)
VALUES
  ('walkin_svc_status','0','待服务','Waiting',   'Chờ',  'រង់ចាំ',   '待ち',   '대기',   1,1,'{"c":"#9ca3af","i":"⏳"}'),
  ('walkin_svc_status','1','服务中','In Service','Đang',  'ដំណើរការ', '進行中', '진행중', 2,1,'{"c":"#f97316","i":"🔄"}'),
  ('walkin_svc_status','2','已完成','Completed', 'Xong', 'បញ្ចប់',   '完了',   '완료',   3,1,'{"c":"#10b981","i":"✅"}')
ON DUPLICATE KEY UPDATE
  `remark` = VALUES(`remark`);

-- 修复 order_status（在线订单状态）
INSERT INTO `sys_dict`
  (`dict_type`,`dict_value`,`label_zh`,`label_en`,`label_vi`,`label_km`,`label_ja`,`label_ko`,`sort`,`status`,`remark`)
VALUES
  ('order_status','0','待支付','Unpaid',     'Chờ TT',  'រង់ចាំ',      '支払待ち',  '결제대기',   1,1,'{"c":"#f59e0b","b":"warning"}'),
  ('order_status','1','待接单','Waiting',    'Chờ',     'រង់ចាំ',      '受注待ち',  '접수대기',   2,1,'{"c":"#3b82f6","b":"processing"}'),
  ('order_status','2','已接单','Accepted',   'Đã nhận', 'ទទួលបាន',     '受注済み',  '접수완료',   3,1,'{"c":"#8b5cf6","b":"processing"}'),
  ('order_status','3','前往中','On the way', 'Đang đến','កំពុងទៅ',     '向かい中',  '이동중',     4,1,'{"c":"#f97316","b":"processing"}'),
  ('order_status','4','已到达','Arrived',    'Đến rồi', 'ដល់ហើយ',     '到着済み',  '도착완료',   5,1,'{"c":"#06b6d4","b":"processing"}'),
  ('order_status','5','服务中','In Service', 'Đang làm','ដំណើរការ',    '施術中',    '시술중',     6,1,'{"c":"#f97316","b":"processing"}'),
  ('order_status','6','已完成','Completed',  'Hoàn tất','បញ្ចប់',      '完了',      '완료',       7,1,'{"c":"#10b981","b":"success"}'),
  ('order_status','7','已取消','Cancelled',  'Đã hủy',  'បោះបង់',      'キャンセル','취소',       8,1,'{"c":"#94a3b8","b":"default"}'),
  ('order_status','8','退款中','Refunding',  'Hoàn tiền','ដំណើរការ HT', '返金中',    '환불중',     9,1,'{"c":"#ec4899","b":"warning"}'),
  ('order_status','9','已退款','Refunded',   'Đã HT',   'បានសង HT',    '返金済み',  '환불완료',  10,1,'{"c":"#6b7280","b":"default"}')
ON DUPLICATE KEY UPDATE
  `remark` = VALUES(`remark`);


-- ═══════════════════════════════════════════════════════════════════════════
-- SECTION 3: v5.x Migration（v5.0 ~ v5.13）
-- ═══════════════════════════════════════════════════════════════════════════

-- ── migrate_v5_0.sql ─────────────────────────────────────────────────────────
-- ============================================================
-- migrate_v5_0.sql  国际化消息补全
--
-- 补充内容：
--   1. CbCodeEnum 新增的技师端枚举（TECHNICIAN_AUDIT_REJECTED /
--      TECHNICIAN_BANNED / TECHNICIAN_MOBILE_EXISTS / MERCHANT_NO_INVALID）
--   2. 通用枚举新增（DATA_DUPLICATE / MISSING_PARAM / METHOD_NOT_ALLOWED）
--
-- 使用 ON DUPLICATE KEY UPDATE 保证脚本幂等（重复执行不报错）
-- ============================================================

INSERT INTO `sys_i18n` (`enum_code`, `lang`, `message`) VALUES

-- ── TECHNICIAN_AUDIT_REJECTED ────────────────────────────────────────────────
('TECHNICIAN_AUDIT_REJECTED','zh','审核未通过，请联系商户了解详情'),
('TECHNICIAN_AUDIT_REJECTED','en','Your application has been rejected, please contact the merchant for details'),
('TECHNICIAN_AUDIT_REJECTED','vi','Đơn đăng ký của bạn bị từ chối, vui lòng liên hệ đối tác để biết thêm chi tiết'),
('TECHNICIAN_AUDIT_REJECTED','km','ពាក្យស្នើសុំរបស់អ្នកត្រូវបានបដិសេធ សូមទំនាក់ទំនងឈ្មួញ'),
('TECHNICIAN_AUDIT_REJECTED','ja','申請が却下されました。詳細は加盟店にお問い合わせください'),
('TECHNICIAN_AUDIT_REJECTED','ko','신청이 거부되었습니다. 가맹점에 문의하세요'),

-- ── TECHNICIAN_BANNED ────────────────────────────────────────────────────────
('TECHNICIAN_BANNED','zh','账号已被停用，请联系商户处理'),
('TECHNICIAN_BANNED','en','Your account has been suspended, please contact the merchant'),
('TECHNICIAN_BANNED','vi','Tài khoản của bạn đã bị đình chỉ, vui lòng liên hệ đối tác'),
('TECHNICIAN_BANNED','km','គណនីរបស់អ្នកត្រូវបានផ្អាក សូមទំនាក់ទំនងឈ្មួញ'),
('TECHNICIAN_BANNED','ja','アカウントが停止されました。加盟店にお問い合わせください'),
('TECHNICIAN_BANNED','ko','계정이 정지되었습니다. 가맹점에 문의하세요'),

-- ── TECHNICIAN_MOBILE_EXISTS ─────────────────────────────────────────────────
('TECHNICIAN_MOBILE_EXISTS','zh','该手机号已注册，请直接登录'),
('TECHNICIAN_MOBILE_EXISTS','en','This mobile number is already registered, please log in directly'),
('TECHNICIAN_MOBILE_EXISTS','vi','Số điện thoại này đã được đăng ký, vui lòng đăng nhập trực tiếp'),
('TECHNICIAN_MOBILE_EXISTS','km','លេខទូរស័ព្ទនេះបានចុះឈ្មោះហើយ សូមចូលដោយផ្ទាល់'),
('TECHNICIAN_MOBILE_EXISTS','ja','この携帯番号はすでに登録されています。直接ログインしてください'),
('TECHNICIAN_MOBILE_EXISTS','ko','이 휴대폰 번호는 이미 등록되어 있습니다. 직접 로그인하세요'),

-- ── MERCHANT_NO_INVALID ──────────────────────────────────────────────────────
('MERCHANT_NO_INVALID','zh','商户编号无效或商户审核未通过，请核实后重试'),
('MERCHANT_NO_INVALID','en','Invalid merchant code or merchant not approved, please verify and retry'),
('MERCHANT_NO_INVALID','vi','Mã đối tác không hợp lệ hoặc chưa được phê duyệt'),
('MERCHANT_NO_INVALID','km','លេខកូដឈ្មួញមិនត្រឹមត្រូវ ឬឈ្មួញមិនទាន់ដំណើរការ'),
('MERCHANT_NO_INVALID','ja','加盟店コードが無効か、加盟店が承認されていません'),
('MERCHANT_NO_INVALID','ko','가맹점 코드가 유효하지 않거나 승인되지 않았습니다'),

-- ── DATA_DUPLICATE ───────────────────────────────────────────────────────────
('DATA_DUPLICATE','zh','数据已存在，请勿重复提交'),
('DATA_DUPLICATE','en','Data already exists, please do not submit again'),
('DATA_DUPLICATE','vi','Dữ liệu đã tồn tại, vui lòng không gửi lại'),
('DATA_DUPLICATE','km','ទិន្នន័យមានស្រាប់ សូមមិនបញ្ជូនម្ដងទៀត'),
('DATA_DUPLICATE','ja','データが既に存在します。再送信しないでください'),
('DATA_DUPLICATE','ko','데이터가 이미 존재합니다. 다시 제출하지 마세요'),

-- ── MISSING_PARAM ────────────────────────────────────────────────────────────
('MISSING_PARAM','zh','缺少必要请求参数，请检查后重试'),
('MISSING_PARAM','en','Missing required request parameter, please check and retry'),
('MISSING_PARAM','vi','Thiếu tham số yêu cầu bắt buộc, vui lòng kiểm tra lại'),
('MISSING_PARAM','km','ខ្វះប៉ារ៉ាម៉ែត្រស្នើសុំដែលតម្រូវ'),
('MISSING_PARAM','ja','必須リクエストパラメータが不足しています'),
('MISSING_PARAM','ko','필수 요청 매개변수가 누락되었습니다'),

-- ── METHOD_NOT_ALLOWED ───────────────────────────────────────────────────────
('METHOD_NOT_ALLOWED','zh','请求方式不支持，请使用正确的 HTTP 方法'),
('METHOD_NOT_ALLOWED','en','HTTP method not supported, please use the correct method'),
('METHOD_NOT_ALLOWED','vi','Phương thức HTTP không được hỗ trợ'),
('METHOD_NOT_ALLOWED','km','វិធីសាស្ត្រ HTTP មិនត្រូវបានគាំទ្រ'),
('METHOD_NOT_ALLOWED','ja','HTTPメソッドはサポートされていません'),
('METHOD_NOT_ALLOWED','ko','HTTP 메서드가 지원되지 않습니다')

AS new_vals(enum_code, lang, message)
ON DUPLICATE KEY UPDATE message = new_vals.message;

-- ── migrate_v5_1.sql ─────────────────────────────────────────────────────────
-- ============================================================
-- migrate_v5_1.sql  技师端登录状态消息补全
--
-- 补充内容：
--   1. TECHNICIAN_NOT_FOUND     —— 技师账号/密码错误（账号不存在 & 密码错误统一消息，防枚举）
--   2. TECHNICIAN_AUDIT_PENDING —— 账号待审核
--
-- 使用 ON DUPLICATE KEY UPDATE 保证脚本幂等（重复执行不报错）
-- ============================================================

INSERT INTO `sys_i18n` (`enum_code`, `lang`, `message`) VALUES

-- ── TECHNICIAN_NOT_FOUND（账号不存在 或 密码错误，统一提示防枚举攻击）───────────
('TECHNICIAN_NOT_FOUND','zh','账号或密码错误，请重新输入'),
('TECHNICIAN_NOT_FOUND','en','Incorrect account or password, please try again'),
('TECHNICIAN_NOT_FOUND','vi','Tài khoản hoặc mật khẩu không đúng, vui lòng thử lại'),
('TECHNICIAN_NOT_FOUND','km','គណនី ឬលេខសម្ងាត់មិនត្រឹមត្រូវ សូមព្យាយាមម្ដងទៀត'),
('TECHNICIAN_NOT_FOUND','ja','アカウントまたはパスワードが正しくありません。再度入力してください'),
('TECHNICIAN_NOT_FOUND','ko','계정 또는 비밀번호가 올바르지 않습니다. 다시 입력해 주세요'),

-- ── TECHNICIAN_AUDIT_PENDING（注册后等待商户审核）────────────────────────────────
('TECHNICIAN_AUDIT_PENDING','zh','账号正在审核中，请耐心等待商户审核通过后再登录'),
('TECHNICIAN_AUDIT_PENDING','en','Your account is under review, please wait for merchant approval before logging in'),
('TECHNICIAN_AUDIT_PENDING','vi','Tài khoản đang được xem xét, vui lòng chờ đối tác phê duyệt trước khi đăng nhập'),
('TECHNICIAN_AUDIT_PENDING','km','គណនីរបស់អ្នកកំពុងត្រូវបានពិនិត្យ សូមរង់ចាំការអនុម័តពីឈ្មួញ'),
('TECHNICIAN_AUDIT_PENDING','ja','アカウントは審査中です。加盟店の承認後にログインしてください'),
('TECHNICIAN_AUDIT_PENDING','ko','계정이 심사 중입니다. 가맹점 승인 후 로그인해 주세요')

AS new_vals(enum_code, lang, message)
ON DUPLICATE KEY UPDATE message = new_vals.message;

-- ── migrate_v5_2.sql ─────────────────────────────────────────────────────────
-- 版本：v5.2  时区安全改造：所有 DATETIME 列迁移为 BIGINT（UTC 秒级时间戳）
--
-- 每列四步，全部由 information_schema 守护（双重条件），完全幂等，兼容 MySQL 5.7+
--
--   A. ADD  _ts │ 原列=datetime  AND  _ts 不存在
--   B. UPDATE   │ _ts 存在       AND  原列=datetime   ← 防止对已迁移 BIGINT 执行 UNIX_TIMESTAMP
--   C. DROP 原列 │ _ts 存在       AND  原列=datetime
--   D. CHANGE   │ _ts 存在       AND  原列不是 bigint  ← 防止 Duplicate column name
--
SET NAMES utf8mb4;
SET SESSION time_zone = '+00:00';

-- ===== sys_i18n =====
SET @p1=IF((SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_i18n' AND COLUMN_NAME='create_time')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_i18n' AND COLUMN_NAME='create_time_ts')=0,'ALTER TABLE `sys_i18n` ADD COLUMN `create_time_ts` BIGINT NOT NULL DEFAULT 0 COMMENT ''tmp'' AFTER `create_time`','SELECT 1');
PREPARE s1 FROM @p1;EXECUTE s1;DEALLOCATE PREPARE s1;
SET @p2=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_i18n' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_i18n' AND COLUMN_NAME='create_time')='datetime','UPDATE `sys_i18n` SET `create_time_ts`=UNIX_TIMESTAMP(`create_time`)','SELECT 1');
PREPARE s2 FROM @p2;EXECUTE s2;DEALLOCATE PREPARE s2;
SET @p3=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_i18n' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_i18n' AND COLUMN_NAME='create_time')='datetime','ALTER TABLE `sys_i18n` DROP COLUMN `create_time`','SELECT 1');
PREPARE s3 FROM @p3;EXECUTE s3;DEALLOCATE PREPARE s3;
SET @p4=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_i18n' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_i18n' AND COLUMN_NAME='create_time')!='bigint','ALTER TABLE `sys_i18n` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''创建时间，自动填充（UTC 秒级时间戳）''','SELECT 1');
PREPARE s4 FROM @p4;EXECUTE s4;DEALLOCATE PREPARE s4;
SET @p5=IF((SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_i18n' AND COLUMN_NAME='update_time')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_i18n' AND COLUMN_NAME='update_time_ts')=0,'ALTER TABLE `sys_i18n` ADD COLUMN `update_time_ts` BIGINT NOT NULL DEFAULT 0 COMMENT ''tmp'' AFTER `update_time`','SELECT 1');
PREPARE s5 FROM @p5;EXECUTE s5;DEALLOCATE PREPARE s5;
SET @p6=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_i18n' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_i18n' AND COLUMN_NAME='update_time')='datetime','UPDATE `sys_i18n` SET `update_time_ts`=UNIX_TIMESTAMP(`update_time`)','SELECT 1');
PREPARE s6 FROM @p6;EXECUTE s6;DEALLOCATE PREPARE s6;
SET @p7=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_i18n' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_i18n' AND COLUMN_NAME='update_time')='datetime','ALTER TABLE `sys_i18n` DROP COLUMN `update_time`','SELECT 1');
PREPARE s7 FROM @p7;EXECUTE s7;DEALLOCATE PREPARE s7;
SET @p8=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_i18n' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_i18n' AND COLUMN_NAME='update_time')!='bigint','ALTER TABLE `sys_i18n` CHANGE COLUMN `update_time_ts` `update_time` BIGINT NOT NULL COMMENT ''最后修改时间，自动更新（UTC 秒级时间戳）''','SELECT 1');
PREPARE s8 FROM @p8;EXECUTE s8;DEALLOCATE PREPARE s8;

-- ===== sys_dict_type =====
SET @p9=IF((SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_dict_type' AND COLUMN_NAME='create_time')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_dict_type' AND COLUMN_NAME='create_time_ts')=0,'ALTER TABLE `sys_dict_type` ADD COLUMN `create_time_ts` BIGINT NOT NULL DEFAULT 0 COMMENT ''tmp'' AFTER `create_time`','SELECT 1');
PREPARE s9 FROM @p9;EXECUTE s9;DEALLOCATE PREPARE s9;
SET @p10=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_dict_type' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_dict_type' AND COLUMN_NAME='create_time')='datetime','UPDATE `sys_dict_type` SET `create_time_ts`=UNIX_TIMESTAMP(`create_time`)','SELECT 1');
PREPARE s10 FROM @p10;EXECUTE s10;DEALLOCATE PREPARE s10;
SET @p11=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_dict_type' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_dict_type' AND COLUMN_NAME='create_time')='datetime','ALTER TABLE `sys_dict_type` DROP COLUMN `create_time`','SELECT 1');
PREPARE s11 FROM @p11;EXECUTE s11;DEALLOCATE PREPARE s11;
SET @p12=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_dict_type' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_dict_type' AND COLUMN_NAME='create_time')!='bigint','ALTER TABLE `sys_dict_type` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''创建时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE s12 FROM @p12;EXECUTE s12;DEALLOCATE PREPARE s12;
SET @p13=IF((SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_dict_type' AND COLUMN_NAME='update_time')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_dict_type' AND COLUMN_NAME='update_time_ts')=0,'ALTER TABLE `sys_dict_type` ADD COLUMN `update_time_ts` BIGINT NOT NULL DEFAULT 0 COMMENT ''tmp'' AFTER `update_time`','SELECT 1');
PREPARE s13 FROM @p13;EXECUTE s13;DEALLOCATE PREPARE s13;
SET @p14=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_dict_type' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_dict_type' AND COLUMN_NAME='update_time')='datetime','UPDATE `sys_dict_type` SET `update_time_ts`=UNIX_TIMESTAMP(`update_time`)','SELECT 1');
PREPARE s14 FROM @p14;EXECUTE s14;DEALLOCATE PREPARE s14;
SET @p15=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_dict_type' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_dict_type' AND COLUMN_NAME='update_time')='datetime','ALTER TABLE `sys_dict_type` DROP COLUMN `update_time`','SELECT 1');
PREPARE s15 FROM @p15;EXECUTE s15;DEALLOCATE PREPARE s15;
SET @p16=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_dict_type' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_dict_type' AND COLUMN_NAME='update_time')!='bigint','ALTER TABLE `sys_dict_type` CHANGE COLUMN `update_time_ts` `update_time` BIGINT NOT NULL COMMENT ''最后修改时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE s16 FROM @p16;EXECUTE s16;DEALLOCATE PREPARE s16;

-- ===== sys_dict =====
SET @p17=IF((SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_dict' AND COLUMN_NAME='create_time')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_dict' AND COLUMN_NAME='create_time_ts')=0,'ALTER TABLE `sys_dict` ADD COLUMN `create_time_ts` BIGINT NOT NULL DEFAULT 0 COMMENT ''tmp'' AFTER `create_time`','SELECT 1');
PREPARE s17 FROM @p17;EXECUTE s17;DEALLOCATE PREPARE s17;
SET @p18=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_dict' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_dict' AND COLUMN_NAME='create_time')='datetime','UPDATE `sys_dict` SET `create_time_ts`=UNIX_TIMESTAMP(`create_time`)','SELECT 1');
PREPARE s18 FROM @p18;EXECUTE s18;DEALLOCATE PREPARE s18;
SET @p19=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_dict' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_dict' AND COLUMN_NAME='create_time')='datetime','ALTER TABLE `sys_dict` DROP COLUMN `create_time`','SELECT 1');
PREPARE s19 FROM @p19;EXECUTE s19;DEALLOCATE PREPARE s19;
SET @p20=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_dict' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_dict' AND COLUMN_NAME='create_time')!='bigint','ALTER TABLE `sys_dict` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''创建时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE s20 FROM @p20;EXECUTE s20;DEALLOCATE PREPARE s20;
SET @p21=IF((SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_dict' AND COLUMN_NAME='update_time')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_dict' AND COLUMN_NAME='update_time_ts')=0,'ALTER TABLE `sys_dict` ADD COLUMN `update_time_ts` BIGINT NOT NULL DEFAULT 0 COMMENT ''tmp'' AFTER `update_time`','SELECT 1');
PREPARE s21 FROM @p21;EXECUTE s21;DEALLOCATE PREPARE s21;
SET @p22=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_dict' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_dict' AND COLUMN_NAME='update_time')='datetime','UPDATE `sys_dict` SET `update_time_ts`=UNIX_TIMESTAMP(`update_time`)','SELECT 1');
PREPARE s22 FROM @p22;EXECUTE s22;DEALLOCATE PREPARE s22;
SET @p23=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_dict' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_dict' AND COLUMN_NAME='update_time')='datetime','ALTER TABLE `sys_dict` DROP COLUMN `update_time`','SELECT 1');
PREPARE s23 FROM @p23;EXECUTE s23;DEALLOCATE PREPARE s23;
SET @p24=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_dict' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_dict' AND COLUMN_NAME='update_time')!='bigint','ALTER TABLE `sys_dict` CHANGE COLUMN `update_time_ts` `update_time` BIGINT NOT NULL COMMENT ''最后修改时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE s24 FROM @p24;EXECUTE s24;DEALLOCATE PREPARE s24;

-- ===== sys_config =====
SET @p25=IF((SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_config' AND COLUMN_NAME='create_time')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_config' AND COLUMN_NAME='create_time_ts')=0,'ALTER TABLE `sys_config` ADD COLUMN `create_time_ts` BIGINT NOT NULL DEFAULT 0 COMMENT ''tmp'' AFTER `create_time`','SELECT 1');
PREPARE s25 FROM @p25;EXECUTE s25;DEALLOCATE PREPARE s25;
SET @p26=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_config' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_config' AND COLUMN_NAME='create_time')='datetime','UPDATE `sys_config` SET `create_time_ts`=UNIX_TIMESTAMP(`create_time`)','SELECT 1');
PREPARE s26 FROM @p26;EXECUTE s26;DEALLOCATE PREPARE s26;
SET @p27=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_config' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_config' AND COLUMN_NAME='create_time')='datetime','ALTER TABLE `sys_config` DROP COLUMN `create_time`','SELECT 1');
PREPARE s27 FROM @p27;EXECUTE s27;DEALLOCATE PREPARE s27;
SET @p28=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_config' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_config' AND COLUMN_NAME='create_time')!='bigint','ALTER TABLE `sys_config` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''创建时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE s28 FROM @p28;EXECUTE s28;DEALLOCATE PREPARE s28;
SET @p29=IF((SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_config' AND COLUMN_NAME='update_time')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_config' AND COLUMN_NAME='update_time_ts')=0,'ALTER TABLE `sys_config` ADD COLUMN `update_time_ts` BIGINT NOT NULL DEFAULT 0 COMMENT ''tmp'' AFTER `update_time`','SELECT 1');
PREPARE s29 FROM @p29;EXECUTE s29;DEALLOCATE PREPARE s29;
SET @p30=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_config' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_config' AND COLUMN_NAME='update_time')='datetime','UPDATE `sys_config` SET `update_time_ts`=UNIX_TIMESTAMP(`update_time`)','SELECT 1');
PREPARE s30 FROM @p30;EXECUTE s30;DEALLOCATE PREPARE s30;
SET @p31=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_config' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_config' AND COLUMN_NAME='update_time')='datetime','ALTER TABLE `sys_config` DROP COLUMN `update_time`','SELECT 1');
PREPARE s31 FROM @p31;EXECUTE s31;DEALLOCATE PREPARE s31;
SET @p32=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_config' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_config' AND COLUMN_NAME='update_time')!='bigint','ALTER TABLE `sys_config` CHANGE COLUMN `update_time_ts` `update_time` BIGINT NOT NULL COMMENT ''最后修改时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE s32 FROM @p32;EXECUTE s32;DEALLOCATE PREPARE s32;

-- ===== sys_user =====
SET @p33=IF((SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_user' AND COLUMN_NAME='last_login_time')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_user' AND COLUMN_NAME='last_login_time_ts')=0,'ALTER TABLE `sys_user` ADD COLUMN `last_login_time_ts` BIGINT NULL COMMENT ''tmp'' AFTER `last_login_time`','SELECT 1');
PREPARE s33 FROM @p33;EXECUTE s33;DEALLOCATE PREPARE s33;
SET @p34=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_user' AND COLUMN_NAME='last_login_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_user' AND COLUMN_NAME='last_login_time')='datetime','UPDATE `sys_user` SET `last_login_time_ts`=UNIX_TIMESTAMP(`last_login_time`) WHERE `last_login_time` IS NOT NULL','SELECT 1');
PREPARE s34 FROM @p34;EXECUTE s34;DEALLOCATE PREPARE s34;
SET @p35=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_user' AND COLUMN_NAME='last_login_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_user' AND COLUMN_NAME='last_login_time')='datetime','ALTER TABLE `sys_user` DROP COLUMN `last_login_time`','SELECT 1');
PREPARE s35 FROM @p35;EXECUTE s35;DEALLOCATE PREPARE s35;
SET @p36=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_user' AND COLUMN_NAME='last_login_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_user' AND COLUMN_NAME='last_login_time')!='bigint','ALTER TABLE `sys_user` CHANGE COLUMN `last_login_time_ts` `last_login_time` BIGINT NULL COMMENT ''最后一次登录时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE s36 FROM @p36;EXECUTE s36;DEALLOCATE PREPARE s36;
SET @p37=IF((SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_user' AND COLUMN_NAME='create_time')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_user' AND COLUMN_NAME='create_time_ts')=0,'ALTER TABLE `sys_user` ADD COLUMN `create_time_ts` BIGINT NOT NULL DEFAULT 0 COMMENT ''tmp'' AFTER `create_time`','SELECT 1');
PREPARE s37 FROM @p37;EXECUTE s37;DEALLOCATE PREPARE s37;
SET @p38=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_user' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_user' AND COLUMN_NAME='create_time')='datetime','UPDATE `sys_user` SET `create_time_ts`=UNIX_TIMESTAMP(`create_time`)','SELECT 1');
PREPARE s38 FROM @p38;EXECUTE s38;DEALLOCATE PREPARE s38;
SET @p39=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_user' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_user' AND COLUMN_NAME='create_time')='datetime','ALTER TABLE `sys_user` DROP COLUMN `create_time`','SELECT 1');
PREPARE s39 FROM @p39;EXECUTE s39;DEALLOCATE PREPARE s39;
SET @p40=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_user' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_user' AND COLUMN_NAME='create_time')!='bigint','ALTER TABLE `sys_user` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''账号创建时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE s40 FROM @p40;EXECUTE s40;DEALLOCATE PREPARE s40;
SET @p41=IF((SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_user' AND COLUMN_NAME='update_time')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_user' AND COLUMN_NAME='update_time_ts')=0,'ALTER TABLE `sys_user` ADD COLUMN `update_time_ts` BIGINT NOT NULL DEFAULT 0 COMMENT ''tmp'' AFTER `update_time`','SELECT 1');
PREPARE s41 FROM @p41;EXECUTE s41;DEALLOCATE PREPARE s41;
SET @p42=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_user' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_user' AND COLUMN_NAME='update_time')='datetime','UPDATE `sys_user` SET `update_time_ts`=UNIX_TIMESTAMP(`update_time`)','SELECT 1');
PREPARE s42 FROM @p42;EXECUTE s42;DEALLOCATE PREPARE s42;
SET @p43=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_user' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_user' AND COLUMN_NAME='update_time')='datetime','ALTER TABLE `sys_user` DROP COLUMN `update_time`','SELECT 1');
PREPARE s43 FROM @p43;EXECUTE s43;DEALLOCATE PREPARE s43;
SET @p44=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_user' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_user' AND COLUMN_NAME='update_time')!='bigint','ALTER TABLE `sys_user` CHANGE COLUMN `update_time_ts` `update_time` BIGINT NOT NULL COMMENT ''最后修改时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE s44 FROM @p44;EXECUTE s44;DEALLOCATE PREPARE s44;

-- ===== sys_role =====
SET @p45=IF((SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_role' AND COLUMN_NAME='create_time')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_role' AND COLUMN_NAME='create_time_ts')=0,'ALTER TABLE `sys_role` ADD COLUMN `create_time_ts` BIGINT NOT NULL DEFAULT 0 COMMENT ''tmp'' AFTER `create_time`','SELECT 1');
PREPARE s45 FROM @p45;EXECUTE s45;DEALLOCATE PREPARE s45;
SET @p46=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_role' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_role' AND COLUMN_NAME='create_time')='datetime','UPDATE `sys_role` SET `create_time_ts`=UNIX_TIMESTAMP(`create_time`)','SELECT 1');
PREPARE s46 FROM @p46;EXECUTE s46;DEALLOCATE PREPARE s46;
SET @p47=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_role' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_role' AND COLUMN_NAME='create_time')='datetime','ALTER TABLE `sys_role` DROP COLUMN `create_time`','SELECT 1');
PREPARE s47 FROM @p47;EXECUTE s47;DEALLOCATE PREPARE s47;
SET @p48=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_role' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_role' AND COLUMN_NAME='create_time')!='bigint','ALTER TABLE `sys_role` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''创建时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE s48 FROM @p48;EXECUTE s48;DEALLOCATE PREPARE s48;
SET @p49=IF((SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_role' AND COLUMN_NAME='update_time')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_role' AND COLUMN_NAME='update_time_ts')=0,'ALTER TABLE `sys_role` ADD COLUMN `update_time_ts` BIGINT NOT NULL DEFAULT 0 COMMENT ''tmp'' AFTER `update_time`','SELECT 1');
PREPARE s49 FROM @p49;EXECUTE s49;DEALLOCATE PREPARE s49;
SET @p50=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_role' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_role' AND COLUMN_NAME='update_time')='datetime','UPDATE `sys_role` SET `update_time_ts`=UNIX_TIMESTAMP(`update_time`)','SELECT 1');
PREPARE s50 FROM @p50;EXECUTE s50;DEALLOCATE PREPARE s50;
SET @p51=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_role' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_role' AND COLUMN_NAME='update_time')='datetime','ALTER TABLE `sys_role` DROP COLUMN `update_time`','SELECT 1');
PREPARE s51 FROM @p51;EXECUTE s51;DEALLOCATE PREPARE s51;
SET @p52=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_role' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_role' AND COLUMN_NAME='update_time')!='bigint','ALTER TABLE `sys_role` CHANGE COLUMN `update_time_ts` `update_time` BIGINT NOT NULL COMMENT ''最后修改时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE s52 FROM @p52;EXECUTE s52;DEALLOCATE PREPARE s52;

-- ===== sys_permission =====
SET @p53=IF((SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_permission' AND COLUMN_NAME='create_time')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_permission' AND COLUMN_NAME='create_time_ts')=0,'ALTER TABLE `sys_permission` ADD COLUMN `create_time_ts` BIGINT NOT NULL DEFAULT 0 COMMENT ''tmp'' AFTER `create_time`','SELECT 1');
PREPARE s53 FROM @p53;EXECUTE s53;DEALLOCATE PREPARE s53;
SET @p54=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_permission' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_permission' AND COLUMN_NAME='create_time')='datetime','UPDATE `sys_permission` SET `create_time_ts`=UNIX_TIMESTAMP(`create_time`)','SELECT 1');
PREPARE s54 FROM @p54;EXECUTE s54;DEALLOCATE PREPARE s54;
SET @p55=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_permission' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_permission' AND COLUMN_NAME='create_time')='datetime','ALTER TABLE `sys_permission` DROP COLUMN `create_time`','SELECT 1');
PREPARE s55 FROM @p55;EXECUTE s55;DEALLOCATE PREPARE s55;
SET @p56=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_permission' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_permission' AND COLUMN_NAME='create_time')!='bigint','ALTER TABLE `sys_permission` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''创建时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE s56 FROM @p56;EXECUTE s56;DEALLOCATE PREPARE s56;
SET @p57=IF((SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_permission' AND COLUMN_NAME='update_time')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_permission' AND COLUMN_NAME='update_time_ts')=0,'ALTER TABLE `sys_permission` ADD COLUMN `update_time_ts` BIGINT NOT NULL DEFAULT 0 COMMENT ''tmp'' AFTER `update_time`','SELECT 1');
PREPARE s57 FROM @p57;EXECUTE s57;DEALLOCATE PREPARE s57;
SET @p58=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_permission' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_permission' AND COLUMN_NAME='update_time')='datetime','UPDATE `sys_permission` SET `update_time_ts`=UNIX_TIMESTAMP(`update_time`)','SELECT 1');
PREPARE s58 FROM @p58;EXECUTE s58;DEALLOCATE PREPARE s58;
SET @p59=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_permission' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_permission' AND COLUMN_NAME='update_time')='datetime','ALTER TABLE `sys_permission` DROP COLUMN `update_time`','SELECT 1');
PREPARE s59 FROM @p59;EXECUTE s59;DEALLOCATE PREPARE s59;
SET @p60=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_permission' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_permission' AND COLUMN_NAME='update_time')!='bigint','ALTER TABLE `sys_permission` CHANGE COLUMN `update_time_ts` `update_time` BIGINT NOT NULL COMMENT ''最后修改时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE s60 FROM @p60;EXECUTE s60;DEALLOCATE PREPARE s60;

-- ===== sys_operation_log =====
SET @p61=IF((SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_operation_log' AND COLUMN_NAME='create_time')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_operation_log' AND COLUMN_NAME='create_time_ts')=0,'ALTER TABLE `sys_operation_log` ADD COLUMN `create_time_ts` BIGINT NOT NULL DEFAULT 0 COMMENT ''tmp'' AFTER `create_time`','SELECT 1');
PREPARE s61 FROM @p61;EXECUTE s61;DEALLOCATE PREPARE s61;
SET @p62=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_operation_log' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_operation_log' AND COLUMN_NAME='create_time')='datetime','UPDATE `sys_operation_log` SET `create_time_ts`=UNIX_TIMESTAMP(`create_time`)','SELECT 1');
PREPARE s62 FROM @p62;EXECUTE s62;DEALLOCATE PREPARE s62;
SET @p63=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_operation_log' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_operation_log' AND COLUMN_NAME='create_time')='datetime','ALTER TABLE `sys_operation_log` DROP COLUMN `create_time`','SELECT 1');
PREPARE s63 FROM @p63;EXECUTE s63;DEALLOCATE PREPARE s63;
SET @p64=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_operation_log' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_operation_log' AND COLUMN_NAME='create_time')!='bigint','ALTER TABLE `sys_operation_log` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''操作发生时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE s64 FROM @p64;EXECUTE s64;DEALLOCATE PREPARE s64;

-- ===== cb_member =====
SET @p65=IF((SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_member' AND COLUMN_NAME='register_time')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_member' AND COLUMN_NAME='register_time_ts')=0,'ALTER TABLE `cb_member` ADD COLUMN `register_time_ts` BIGINT NOT NULL DEFAULT 0 COMMENT ''tmp'' AFTER `register_time`','SELECT 1');
PREPARE s65 FROM @p65;EXECUTE s65;DEALLOCATE PREPARE s65;
SET @p66=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_member' AND COLUMN_NAME='register_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_member' AND COLUMN_NAME='register_time')='datetime','UPDATE `cb_member` SET `register_time_ts`=UNIX_TIMESTAMP(`register_time`)','SELECT 1');
PREPARE s66 FROM @p66;EXECUTE s66;DEALLOCATE PREPARE s66;
SET @p67=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_member' AND COLUMN_NAME='register_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_member' AND COLUMN_NAME='register_time')='datetime','ALTER TABLE `cb_member` DROP COLUMN `register_time`','SELECT 1');
PREPARE s67 FROM @p67;EXECUTE s67;DEALLOCATE PREPARE s67;
SET @p68=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_member' AND COLUMN_NAME='register_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_member' AND COLUMN_NAME='register_time')!='bigint','ALTER TABLE `cb_member` CHANGE COLUMN `register_time_ts` `register_time` BIGINT NOT NULL COMMENT ''注册时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE s68 FROM @p68;EXECUTE s68;DEALLOCATE PREPARE s68;
SET @p69=IF((SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_member' AND COLUMN_NAME='last_login_time')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_member' AND COLUMN_NAME='last_login_time_ts')=0,'ALTER TABLE `cb_member` ADD COLUMN `last_login_time_ts` BIGINT NULL COMMENT ''tmp'' AFTER `last_login_time`','SELECT 1');
PREPARE s69 FROM @p69;EXECUTE s69;DEALLOCATE PREPARE s69;
SET @p70=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_member' AND COLUMN_NAME='last_login_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_member' AND COLUMN_NAME='last_login_time')='datetime','UPDATE `cb_member` SET `last_login_time_ts`=UNIX_TIMESTAMP(`last_login_time`) WHERE `last_login_time` IS NOT NULL','SELECT 1');
PREPARE s70 FROM @p70;EXECUTE s70;DEALLOCATE PREPARE s70;
SET @p71=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_member' AND COLUMN_NAME='last_login_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_member' AND COLUMN_NAME='last_login_time')='datetime','ALTER TABLE `cb_member` DROP COLUMN `last_login_time`','SELECT 1');
PREPARE s71 FROM @p71;EXECUTE s71;DEALLOCATE PREPARE s71;
SET @p72=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_member' AND COLUMN_NAME='last_login_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_member' AND COLUMN_NAME='last_login_time')!='bigint','ALTER TABLE `cb_member` CHANGE COLUMN `last_login_time_ts` `last_login_time` BIGINT NULL COMMENT ''最后一次登录时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE s72 FROM @p72;EXECUTE s72;DEALLOCATE PREPARE s72;
SET @p73=IF((SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_member' AND COLUMN_NAME='create_time')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_member' AND COLUMN_NAME='create_time_ts')=0,'ALTER TABLE `cb_member` ADD COLUMN `create_time_ts` BIGINT NOT NULL DEFAULT 0 COMMENT ''tmp'' AFTER `create_time`','SELECT 1');
PREPARE s73 FROM @p73;EXECUTE s73;DEALLOCATE PREPARE s73;
SET @p74=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_member' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_member' AND COLUMN_NAME='create_time')='datetime','UPDATE `cb_member` SET `create_time_ts`=UNIX_TIMESTAMP(`create_time`)','SELECT 1');
PREPARE s74 FROM @p74;EXECUTE s74;DEALLOCATE PREPARE s74;
SET @p75=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_member' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_member' AND COLUMN_NAME='create_time')='datetime','ALTER TABLE `cb_member` DROP COLUMN `create_time`','SELECT 1');
PREPARE s75 FROM @p75;EXECUTE s75;DEALLOCATE PREPARE s75;
SET @p76=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_member' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_member' AND COLUMN_NAME='create_time')!='bigint','ALTER TABLE `cb_member` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''记录创建时间（同 register_time，由 MyBatis-Plus 自动填充）（UTC 秒级时间戳）''','SELECT 1');
PREPARE s76 FROM @p76;EXECUTE s76;DEALLOCATE PREPARE s76;
SET @p77=IF((SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_member' AND COLUMN_NAME='update_time')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_member' AND COLUMN_NAME='update_time_ts')=0,'ALTER TABLE `cb_member` ADD COLUMN `update_time_ts` BIGINT NOT NULL DEFAULT 0 COMMENT ''tmp'' AFTER `update_time`','SELECT 1');
PREPARE s77 FROM @p77;EXECUTE s77;DEALLOCATE PREPARE s77;
SET @p78=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_member' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_member' AND COLUMN_NAME='update_time')='datetime','UPDATE `cb_member` SET `update_time_ts`=UNIX_TIMESTAMP(`update_time`)','SELECT 1');
PREPARE s78 FROM @p78;EXECUTE s78;DEALLOCATE PREPARE s78;
SET @p79=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_member' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_member' AND COLUMN_NAME='update_time')='datetime','ALTER TABLE `cb_member` DROP COLUMN `update_time`','SELECT 1');
PREPARE s79 FROM @p79;EXECUTE s79;DEALLOCATE PREPARE s79;
SET @p80=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_member' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_member' AND COLUMN_NAME='update_time')!='bigint','ALTER TABLE `cb_member` CHANGE COLUMN `update_time_ts` `update_time` BIGINT NOT NULL COMMENT ''记录最后修改时间，自动更新（UTC 秒级时间戳）''','SELECT 1');
PREPARE s80 FROM @p80;EXECUTE s80;DEALLOCATE PREPARE s80;

-- ===== cb_technician =====
SET @p81=IF((SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician' AND COLUMN_NAME='create_time')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician' AND COLUMN_NAME='create_time_ts')=0,'ALTER TABLE `cb_technician` ADD COLUMN `create_time_ts` BIGINT NOT NULL DEFAULT 0 COMMENT ''tmp'' AFTER `create_time`','SELECT 1');
PREPARE s81 FROM @p81;EXECUTE s81;DEALLOCATE PREPARE s81;
SET @p82=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician' AND COLUMN_NAME='create_time')='datetime','UPDATE `cb_technician` SET `create_time_ts`=UNIX_TIMESTAMP(`create_time`)','SELECT 1');
PREPARE s82 FROM @p82;EXECUTE s82;DEALLOCATE PREPARE s82;
SET @p83=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician' AND COLUMN_NAME='create_time')='datetime','ALTER TABLE `cb_technician` DROP COLUMN `create_time`','SELECT 1');
PREPARE s83 FROM @p83;EXECUTE s83;DEALLOCATE PREPARE s83;
SET @p84=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician' AND COLUMN_NAME='create_time')!='bigint','ALTER TABLE `cb_technician` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''申请入驻时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE s84 FROM @p84;EXECUTE s84;DEALLOCATE PREPARE s84;
SET @p85=IF((SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician' AND COLUMN_NAME='update_time')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician' AND COLUMN_NAME='update_time_ts')=0,'ALTER TABLE `cb_technician` ADD COLUMN `update_time_ts` BIGINT NOT NULL DEFAULT 0 COMMENT ''tmp'' AFTER `update_time`','SELECT 1');
PREPARE s85 FROM @p85;EXECUTE s85;DEALLOCATE PREPARE s85;
SET @p86=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician' AND COLUMN_NAME='update_time')='datetime','UPDATE `cb_technician` SET `update_time_ts`=UNIX_TIMESTAMP(`update_time`)','SELECT 1');
PREPARE s86 FROM @p86;EXECUTE s86;DEALLOCATE PREPARE s86;
SET @p87=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician' AND COLUMN_NAME='update_time')='datetime','ALTER TABLE `cb_technician` DROP COLUMN `update_time`','SELECT 1');
PREPARE s87 FROM @p87;EXECUTE s87;DEALLOCATE PREPARE s87;
SET @p88=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician' AND COLUMN_NAME='update_time')!='bigint','ALTER TABLE `cb_technician` CHANGE COLUMN `update_time_ts` `update_time` BIGINT NOT NULL COMMENT ''最后修改时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE s88 FROM @p88;EXECUTE s88;DEALLOCATE PREPARE s88;

-- ===== cb_merchant =====
SET @p89=IF((SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_merchant' AND COLUMN_NAME='create_time')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_merchant' AND COLUMN_NAME='create_time_ts')=0,'ALTER TABLE `cb_merchant` ADD COLUMN `create_time_ts` BIGINT NOT NULL DEFAULT 0 COMMENT ''tmp'' AFTER `create_time`','SELECT 1');
PREPARE s89 FROM @p89;EXECUTE s89;DEALLOCATE PREPARE s89;
SET @p90=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_merchant' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_merchant' AND COLUMN_NAME='create_time')='datetime','UPDATE `cb_merchant` SET `create_time_ts`=UNIX_TIMESTAMP(`create_time`)','SELECT 1');
PREPARE s90 FROM @p90;EXECUTE s90;DEALLOCATE PREPARE s90;
SET @p91=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_merchant' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_merchant' AND COLUMN_NAME='create_time')='datetime','ALTER TABLE `cb_merchant` DROP COLUMN `create_time`','SELECT 1');
PREPARE s91 FROM @p91;EXECUTE s91;DEALLOCATE PREPARE s91;
SET @p92=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_merchant' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_merchant' AND COLUMN_NAME='create_time')!='bigint','ALTER TABLE `cb_merchant` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''入驻申请时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE s92 FROM @p92;EXECUTE s92;DEALLOCATE PREPARE s92;
SET @p93=IF((SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_merchant' AND COLUMN_NAME='update_time')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_merchant' AND COLUMN_NAME='update_time_ts')=0,'ALTER TABLE `cb_merchant` ADD COLUMN `update_time_ts` BIGINT NOT NULL DEFAULT 0 COMMENT ''tmp'' AFTER `update_time`','SELECT 1');
PREPARE s93 FROM @p93;EXECUTE s93;DEALLOCATE PREPARE s93;
SET @p94=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_merchant' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_merchant' AND COLUMN_NAME='update_time')='datetime','UPDATE `cb_merchant` SET `update_time_ts`=UNIX_TIMESTAMP(`update_time`)','SELECT 1');
PREPARE s94 FROM @p94;EXECUTE s94;DEALLOCATE PREPARE s94;
SET @p95=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_merchant' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_merchant' AND COLUMN_NAME='update_time')='datetime','ALTER TABLE `cb_merchant` DROP COLUMN `update_time`','SELECT 1');
PREPARE s95 FROM @p95;EXECUTE s95;DEALLOCATE PREPARE s95;
SET @p96=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_merchant' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_merchant' AND COLUMN_NAME='update_time')!='bigint','ALTER TABLE `cb_merchant` CHANGE COLUMN `update_time_ts` `update_time` BIGINT NOT NULL COMMENT ''最后修改时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE s96 FROM @p96;EXECUTE s96;DEALLOCATE PREPARE s96;

-- ===== cb_service_category =====
SET @p97=IF((SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_service_category' AND COLUMN_NAME='create_time')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_service_category' AND COLUMN_NAME='create_time_ts')=0,'ALTER TABLE `cb_service_category` ADD COLUMN `create_time_ts` BIGINT NOT NULL DEFAULT 0 COMMENT ''tmp'' AFTER `create_time`','SELECT 1');
PREPARE s97 FROM @p97;EXECUTE s97;DEALLOCATE PREPARE s97;
SET @p98=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_service_category' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_service_category' AND COLUMN_NAME='create_time')='datetime','UPDATE `cb_service_category` SET `create_time_ts`=UNIX_TIMESTAMP(`create_time`)','SELECT 1');
PREPARE s98 FROM @p98;EXECUTE s98;DEALLOCATE PREPARE s98;
SET @p99=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_service_category' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_service_category' AND COLUMN_NAME='create_time')='datetime','ALTER TABLE `cb_service_category` DROP COLUMN `create_time`','SELECT 1');
PREPARE s99 FROM @p99;EXECUTE s99;DEALLOCATE PREPARE s99;
SET @p100=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_service_category' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_service_category' AND COLUMN_NAME='create_time')!='bigint','ALTER TABLE `cb_service_category` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''创建时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE s100 FROM @p100;EXECUTE s100;DEALLOCATE PREPARE s100;
SET @p101=IF((SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_service_category' AND COLUMN_NAME='update_time')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_service_category' AND COLUMN_NAME='update_time_ts')=0,'ALTER TABLE `cb_service_category` ADD COLUMN `update_time_ts` BIGINT NOT NULL DEFAULT 0 COMMENT ''tmp'' AFTER `update_time`','SELECT 1');
PREPARE s101 FROM @p101;EXECUTE s101;DEALLOCATE PREPARE s101;
SET @p102=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_service_category' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_service_category' AND COLUMN_NAME='update_time')='datetime','UPDATE `cb_service_category` SET `update_time_ts`=UNIX_TIMESTAMP(`update_time`)','SELECT 1');
PREPARE s102 FROM @p102;EXECUTE s102;DEALLOCATE PREPARE s102;
SET @p103=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_service_category' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_service_category' AND COLUMN_NAME='update_time')='datetime','ALTER TABLE `cb_service_category` DROP COLUMN `update_time`','SELECT 1');
PREPARE s103 FROM @p103;EXECUTE s103;DEALLOCATE PREPARE s103;
SET @p104=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_service_category' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_service_category' AND COLUMN_NAME='update_time')!='bigint','ALTER TABLE `cb_service_category` CHANGE COLUMN `update_time_ts` `update_time` BIGINT NOT NULL COMMENT ''最后修改时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE s104 FROM @p104;EXECUTE s104;DEALLOCATE PREPARE s104;

-- ===== cb_service_item =====
SET @p105=IF((SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_service_item' AND COLUMN_NAME='create_time')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_service_item' AND COLUMN_NAME='create_time_ts')=0,'ALTER TABLE `cb_service_item` ADD COLUMN `create_time_ts` BIGINT NOT NULL DEFAULT 0 COMMENT ''tmp'' AFTER `create_time`','SELECT 1');
PREPARE s105 FROM @p105;EXECUTE s105;DEALLOCATE PREPARE s105;
SET @p106=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_service_item' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_service_item' AND COLUMN_NAME='create_time')='datetime','UPDATE `cb_service_item` SET `create_time_ts`=UNIX_TIMESTAMP(`create_time`)','SELECT 1');
PREPARE s106 FROM @p106;EXECUTE s106;DEALLOCATE PREPARE s106;
SET @p107=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_service_item' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_service_item' AND COLUMN_NAME='create_time')='datetime','ALTER TABLE `cb_service_item` DROP COLUMN `create_time`','SELECT 1');
PREPARE s107 FROM @p107;EXECUTE s107;DEALLOCATE PREPARE s107;
SET @p108=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_service_item' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_service_item' AND COLUMN_NAME='create_time')!='bigint','ALTER TABLE `cb_service_item` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''创建时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE s108 FROM @p108;EXECUTE s108;DEALLOCATE PREPARE s108;
SET @p109=IF((SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_service_item' AND COLUMN_NAME='update_time')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_service_item' AND COLUMN_NAME='update_time_ts')=0,'ALTER TABLE `cb_service_item` ADD COLUMN `update_time_ts` BIGINT NOT NULL DEFAULT 0 COMMENT ''tmp'' AFTER `update_time`','SELECT 1');
PREPARE s109 FROM @p109;EXECUTE s109;DEALLOCATE PREPARE s109;
SET @p110=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_service_item' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_service_item' AND COLUMN_NAME='update_time')='datetime','UPDATE `cb_service_item` SET `update_time_ts`=UNIX_TIMESTAMP(`update_time`)','SELECT 1');
PREPARE s110 FROM @p110;EXECUTE s110;DEALLOCATE PREPARE s110;
SET @p111=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_service_item' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_service_item' AND COLUMN_NAME='update_time')='datetime','ALTER TABLE `cb_service_item` DROP COLUMN `update_time`','SELECT 1');
PREPARE s111 FROM @p111;EXECUTE s111;DEALLOCATE PREPARE s111;
SET @p112=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_service_item' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_service_item' AND COLUMN_NAME='update_time')!='bigint','ALTER TABLE `cb_service_item` CHANGE COLUMN `update_time_ts` `update_time` BIGINT NOT NULL COMMENT ''最后修改时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE s112 FROM @p112;EXECUTE s112;DEALLOCATE PREPARE s112;

-- ===== cb_order =====
SET @p113=IF((SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order' AND COLUMN_NAME='appoint_time')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order' AND COLUMN_NAME='appoint_time_ts')=0,'ALTER TABLE `cb_order` ADD COLUMN `appoint_time_ts` BIGINT NOT NULL DEFAULT 0 COMMENT ''tmp'' AFTER `appoint_time`','SELECT 1');
PREPARE s113 FROM @p113;EXECUTE s113;DEALLOCATE PREPARE s113;
SET @p114=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order' AND COLUMN_NAME='appoint_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order' AND COLUMN_NAME='appoint_time')='datetime','UPDATE `cb_order` SET `appoint_time_ts`=UNIX_TIMESTAMP(`appoint_time`)','SELECT 1');
PREPARE s114 FROM @p114;EXECUTE s114;DEALLOCATE PREPARE s114;
SET @p115=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order' AND COLUMN_NAME='appoint_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order' AND COLUMN_NAME='appoint_time')='datetime','ALTER TABLE `cb_order` DROP COLUMN `appoint_time`','SELECT 1');
PREPARE s115 FROM @p115;EXECUTE s115;DEALLOCATE PREPARE s115;
SET @p116=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order' AND COLUMN_NAME='appoint_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order' AND COLUMN_NAME='appoint_time')!='bigint','ALTER TABLE `cb_order` CHANGE COLUMN `appoint_time_ts` `appoint_time` BIGINT NOT NULL COMMENT ''预约服务开始时间（会员选择的上门时间）（UTC 秒级时间戳）''','SELECT 1');
PREPARE s116 FROM @p116;EXECUTE s116;DEALLOCATE PREPARE s116;
SET @p117=IF((SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order' AND COLUMN_NAME='start_time')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order' AND COLUMN_NAME='start_time_ts')=0,'ALTER TABLE `cb_order` ADD COLUMN `start_time_ts` BIGINT NULL COMMENT ''tmp'' AFTER `start_time`','SELECT 1');
PREPARE s117 FROM @p117;EXECUTE s117;DEALLOCATE PREPARE s117;
SET @p118=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order' AND COLUMN_NAME='start_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order' AND COLUMN_NAME='start_time')='datetime','UPDATE `cb_order` SET `start_time_ts`=UNIX_TIMESTAMP(`start_time`) WHERE `start_time` IS NOT NULL','SELECT 1');
PREPARE s118 FROM @p118;EXECUTE s118;DEALLOCATE PREPARE s118;
SET @p119=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order' AND COLUMN_NAME='start_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order' AND COLUMN_NAME='start_time')='datetime','ALTER TABLE `cb_order` DROP COLUMN `start_time`','SELECT 1');
PREPARE s119 FROM @p119;EXECUTE s119;DEALLOCATE PREPARE s119;
SET @p120=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order' AND COLUMN_NAME='start_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order' AND COLUMN_NAME='start_time')!='bigint','ALTER TABLE `cb_order` CHANGE COLUMN `start_time_ts` `start_time` BIGINT NULL COMMENT ''实际开始服务时间（技师操作开始）（UTC 秒级时间戳）''','SELECT 1');
PREPARE s120 FROM @p120;EXECUTE s120;DEALLOCATE PREPARE s120;
SET @p121=IF((SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order' AND COLUMN_NAME='end_time')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order' AND COLUMN_NAME='end_time_ts')=0,'ALTER TABLE `cb_order` ADD COLUMN `end_time_ts` BIGINT NULL COMMENT ''tmp'' AFTER `end_time`','SELECT 1');
PREPARE s121 FROM @p121;EXECUTE s121;DEALLOCATE PREPARE s121;
SET @p122=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order' AND COLUMN_NAME='end_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order' AND COLUMN_NAME='end_time')='datetime','UPDATE `cb_order` SET `end_time_ts`=UNIX_TIMESTAMP(`end_time`) WHERE `end_time` IS NOT NULL','SELECT 1');
PREPARE s122 FROM @p122;EXECUTE s122;DEALLOCATE PREPARE s122;
SET @p123=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order' AND COLUMN_NAME='end_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order' AND COLUMN_NAME='end_time')='datetime','ALTER TABLE `cb_order` DROP COLUMN `end_time`','SELECT 1');
PREPARE s123 FROM @p123;EXECUTE s123;DEALLOCATE PREPARE s123;
SET @p124=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order' AND COLUMN_NAME='end_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order' AND COLUMN_NAME='end_time')!='bigint','ALTER TABLE `cb_order` CHANGE COLUMN `end_time_ts` `end_time` BIGINT NULL COMMENT ''实际结束服务时间（技师操作完成）（UTC 秒级时间戳）''','SELECT 1');
PREPARE s124 FROM @p124;EXECUTE s124;DEALLOCATE PREPARE s124;
SET @p125=IF((SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order' AND COLUMN_NAME='pay_time')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order' AND COLUMN_NAME='pay_time_ts')=0,'ALTER TABLE `cb_order` ADD COLUMN `pay_time_ts` BIGINT NULL COMMENT ''tmp'' AFTER `pay_time`','SELECT 1');
PREPARE s125 FROM @p125;EXECUTE s125;DEALLOCATE PREPARE s125;
SET @p126=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order' AND COLUMN_NAME='pay_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order' AND COLUMN_NAME='pay_time')='datetime','UPDATE `cb_order` SET `pay_time_ts`=UNIX_TIMESTAMP(`pay_time`) WHERE `pay_time` IS NOT NULL','SELECT 1');
PREPARE s126 FROM @p126;EXECUTE s126;DEALLOCATE PREPARE s126;
SET @p127=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order' AND COLUMN_NAME='pay_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order' AND COLUMN_NAME='pay_time')='datetime','ALTER TABLE `cb_order` DROP COLUMN `pay_time`','SELECT 1');
PREPARE s127 FROM @p127;EXECUTE s127;DEALLOCATE PREPARE s127;
SET @p128=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order' AND COLUMN_NAME='pay_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order' AND COLUMN_NAME='pay_time')!='bigint','ALTER TABLE `cb_order` CHANGE COLUMN `pay_time_ts` `pay_time` BIGINT NULL COMMENT ''实际支付完成时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE s128 FROM @p128;EXECUTE s128;DEALLOCATE PREPARE s128;
SET @p129=IF((SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order' AND COLUMN_NAME='create_time')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order' AND COLUMN_NAME='create_time_ts')=0,'ALTER TABLE `cb_order` ADD COLUMN `create_time_ts` BIGINT NOT NULL DEFAULT 0 COMMENT ''tmp'' AFTER `create_time`','SELECT 1');
PREPARE s129 FROM @p129;EXECUTE s129;DEALLOCATE PREPARE s129;
SET @p130=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order' AND COLUMN_NAME='create_time')='datetime','UPDATE `cb_order` SET `create_time_ts`=UNIX_TIMESTAMP(`create_time`)','SELECT 1');
PREPARE s130 FROM @p130;EXECUTE s130;DEALLOCATE PREPARE s130;
SET @p131=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order' AND COLUMN_NAME='create_time')='datetime','ALTER TABLE `cb_order` DROP COLUMN `create_time`','SELECT 1');
PREPARE s131 FROM @p131;EXECUTE s131;DEALLOCATE PREPARE s131;
SET @p132=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order' AND COLUMN_NAME='create_time')!='bigint','ALTER TABLE `cb_order` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''下单时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE s132 FROM @p132;EXECUTE s132;DEALLOCATE PREPARE s132;
SET @p133=IF((SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order' AND COLUMN_NAME='update_time')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order' AND COLUMN_NAME='update_time_ts')=0,'ALTER TABLE `cb_order` ADD COLUMN `update_time_ts` BIGINT NOT NULL DEFAULT 0 COMMENT ''tmp'' AFTER `update_time`','SELECT 1');
PREPARE s133 FROM @p133;EXECUTE s133;DEALLOCATE PREPARE s133;
SET @p134=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order' AND COLUMN_NAME='update_time')='datetime','UPDATE `cb_order` SET `update_time_ts`=UNIX_TIMESTAMP(`update_time`)','SELECT 1');
PREPARE s134 FROM @p134;EXECUTE s134;DEALLOCATE PREPARE s134;
SET @p135=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order' AND COLUMN_NAME='update_time')='datetime','ALTER TABLE `cb_order` DROP COLUMN `update_time`','SELECT 1');
PREPARE s135 FROM @p135;EXECUTE s135;DEALLOCATE PREPARE s135;
SET @p136=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order' AND COLUMN_NAME='update_time')!='bigint','ALTER TABLE `cb_order` CHANGE COLUMN `update_time_ts` `update_time` BIGINT NOT NULL COMMENT ''最后修改时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE s136 FROM @p136;EXECUTE s136;DEALLOCATE PREPARE s136;

-- ===== cb_review =====
SET @p137=IF((SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_review' AND COLUMN_NAME='reply_time')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_review' AND COLUMN_NAME='reply_time_ts')=0,'ALTER TABLE `cb_review` ADD COLUMN `reply_time_ts` BIGINT NULL COMMENT ''tmp'' AFTER `reply_time`','SELECT 1');
PREPARE s137 FROM @p137;EXECUTE s137;DEALLOCATE PREPARE s137;
SET @p138=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_review' AND COLUMN_NAME='reply_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_review' AND COLUMN_NAME='reply_time')='datetime','UPDATE `cb_review` SET `reply_time_ts`=UNIX_TIMESTAMP(`reply_time`) WHERE `reply_time` IS NOT NULL','SELECT 1');
PREPARE s138 FROM @p138;EXECUTE s138;DEALLOCATE PREPARE s138;
SET @p139=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_review' AND COLUMN_NAME='reply_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_review' AND COLUMN_NAME='reply_time')='datetime','ALTER TABLE `cb_review` DROP COLUMN `reply_time`','SELECT 1');
PREPARE s139 FROM @p139;EXECUTE s139;DEALLOCATE PREPARE s139;
SET @p140=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_review' AND COLUMN_NAME='reply_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_review' AND COLUMN_NAME='reply_time')!='bigint','ALTER TABLE `cb_review` CHANGE COLUMN `reply_time_ts` `reply_time` BIGINT NULL COMMENT ''技师回复时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE s140 FROM @p140;EXECUTE s140;DEALLOCATE PREPARE s140;
SET @p141=IF((SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_review' AND COLUMN_NAME='create_time')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_review' AND COLUMN_NAME='create_time_ts')=0,'ALTER TABLE `cb_review` ADD COLUMN `create_time_ts` BIGINT NOT NULL DEFAULT 0 COMMENT ''tmp'' AFTER `create_time`','SELECT 1');
PREPARE s141 FROM @p141;EXECUTE s141;DEALLOCATE PREPARE s141;
SET @p142=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_review' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_review' AND COLUMN_NAME='create_time')='datetime','UPDATE `cb_review` SET `create_time_ts`=UNIX_TIMESTAMP(`create_time`)','SELECT 1');
PREPARE s142 FROM @p142;EXECUTE s142;DEALLOCATE PREPARE s142;
SET @p143=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_review' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_review' AND COLUMN_NAME='create_time')='datetime','ALTER TABLE `cb_review` DROP COLUMN `create_time`','SELECT 1');
PREPARE s143 FROM @p143;EXECUTE s143;DEALLOCATE PREPARE s143;
SET @p144=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_review' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_review' AND COLUMN_NAME='create_time')!='bigint','ALTER TABLE `cb_review` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''评价发布时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE s144 FROM @p144;EXECUTE s144;DEALLOCATE PREPARE s144;
SET @p145=IF((SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_review' AND COLUMN_NAME='update_time')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_review' AND COLUMN_NAME='update_time_ts')=0,'ALTER TABLE `cb_review` ADD COLUMN `update_time_ts` BIGINT NOT NULL DEFAULT 0 COMMENT ''tmp'' AFTER `update_time`','SELECT 1');
PREPARE s145 FROM @p145;EXECUTE s145;DEALLOCATE PREPARE s145;
SET @p146=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_review' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_review' AND COLUMN_NAME='update_time')='datetime','UPDATE `cb_review` SET `update_time_ts`=UNIX_TIMESTAMP(`update_time`)','SELECT 1');
PREPARE s146 FROM @p146;EXECUTE s146;DEALLOCATE PREPARE s146;
SET @p147=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_review' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_review' AND COLUMN_NAME='update_time')='datetime','ALTER TABLE `cb_review` DROP COLUMN `update_time`','SELECT 1');
PREPARE s147 FROM @p147;EXECUTE s147;DEALLOCATE PREPARE s147;
SET @p148=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_review' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_review' AND COLUMN_NAME='update_time')!='bigint','ALTER TABLE `cb_review` CHANGE COLUMN `update_time_ts` `update_time` BIGINT NOT NULL COMMENT ''最后修改时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE s148 FROM @p148;EXECUTE s148;DEALLOCATE PREPARE s148;

-- ===== cb_payment =====
SET @p149=IF((SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_payment' AND COLUMN_NAME='refund_time')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_payment' AND COLUMN_NAME='refund_time_ts')=0,'ALTER TABLE `cb_payment` ADD COLUMN `refund_time_ts` BIGINT NULL COMMENT ''tmp'' AFTER `refund_time`','SELECT 1');
PREPARE s149 FROM @p149;EXECUTE s149;DEALLOCATE PREPARE s149;
SET @p150=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_payment' AND COLUMN_NAME='refund_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_payment' AND COLUMN_NAME='refund_time')='datetime','UPDATE `cb_payment` SET `refund_time_ts`=UNIX_TIMESTAMP(`refund_time`) WHERE `refund_time` IS NOT NULL','SELECT 1');
PREPARE s150 FROM @p150;EXECUTE s150;DEALLOCATE PREPARE s150;
SET @p151=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_payment' AND COLUMN_NAME='refund_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_payment' AND COLUMN_NAME='refund_time')='datetime','ALTER TABLE `cb_payment` DROP COLUMN `refund_time`','SELECT 1');
PREPARE s151 FROM @p151;EXECUTE s151;DEALLOCATE PREPARE s151;
SET @p152=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_payment' AND COLUMN_NAME='refund_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_payment' AND COLUMN_NAME='refund_time')!='bigint','ALTER TABLE `cb_payment` CHANGE COLUMN `refund_time_ts` `refund_time` BIGINT NULL COMMENT ''退款完成时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE s152 FROM @p152;EXECUTE s152;DEALLOCATE PREPARE s152;
SET @p153=IF((SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_payment' AND COLUMN_NAME='create_time')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_payment' AND COLUMN_NAME='create_time_ts')=0,'ALTER TABLE `cb_payment` ADD COLUMN `create_time_ts` BIGINT NOT NULL DEFAULT 0 COMMENT ''tmp'' AFTER `create_time`','SELECT 1');
PREPARE s153 FROM @p153;EXECUTE s153;DEALLOCATE PREPARE s153;
SET @p154=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_payment' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_payment' AND COLUMN_NAME='create_time')='datetime','UPDATE `cb_payment` SET `create_time_ts`=UNIX_TIMESTAMP(`create_time`)','SELECT 1');
PREPARE s154 FROM @p154;EXECUTE s154;DEALLOCATE PREPARE s154;
SET @p155=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_payment' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_payment' AND COLUMN_NAME='create_time')='datetime','ALTER TABLE `cb_payment` DROP COLUMN `create_time`','SELECT 1');
PREPARE s155 FROM @p155;EXECUTE s155;DEALLOCATE PREPARE s155;
SET @p156=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_payment' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_payment' AND COLUMN_NAME='create_time')!='bigint','ALTER TABLE `cb_payment` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''支付记录创建时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE s156 FROM @p156;EXECUTE s156;DEALLOCATE PREPARE s156;
SET @p157=IF((SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_payment' AND COLUMN_NAME='update_time')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_payment' AND COLUMN_NAME='update_time_ts')=0,'ALTER TABLE `cb_payment` ADD COLUMN `update_time_ts` BIGINT NOT NULL DEFAULT 0 COMMENT ''tmp'' AFTER `update_time`','SELECT 1');
PREPARE s157 FROM @p157;EXECUTE s157;DEALLOCATE PREPARE s157;
SET @p158=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_payment' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_payment' AND COLUMN_NAME='update_time')='datetime','UPDATE `cb_payment` SET `update_time_ts`=UNIX_TIMESTAMP(`update_time`)','SELECT 1');
PREPARE s158 FROM @p158;EXECUTE s158;DEALLOCATE PREPARE s158;
SET @p159=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_payment' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_payment' AND COLUMN_NAME='update_time')='datetime','ALTER TABLE `cb_payment` DROP COLUMN `update_time`','SELECT 1');
PREPARE s159 FROM @p159;EXECUTE s159;DEALLOCATE PREPARE s159;
SET @p160=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_payment' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_payment' AND COLUMN_NAME='update_time')!='bigint','ALTER TABLE `cb_payment` CHANGE COLUMN `update_time_ts` `update_time` BIGINT NOT NULL COMMENT ''最后修改时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE s160 FROM @p160;EXECUTE s160;DEALLOCATE PREPARE s160;

-- ===== cb_wallet =====
SET @p161=IF((SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_wallet' AND COLUMN_NAME='created_at')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_wallet' AND COLUMN_NAME='created_at_ts')=0,'ALTER TABLE `cb_wallet` ADD COLUMN `created_at_ts` BIGINT NOT NULL DEFAULT 0 COMMENT ''tmp'' AFTER `created_at`','SELECT 1');
PREPARE s161 FROM @p161;EXECUTE s161;DEALLOCATE PREPARE s161;
SET @p162=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_wallet' AND COLUMN_NAME='created_at_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_wallet' AND COLUMN_NAME='created_at')='datetime','UPDATE `cb_wallet` SET `created_at_ts`=UNIX_TIMESTAMP(`created_at`)','SELECT 1');
PREPARE s162 FROM @p162;EXECUTE s162;DEALLOCATE PREPARE s162;
SET @p163=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_wallet' AND COLUMN_NAME='created_at_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_wallet' AND COLUMN_NAME='created_at')='datetime','ALTER TABLE `cb_wallet` DROP COLUMN `created_at`','SELECT 1');
PREPARE s163 FROM @p163;EXECUTE s163;DEALLOCATE PREPARE s163;
SET @p164=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_wallet' AND COLUMN_NAME='created_at_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_wallet' AND COLUMN_NAME='created_at')!='bigint','ALTER TABLE `cb_wallet` CHANGE COLUMN `created_at_ts` `created_at` BIGINT NOT NULL COMMENT ''创建时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE s164 FROM @p164;EXECUTE s164;DEALLOCATE PREPARE s164;
SET @p165=IF((SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_wallet' AND COLUMN_NAME='updated_at')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_wallet' AND COLUMN_NAME='updated_at_ts')=0,'ALTER TABLE `cb_wallet` ADD COLUMN `updated_at_ts` BIGINT NOT NULL DEFAULT 0 COMMENT ''tmp'' AFTER `updated_at`','SELECT 1');
PREPARE s165 FROM @p165;EXECUTE s165;DEALLOCATE PREPARE s165;
SET @p166=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_wallet' AND COLUMN_NAME='updated_at_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_wallet' AND COLUMN_NAME='updated_at')='datetime','UPDATE `cb_wallet` SET `updated_at_ts`=UNIX_TIMESTAMP(`updated_at`)','SELECT 1');
PREPARE s166 FROM @p166;EXECUTE s166;DEALLOCATE PREPARE s166;
SET @p167=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_wallet' AND COLUMN_NAME='updated_at_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_wallet' AND COLUMN_NAME='updated_at')='datetime','ALTER TABLE `cb_wallet` DROP COLUMN `updated_at`','SELECT 1');
PREPARE s167 FROM @p167;EXECUTE s167;DEALLOCATE PREPARE s167;
SET @p168=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_wallet' AND COLUMN_NAME='updated_at_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_wallet' AND COLUMN_NAME='updated_at')!='bigint','ALTER TABLE `cb_wallet` CHANGE COLUMN `updated_at_ts` `updated_at` BIGINT NOT NULL COMMENT ''最后更新时间（用作乐观锁版本号）（UTC 秒级时间戳）''','SELECT 1');
PREPARE s168 FROM @p168;EXECUTE s168;DEALLOCATE PREPARE s168;

-- ===== cb_wallet_record =====
SET @p169=IF((SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_wallet_record' AND COLUMN_NAME='create_time')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_wallet_record' AND COLUMN_NAME='create_time_ts')=0,'ALTER TABLE `cb_wallet_record` ADD COLUMN `create_time_ts` BIGINT NOT NULL DEFAULT 0 COMMENT ''tmp'' AFTER `create_time`','SELECT 1');
PREPARE s169 FROM @p169;EXECUTE s169;DEALLOCATE PREPARE s169;
SET @p170=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_wallet_record' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_wallet_record' AND COLUMN_NAME='create_time')='datetime','UPDATE `cb_wallet_record` SET `create_time_ts`=UNIX_TIMESTAMP(`create_time`)','SELECT 1');
PREPARE s170 FROM @p170;EXECUTE s170;DEALLOCATE PREPARE s170;
SET @p171=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_wallet_record' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_wallet_record' AND COLUMN_NAME='create_time')='datetime','ALTER TABLE `cb_wallet_record` DROP COLUMN `create_time`','SELECT 1');
PREPARE s171 FROM @p171;EXECUTE s171;DEALLOCATE PREPARE s171;
SET @p172=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_wallet_record' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_wallet_record' AND COLUMN_NAME='create_time')!='bigint','ALTER TABLE `cb_wallet_record` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''流水产生时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE s172 FROM @p172;EXECUTE s172;DEALLOCATE PREPARE s172;

-- ===== cb_coupon_template =====
SET @p173=IF((SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_coupon_template' AND COLUMN_NAME='start_time')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_coupon_template' AND COLUMN_NAME='start_time_ts')=0,'ALTER TABLE `cb_coupon_template` ADD COLUMN `start_time_ts` BIGINT NULL COMMENT ''tmp'' AFTER `start_time`','SELECT 1');
PREPARE s173 FROM @p173;EXECUTE s173;DEALLOCATE PREPARE s173;
SET @p174=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_coupon_template' AND COLUMN_NAME='start_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_coupon_template' AND COLUMN_NAME='start_time')='datetime','UPDATE `cb_coupon_template` SET `start_time_ts`=UNIX_TIMESTAMP(`start_time`) WHERE `start_time` IS NOT NULL','SELECT 1');
PREPARE s174 FROM @p174;EXECUTE s174;DEALLOCATE PREPARE s174;
SET @p175=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_coupon_template' AND COLUMN_NAME='start_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_coupon_template' AND COLUMN_NAME='start_time')='datetime','ALTER TABLE `cb_coupon_template` DROP COLUMN `start_time`','SELECT 1');
PREPARE s175 FROM @p175;EXECUTE s175;DEALLOCATE PREPARE s175;
SET @p176=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_coupon_template' AND COLUMN_NAME='start_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_coupon_template' AND COLUMN_NAME='start_time')!='bigint','ALTER TABLE `cb_coupon_template` CHANGE COLUMN `start_time_ts` `start_time` BIGINT NULL COMMENT ''绝对有效期开始时间（与 valid_days 二选一）（UTC 秒级时间戳）''','SELECT 1');
PREPARE s176 FROM @p176;EXECUTE s176;DEALLOCATE PREPARE s176;
SET @p177=IF((SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_coupon_template' AND COLUMN_NAME='end_time')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_coupon_template' AND COLUMN_NAME='end_time_ts')=0,'ALTER TABLE `cb_coupon_template` ADD COLUMN `end_time_ts` BIGINT NULL COMMENT ''tmp'' AFTER `end_time`','SELECT 1');
PREPARE s177 FROM @p177;EXECUTE s177;DEALLOCATE PREPARE s177;
SET @p178=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_coupon_template' AND COLUMN_NAME='end_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_coupon_template' AND COLUMN_NAME='end_time')='datetime','UPDATE `cb_coupon_template` SET `end_time_ts`=UNIX_TIMESTAMP(`end_time`) WHERE `end_time` IS NOT NULL','SELECT 1');
PREPARE s178 FROM @p178;EXECUTE s178;DEALLOCATE PREPARE s178;
SET @p179=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_coupon_template' AND COLUMN_NAME='end_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_coupon_template' AND COLUMN_NAME='end_time')='datetime','ALTER TABLE `cb_coupon_template` DROP COLUMN `end_time`','SELECT 1');
PREPARE s179 FROM @p179;EXECUTE s179;DEALLOCATE PREPARE s179;
SET @p180=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_coupon_template' AND COLUMN_NAME='end_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_coupon_template' AND COLUMN_NAME='end_time')!='bigint','ALTER TABLE `cb_coupon_template` CHANGE COLUMN `end_time_ts` `end_time` BIGINT NULL COMMENT ''绝对有效期结束时间（与 valid_days 二选一）（UTC 秒级时间戳）''','SELECT 1');
PREPARE s180 FROM @p180;EXECUTE s180;DEALLOCATE PREPARE s180;
SET @p181=IF((SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_coupon_template' AND COLUMN_NAME='create_time')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_coupon_template' AND COLUMN_NAME='create_time_ts')=0,'ALTER TABLE `cb_coupon_template` ADD COLUMN `create_time_ts` BIGINT NOT NULL DEFAULT 0 COMMENT ''tmp'' AFTER `create_time`','SELECT 1');
PREPARE s181 FROM @p181;EXECUTE s181;DEALLOCATE PREPARE s181;
SET @p182=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_coupon_template' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_coupon_template' AND COLUMN_NAME='create_time')='datetime','UPDATE `cb_coupon_template` SET `create_time_ts`=UNIX_TIMESTAMP(`create_time`)','SELECT 1');
PREPARE s182 FROM @p182;EXECUTE s182;DEALLOCATE PREPARE s182;
SET @p183=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_coupon_template' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_coupon_template' AND COLUMN_NAME='create_time')='datetime','ALTER TABLE `cb_coupon_template` DROP COLUMN `create_time`','SELECT 1');
PREPARE s183 FROM @p183;EXECUTE s183;DEALLOCATE PREPARE s183;
SET @p184=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_coupon_template' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_coupon_template' AND COLUMN_NAME='create_time')!='bigint','ALTER TABLE `cb_coupon_template` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''创建时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE s184 FROM @p184;EXECUTE s184;DEALLOCATE PREPARE s184;
SET @p185=IF((SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_coupon_template' AND COLUMN_NAME='update_time')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_coupon_template' AND COLUMN_NAME='update_time_ts')=0,'ALTER TABLE `cb_coupon_template` ADD COLUMN `update_time_ts` BIGINT NOT NULL DEFAULT 0 COMMENT ''tmp'' AFTER `update_time`','SELECT 1');
PREPARE s185 FROM @p185;EXECUTE s185;DEALLOCATE PREPARE s185;
SET @p186=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_coupon_template' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_coupon_template' AND COLUMN_NAME='update_time')='datetime','UPDATE `cb_coupon_template` SET `update_time_ts`=UNIX_TIMESTAMP(`update_time`)','SELECT 1');
PREPARE s186 FROM @p186;EXECUTE s186;DEALLOCATE PREPARE s186;
SET @p187=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_coupon_template' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_coupon_template' AND COLUMN_NAME='update_time')='datetime','ALTER TABLE `cb_coupon_template` DROP COLUMN `update_time`','SELECT 1');
PREPARE s187 FROM @p187;EXECUTE s187;DEALLOCATE PREPARE s187;
SET @p188=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_coupon_template' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_coupon_template' AND COLUMN_NAME='update_time')!='bigint','ALTER TABLE `cb_coupon_template` CHANGE COLUMN `update_time_ts` `update_time` BIGINT NOT NULL COMMENT ''最后修改时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE s188 FROM @p188;EXECUTE s188;DEALLOCATE PREPARE s188;

-- ===== cb_member_coupon =====
SET @p189=IF((SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_member_coupon' AND COLUMN_NAME='use_time')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_member_coupon' AND COLUMN_NAME='use_time_ts')=0,'ALTER TABLE `cb_member_coupon` ADD COLUMN `use_time_ts` BIGINT NULL COMMENT ''tmp'' AFTER `use_time`','SELECT 1');
PREPARE s189 FROM @p189;EXECUTE s189;DEALLOCATE PREPARE s189;
SET @p190=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_member_coupon' AND COLUMN_NAME='use_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_member_coupon' AND COLUMN_NAME='use_time')='datetime','UPDATE `cb_member_coupon` SET `use_time_ts`=UNIX_TIMESTAMP(`use_time`) WHERE `use_time` IS NOT NULL','SELECT 1');
PREPARE s190 FROM @p190;EXECUTE s190;DEALLOCATE PREPARE s190;
SET @p191=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_member_coupon' AND COLUMN_NAME='use_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_member_coupon' AND COLUMN_NAME='use_time')='datetime','ALTER TABLE `cb_member_coupon` DROP COLUMN `use_time`','SELECT 1');
PREPARE s191 FROM @p191;EXECUTE s191;DEALLOCATE PREPARE s191;
SET @p192=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_member_coupon' AND COLUMN_NAME='use_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_member_coupon' AND COLUMN_NAME='use_time')!='bigint','ALTER TABLE `cb_member_coupon` CHANGE COLUMN `use_time_ts` `use_time` BIGINT NULL COMMENT ''实际使用时间（status=1时填写）（UTC 秒级时间戳）''','SELECT 1');
PREPARE s192 FROM @p192;EXECUTE s192;DEALLOCATE PREPARE s192;
SET @p193=IF((SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_member_coupon' AND COLUMN_NAME='expire_time')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_member_coupon' AND COLUMN_NAME='expire_time_ts')=0,'ALTER TABLE `cb_member_coupon` ADD COLUMN `expire_time_ts` BIGINT NOT NULL DEFAULT 0 COMMENT ''tmp'' AFTER `expire_time`','SELECT 1');
PREPARE s193 FROM @p193;EXECUTE s193;DEALLOCATE PREPARE s193;
SET @p194=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_member_coupon' AND COLUMN_NAME='expire_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_member_coupon' AND COLUMN_NAME='expire_time')='datetime','UPDATE `cb_member_coupon` SET `expire_time_ts`=UNIX_TIMESTAMP(`expire_time`)','SELECT 1');
PREPARE s194 FROM @p194;EXECUTE s194;DEALLOCATE PREPARE s194;
SET @p195=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_member_coupon' AND COLUMN_NAME='expire_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_member_coupon' AND COLUMN_NAME='expire_time')='datetime','ALTER TABLE `cb_member_coupon` DROP COLUMN `expire_time`','SELECT 1');
PREPARE s195 FROM @p195;EXECUTE s195;DEALLOCATE PREPARE s195;
SET @p196=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_member_coupon' AND COLUMN_NAME='expire_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_member_coupon' AND COLUMN_NAME='expire_time')!='bigint','ALTER TABLE `cb_member_coupon` CHANGE COLUMN `expire_time_ts` `expire_time` BIGINT NOT NULL COMMENT ''过期时间（根据模板 valid_days 或 end_time 计算后写入）（UTC 秒级时间戳）''','SELECT 1');
PREPARE s196 FROM @p196;EXECUTE s196;DEALLOCATE PREPARE s196;
SET @p197=IF((SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_member_coupon' AND COLUMN_NAME='create_time')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_member_coupon' AND COLUMN_NAME='create_time_ts')=0,'ALTER TABLE `cb_member_coupon` ADD COLUMN `create_time_ts` BIGINT NOT NULL DEFAULT 0 COMMENT ''tmp'' AFTER `create_time`','SELECT 1');
PREPARE s197 FROM @p197;EXECUTE s197;DEALLOCATE PREPARE s197;
SET @p198=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_member_coupon' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_member_coupon' AND COLUMN_NAME='create_time')='datetime','UPDATE `cb_member_coupon` SET `create_time_ts`=UNIX_TIMESTAMP(`create_time`)','SELECT 1');
PREPARE s198 FROM @p198;EXECUTE s198;DEALLOCATE PREPARE s198;
SET @p199=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_member_coupon' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_member_coupon' AND COLUMN_NAME='create_time')='datetime','ALTER TABLE `cb_member_coupon` DROP COLUMN `create_time`','SELECT 1');
PREPARE s199 FROM @p199;EXECUTE s199;DEALLOCATE PREPARE s199;
SET @p200=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_member_coupon' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_member_coupon' AND COLUMN_NAME='create_time')!='bigint','ALTER TABLE `cb_member_coupon` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''领取时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE s200 FROM @p200;EXECUTE s200;DEALLOCATE PREPARE s200;

-- ===== cb_address =====
SET @p201=IF((SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_address' AND COLUMN_NAME='create_time')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_address' AND COLUMN_NAME='create_time_ts')=0,'ALTER TABLE `cb_address` ADD COLUMN `create_time_ts` BIGINT NOT NULL DEFAULT 0 COMMENT ''tmp'' AFTER `create_time`','SELECT 1');
PREPARE s201 FROM @p201;EXECUTE s201;DEALLOCATE PREPARE s201;
SET @p202=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_address' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_address' AND COLUMN_NAME='create_time')='datetime','UPDATE `cb_address` SET `create_time_ts`=UNIX_TIMESTAMP(`create_time`)','SELECT 1');
PREPARE s202 FROM @p202;EXECUTE s202;DEALLOCATE PREPARE s202;
SET @p203=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_address' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_address' AND COLUMN_NAME='create_time')='datetime','ALTER TABLE `cb_address` DROP COLUMN `create_time`','SELECT 1');
PREPARE s203 FROM @p203;EXECUTE s203;DEALLOCATE PREPARE s203;
SET @p204=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_address' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_address' AND COLUMN_NAME='create_time')!='bigint','ALTER TABLE `cb_address` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''创建时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE s204 FROM @p204;EXECUTE s204;DEALLOCATE PREPARE s204;
SET @p205=IF((SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_address' AND COLUMN_NAME='update_time')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_address' AND COLUMN_NAME='update_time_ts')=0,'ALTER TABLE `cb_address` ADD COLUMN `update_time_ts` BIGINT NOT NULL DEFAULT 0 COMMENT ''tmp'' AFTER `update_time`','SELECT 1');
PREPARE s205 FROM @p205;EXECUTE s205;DEALLOCATE PREPARE s205;
SET @p206=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_address' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_address' AND COLUMN_NAME='update_time')='datetime','UPDATE `cb_address` SET `update_time_ts`=UNIX_TIMESTAMP(`update_time`)','SELECT 1');
PREPARE s206 FROM @p206;EXECUTE s206;DEALLOCATE PREPARE s206;
SET @p207=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_address' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_address' AND COLUMN_NAME='update_time')='datetime','ALTER TABLE `cb_address` DROP COLUMN `update_time`','SELECT 1');
PREPARE s207 FROM @p207;EXECUTE s207;DEALLOCATE PREPARE s207;
SET @p208=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_address' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_address' AND COLUMN_NAME='update_time')!='bigint','ALTER TABLE `cb_address` CHANGE COLUMN `update_time_ts` `update_time` BIGINT NOT NULL COMMENT ''最后修改时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE s208 FROM @p208;EXECUTE s208;DEALLOCATE PREPARE s208;

-- ===== cb_technician_schedule =====
SET @p209=IF((SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician_schedule' AND COLUMN_NAME='create_time')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician_schedule' AND COLUMN_NAME='create_time_ts')=0,'ALTER TABLE `cb_technician_schedule` ADD COLUMN `create_time_ts` BIGINT NOT NULL DEFAULT 0 COMMENT ''tmp'' AFTER `create_time`','SELECT 1');
PREPARE s209 FROM @p209;EXECUTE s209;DEALLOCATE PREPARE s209;
SET @p210=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician_schedule' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician_schedule' AND COLUMN_NAME='create_time')='datetime','UPDATE `cb_technician_schedule` SET `create_time_ts`=UNIX_TIMESTAMP(`create_time`)','SELECT 1');
PREPARE s210 FROM @p210;EXECUTE s210;DEALLOCATE PREPARE s210;
SET @p211=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician_schedule' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician_schedule' AND COLUMN_NAME='create_time')='datetime','ALTER TABLE `cb_technician_schedule` DROP COLUMN `create_time`','SELECT 1');
PREPARE s211 FROM @p211;EXECUTE s211;DEALLOCATE PREPARE s211;
SET @p212=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician_schedule' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician_schedule' AND COLUMN_NAME='create_time')!='bigint','ALTER TABLE `cb_technician_schedule` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''创建时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE s212 FROM @p212;EXECUTE s212;DEALLOCATE PREPARE s212;

-- ===== cb_banner =====
SET @p213=IF((SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_banner' AND COLUMN_NAME='start_time')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_banner' AND COLUMN_NAME='start_time_ts')=0,'ALTER TABLE `cb_banner` ADD COLUMN `start_time_ts` BIGINT NULL COMMENT ''tmp'' AFTER `start_time`','SELECT 1');
PREPARE s213 FROM @p213;EXECUTE s213;DEALLOCATE PREPARE s213;
SET @p214=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_banner' AND COLUMN_NAME='start_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_banner' AND COLUMN_NAME='start_time')='datetime','UPDATE `cb_banner` SET `start_time_ts`=UNIX_TIMESTAMP(`start_time`) WHERE `start_time` IS NOT NULL','SELECT 1');
PREPARE s214 FROM @p214;EXECUTE s214;DEALLOCATE PREPARE s214;
SET @p215=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_banner' AND COLUMN_NAME='start_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_banner' AND COLUMN_NAME='start_time')='datetime','ALTER TABLE `cb_banner` DROP COLUMN `start_time`','SELECT 1');
PREPARE s215 FROM @p215;EXECUTE s215;DEALLOCATE PREPARE s215;
SET @p216=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_banner' AND COLUMN_NAME='start_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_banner' AND COLUMN_NAME='start_time')!='bigint','ALTER TABLE `cb_banner` CHANGE COLUMN `start_time_ts` `start_time` BIGINT NULL COMMENT ''生效开始时间（为空则立即生效）（UTC 秒级时间戳）''','SELECT 1');
PREPARE s216 FROM @p216;EXECUTE s216;DEALLOCATE PREPARE s216;
SET @p217=IF((SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_banner' AND COLUMN_NAME='end_time')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_banner' AND COLUMN_NAME='end_time_ts')=0,'ALTER TABLE `cb_banner` ADD COLUMN `end_time_ts` BIGINT NULL COMMENT ''tmp'' AFTER `end_time`','SELECT 1');
PREPARE s217 FROM @p217;EXECUTE s217;DEALLOCATE PREPARE s217;
SET @p218=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_banner' AND COLUMN_NAME='end_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_banner' AND COLUMN_NAME='end_time')='datetime','UPDATE `cb_banner` SET `end_time_ts`=UNIX_TIMESTAMP(`end_time`) WHERE `end_time` IS NOT NULL','SELECT 1');
PREPARE s218 FROM @p218;EXECUTE s218;DEALLOCATE PREPARE s218;
SET @p219=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_banner' AND COLUMN_NAME='end_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_banner' AND COLUMN_NAME='end_time')='datetime','ALTER TABLE `cb_banner` DROP COLUMN `end_time`','SELECT 1');
PREPARE s219 FROM @p219;EXECUTE s219;DEALLOCATE PREPARE s219;
SET @p220=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_banner' AND COLUMN_NAME='end_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_banner' AND COLUMN_NAME='end_time')!='bigint','ALTER TABLE `cb_banner` CHANGE COLUMN `end_time_ts` `end_time` BIGINT NULL COMMENT ''生效结束时间（为空则永久有效）（UTC 秒级时间戳）''','SELECT 1');
PREPARE s220 FROM @p220;EXECUTE s220;DEALLOCATE PREPARE s220;
SET @p221=IF((SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_banner' AND COLUMN_NAME='create_time')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_banner' AND COLUMN_NAME='create_time_ts')=0,'ALTER TABLE `cb_banner` ADD COLUMN `create_time_ts` BIGINT NOT NULL DEFAULT 0 COMMENT ''tmp'' AFTER `create_time`','SELECT 1');
PREPARE s221 FROM @p221;EXECUTE s221;DEALLOCATE PREPARE s221;
SET @p222=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_banner' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_banner' AND COLUMN_NAME='create_time')='datetime','UPDATE `cb_banner` SET `create_time_ts`=UNIX_TIMESTAMP(`create_time`)','SELECT 1');
PREPARE s222 FROM @p222;EXECUTE s222;DEALLOCATE PREPARE s222;
SET @p223=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_banner' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_banner' AND COLUMN_NAME='create_time')='datetime','ALTER TABLE `cb_banner` DROP COLUMN `create_time`','SELECT 1');
PREPARE s223 FROM @p223;EXECUTE s223;DEALLOCATE PREPARE s223;
SET @p224=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_banner' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_banner' AND COLUMN_NAME='create_time')!='bigint','ALTER TABLE `cb_banner` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''创建时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE s224 FROM @p224;EXECUTE s224;DEALLOCATE PREPARE s224;
SET @p225=IF((SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_banner' AND COLUMN_NAME='update_time')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_banner' AND COLUMN_NAME='update_time_ts')=0,'ALTER TABLE `cb_banner` ADD COLUMN `update_time_ts` BIGINT NOT NULL DEFAULT 0 COMMENT ''tmp'' AFTER `update_time`','SELECT 1');
PREPARE s225 FROM @p225;EXECUTE s225;DEALLOCATE PREPARE s225;
SET @p226=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_banner' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_banner' AND COLUMN_NAME='update_time')='datetime','UPDATE `cb_banner` SET `update_time_ts`=UNIX_TIMESTAMP(`update_time`)','SELECT 1');
PREPARE s226 FROM @p226;EXECUTE s226;DEALLOCATE PREPARE s226;
SET @p227=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_banner' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_banner' AND COLUMN_NAME='update_time')='datetime','ALTER TABLE `cb_banner` DROP COLUMN `update_time`','SELECT 1');
PREPARE s227 FROM @p227;EXECUTE s227;DEALLOCATE PREPARE s227;
SET @p228=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_banner' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_banner' AND COLUMN_NAME='update_time')!='bigint','ALTER TABLE `cb_banner` CHANGE COLUMN `update_time_ts` `update_time` BIGINT NOT NULL COMMENT ''最后修改时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE s228 FROM @p228;EXECUTE s228;DEALLOCATE PREPARE s228;

-- ===== cb_nav =====
SET @p229=IF((SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_nav' AND COLUMN_NAME='create_time')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_nav' AND COLUMN_NAME='create_time_ts')=0,'ALTER TABLE `cb_nav` ADD COLUMN `create_time_ts` BIGINT NOT NULL DEFAULT 0 COMMENT ''tmp'' AFTER `create_time`','SELECT 1');
PREPARE s229 FROM @p229;EXECUTE s229;DEALLOCATE PREPARE s229;
SET @p230=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_nav' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_nav' AND COLUMN_NAME='create_time')='datetime','UPDATE `cb_nav` SET `create_time_ts`=UNIX_TIMESTAMP(`create_time`)','SELECT 1');
PREPARE s230 FROM @p230;EXECUTE s230;DEALLOCATE PREPARE s230;
SET @p231=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_nav' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_nav' AND COLUMN_NAME='create_time')='datetime','ALTER TABLE `cb_nav` DROP COLUMN `create_time`','SELECT 1');
PREPARE s231 FROM @p231;EXECUTE s231;DEALLOCATE PREPARE s231;
SET @p232=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_nav' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_nav' AND COLUMN_NAME='create_time')!='bigint','ALTER TABLE `cb_nav` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''创建时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE s232 FROM @p232;EXECUTE s232;DEALLOCATE PREPARE s232;
SET @p233=IF((SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_nav' AND COLUMN_NAME='update_time')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_nav' AND COLUMN_NAME='update_time_ts')=0,'ALTER TABLE `cb_nav` ADD COLUMN `update_time_ts` BIGINT NOT NULL DEFAULT 0 COMMENT ''tmp'' AFTER `update_time`','SELECT 1');
PREPARE s233 FROM @p233;EXECUTE s233;DEALLOCATE PREPARE s233;
SET @p234=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_nav' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_nav' AND COLUMN_NAME='update_time')='datetime','UPDATE `cb_nav` SET `update_time_ts`=UNIX_TIMESTAMP(`update_time`)','SELECT 1');
PREPARE s234 FROM @p234;EXECUTE s234;DEALLOCATE PREPARE s234;
SET @p235=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_nav' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_nav' AND COLUMN_NAME='update_time')='datetime','ALTER TABLE `cb_nav` DROP COLUMN `update_time`','SELECT 1');
PREPARE s235 FROM @p235;EXECUTE s235;DEALLOCATE PREPARE s235;
SET @p236=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_nav' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_nav' AND COLUMN_NAME='update_time')!='bigint','ALTER TABLE `cb_nav` CHANGE COLUMN `update_time_ts` `update_time` BIGINT NOT NULL COMMENT ''最后修改时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE s236 FROM @p236;EXECUTE s236;DEALLOCATE PREPARE s236;

-- ===== cb_icon =====
SET @p237=IF((SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_icon' AND COLUMN_NAME='create_time')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_icon' AND COLUMN_NAME='create_time_ts')=0,'ALTER TABLE `cb_icon` ADD COLUMN `create_time_ts` BIGINT NOT NULL DEFAULT 0 COMMENT ''tmp'' AFTER `create_time`','SELECT 1');
PREPARE s237 FROM @p237;EXECUTE s237;DEALLOCATE PREPARE s237;
SET @p238=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_icon' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_icon' AND COLUMN_NAME='create_time')='datetime','UPDATE `cb_icon` SET `create_time_ts`=UNIX_TIMESTAMP(`create_time`)','SELECT 1');
PREPARE s238 FROM @p238;EXECUTE s238;DEALLOCATE PREPARE s238;
SET @p239=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_icon' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_icon' AND COLUMN_NAME='create_time')='datetime','ALTER TABLE `cb_icon` DROP COLUMN `create_time`','SELECT 1');
PREPARE s239 FROM @p239;EXECUTE s239;DEALLOCATE PREPARE s239;
SET @p240=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_icon' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_icon' AND COLUMN_NAME='create_time')!='bigint','ALTER TABLE `cb_icon` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''创建时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE s240 FROM @p240;EXECUTE s240;DEALLOCATE PREPARE s240;
SET @p241=IF((SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_icon' AND COLUMN_NAME='update_time')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_icon' AND COLUMN_NAME='update_time_ts')=0,'ALTER TABLE `cb_icon` ADD COLUMN `update_time_ts` BIGINT NOT NULL DEFAULT 0 COMMENT ''tmp'' AFTER `update_time`','SELECT 1');
PREPARE s241 FROM @p241;EXECUTE s241;DEALLOCATE PREPARE s241;
SET @p242=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_icon' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_icon' AND COLUMN_NAME='update_time')='datetime','UPDATE `cb_icon` SET `update_time_ts`=UNIX_TIMESTAMP(`update_time`)','SELECT 1');
PREPARE s242 FROM @p242;EXECUTE s242;DEALLOCATE PREPARE s242;
SET @p243=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_icon' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_icon' AND COLUMN_NAME='update_time')='datetime','ALTER TABLE `cb_icon` DROP COLUMN `update_time`','SELECT 1');
PREPARE s243 FROM @p243;EXECUTE s243;DEALLOCATE PREPARE s243;
SET @p244=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_icon' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_icon' AND COLUMN_NAME='update_time')!='bigint','ALTER TABLE `cb_icon` CHANGE COLUMN `update_time_ts` `update_time` BIGINT NOT NULL COMMENT ''最后修改时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE s244 FROM @p244;EXECUTE s244;DEALLOCATE PREPARE s244;

-- ===== cb_tag =====
SET @p245=IF((SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_tag' AND COLUMN_NAME='create_time')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_tag' AND COLUMN_NAME='create_time_ts')=0,'ALTER TABLE `cb_tag` ADD COLUMN `create_time_ts` BIGINT NOT NULL DEFAULT 0 COMMENT ''tmp'' AFTER `create_time`','SELECT 1');
PREPARE s245 FROM @p245;EXECUTE s245;DEALLOCATE PREPARE s245;
SET @p246=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_tag' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_tag' AND COLUMN_NAME='create_time')='datetime','UPDATE `cb_tag` SET `create_time_ts`=UNIX_TIMESTAMP(`create_time`)','SELECT 1');
PREPARE s246 FROM @p246;EXECUTE s246;DEALLOCATE PREPARE s246;
SET @p247=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_tag' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_tag' AND COLUMN_NAME='create_time')='datetime','ALTER TABLE `cb_tag` DROP COLUMN `create_time`','SELECT 1');
PREPARE s247 FROM @p247;EXECUTE s247;DEALLOCATE PREPARE s247;
SET @p248=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_tag' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_tag' AND COLUMN_NAME='create_time')!='bigint','ALTER TABLE `cb_tag` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''创建时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE s248 FROM @p248;EXECUTE s248;DEALLOCATE PREPARE s248;

-- ===== cb_im_session =====
SET @p249=IF((SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_im_session' AND COLUMN_NAME='last_msg_time')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_im_session' AND COLUMN_NAME='last_msg_time_ts')=0,'ALTER TABLE `cb_im_session` ADD COLUMN `last_msg_time_ts` BIGINT NULL COMMENT ''tmp'' AFTER `last_msg_time`','SELECT 1');
PREPARE s249 FROM @p249;EXECUTE s249;DEALLOCATE PREPARE s249;
SET @p250=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_im_session' AND COLUMN_NAME='last_msg_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_im_session' AND COLUMN_NAME='last_msg_time')='datetime','UPDATE `cb_im_session` SET `last_msg_time_ts`=UNIX_TIMESTAMP(`last_msg_time`) WHERE `last_msg_time` IS NOT NULL','SELECT 1');
PREPARE s250 FROM @p250;EXECUTE s250;DEALLOCATE PREPARE s250;
SET @p251=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_im_session' AND COLUMN_NAME='last_msg_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_im_session' AND COLUMN_NAME='last_msg_time')='datetime','ALTER TABLE `cb_im_session` DROP COLUMN `last_msg_time`','SELECT 1');
PREPARE s251 FROM @p251;EXECUTE s251;DEALLOCATE PREPARE s251;
SET @p252=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_im_session' AND COLUMN_NAME='last_msg_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_im_session' AND COLUMN_NAME='last_msg_time')!='bigint','ALTER TABLE `cb_im_session` CHANGE COLUMN `last_msg_time_ts` `last_msg_time` BIGINT NULL COMMENT ''最后一条消息发送时间（用于会话列表按时间倒序）（UTC 秒级时间戳）''','SELECT 1');
PREPARE s252 FROM @p252;EXECUTE s252;DEALLOCATE PREPARE s252;
SET @p253=IF((SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_im_session' AND COLUMN_NAME='create_time')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_im_session' AND COLUMN_NAME='create_time_ts')=0,'ALTER TABLE `cb_im_session` ADD COLUMN `create_time_ts` BIGINT NOT NULL DEFAULT 0 COMMENT ''tmp'' AFTER `create_time`','SELECT 1');
PREPARE s253 FROM @p253;EXECUTE s253;DEALLOCATE PREPARE s253;
SET @p254=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_im_session' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_im_session' AND COLUMN_NAME='create_time')='datetime','UPDATE `cb_im_session` SET `create_time_ts`=UNIX_TIMESTAMP(`create_time`)','SELECT 1');
PREPARE s254 FROM @p254;EXECUTE s254;DEALLOCATE PREPARE s254;
SET @p255=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_im_session' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_im_session' AND COLUMN_NAME='create_time')='datetime','ALTER TABLE `cb_im_session` DROP COLUMN `create_time`','SELECT 1');
PREPARE s255 FROM @p255;EXECUTE s255;DEALLOCATE PREPARE s255;
SET @p256=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_im_session' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_im_session' AND COLUMN_NAME='create_time')!='bigint','ALTER TABLE `cb_im_session` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''会话创建时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE s256 FROM @p256;EXECUTE s256;DEALLOCATE PREPARE s256;
SET @p257=IF((SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_im_session' AND COLUMN_NAME='update_time')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_im_session' AND COLUMN_NAME='update_time_ts')=0,'ALTER TABLE `cb_im_session` ADD COLUMN `update_time_ts` BIGINT NOT NULL DEFAULT 0 COMMENT ''tmp'' AFTER `update_time`','SELECT 1');
PREPARE s257 FROM @p257;EXECUTE s257;DEALLOCATE PREPARE s257;
SET @p258=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_im_session' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_im_session' AND COLUMN_NAME='update_time')='datetime','UPDATE `cb_im_session` SET `update_time_ts`=UNIX_TIMESTAMP(`update_time`)','SELECT 1');
PREPARE s258 FROM @p258;EXECUTE s258;DEALLOCATE PREPARE s258;
SET @p259=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_im_session' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_im_session' AND COLUMN_NAME='update_time')='datetime','ALTER TABLE `cb_im_session` DROP COLUMN `update_time`','SELECT 1');
PREPARE s259 FROM @p259;EXECUTE s259;DEALLOCATE PREPARE s259;
SET @p260=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_im_session' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_im_session' AND COLUMN_NAME='update_time')!='bigint','ALTER TABLE `cb_im_session` CHANGE COLUMN `update_time_ts` `update_time` BIGINT NOT NULL COMMENT ''最后消息更新时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE s260 FROM @p260;EXECUTE s260;DEALLOCATE PREPARE s260;

-- ===== cb_im_message =====
SET @p261=IF((SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_im_message' AND COLUMN_NAME='create_time')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_im_message' AND COLUMN_NAME='create_time_ts')=0,'ALTER TABLE `cb_im_message` ADD COLUMN `create_time_ts` BIGINT NOT NULL DEFAULT 0 COMMENT ''tmp'' AFTER `create_time`','SELECT 1');
PREPARE s261 FROM @p261;EXECUTE s261;DEALLOCATE PREPARE s261;
SET @p262=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_im_message' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_im_message' AND COLUMN_NAME='create_time')='datetime','UPDATE `cb_im_message` SET `create_time_ts`=UNIX_TIMESTAMP(`create_time`)','SELECT 1');
PREPARE s262 FROM @p262;EXECUTE s262;DEALLOCATE PREPARE s262;
SET @p263=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_im_message' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_im_message' AND COLUMN_NAME='create_time')='datetime','ALTER TABLE `cb_im_message` DROP COLUMN `create_time`','SELECT 1');
PREPARE s263 FROM @p263;EXECUTE s263;DEALLOCATE PREPARE s263;
SET @p264=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_im_message' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_im_message' AND COLUMN_NAME='create_time')!='bigint','ALTER TABLE `cb_im_message` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''消息发送时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE s264 FROM @p264;EXECUTE s264;DEALLOCATE PREPARE s264;

-- ===== cb_notification =====
SET @p265=IF((SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_notification' AND COLUMN_NAME='create_time')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_notification' AND COLUMN_NAME='create_time_ts')=0,'ALTER TABLE `cb_notification` ADD COLUMN `create_time_ts` BIGINT NOT NULL DEFAULT 0 COMMENT ''tmp'' AFTER `create_time`','SELECT 1');
PREPARE s265 FROM @p265;EXECUTE s265;DEALLOCATE PREPARE s265;
SET @p266=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_notification' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_notification' AND COLUMN_NAME='create_time')='datetime','UPDATE `cb_notification` SET `create_time_ts`=UNIX_TIMESTAMP(`create_time`)','SELECT 1');
PREPARE s266 FROM @p266;EXECUTE s266;DEALLOCATE PREPARE s266;
SET @p267=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_notification' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_notification' AND COLUMN_NAME='create_time')='datetime','ALTER TABLE `cb_notification` DROP COLUMN `create_time`','SELECT 1');
PREPARE s267 FROM @p267;EXECUTE s267;DEALLOCATE PREPARE s267;
SET @p268=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_notification' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_notification' AND COLUMN_NAME='create_time')!='bigint','ALTER TABLE `cb_notification` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''通知推送时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE s268 FROM @p268;EXECUTE s268;DEALLOCATE PREPARE s268;

-- ===== cb_login_log =====
SET @p269=IF((SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_login_log' AND COLUMN_NAME='create_time')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_login_log' AND COLUMN_NAME='create_time_ts')=0,'ALTER TABLE `cb_login_log` ADD COLUMN `create_time_ts` BIGINT NOT NULL DEFAULT 0 COMMENT ''tmp'' AFTER `create_time`','SELECT 1');
PREPARE s269 FROM @p269;EXECUTE s269;DEALLOCATE PREPARE s269;
SET @p270=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_login_log' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_login_log' AND COLUMN_NAME='create_time')='datetime','UPDATE `cb_login_log` SET `create_time_ts`=UNIX_TIMESTAMP(`create_time`)','SELECT 1');
PREPARE s270 FROM @p270;EXECUTE s270;DEALLOCATE PREPARE s270;
SET @p271=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_login_log' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_login_log' AND COLUMN_NAME='create_time')='datetime','ALTER TABLE `cb_login_log` DROP COLUMN `create_time`','SELECT 1');
PREPARE s271 FROM @p271;EXECUTE s271;DEALLOCATE PREPARE s271;
SET @p272=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_login_log' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_login_log' AND COLUMN_NAME='create_time')!='bigint','ALTER TABLE `cb_login_log` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''登录时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE s272 FROM @p272;EXECUTE s272;DEALLOCATE PREPARE s272;

-- ===== cb_driver =====
SET @p273=IF((SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_driver' AND COLUMN_NAME='create_time')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_driver' AND COLUMN_NAME='create_time_ts')=0,'ALTER TABLE `cb_driver` ADD COLUMN `create_time_ts` BIGINT NOT NULL DEFAULT 0 COMMENT ''tmp'' AFTER `create_time`','SELECT 1');
PREPARE s273 FROM @p273;EXECUTE s273;DEALLOCATE PREPARE s273;
SET @p274=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_driver' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_driver' AND COLUMN_NAME='create_time')='datetime','UPDATE `cb_driver` SET `create_time_ts`=UNIX_TIMESTAMP(`create_time`)','SELECT 1');
PREPARE s274 FROM @p274;EXECUTE s274;DEALLOCATE PREPARE s274;
SET @p275=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_driver' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_driver' AND COLUMN_NAME='create_time')='datetime','ALTER TABLE `cb_driver` DROP COLUMN `create_time`','SELECT 1');
PREPARE s275 FROM @p275;EXECUTE s275;DEALLOCATE PREPARE s275;
SET @p276=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_driver' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_driver' AND COLUMN_NAME='create_time')!='bigint','ALTER TABLE `cb_driver` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''申请注册时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE s276 FROM @p276;EXECUTE s276;DEALLOCATE PREPARE s276;
SET @p277=IF((SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_driver' AND COLUMN_NAME='update_time')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_driver' AND COLUMN_NAME='update_time_ts')=0,'ALTER TABLE `cb_driver` ADD COLUMN `update_time_ts` BIGINT NOT NULL DEFAULT 0 COMMENT ''tmp'' AFTER `update_time`','SELECT 1');
PREPARE s277 FROM @p277;EXECUTE s277;DEALLOCATE PREPARE s277;
SET @p278=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_driver' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_driver' AND COLUMN_NAME='update_time')='datetime','UPDATE `cb_driver` SET `update_time_ts`=UNIX_TIMESTAMP(`update_time`)','SELECT 1');
PREPARE s278 FROM @p278;EXECUTE s278;DEALLOCATE PREPARE s278;
SET @p279=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_driver' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_driver' AND COLUMN_NAME='update_time')='datetime','ALTER TABLE `cb_driver` DROP COLUMN `update_time`','SELECT 1');
PREPARE s279 FROM @p279;EXECUTE s279;DEALLOCATE PREPARE s279;
SET @p280=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_driver' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_driver' AND COLUMN_NAME='update_time')!='bigint','ALTER TABLE `cb_driver` CHANGE COLUMN `update_time_ts` `update_time` BIGINT NOT NULL COMMENT ''最后修改时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE s280 FROM @p280;EXECUTE s280;DEALLOCATE PREPARE s280;

-- ===== cb_vehicle =====
SET @p281=IF((SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_vehicle' AND COLUMN_NAME='create_time')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_vehicle' AND COLUMN_NAME='create_time_ts')=0,'ALTER TABLE `cb_vehicle` ADD COLUMN `create_time_ts` BIGINT NOT NULL DEFAULT 0 COMMENT ''tmp'' AFTER `create_time`','SELECT 1');
PREPARE s281 FROM @p281;EXECUTE s281;DEALLOCATE PREPARE s281;
SET @p282=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_vehicle' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_vehicle' AND COLUMN_NAME='create_time')='datetime','UPDATE `cb_vehicle` SET `create_time_ts`=UNIX_TIMESTAMP(`create_time`)','SELECT 1');
PREPARE s282 FROM @p282;EXECUTE s282;DEALLOCATE PREPARE s282;
SET @p283=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_vehicle' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_vehicle' AND COLUMN_NAME='create_time')='datetime','ALTER TABLE `cb_vehicle` DROP COLUMN `create_time`','SELECT 1');
PREPARE s283 FROM @p283;EXECUTE s283;DEALLOCATE PREPARE s283;
SET @p284=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_vehicle' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_vehicle' AND COLUMN_NAME='create_time')!='bigint','ALTER TABLE `cb_vehicle` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''车辆录入时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE s284 FROM @p284;EXECUTE s284;DEALLOCATE PREPARE s284;
SET @p285=IF((SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_vehicle' AND COLUMN_NAME='update_time')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_vehicle' AND COLUMN_NAME='update_time_ts')=0,'ALTER TABLE `cb_vehicle` ADD COLUMN `update_time_ts` BIGINT NOT NULL DEFAULT 0 COMMENT ''tmp'' AFTER `update_time`','SELECT 1');
PREPARE s285 FROM @p285;EXECUTE s285;DEALLOCATE PREPARE s285;
SET @p286=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_vehicle' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_vehicle' AND COLUMN_NAME='update_time')='datetime','UPDATE `cb_vehicle` SET `update_time_ts`=UNIX_TIMESTAMP(`update_time`)','SELECT 1');
PREPARE s286 FROM @p286;EXECUTE s286;DEALLOCATE PREPARE s286;
SET @p287=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_vehicle' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_vehicle' AND COLUMN_NAME='update_time')='datetime','ALTER TABLE `cb_vehicle` DROP COLUMN `update_time`','SELECT 1');
PREPARE s287 FROM @p287;EXECUTE s287;DEALLOCATE PREPARE s287;
SET @p288=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_vehicle' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_vehicle' AND COLUMN_NAME='update_time')!='bigint','ALTER TABLE `cb_vehicle` CHANGE COLUMN `update_time_ts` `update_time` BIGINT NOT NULL COMMENT ''最后修改时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE s288 FROM @p288;EXECUTE s288;DEALLOCATE PREPARE s288;

-- ===== cb_dispatch_order =====
SET @p289=IF((SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_dispatch_order' AND COLUMN_NAME='pickup_time')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_dispatch_order' AND COLUMN_NAME='pickup_time_ts')=0,'ALTER TABLE `cb_dispatch_order` ADD COLUMN `pickup_time_ts` BIGINT NOT NULL DEFAULT 0 COMMENT ''tmp'' AFTER `pickup_time`','SELECT 1');
PREPARE s289 FROM @p289;EXECUTE s289;DEALLOCATE PREPARE s289;
SET @p290=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_dispatch_order' AND COLUMN_NAME='pickup_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_dispatch_order' AND COLUMN_NAME='pickup_time')='datetime','UPDATE `cb_dispatch_order` SET `pickup_time_ts`=UNIX_TIMESTAMP(`pickup_time`)','SELECT 1');
PREPARE s290 FROM @p290;EXECUTE s290;DEALLOCATE PREPARE s290;
SET @p291=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_dispatch_order' AND COLUMN_NAME='pickup_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_dispatch_order' AND COLUMN_NAME='pickup_time')='datetime','ALTER TABLE `cb_dispatch_order` DROP COLUMN `pickup_time`','SELECT 1');
PREPARE s291 FROM @p291;EXECUTE s291;DEALLOCATE PREPARE s291;
SET @p292=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_dispatch_order' AND COLUMN_NAME='pickup_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_dispatch_order' AND COLUMN_NAME='pickup_time')!='bigint','ALTER TABLE `cb_dispatch_order` CHANGE COLUMN `pickup_time_ts` `pickup_time` BIGINT NOT NULL COMMENT ''预约接送时间（会员选择的上车时间）（UTC 秒级时间戳）''','SELECT 1');
PREPARE s292 FROM @p292;EXECUTE s292;DEALLOCATE PREPARE s292;
SET @p293=IF((SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_dispatch_order' AND COLUMN_NAME='actual_pickup_time')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_dispatch_order' AND COLUMN_NAME='actual_pickup_time_ts')=0,'ALTER TABLE `cb_dispatch_order` ADD COLUMN `actual_pickup_time_ts` BIGINT NULL COMMENT ''tmp'' AFTER `actual_pickup_time`','SELECT 1');
PREPARE s293 FROM @p293;EXECUTE s293;DEALLOCATE PREPARE s293;
SET @p294=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_dispatch_order' AND COLUMN_NAME='actual_pickup_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_dispatch_order' AND COLUMN_NAME='actual_pickup_time')='datetime','UPDATE `cb_dispatch_order` SET `actual_pickup_time_ts`=UNIX_TIMESTAMP(`actual_pickup_time`) WHERE `actual_pickup_time` IS NOT NULL','SELECT 1');
PREPARE s294 FROM @p294;EXECUTE s294;DEALLOCATE PREPARE s294;
SET @p295=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_dispatch_order' AND COLUMN_NAME='actual_pickup_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_dispatch_order' AND COLUMN_NAME='actual_pickup_time')='datetime','ALTER TABLE `cb_dispatch_order` DROP COLUMN `actual_pickup_time`','SELECT 1');
PREPARE s295 FROM @p295;EXECUTE s295;DEALLOCATE PREPARE s295;
SET @p296=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_dispatch_order' AND COLUMN_NAME='actual_pickup_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_dispatch_order' AND COLUMN_NAME='actual_pickup_time')!='bigint','ALTER TABLE `cb_dispatch_order` CHANGE COLUMN `actual_pickup_time_ts` `actual_pickup_time` BIGINT NULL COMMENT ''实际接到乘客时间（司机操作"已接到"时记录）（UTC 秒级时间戳）''','SELECT 1');
PREPARE s296 FROM @p296;EXECUTE s296;DEALLOCATE PREPARE s296;
SET @p297=IF((SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_dispatch_order' AND COLUMN_NAME='finish_time')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_dispatch_order' AND COLUMN_NAME='finish_time_ts')=0,'ALTER TABLE `cb_dispatch_order` ADD COLUMN `finish_time_ts` BIGINT NULL COMMENT ''tmp'' AFTER `finish_time`','SELECT 1');
PREPARE s297 FROM @p297;EXECUTE s297;DEALLOCATE PREPARE s297;
SET @p298=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_dispatch_order' AND COLUMN_NAME='finish_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_dispatch_order' AND COLUMN_NAME='finish_time')='datetime','UPDATE `cb_dispatch_order` SET `finish_time_ts`=UNIX_TIMESTAMP(`finish_time`) WHERE `finish_time` IS NOT NULL','SELECT 1');
PREPARE s298 FROM @p298;EXECUTE s298;DEALLOCATE PREPARE s298;
SET @p299=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_dispatch_order' AND COLUMN_NAME='finish_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_dispatch_order' AND COLUMN_NAME='finish_time')='datetime','ALTER TABLE `cb_dispatch_order` DROP COLUMN `finish_time`','SELECT 1');
PREPARE s299 FROM @p299;EXECUTE s299;DEALLOCATE PREPARE s299;
SET @p300=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_dispatch_order' AND COLUMN_NAME='finish_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_dispatch_order' AND COLUMN_NAME='finish_time')!='bigint','ALTER TABLE `cb_dispatch_order` CHANGE COLUMN `finish_time_ts` `finish_time` BIGINT NULL COMMENT ''行程完成时间（司机操作"已送达"时记录）（UTC 秒级时间戳）''','SELECT 1');
PREPARE s300 FROM @p300;EXECUTE s300;DEALLOCATE PREPARE s300;
SET @p301=IF((SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_dispatch_order' AND COLUMN_NAME='create_time')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_dispatch_order' AND COLUMN_NAME='create_time_ts')=0,'ALTER TABLE `cb_dispatch_order` ADD COLUMN `create_time_ts` BIGINT NOT NULL DEFAULT 0 COMMENT ''tmp'' AFTER `create_time`','SELECT 1');
PREPARE s301 FROM @p301;EXECUTE s301;DEALLOCATE PREPARE s301;
SET @p302=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_dispatch_order' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_dispatch_order' AND COLUMN_NAME='create_time')='datetime','UPDATE `cb_dispatch_order` SET `create_time_ts`=UNIX_TIMESTAMP(`create_time`)','SELECT 1');
PREPARE s302 FROM @p302;EXECUTE s302;DEALLOCATE PREPARE s302;
SET @p303=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_dispatch_order' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_dispatch_order' AND COLUMN_NAME='create_time')='datetime','ALTER TABLE `cb_dispatch_order` DROP COLUMN `create_time`','SELECT 1');
PREPARE s303 FROM @p303;EXECUTE s303;DEALLOCATE PREPARE s303;
SET @p304=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_dispatch_order' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_dispatch_order' AND COLUMN_NAME='create_time')!='bigint','ALTER TABLE `cb_dispatch_order` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''派车单创建时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE s304 FROM @p304;EXECUTE s304;DEALLOCATE PREPARE s304;
SET @p305=IF((SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_dispatch_order' AND COLUMN_NAME='update_time')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_dispatch_order' AND COLUMN_NAME='update_time_ts')=0,'ALTER TABLE `cb_dispatch_order` ADD COLUMN `update_time_ts` BIGINT NOT NULL DEFAULT 0 COMMENT ''tmp'' AFTER `update_time`','SELECT 1');
PREPARE s305 FROM @p305;EXECUTE s305;DEALLOCATE PREPARE s305;
SET @p306=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_dispatch_order' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_dispatch_order' AND COLUMN_NAME='update_time')='datetime','UPDATE `cb_dispatch_order` SET `update_time_ts`=UNIX_TIMESTAMP(`update_time`)','SELECT 1');
PREPARE s306 FROM @p306;EXECUTE s306;DEALLOCATE PREPARE s306;
SET @p307=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_dispatch_order' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_dispatch_order' AND COLUMN_NAME='update_time')='datetime','ALTER TABLE `cb_dispatch_order` DROP COLUMN `update_time`','SELECT 1');
PREPARE s307 FROM @p307;EXECUTE s307;DEALLOCATE PREPARE s307;
SET @p308=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_dispatch_order' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_dispatch_order' AND COLUMN_NAME='update_time')!='bigint','ALTER TABLE `cb_dispatch_order` CHANGE COLUMN `update_time_ts` `update_time` BIGINT NOT NULL COMMENT ''最后修改时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE s308 FROM @p308;EXECUTE s308;DEALLOCATE PREPARE s308;

-- ===== cb_walkin_session =====
SET @p309=IF((SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_walkin_session' AND COLUMN_NAME='check_in_time')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_walkin_session' AND COLUMN_NAME='check_in_time_ts')=0,'ALTER TABLE `cb_walkin_session` ADD COLUMN `check_in_time_ts` BIGINT NOT NULL DEFAULT 0 COMMENT ''tmp'' AFTER `check_in_time`','SELECT 1');
PREPARE s309 FROM @p309;EXECUTE s309;DEALLOCATE PREPARE s309;
SET @p310=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_walkin_session' AND COLUMN_NAME='check_in_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_walkin_session' AND COLUMN_NAME='check_in_time')='datetime','UPDATE `cb_walkin_session` SET `check_in_time_ts`=UNIX_TIMESTAMP(`check_in_time`)','SELECT 1');
PREPARE s310 FROM @p310;EXECUTE s310;DEALLOCATE PREPARE s310;
SET @p311=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_walkin_session' AND COLUMN_NAME='check_in_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_walkin_session' AND COLUMN_NAME='check_in_time')='datetime','ALTER TABLE `cb_walkin_session` DROP COLUMN `check_in_time`','SELECT 1');
PREPARE s311 FROM @p311;EXECUTE s311;DEALLOCATE PREPARE s311;
SET @p312=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_walkin_session' AND COLUMN_NAME='check_in_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_walkin_session' AND COLUMN_NAME='check_in_time')!='bigint','ALTER TABLE `cb_walkin_session` CHANGE COLUMN `check_in_time_ts` `check_in_time` BIGINT NOT NULL COMMENT ''签到时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE s312 FROM @p312;EXECUTE s312;DEALLOCATE PREPARE s312;
SET @p313=IF((SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_walkin_session' AND COLUMN_NAME='check_out_time')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_walkin_session' AND COLUMN_NAME='check_out_time_ts')=0,'ALTER TABLE `cb_walkin_session` ADD COLUMN `check_out_time_ts` BIGINT NULL COMMENT ''tmp'' AFTER `check_out_time`','SELECT 1');
PREPARE s313 FROM @p313;EXECUTE s313;DEALLOCATE PREPARE s313;
SET @p314=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_walkin_session' AND COLUMN_NAME='check_out_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_walkin_session' AND COLUMN_NAME='check_out_time')='datetime','UPDATE `cb_walkin_session` SET `check_out_time_ts`=UNIX_TIMESTAMP(`check_out_time`) WHERE `check_out_time` IS NOT NULL','SELECT 1');
PREPARE s314 FROM @p314;EXECUTE s314;DEALLOCATE PREPARE s314;
SET @p315=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_walkin_session' AND COLUMN_NAME='check_out_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_walkin_session' AND COLUMN_NAME='check_out_time')='datetime','ALTER TABLE `cb_walkin_session` DROP COLUMN `check_out_time`','SELECT 1');
PREPARE s315 FROM @p315;EXECUTE s315;DEALLOCATE PREPARE s315;
SET @p316=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_walkin_session' AND COLUMN_NAME='check_out_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_walkin_session' AND COLUMN_NAME='check_out_time')!='bigint','ALTER TABLE `cb_walkin_session` CHANGE COLUMN `check_out_time_ts` `check_out_time` BIGINT NULL COMMENT ''签出时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE s316 FROM @p316;EXECUTE s316;DEALLOCATE PREPARE s316;
SET @p317=IF((SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_walkin_session' AND COLUMN_NAME='create_time')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_walkin_session' AND COLUMN_NAME='create_time_ts')=0,'ALTER TABLE `cb_walkin_session` ADD COLUMN `create_time_ts` BIGINT NOT NULL DEFAULT 0 COMMENT ''tmp'' AFTER `create_time`','SELECT 1');
PREPARE s317 FROM @p317;EXECUTE s317;DEALLOCATE PREPARE s317;
SET @p318=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_walkin_session' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_walkin_session' AND COLUMN_NAME='create_time')='datetime','UPDATE `cb_walkin_session` SET `create_time_ts`=UNIX_TIMESTAMP(`create_time`)','SELECT 1');
PREPARE s318 FROM @p318;EXECUTE s318;DEALLOCATE PREPARE s318;
SET @p319=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_walkin_session' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_walkin_session' AND COLUMN_NAME='create_time')='datetime','ALTER TABLE `cb_walkin_session` DROP COLUMN `create_time`','SELECT 1');
PREPARE s319 FROM @p319;EXECUTE s319;DEALLOCATE PREPARE s319;
SET @p320=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_walkin_session' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_walkin_session' AND COLUMN_NAME='create_time')!='bigint','ALTER TABLE `cb_walkin_session` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''创建时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE s320 FROM @p320;EXECUTE s320;DEALLOCATE PREPARE s320;
SET @p321=IF((SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_walkin_session' AND COLUMN_NAME='update_time')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_walkin_session' AND COLUMN_NAME='update_time_ts')=0,'ALTER TABLE `cb_walkin_session` ADD COLUMN `update_time_ts` BIGINT NOT NULL DEFAULT 0 COMMENT ''tmp'' AFTER `update_time`','SELECT 1');
PREPARE s321 FROM @p321;EXECUTE s321;DEALLOCATE PREPARE s321;
SET @p322=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_walkin_session' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_walkin_session' AND COLUMN_NAME='update_time')='datetime','UPDATE `cb_walkin_session` SET `update_time_ts`=UNIX_TIMESTAMP(`update_time`)','SELECT 1');
PREPARE s322 FROM @p322;EXECUTE s322;DEALLOCATE PREPARE s322;
SET @p323=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_walkin_session' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_walkin_session' AND COLUMN_NAME='update_time')='datetime','ALTER TABLE `cb_walkin_session` DROP COLUMN `update_time`','SELECT 1');
PREPARE s323 FROM @p323;EXECUTE s323;DEALLOCATE PREPARE s323;
SET @p324=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_walkin_session' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_walkin_session' AND COLUMN_NAME='update_time')!='bigint','ALTER TABLE `cb_walkin_session` CHANGE COLUMN `update_time_ts` `update_time` BIGINT NOT NULL COMMENT ''更新时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE s324 FROM @p324;EXECUTE s324;DEALLOCATE PREPARE s324;

-- ===== cb_payment_record =====
SET @p325=IF((SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_payment_record' AND COLUMN_NAME='pay_time')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_payment_record' AND COLUMN_NAME='pay_time_ts')=0,'ALTER TABLE `cb_payment_record` ADD COLUMN `pay_time_ts` BIGINT NULL COMMENT ''tmp'' AFTER `pay_time`','SELECT 1');
PREPARE s325 FROM @p325;EXECUTE s325;DEALLOCATE PREPARE s325;
SET @p326=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_payment_record' AND COLUMN_NAME='pay_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_payment_record' AND COLUMN_NAME='pay_time')='datetime','UPDATE `cb_payment_record` SET `pay_time_ts`=UNIX_TIMESTAMP(`pay_time`) WHERE `pay_time` IS NOT NULL','SELECT 1');
PREPARE s326 FROM @p326;EXECUTE s326;DEALLOCATE PREPARE s326;
SET @p327=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_payment_record' AND COLUMN_NAME='pay_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_payment_record' AND COLUMN_NAME='pay_time')='datetime','ALTER TABLE `cb_payment_record` DROP COLUMN `pay_time`','SELECT 1');
PREPARE s327 FROM @p327;EXECUTE s327;DEALLOCATE PREPARE s327;
SET @p328=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_payment_record' AND COLUMN_NAME='pay_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_payment_record' AND COLUMN_NAME='pay_time')!='bigint','ALTER TABLE `cb_payment_record` CHANGE COLUMN `pay_time_ts` `pay_time` BIGINT NULL COMMENT ''支付时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE s328 FROM @p328;EXECUTE s328;DEALLOCATE PREPARE s328;
SET @p329=IF((SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_payment_record' AND COLUMN_NAME='create_time')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_payment_record' AND COLUMN_NAME='create_time_ts')=0,'ALTER TABLE `cb_payment_record` ADD COLUMN `create_time_ts` BIGINT NOT NULL DEFAULT 0 COMMENT ''tmp'' AFTER `create_time`','SELECT 1');
PREPARE s329 FROM @p329;EXECUTE s329;DEALLOCATE PREPARE s329;
SET @p330=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_payment_record' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_payment_record' AND COLUMN_NAME='create_time')='datetime','UPDATE `cb_payment_record` SET `create_time_ts`=UNIX_TIMESTAMP(`create_time`)','SELECT 1');
PREPARE s330 FROM @p330;EXECUTE s330;DEALLOCATE PREPARE s330;
SET @p331=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_payment_record' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_payment_record' AND COLUMN_NAME='create_time')='datetime','ALTER TABLE `cb_payment_record` DROP COLUMN `create_time`','SELECT 1');
PREPARE s331 FROM @p331;EXECUTE s331;DEALLOCATE PREPARE s331;
SET @p332=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_payment_record' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_payment_record' AND COLUMN_NAME='create_time')!='bigint','ALTER TABLE `cb_payment_record` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''创建时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE s332 FROM @p332;EXECUTE s332;DEALLOCATE PREPARE s332;

-- ===== cb_vehicle_dispatch =====
SET @p333=IF((SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_vehicle_dispatch' AND COLUMN_NAME='depart_time')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_vehicle_dispatch' AND COLUMN_NAME='depart_time_ts')=0,'ALTER TABLE `cb_vehicle_dispatch` ADD COLUMN `depart_time_ts` BIGINT NULL COMMENT ''tmp'' AFTER `depart_time`','SELECT 1');
PREPARE s333 FROM @p333;EXECUTE s333;DEALLOCATE PREPARE s333;
SET @p334=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_vehicle_dispatch' AND COLUMN_NAME='depart_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_vehicle_dispatch' AND COLUMN_NAME='depart_time')='datetime','UPDATE `cb_vehicle_dispatch` SET `depart_time_ts`=UNIX_TIMESTAMP(`depart_time`) WHERE `depart_time` IS NOT NULL','SELECT 1');
PREPARE s334 FROM @p334;EXECUTE s334;DEALLOCATE PREPARE s334;
SET @p335=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_vehicle_dispatch' AND COLUMN_NAME='depart_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_vehicle_dispatch' AND COLUMN_NAME='depart_time')='datetime','ALTER TABLE `cb_vehicle_dispatch` DROP COLUMN `depart_time`','SELECT 1');
PREPARE s335 FROM @p335;EXECUTE s335;DEALLOCATE PREPARE s335;
SET @p336=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_vehicle_dispatch' AND COLUMN_NAME='depart_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_vehicle_dispatch' AND COLUMN_NAME='depart_time')!='bigint','ALTER TABLE `cb_vehicle_dispatch` CHANGE COLUMN `depart_time_ts` `depart_time` BIGINT NULL COMMENT ''出发时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE s336 FROM @p336;EXECUTE s336;DEALLOCATE PREPARE s336;
SET @p337=IF((SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_vehicle_dispatch' AND COLUMN_NAME='return_time')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_vehicle_dispatch' AND COLUMN_NAME='return_time_ts')=0,'ALTER TABLE `cb_vehicle_dispatch` ADD COLUMN `return_time_ts` BIGINT NULL COMMENT ''tmp'' AFTER `return_time`','SELECT 1');
PREPARE s337 FROM @p337;EXECUTE s337;DEALLOCATE PREPARE s337;
SET @p338=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_vehicle_dispatch' AND COLUMN_NAME='return_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_vehicle_dispatch' AND COLUMN_NAME='return_time')='datetime','UPDATE `cb_vehicle_dispatch` SET `return_time_ts`=UNIX_TIMESTAMP(`return_time`) WHERE `return_time` IS NOT NULL','SELECT 1');
PREPARE s338 FROM @p338;EXECUTE s338;DEALLOCATE PREPARE s338;
SET @p339=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_vehicle_dispatch' AND COLUMN_NAME='return_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_vehicle_dispatch' AND COLUMN_NAME='return_time')='datetime','ALTER TABLE `cb_vehicle_dispatch` DROP COLUMN `return_time`','SELECT 1');
PREPARE s339 FROM @p339;EXECUTE s339;DEALLOCATE PREPARE s339;
SET @p340=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_vehicle_dispatch' AND COLUMN_NAME='return_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_vehicle_dispatch' AND COLUMN_NAME='return_time')!='bigint','ALTER TABLE `cb_vehicle_dispatch` CHANGE COLUMN `return_time_ts` `return_time` BIGINT NULL COMMENT ''返回时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE s340 FROM @p340;EXECUTE s340;DEALLOCATE PREPARE s340;
SET @p341=IF((SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_vehicle_dispatch' AND COLUMN_NAME='create_time')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_vehicle_dispatch' AND COLUMN_NAME='create_time_ts')=0,'ALTER TABLE `cb_vehicle_dispatch` ADD COLUMN `create_time_ts` BIGINT NOT NULL DEFAULT 0 COMMENT ''tmp'' AFTER `create_time`','SELECT 1');
PREPARE s341 FROM @p341;EXECUTE s341;DEALLOCATE PREPARE s341;
SET @p342=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_vehicle_dispatch' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_vehicle_dispatch' AND COLUMN_NAME='create_time')='datetime','UPDATE `cb_vehicle_dispatch` SET `create_time_ts`=UNIX_TIMESTAMP(`create_time`)','SELECT 1');
PREPARE s342 FROM @p342;EXECUTE s342;DEALLOCATE PREPARE s342;
SET @p343=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_vehicle_dispatch' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_vehicle_dispatch' AND COLUMN_NAME='create_time')='datetime','ALTER TABLE `cb_vehicle_dispatch` DROP COLUMN `create_time`','SELECT 1');
PREPARE s343 FROM @p343;EXECUTE s343;DEALLOCATE PREPARE s343;
SET @p344=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_vehicle_dispatch' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_vehicle_dispatch' AND COLUMN_NAME='create_time')!='bigint','ALTER TABLE `cb_vehicle_dispatch` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''创建时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE s344 FROM @p344;EXECUTE s344;DEALLOCATE PREPARE s344;
SET @p345=IF((SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_vehicle_dispatch' AND COLUMN_NAME='update_time')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_vehicle_dispatch' AND COLUMN_NAME='update_time_ts')=0,'ALTER TABLE `cb_vehicle_dispatch` ADD COLUMN `update_time_ts` BIGINT NOT NULL DEFAULT 0 COMMENT ''tmp'' AFTER `update_time`','SELECT 1');
PREPARE s345 FROM @p345;EXECUTE s345;DEALLOCATE PREPARE s345;
SET @p346=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_vehicle_dispatch' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_vehicle_dispatch' AND COLUMN_NAME='update_time')='datetime','UPDATE `cb_vehicle_dispatch` SET `update_time_ts`=UNIX_TIMESTAMP(`update_time`)','SELECT 1');
PREPARE s346 FROM @p346;EXECUTE s346;DEALLOCATE PREPARE s346;
SET @p347=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_vehicle_dispatch' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_vehicle_dispatch' AND COLUMN_NAME='update_time')='datetime','ALTER TABLE `cb_vehicle_dispatch` DROP COLUMN `update_time`','SELECT 1');
PREPARE s347 FROM @p347;EXECUTE s347;DEALLOCATE PREPARE s347;
SET @p348=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_vehicle_dispatch' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_vehicle_dispatch' AND COLUMN_NAME='update_time')!='bigint','ALTER TABLE `cb_vehicle_dispatch` CHANGE COLUMN `update_time_ts` `update_time` BIGINT NOT NULL COMMENT ''更新时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE s348 FROM @p348;EXECUTE s348;DEALLOCATE PREPARE s348;

-- ===== cb_finance_expense =====
SET @p349=IF((SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_finance_expense' AND COLUMN_NAME='create_time')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_finance_expense' AND COLUMN_NAME='create_time_ts')=0,'ALTER TABLE `cb_finance_expense` ADD COLUMN `create_time_ts` BIGINT NOT NULL DEFAULT 0 COMMENT ''tmp'' AFTER `create_time`','SELECT 1');
PREPARE s349 FROM @p349;EXECUTE s349;DEALLOCATE PREPARE s349;
SET @p350=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_finance_expense' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_finance_expense' AND COLUMN_NAME='create_time')='datetime','UPDATE `cb_finance_expense` SET `create_time_ts`=UNIX_TIMESTAMP(`create_time`)','SELECT 1');
PREPARE s350 FROM @p350;EXECUTE s350;DEALLOCATE PREPARE s350;
SET @p351=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_finance_expense' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_finance_expense' AND COLUMN_NAME='create_time')='datetime','ALTER TABLE `cb_finance_expense` DROP COLUMN `create_time`','SELECT 1');
PREPARE s351 FROM @p351;EXECUTE s351;DEALLOCATE PREPARE s351;
SET @p352=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_finance_expense' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_finance_expense' AND COLUMN_NAME='create_time')!='bigint','ALTER TABLE `cb_finance_expense` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''创建时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE s352 FROM @p352;EXECUTE s352;DEALLOCATE PREPARE s352;
SET @p353=IF((SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_finance_expense' AND COLUMN_NAME='update_time')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_finance_expense' AND COLUMN_NAME='update_time_ts')=0,'ALTER TABLE `cb_finance_expense` ADD COLUMN `update_time_ts` BIGINT NOT NULL DEFAULT 0 COMMENT ''tmp'' AFTER `update_time`','SELECT 1');
PREPARE s353 FROM @p353;EXECUTE s353;DEALLOCATE PREPARE s353;
SET @p354=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_finance_expense' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_finance_expense' AND COLUMN_NAME='update_time')='datetime','UPDATE `cb_finance_expense` SET `update_time_ts`=UNIX_TIMESTAMP(`update_time`)','SELECT 1');
PREPARE s354 FROM @p354;EXECUTE s354;DEALLOCATE PREPARE s354;
SET @p355=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_finance_expense' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_finance_expense' AND COLUMN_NAME='update_time')='datetime','ALTER TABLE `cb_finance_expense` DROP COLUMN `update_time`','SELECT 1');
PREPARE s355 FROM @p355;EXECUTE s355;DEALLOCATE PREPARE s355;
SET @p356=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_finance_expense' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_finance_expense' AND COLUMN_NAME='update_time')!='bigint','ALTER TABLE `cb_finance_expense` CHANGE COLUMN `update_time_ts` `update_time` BIGINT NOT NULL COMMENT ''更新时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE s356 FROM @p356;EXECUTE s356;DEALLOCATE PREPARE s356;

-- ===== cb_finance_salary =====
SET @p357=IF((SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_finance_salary' AND COLUMN_NAME='pay_time')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_finance_salary' AND COLUMN_NAME='pay_time_ts')=0,'ALTER TABLE `cb_finance_salary` ADD COLUMN `pay_time_ts` BIGINT NULL COMMENT ''tmp'' AFTER `pay_time`','SELECT 1');
PREPARE s357 FROM @p357;EXECUTE s357;DEALLOCATE PREPARE s357;
SET @p358=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_finance_salary' AND COLUMN_NAME='pay_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_finance_salary' AND COLUMN_NAME='pay_time')='datetime','UPDATE `cb_finance_salary` SET `pay_time_ts`=UNIX_TIMESTAMP(`pay_time`) WHERE `pay_time` IS NOT NULL','SELECT 1');
PREPARE s358 FROM @p358;EXECUTE s358;DEALLOCATE PREPARE s358;
SET @p359=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_finance_salary' AND COLUMN_NAME='pay_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_finance_salary' AND COLUMN_NAME='pay_time')='datetime','ALTER TABLE `cb_finance_salary` DROP COLUMN `pay_time`','SELECT 1');
PREPARE s359 FROM @p359;EXECUTE s359;DEALLOCATE PREPARE s359;
SET @p360=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_finance_salary' AND COLUMN_NAME='pay_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_finance_salary' AND COLUMN_NAME='pay_time')!='bigint','ALTER TABLE `cb_finance_salary` CHANGE COLUMN `pay_time_ts` `pay_time` BIGINT NULL COMMENT ''发薪时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE s360 FROM @p360;EXECUTE s360;DEALLOCATE PREPARE s360;
SET @p361=IF((SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_finance_salary' AND COLUMN_NAME='create_time')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_finance_salary' AND COLUMN_NAME='create_time_ts')=0,'ALTER TABLE `cb_finance_salary` ADD COLUMN `create_time_ts` BIGINT NOT NULL DEFAULT 0 COMMENT ''tmp'' AFTER `create_time`','SELECT 1');
PREPARE s361 FROM @p361;EXECUTE s361;DEALLOCATE PREPARE s361;
SET @p362=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_finance_salary' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_finance_salary' AND COLUMN_NAME='create_time')='datetime','UPDATE `cb_finance_salary` SET `create_time_ts`=UNIX_TIMESTAMP(`create_time`)','SELECT 1');
PREPARE s362 FROM @p362;EXECUTE s362;DEALLOCATE PREPARE s362;
SET @p363=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_finance_salary' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_finance_salary' AND COLUMN_NAME='create_time')='datetime','ALTER TABLE `cb_finance_salary` DROP COLUMN `create_time`','SELECT 1');
PREPARE s363 FROM @p363;EXECUTE s363;DEALLOCATE PREPARE s363;
SET @p364=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_finance_salary' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_finance_salary' AND COLUMN_NAME='create_time')!='bigint','ALTER TABLE `cb_finance_salary` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''创建时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE s364 FROM @p364;EXECUTE s364;DEALLOCATE PREPARE s364;
SET @p365=IF((SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_finance_salary' AND COLUMN_NAME='update_time')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_finance_salary' AND COLUMN_NAME='update_time_ts')=0,'ALTER TABLE `cb_finance_salary` ADD COLUMN `update_time_ts` BIGINT NOT NULL DEFAULT 0 COMMENT ''tmp'' AFTER `update_time`','SELECT 1');
PREPARE s365 FROM @p365;EXECUTE s365;DEALLOCATE PREPARE s365;
SET @p366=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_finance_salary' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_finance_salary' AND COLUMN_NAME='update_time')='datetime','UPDATE `cb_finance_salary` SET `update_time_ts`=UNIX_TIMESTAMP(`update_time`)','SELECT 1');
PREPARE s366 FROM @p366;EXECUTE s366;DEALLOCATE PREPARE s366;
SET @p367=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_finance_salary' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_finance_salary' AND COLUMN_NAME='update_time')='datetime','ALTER TABLE `cb_finance_salary` DROP COLUMN `update_time`','SELECT 1');
PREPARE s367 FROM @p367;EXECUTE s367;DEALLOCATE PREPARE s367;
SET @p368=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_finance_salary' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_finance_salary' AND COLUMN_NAME='update_time')!='bigint','ALTER TABLE `cb_finance_salary` CHANGE COLUMN `update_time_ts` `update_time` BIGINT NOT NULL COMMENT ''更新时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE s368 FROM @p368;EXECUTE s368;DEALLOCATE PREPARE s368;

-- ===== cb_technician_settlement =====
SET @p369=IF((SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician_settlement' AND COLUMN_NAME='paid_time')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician_settlement' AND COLUMN_NAME='paid_time_ts')=0,'ALTER TABLE `cb_technician_settlement` ADD COLUMN `paid_time_ts` BIGINT NULL COMMENT ''tmp'' AFTER `paid_time`','SELECT 1');
PREPARE s369 FROM @p369;EXECUTE s369;DEALLOCATE PREPARE s369;
SET @p370=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician_settlement' AND COLUMN_NAME='paid_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician_settlement' AND COLUMN_NAME='paid_time')='datetime','UPDATE `cb_technician_settlement` SET `paid_time_ts`=UNIX_TIMESTAMP(`paid_time`) WHERE `paid_time` IS NOT NULL','SELECT 1');
PREPARE s370 FROM @p370;EXECUTE s370;DEALLOCATE PREPARE s370;
SET @p371=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician_settlement' AND COLUMN_NAME='paid_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician_settlement' AND COLUMN_NAME='paid_time')='datetime','ALTER TABLE `cb_technician_settlement` DROP COLUMN `paid_time`','SELECT 1');
PREPARE s371 FROM @p371;EXECUTE s371;DEALLOCATE PREPARE s371;
SET @p372=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician_settlement' AND COLUMN_NAME='paid_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician_settlement' AND COLUMN_NAME='paid_time')!='bigint','ALTER TABLE `cb_technician_settlement` CHANGE COLUMN `paid_time_ts` `paid_time` BIGINT NULL COMMENT ''打款时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE s372 FROM @p372;EXECUTE s372;DEALLOCATE PREPARE s372;
SET @p373=IF((SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician_settlement' AND COLUMN_NAME='create_time')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician_settlement' AND COLUMN_NAME='create_time_ts')=0,'ALTER TABLE `cb_technician_settlement` ADD COLUMN `create_time_ts` BIGINT NOT NULL DEFAULT 0 COMMENT ''tmp'' AFTER `create_time`','SELECT 1');
PREPARE s373 FROM @p373;EXECUTE s373;DEALLOCATE PREPARE s373;
SET @p374=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician_settlement' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician_settlement' AND COLUMN_NAME='create_time')='datetime','UPDATE `cb_technician_settlement` SET `create_time_ts`=UNIX_TIMESTAMP(`create_time`)','SELECT 1');
PREPARE s374 FROM @p374;EXECUTE s374;DEALLOCATE PREPARE s374;
SET @p375=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician_settlement' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician_settlement' AND COLUMN_NAME='create_time')='datetime','ALTER TABLE `cb_technician_settlement` DROP COLUMN `create_time`','SELECT 1');
PREPARE s375 FROM @p375;EXECUTE s375;DEALLOCATE PREPARE s375;
SET @p376=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician_settlement' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician_settlement' AND COLUMN_NAME='create_time')!='bigint','ALTER TABLE `cb_technician_settlement` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''创建时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE s376 FROM @p376;EXECUTE s376;DEALLOCATE PREPARE s376;
SET @p377=IF((SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician_settlement' AND COLUMN_NAME='update_time')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician_settlement' AND COLUMN_NAME='update_time_ts')=0,'ALTER TABLE `cb_technician_settlement` ADD COLUMN `update_time_ts` BIGINT NOT NULL DEFAULT 0 COMMENT ''tmp'' AFTER `update_time`','SELECT 1');
PREPARE s377 FROM @p377;EXECUTE s377;DEALLOCATE PREPARE s377;
SET @p378=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician_settlement' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician_settlement' AND COLUMN_NAME='update_time')='datetime','UPDATE `cb_technician_settlement` SET `update_time_ts`=UNIX_TIMESTAMP(`update_time`)','SELECT 1');
PREPARE s378 FROM @p378;EXECUTE s378;DEALLOCATE PREPARE s378;
SET @p379=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician_settlement' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician_settlement' AND COLUMN_NAME='update_time')='datetime','ALTER TABLE `cb_technician_settlement` DROP COLUMN `update_time`','SELECT 1');
PREPARE s379 FROM @p379;EXECUTE s379;DEALLOCATE PREPARE s379;
SET @p380=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician_settlement' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician_settlement' AND COLUMN_NAME='update_time')!='bigint','ALTER TABLE `cb_technician_settlement` CHANGE COLUMN `update_time_ts` `update_time` BIGINT NOT NULL COMMENT ''更新时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE s380 FROM @p380;EXECUTE s380;DEALLOCATE PREPARE s380;

-- ===== cb_technician_settlement_item =====
SET @p381=IF((SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician_settlement_item' AND COLUMN_NAME='service_time')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician_settlement_item' AND COLUMN_NAME='service_time_ts')=0,'ALTER TABLE `cb_technician_settlement_item` ADD COLUMN `service_time_ts` BIGINT NULL COMMENT ''tmp'' AFTER `service_time`','SELECT 1');
PREPARE s381 FROM @p381;EXECUTE s381;DEALLOCATE PREPARE s381;
SET @p382=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician_settlement_item' AND COLUMN_NAME='service_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician_settlement_item' AND COLUMN_NAME='service_time')='datetime','UPDATE `cb_technician_settlement_item` SET `service_time_ts`=UNIX_TIMESTAMP(`service_time`) WHERE `service_time` IS NOT NULL','SELECT 1');
PREPARE s382 FROM @p382;EXECUTE s382;DEALLOCATE PREPARE s382;
SET @p383=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician_settlement_item' AND COLUMN_NAME='service_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician_settlement_item' AND COLUMN_NAME='service_time')='datetime','ALTER TABLE `cb_technician_settlement_item` DROP COLUMN `service_time`','SELECT 1');
PREPARE s383 FROM @p383;EXECUTE s383;DEALLOCATE PREPARE s383;
SET @p384=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician_settlement_item' AND COLUMN_NAME='service_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician_settlement_item' AND COLUMN_NAME='service_time')!='bigint','ALTER TABLE `cb_technician_settlement_item` CHANGE COLUMN `service_time_ts` `service_time` BIGINT NULL COMMENT ''服务时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE s384 FROM @p384;EXECUTE s384;DEALLOCATE PREPARE s384;

-- ===== cb_commission_rule =====
SET @p385=IF((SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_commission_rule' AND COLUMN_NAME='create_time')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_commission_rule' AND COLUMN_NAME='create_time_ts')=0,'ALTER TABLE `cb_commission_rule` ADD COLUMN `create_time_ts` BIGINT NOT NULL DEFAULT 0 COMMENT ''tmp'' AFTER `create_time`','SELECT 1');
PREPARE s385 FROM @p385;EXECUTE s385;DEALLOCATE PREPARE s385;
SET @p386=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_commission_rule' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_commission_rule' AND COLUMN_NAME='create_time')='datetime','UPDATE `cb_commission_rule` SET `create_time_ts`=UNIX_TIMESTAMP(`create_time`)','SELECT 1');
PREPARE s386 FROM @p386;EXECUTE s386;DEALLOCATE PREPARE s386;
SET @p387=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_commission_rule' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_commission_rule' AND COLUMN_NAME='create_time')='datetime','ALTER TABLE `cb_commission_rule` DROP COLUMN `create_time`','SELECT 1');
PREPARE s387 FROM @p387;EXECUTE s387;DEALLOCATE PREPARE s387;
SET @p388=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_commission_rule' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_commission_rule' AND COLUMN_NAME='create_time')!='bigint','ALTER TABLE `cb_commission_rule` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''创建时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE s388 FROM @p388;EXECUTE s388;DEALLOCATE PREPARE s388;
SET @p389=IF((SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_commission_rule' AND COLUMN_NAME='update_time')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_commission_rule' AND COLUMN_NAME='update_time_ts')=0,'ALTER TABLE `cb_commission_rule` ADD COLUMN `update_time_ts` BIGINT NOT NULL DEFAULT 0 COMMENT ''tmp'' AFTER `update_time`','SELECT 1');
PREPARE s389 FROM @p389;EXECUTE s389;DEALLOCATE PREPARE s389;
SET @p390=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_commission_rule' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_commission_rule' AND COLUMN_NAME='update_time')='datetime','UPDATE `cb_commission_rule` SET `update_time_ts`=UNIX_TIMESTAMP(`update_time`)','SELECT 1');
PREPARE s390 FROM @p390;EXECUTE s390;DEALLOCATE PREPARE s390;
SET @p391=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_commission_rule' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_commission_rule' AND COLUMN_NAME='update_time')='datetime','ALTER TABLE `cb_commission_rule` DROP COLUMN `update_time`','SELECT 1');
PREPARE s391 FROM @p391;EXECUTE s391;DEALLOCATE PREPARE s391;
SET @p392=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_commission_rule' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_commission_rule' AND COLUMN_NAME='update_time')!='bigint','ALTER TABLE `cb_commission_rule` CHANGE COLUMN `update_time_ts` `update_time` BIGINT NOT NULL COMMENT ''更新时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE s392 FROM @p392;EXECUTE s392;DEALLOCATE PREPARE s392;

-- ===== cb_order_item =====
SET @p393=IF((SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order_item' AND COLUMN_NAME='start_time')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order_item' AND COLUMN_NAME='start_time_ts')=0,'ALTER TABLE `cb_order_item` ADD COLUMN `start_time_ts` BIGINT NULL COMMENT ''tmp'' AFTER `start_time`','SELECT 1');
PREPARE s393 FROM @p393;EXECUTE s393;DEALLOCATE PREPARE s393;
SET @p394=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order_item' AND COLUMN_NAME='start_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order_item' AND COLUMN_NAME='start_time')='datetime','UPDATE `cb_order_item` SET `start_time_ts`=UNIX_TIMESTAMP(`start_time`) WHERE `start_time` IS NOT NULL','SELECT 1');
PREPARE s394 FROM @p394;EXECUTE s394;DEALLOCATE PREPARE s394;
SET @p395=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order_item' AND COLUMN_NAME='start_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order_item' AND COLUMN_NAME='start_time')='datetime','ALTER TABLE `cb_order_item` DROP COLUMN `start_time`','SELECT 1');
PREPARE s395 FROM @p395;EXECUTE s395;DEALLOCATE PREPARE s395;
SET @p396=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order_item' AND COLUMN_NAME='start_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order_item' AND COLUMN_NAME='start_time')!='bigint','ALTER TABLE `cb_order_item` CHANGE COLUMN `start_time_ts` `start_time` BIGINT NULL COMMENT ''服务开始时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE s396 FROM @p396;EXECUTE s396;DEALLOCATE PREPARE s396;
SET @p397=IF((SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order_item' AND COLUMN_NAME='end_time')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order_item' AND COLUMN_NAME='end_time_ts')=0,'ALTER TABLE `cb_order_item` ADD COLUMN `end_time_ts` BIGINT NULL COMMENT ''tmp'' AFTER `end_time`','SELECT 1');
PREPARE s397 FROM @p397;EXECUTE s397;DEALLOCATE PREPARE s397;
SET @p398=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order_item' AND COLUMN_NAME='end_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order_item' AND COLUMN_NAME='end_time')='datetime','UPDATE `cb_order_item` SET `end_time_ts`=UNIX_TIMESTAMP(`end_time`) WHERE `end_time` IS NOT NULL','SELECT 1');
PREPARE s398 FROM @p398;EXECUTE s398;DEALLOCATE PREPARE s398;
SET @p399=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order_item' AND COLUMN_NAME='end_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order_item' AND COLUMN_NAME='end_time')='datetime','ALTER TABLE `cb_order_item` DROP COLUMN `end_time`','SELECT 1');
PREPARE s399 FROM @p399;EXECUTE s399;DEALLOCATE PREPARE s399;
SET @p400=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order_item' AND COLUMN_NAME='end_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order_item' AND COLUMN_NAME='end_time')!='bigint','ALTER TABLE `cb_order_item` CHANGE COLUMN `end_time_ts` `end_time` BIGINT NULL COMMENT ''服务结束时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE s400 FROM @p400;EXECUTE s400;DEALLOCATE PREPARE s400;
SET @p401=IF((SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order_item' AND COLUMN_NAME='create_time')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order_item' AND COLUMN_NAME='create_time_ts')=0,'ALTER TABLE `cb_order_item` ADD COLUMN `create_time_ts` BIGINT NOT NULL DEFAULT 0 COMMENT ''tmp'' AFTER `create_time`','SELECT 1');
PREPARE s401 FROM @p401;EXECUTE s401;DEALLOCATE PREPARE s401;
SET @p402=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order_item' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order_item' AND COLUMN_NAME='create_time')='datetime','UPDATE `cb_order_item` SET `create_time_ts`=UNIX_TIMESTAMP(`create_time`)','SELECT 1');
PREPARE s402 FROM @p402;EXECUTE s402;DEALLOCATE PREPARE s402;
SET @p403=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order_item' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order_item' AND COLUMN_NAME='create_time')='datetime','ALTER TABLE `cb_order_item` DROP COLUMN `create_time`','SELECT 1');
PREPARE s403 FROM @p403;EXECUTE s403;DEALLOCATE PREPARE s403;
SET @p404=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order_item' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order_item' AND COLUMN_NAME='create_time')!='bigint','ALTER TABLE `cb_order_item` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''创建时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE s404 FROM @p404;EXECUTE s404;DEALLOCATE PREPARE s404;
SET @p405=IF((SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order_item' AND COLUMN_NAME='update_time')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order_item' AND COLUMN_NAME='update_time_ts')=0,'ALTER TABLE `cb_order_item` ADD COLUMN `update_time_ts` BIGINT NOT NULL DEFAULT 0 COMMENT ''tmp'' AFTER `update_time`','SELECT 1');
PREPARE s405 FROM @p405;EXECUTE s405;DEALLOCATE PREPARE s405;
SET @p406=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order_item' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order_item' AND COLUMN_NAME='update_time')='datetime','UPDATE `cb_order_item` SET `update_time_ts`=UNIX_TIMESTAMP(`update_time`)','SELECT 1');
PREPARE s406 FROM @p406;EXECUTE s406;DEALLOCATE PREPARE s406;
SET @p407=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order_item' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order_item' AND COLUMN_NAME='update_time')='datetime','ALTER TABLE `cb_order_item` DROP COLUMN `update_time`','SELECT 1');
PREPARE s407 FROM @p407;EXECUTE s407;DEALLOCATE PREPARE s407;
SET @p408=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order_item' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order_item' AND COLUMN_NAME='update_time')!='bigint','ALTER TABLE `cb_order_item` CHANGE COLUMN `update_time_ts` `update_time` BIGINT NOT NULL COMMENT ''更新时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE s408 FROM @p408;EXECUTE s408;DEALLOCATE PREPARE s408;

-- ===== cb_technician_service_price =====
SET @p409=IF((SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician_service_price' AND COLUMN_NAME='create_time')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician_service_price' AND COLUMN_NAME='create_time_ts')=0,'ALTER TABLE `cb_technician_service_price` ADD COLUMN `create_time_ts` BIGINT NOT NULL DEFAULT 0 COMMENT ''tmp'' AFTER `create_time`','SELECT 1');
PREPARE s409 FROM @p409;EXECUTE s409;DEALLOCATE PREPARE s409;
SET @p410=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician_service_price' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician_service_price' AND COLUMN_NAME='create_time')='datetime','UPDATE `cb_technician_service_price` SET `create_time_ts`=UNIX_TIMESTAMP(`create_time`)','SELECT 1');
PREPARE s410 FROM @p410;EXECUTE s410;DEALLOCATE PREPARE s410;
SET @p411=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician_service_price' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician_service_price' AND COLUMN_NAME='create_time')='datetime','ALTER TABLE `cb_technician_service_price` DROP COLUMN `create_time`','SELECT 1');
PREPARE s411 FROM @p411;EXECUTE s411;DEALLOCATE PREPARE s411;
SET @p412=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician_service_price' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician_service_price' AND COLUMN_NAME='create_time')!='bigint','ALTER TABLE `cb_technician_service_price` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''创建时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE s412 FROM @p412;EXECUTE s412;DEALLOCATE PREPARE s412;
SET @p413=IF((SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician_service_price' AND COLUMN_NAME='update_time')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician_service_price' AND COLUMN_NAME='update_time_ts')=0,'ALTER TABLE `cb_technician_service_price` ADD COLUMN `update_time_ts` BIGINT NOT NULL DEFAULT 0 COMMENT ''tmp'' AFTER `update_time`','SELECT 1');
PREPARE s413 FROM @p413;EXECUTE s413;DEALLOCATE PREPARE s413;
SET @p414=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician_service_price' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician_service_price' AND COLUMN_NAME='update_time')='datetime','UPDATE `cb_technician_service_price` SET `update_time_ts`=UNIX_TIMESTAMP(`update_time`)','SELECT 1');
PREPARE s414 FROM @p414;EXECUTE s414;DEALLOCATE PREPARE s414;
SET @p415=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician_service_price' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician_service_price' AND COLUMN_NAME='update_time')='datetime','ALTER TABLE `cb_technician_service_price` DROP COLUMN `update_time`','SELECT 1');
PREPARE s415 FROM @p415;EXECUTE s415;DEALLOCATE PREPARE s415;
SET @p416=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician_service_price' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician_service_price' AND COLUMN_NAME='update_time')!='bigint','ALTER TABLE `cb_technician_service_price` CHANGE COLUMN `update_time_ts` `update_time` BIGINT NOT NULL COMMENT ''更新时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE s416 FROM @p416;EXECUTE s416;DEALLOCATE PREPARE s416;

-- ===== sys_oper_log =====
SET @p417=IF((SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_oper_log' AND COLUMN_NAME='oper_time')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_oper_log' AND COLUMN_NAME='oper_time_ts')=0,'ALTER TABLE `sys_oper_log` ADD COLUMN `oper_time_ts` BIGINT NULL COMMENT ''tmp'' AFTER `oper_time`','SELECT 1');
PREPARE s417 FROM @p417;EXECUTE s417;DEALLOCATE PREPARE s417;
SET @p418=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_oper_log' AND COLUMN_NAME='oper_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_oper_log' AND COLUMN_NAME='oper_time')='datetime','UPDATE `sys_oper_log` SET `oper_time_ts`=UNIX_TIMESTAMP(`oper_time`) WHERE `oper_time` IS NOT NULL','SELECT 1');
PREPARE s418 FROM @p418;EXECUTE s418;DEALLOCATE PREPARE s418;
SET @p419=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_oper_log' AND COLUMN_NAME='oper_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_oper_log' AND COLUMN_NAME='oper_time')='datetime','ALTER TABLE `sys_oper_log` DROP COLUMN `oper_time`','SELECT 1');
PREPARE s419 FROM @p419;EXECUTE s419;DEALLOCATE PREPARE s419;
SET @p420=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_oper_log' AND COLUMN_NAME='oper_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_oper_log' AND COLUMN_NAME='oper_time')!='bigint','ALTER TABLE `sys_oper_log` CHANGE COLUMN `oper_time_ts` `oper_time` BIGINT NULL COMMENT ''操作时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE s420 FROM @p420;EXECUTE s420;DEALLOCATE PREPARE s420;

-- ===== merchant_announcement_read =====
SET @p421=IF((SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='merchant_announcement_read' AND COLUMN_NAME='read_time')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='merchant_announcement_read' AND COLUMN_NAME='read_time_ts')=0,'ALTER TABLE `merchant_announcement_read` ADD COLUMN `read_time_ts` BIGINT NULL COMMENT ''tmp'' AFTER `read_time`','SELECT 1');
PREPARE s421 FROM @p421;EXECUTE s421;DEALLOCATE PREPARE s421;
SET @p422=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='merchant_announcement_read' AND COLUMN_NAME='read_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='merchant_announcement_read' AND COLUMN_NAME='read_time')='datetime','UPDATE `merchant_announcement_read` SET `read_time_ts`=UNIX_TIMESTAMP(`read_time`) WHERE `read_time` IS NOT NULL','SELECT 1');
PREPARE s422 FROM @p422;EXECUTE s422;DEALLOCATE PREPARE s422;
SET @p423=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='merchant_announcement_read' AND COLUMN_NAME='read_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='merchant_announcement_read' AND COLUMN_NAME='read_time')='datetime','ALTER TABLE `merchant_announcement_read` DROP COLUMN `read_time`','SELECT 1');
PREPARE s423 FROM @p423;EXECUTE s423;DEALLOCATE PREPARE s423;
SET @p424=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='merchant_announcement_read' AND COLUMN_NAME='read_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='merchant_announcement_read' AND COLUMN_NAME='read_time')!='bigint','ALTER TABLE `merchant_announcement_read` CHANGE COLUMN `read_time_ts` `read_time` BIGINT NULL COMMENT ''已读时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE s424 FROM @p424;EXECUTE s424;DEALLOCATE PREPARE s424;

-- =====================================================================
SELECT 'migrate_v5_2 完成：所有 DATETIME → BIGINT (UTC epoch seconds)' AS result;

-- ── migrate_v5_2_fixD.sql ─────────────────────────────────────────────────────────
-- migrate_v5_2_fixD.sql
-- 应急补丁：只执行 Step D（CHANGE _ts → 原列名）
-- 适用于：GUI 工具未完整执行完整脚本，导致 _ts 列残留的情况
--
SET NAMES utf8mb4;
SET SESSION time_zone = '+00:00';

SET @q1=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_i18n' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_i18n' AND COLUMN_NAME='create_time')!='bigint','ALTER TABLE `sys_i18n` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''创建时间，自动填充（UTC 秒级时间戳）''','SELECT 1');
PREPARE r1 FROM @q1;EXECUTE r1;DEALLOCATE PREPARE r1;
SET @q2=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_i18n' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_i18n' AND COLUMN_NAME='update_time')!='bigint','ALTER TABLE `sys_i18n` CHANGE COLUMN `update_time_ts` `update_time` BIGINT NOT NULL COMMENT ''最后修改时间，自动更新（UTC 秒级时间戳）''','SELECT 1');
PREPARE r2 FROM @q2;EXECUTE r2;DEALLOCATE PREPARE r2;
SET @q3=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_dict_type' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_dict_type' AND COLUMN_NAME='create_time')!='bigint','ALTER TABLE `sys_dict_type` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''创建时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r3 FROM @q3;EXECUTE r3;DEALLOCATE PREPARE r3;
SET @q4=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_dict_type' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_dict_type' AND COLUMN_NAME='update_time')!='bigint','ALTER TABLE `sys_dict_type` CHANGE COLUMN `update_time_ts` `update_time` BIGINT NOT NULL COMMENT ''最后修改时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r4 FROM @q4;EXECUTE r4;DEALLOCATE PREPARE r4;
SET @q5=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_dict' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_dict' AND COLUMN_NAME='create_time')!='bigint','ALTER TABLE `sys_dict` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''创建时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r5 FROM @q5;EXECUTE r5;DEALLOCATE PREPARE r5;
SET @q6=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_dict' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_dict' AND COLUMN_NAME='update_time')!='bigint','ALTER TABLE `sys_dict` CHANGE COLUMN `update_time_ts` `update_time` BIGINT NOT NULL COMMENT ''最后修改时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r6 FROM @q6;EXECUTE r6;DEALLOCATE PREPARE r6;
SET @q7=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_config' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_config' AND COLUMN_NAME='create_time')!='bigint','ALTER TABLE `sys_config` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''创建时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r7 FROM @q7;EXECUTE r7;DEALLOCATE PREPARE r7;
SET @q8=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_config' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_config' AND COLUMN_NAME='update_time')!='bigint','ALTER TABLE `sys_config` CHANGE COLUMN `update_time_ts` `update_time` BIGINT NOT NULL COMMENT ''最后修改时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r8 FROM @q8;EXECUTE r8;DEALLOCATE PREPARE r8;
SET @q9=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_user' AND COLUMN_NAME='last_login_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_user' AND COLUMN_NAME='last_login_time')!='bigint','ALTER TABLE `sys_user` CHANGE COLUMN `last_login_time_ts` `last_login_time` BIGINT NULL COMMENT ''最后一次登录时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r9 FROM @q9;EXECUTE r9;DEALLOCATE PREPARE r9;
SET @q10=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_user' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_user' AND COLUMN_NAME='create_time')!='bigint','ALTER TABLE `sys_user` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''账号创建时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r10 FROM @q10;EXECUTE r10;DEALLOCATE PREPARE r10;
SET @q11=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_user' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_user' AND COLUMN_NAME='update_time')!='bigint','ALTER TABLE `sys_user` CHANGE COLUMN `update_time_ts` `update_time` BIGINT NOT NULL COMMENT ''最后修改时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r11 FROM @q11;EXECUTE r11;DEALLOCATE PREPARE r11;
SET @q12=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_role' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_role' AND COLUMN_NAME='create_time')!='bigint','ALTER TABLE `sys_role` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''创建时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r12 FROM @q12;EXECUTE r12;DEALLOCATE PREPARE r12;
SET @q13=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_role' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_role' AND COLUMN_NAME='update_time')!='bigint','ALTER TABLE `sys_role` CHANGE COLUMN `update_time_ts` `update_time` BIGINT NOT NULL COMMENT ''最后修改时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r13 FROM @q13;EXECUTE r13;DEALLOCATE PREPARE r13;
SET @q14=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_permission' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_permission' AND COLUMN_NAME='create_time')!='bigint','ALTER TABLE `sys_permission` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''创建时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r14 FROM @q14;EXECUTE r14;DEALLOCATE PREPARE r14;
SET @q15=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_permission' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_permission' AND COLUMN_NAME='update_time')!='bigint','ALTER TABLE `sys_permission` CHANGE COLUMN `update_time_ts` `update_time` BIGINT NOT NULL COMMENT ''最后修改时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r15 FROM @q15;EXECUTE r15;DEALLOCATE PREPARE r15;
SET @q16=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_operation_log' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_operation_log' AND COLUMN_NAME='create_time')!='bigint','ALTER TABLE `sys_operation_log` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''操作发生时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r16 FROM @q16;EXECUTE r16;DEALLOCATE PREPARE r16;
SET @q17=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_member' AND COLUMN_NAME='register_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_member' AND COLUMN_NAME='register_time')!='bigint','ALTER TABLE `cb_member` CHANGE COLUMN `register_time_ts` `register_time` BIGINT NOT NULL COMMENT ''注册时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r17 FROM @q17;EXECUTE r17;DEALLOCATE PREPARE r17;
SET @q18=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_member' AND COLUMN_NAME='last_login_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_member' AND COLUMN_NAME='last_login_time')!='bigint','ALTER TABLE `cb_member` CHANGE COLUMN `last_login_time_ts` `last_login_time` BIGINT NULL COMMENT ''最后一次登录时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r18 FROM @q18;EXECUTE r18;DEALLOCATE PREPARE r18;
SET @q19=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_member' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_member' AND COLUMN_NAME='create_time')!='bigint','ALTER TABLE `cb_member` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''记录创建时间（同 register_time，由 MyBatis-Plus 自动填充）（UTC 秒级时间戳）''','SELECT 1');
PREPARE r19 FROM @q19;EXECUTE r19;DEALLOCATE PREPARE r19;
SET @q20=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_member' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_member' AND COLUMN_NAME='update_time')!='bigint','ALTER TABLE `cb_member` CHANGE COLUMN `update_time_ts` `update_time` BIGINT NOT NULL COMMENT ''记录最后修改时间，自动更新（UTC 秒级时间戳）''','SELECT 1');
PREPARE r20 FROM @q20;EXECUTE r20;DEALLOCATE PREPARE r20;
SET @q21=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician' AND COLUMN_NAME='create_time')!='bigint','ALTER TABLE `cb_technician` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''申请入驻时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r21 FROM @q21;EXECUTE r21;DEALLOCATE PREPARE r21;
SET @q22=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician' AND COLUMN_NAME='update_time')!='bigint','ALTER TABLE `cb_technician` CHANGE COLUMN `update_time_ts` `update_time` BIGINT NOT NULL COMMENT ''最后修改时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r22 FROM @q22;EXECUTE r22;DEALLOCATE PREPARE r22;
SET @q23=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_merchant' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_merchant' AND COLUMN_NAME='create_time')!='bigint','ALTER TABLE `cb_merchant` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''入驻申请时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r23 FROM @q23;EXECUTE r23;DEALLOCATE PREPARE r23;
SET @q24=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_merchant' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_merchant' AND COLUMN_NAME='update_time')!='bigint','ALTER TABLE `cb_merchant` CHANGE COLUMN `update_time_ts` `update_time` BIGINT NOT NULL COMMENT ''最后修改时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r24 FROM @q24;EXECUTE r24;DEALLOCATE PREPARE r24;
SET @q25=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_service_category' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_service_category' AND COLUMN_NAME='create_time')!='bigint','ALTER TABLE `cb_service_category` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''创建时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r25 FROM @q25;EXECUTE r25;DEALLOCATE PREPARE r25;
SET @q26=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_service_category' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_service_category' AND COLUMN_NAME='update_time')!='bigint','ALTER TABLE `cb_service_category` CHANGE COLUMN `update_time_ts` `update_time` BIGINT NOT NULL COMMENT ''最后修改时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r26 FROM @q26;EXECUTE r26;DEALLOCATE PREPARE r26;
SET @q27=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_service_item' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_service_item' AND COLUMN_NAME='create_time')!='bigint','ALTER TABLE `cb_service_item` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''创建时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r27 FROM @q27;EXECUTE r27;DEALLOCATE PREPARE r27;
SET @q28=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_service_item' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_service_item' AND COLUMN_NAME='update_time')!='bigint','ALTER TABLE `cb_service_item` CHANGE COLUMN `update_time_ts` `update_time` BIGINT NOT NULL COMMENT ''最后修改时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r28 FROM @q28;EXECUTE r28;DEALLOCATE PREPARE r28;
SET @q29=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order' AND COLUMN_NAME='appoint_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order' AND COLUMN_NAME='appoint_time')!='bigint','ALTER TABLE `cb_order` CHANGE COLUMN `appoint_time_ts` `appoint_time` BIGINT NOT NULL COMMENT ''预约服务开始时间（会员选择的上门时间）（UTC 秒级时间戳）''','SELECT 1');
PREPARE r29 FROM @q29;EXECUTE r29;DEALLOCATE PREPARE r29;
SET @q30=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order' AND COLUMN_NAME='start_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order' AND COLUMN_NAME='start_time')!='bigint','ALTER TABLE `cb_order` CHANGE COLUMN `start_time_ts` `start_time` BIGINT NULL COMMENT ''实际开始服务时间（技师操作开始）（UTC 秒级时间戳）''','SELECT 1');
PREPARE r30 FROM @q30;EXECUTE r30;DEALLOCATE PREPARE r30;
SET @q31=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order' AND COLUMN_NAME='end_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order' AND COLUMN_NAME='end_time')!='bigint','ALTER TABLE `cb_order` CHANGE COLUMN `end_time_ts` `end_time` BIGINT NULL COMMENT ''实际结束服务时间（技师操作完成）（UTC 秒级时间戳）''','SELECT 1');
PREPARE r31 FROM @q31;EXECUTE r31;DEALLOCATE PREPARE r31;
SET @q32=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order' AND COLUMN_NAME='pay_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order' AND COLUMN_NAME='pay_time')!='bigint','ALTER TABLE `cb_order` CHANGE COLUMN `pay_time_ts` `pay_time` BIGINT NULL COMMENT ''实际支付完成时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r32 FROM @q32;EXECUTE r32;DEALLOCATE PREPARE r32;
SET @q33=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order' AND COLUMN_NAME='create_time')!='bigint','ALTER TABLE `cb_order` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''下单时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r33 FROM @q33;EXECUTE r33;DEALLOCATE PREPARE r33;
SET @q34=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order' AND COLUMN_NAME='update_time')!='bigint','ALTER TABLE `cb_order` CHANGE COLUMN `update_time_ts` `update_time` BIGINT NOT NULL COMMENT ''最后修改时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r34 FROM @q34;EXECUTE r34;DEALLOCATE PREPARE r34;
SET @q35=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_review' AND COLUMN_NAME='reply_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_review' AND COLUMN_NAME='reply_time')!='bigint','ALTER TABLE `cb_review` CHANGE COLUMN `reply_time_ts` `reply_time` BIGINT NULL COMMENT ''技师回复时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r35 FROM @q35;EXECUTE r35;DEALLOCATE PREPARE r35;
SET @q36=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_review' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_review' AND COLUMN_NAME='create_time')!='bigint','ALTER TABLE `cb_review` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''评价发布时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r36 FROM @q36;EXECUTE r36;DEALLOCATE PREPARE r36;
SET @q37=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_review' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_review' AND COLUMN_NAME='update_time')!='bigint','ALTER TABLE `cb_review` CHANGE COLUMN `update_time_ts` `update_time` BIGINT NOT NULL COMMENT ''最后修改时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r37 FROM @q37;EXECUTE r37;DEALLOCATE PREPARE r37;
SET @q38=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_payment' AND COLUMN_NAME='refund_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_payment' AND COLUMN_NAME='refund_time')!='bigint','ALTER TABLE `cb_payment` CHANGE COLUMN `refund_time_ts` `refund_time` BIGINT NULL COMMENT ''退款完成时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r38 FROM @q38;EXECUTE r38;DEALLOCATE PREPARE r38;
SET @q39=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_payment' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_payment' AND COLUMN_NAME='create_time')!='bigint','ALTER TABLE `cb_payment` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''支付记录创建时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r39 FROM @q39;EXECUTE r39;DEALLOCATE PREPARE r39;
SET @q40=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_payment' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_payment' AND COLUMN_NAME='update_time')!='bigint','ALTER TABLE `cb_payment` CHANGE COLUMN `update_time_ts` `update_time` BIGINT NOT NULL COMMENT ''最后修改时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r40 FROM @q40;EXECUTE r40;DEALLOCATE PREPARE r40;
SET @q41=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_wallet' AND COLUMN_NAME='created_at_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_wallet' AND COLUMN_NAME='created_at')!='bigint','ALTER TABLE `cb_wallet` CHANGE COLUMN `created_at_ts` `created_at` BIGINT NOT NULL COMMENT ''创建时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r41 FROM @q41;EXECUTE r41;DEALLOCATE PREPARE r41;
SET @q42=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_wallet' AND COLUMN_NAME='updated_at_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_wallet' AND COLUMN_NAME='updated_at')!='bigint','ALTER TABLE `cb_wallet` CHANGE COLUMN `updated_at_ts` `updated_at` BIGINT NOT NULL COMMENT ''最后更新时间（用作乐观锁版本号）（UTC 秒级时间戳）''','SELECT 1');
PREPARE r42 FROM @q42;EXECUTE r42;DEALLOCATE PREPARE r42;
SET @q43=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_wallet_record' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_wallet_record' AND COLUMN_NAME='create_time')!='bigint','ALTER TABLE `cb_wallet_record` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''流水产生时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r43 FROM @q43;EXECUTE r43;DEALLOCATE PREPARE r43;
SET @q44=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_coupon_template' AND COLUMN_NAME='start_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_coupon_template' AND COLUMN_NAME='start_time')!='bigint','ALTER TABLE `cb_coupon_template` CHANGE COLUMN `start_time_ts` `start_time` BIGINT NULL COMMENT ''绝对有效期开始时间（与 valid_days 二选一）（UTC 秒级时间戳）''','SELECT 1');
PREPARE r44 FROM @q44;EXECUTE r44;DEALLOCATE PREPARE r44;
SET @q45=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_coupon_template' AND COLUMN_NAME='end_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_coupon_template' AND COLUMN_NAME='end_time')!='bigint','ALTER TABLE `cb_coupon_template` CHANGE COLUMN `end_time_ts` `end_time` BIGINT NULL COMMENT ''绝对有效期结束时间（与 valid_days 二选一）（UTC 秒级时间戳）''','SELECT 1');
PREPARE r45 FROM @q45;EXECUTE r45;DEALLOCATE PREPARE r45;
SET @q46=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_coupon_template' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_coupon_template' AND COLUMN_NAME='create_time')!='bigint','ALTER TABLE `cb_coupon_template` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''创建时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r46 FROM @q46;EXECUTE r46;DEALLOCATE PREPARE r46;
SET @q47=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_coupon_template' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_coupon_template' AND COLUMN_NAME='update_time')!='bigint','ALTER TABLE `cb_coupon_template` CHANGE COLUMN `update_time_ts` `update_time` BIGINT NOT NULL COMMENT ''最后修改时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r47 FROM @q47;EXECUTE r47;DEALLOCATE PREPARE r47;
SET @q48=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_member_coupon' AND COLUMN_NAME='use_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_member_coupon' AND COLUMN_NAME='use_time')!='bigint','ALTER TABLE `cb_member_coupon` CHANGE COLUMN `use_time_ts` `use_time` BIGINT NULL COMMENT ''实际使用时间（status=1时填写）（UTC 秒级时间戳）''','SELECT 1');
PREPARE r48 FROM @q48;EXECUTE r48;DEALLOCATE PREPARE r48;
SET @q49=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_member_coupon' AND COLUMN_NAME='expire_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_member_coupon' AND COLUMN_NAME='expire_time')!='bigint','ALTER TABLE `cb_member_coupon` CHANGE COLUMN `expire_time_ts` `expire_time` BIGINT NOT NULL COMMENT ''过期时间（根据模板 valid_days 或 end_time 计算后写入）（UTC 秒级时间戳）''','SELECT 1');
PREPARE r49 FROM @q49;EXECUTE r49;DEALLOCATE PREPARE r49;
SET @q50=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_member_coupon' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_member_coupon' AND COLUMN_NAME='create_time')!='bigint','ALTER TABLE `cb_member_coupon` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''领取时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r50 FROM @q50;EXECUTE r50;DEALLOCATE PREPARE r50;
SET @q51=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_address' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_address' AND COLUMN_NAME='create_time')!='bigint','ALTER TABLE `cb_address` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''创建时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r51 FROM @q51;EXECUTE r51;DEALLOCATE PREPARE r51;
SET @q52=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_address' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_address' AND COLUMN_NAME='update_time')!='bigint','ALTER TABLE `cb_address` CHANGE COLUMN `update_time_ts` `update_time` BIGINT NOT NULL COMMENT ''最后修改时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r52 FROM @q52;EXECUTE r52;DEALLOCATE PREPARE r52;
SET @q53=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician_schedule' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician_schedule' AND COLUMN_NAME='create_time')!='bigint','ALTER TABLE `cb_technician_schedule` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''创建时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r53 FROM @q53;EXECUTE r53;DEALLOCATE PREPARE r53;
SET @q54=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_banner' AND COLUMN_NAME='start_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_banner' AND COLUMN_NAME='start_time')!='bigint','ALTER TABLE `cb_banner` CHANGE COLUMN `start_time_ts` `start_time` BIGINT NULL COMMENT ''生效开始时间（为空则立即生效）（UTC 秒级时间戳）''','SELECT 1');
PREPARE r54 FROM @q54;EXECUTE r54;DEALLOCATE PREPARE r54;
SET @q55=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_banner' AND COLUMN_NAME='end_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_banner' AND COLUMN_NAME='end_time')!='bigint','ALTER TABLE `cb_banner` CHANGE COLUMN `end_time_ts` `end_time` BIGINT NULL COMMENT ''生效结束时间（为空则永久有效）（UTC 秒级时间戳）''','SELECT 1');
PREPARE r55 FROM @q55;EXECUTE r55;DEALLOCATE PREPARE r55;
SET @q56=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_banner' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_banner' AND COLUMN_NAME='create_time')!='bigint','ALTER TABLE `cb_banner` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''创建时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r56 FROM @q56;EXECUTE r56;DEALLOCATE PREPARE r56;
SET @q57=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_banner' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_banner' AND COLUMN_NAME='update_time')!='bigint','ALTER TABLE `cb_banner` CHANGE COLUMN `update_time_ts` `update_time` BIGINT NOT NULL COMMENT ''最后修改时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r57 FROM @q57;EXECUTE r57;DEALLOCATE PREPARE r57;
SET @q58=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_nav' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_nav' AND COLUMN_NAME='create_time')!='bigint','ALTER TABLE `cb_nav` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''创建时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r58 FROM @q58;EXECUTE r58;DEALLOCATE PREPARE r58;
SET @q59=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_nav' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_nav' AND COLUMN_NAME='update_time')!='bigint','ALTER TABLE `cb_nav` CHANGE COLUMN `update_time_ts` `update_time` BIGINT NOT NULL COMMENT ''最后修改时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r59 FROM @q59;EXECUTE r59;DEALLOCATE PREPARE r59;
SET @q60=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_icon' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_icon' AND COLUMN_NAME='create_time')!='bigint','ALTER TABLE `cb_icon` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''创建时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r60 FROM @q60;EXECUTE r60;DEALLOCATE PREPARE r60;
SET @q61=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_icon' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_icon' AND COLUMN_NAME='update_time')!='bigint','ALTER TABLE `cb_icon` CHANGE COLUMN `update_time_ts` `update_time` BIGINT NOT NULL COMMENT ''最后修改时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r61 FROM @q61;EXECUTE r61;DEALLOCATE PREPARE r61;
SET @q62=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_tag' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_tag' AND COLUMN_NAME='create_time')!='bigint','ALTER TABLE `cb_tag` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''创建时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r62 FROM @q62;EXECUTE r62;DEALLOCATE PREPARE r62;
SET @q63=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_im_session' AND COLUMN_NAME='last_msg_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_im_session' AND COLUMN_NAME='last_msg_time')!='bigint','ALTER TABLE `cb_im_session` CHANGE COLUMN `last_msg_time_ts` `last_msg_time` BIGINT NULL COMMENT ''最后一条消息发送时间（用于会话列表按时间倒序）（UTC 秒级时间戳）''','SELECT 1');
PREPARE r63 FROM @q63;EXECUTE r63;DEALLOCATE PREPARE r63;
SET @q64=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_im_session' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_im_session' AND COLUMN_NAME='create_time')!='bigint','ALTER TABLE `cb_im_session` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''会话创建时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r64 FROM @q64;EXECUTE r64;DEALLOCATE PREPARE r64;
SET @q65=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_im_session' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_im_session' AND COLUMN_NAME='update_time')!='bigint','ALTER TABLE `cb_im_session` CHANGE COLUMN `update_time_ts` `update_time` BIGINT NOT NULL COMMENT ''最后消息更新时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r65 FROM @q65;EXECUTE r65;DEALLOCATE PREPARE r65;
SET @q66=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_im_message' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_im_message' AND COLUMN_NAME='create_time')!='bigint','ALTER TABLE `cb_im_message` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''消息发送时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r66 FROM @q66;EXECUTE r66;DEALLOCATE PREPARE r66;
SET @q67=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_notification' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_notification' AND COLUMN_NAME='create_time')!='bigint','ALTER TABLE `cb_notification` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''通知推送时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r67 FROM @q67;EXECUTE r67;DEALLOCATE PREPARE r67;
SET @q68=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_login_log' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_login_log' AND COLUMN_NAME='create_time')!='bigint','ALTER TABLE `cb_login_log` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''登录时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r68 FROM @q68;EXECUTE r68;DEALLOCATE PREPARE r68;
SET @q69=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_driver' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_driver' AND COLUMN_NAME='create_time')!='bigint','ALTER TABLE `cb_driver` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''申请注册时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r69 FROM @q69;EXECUTE r69;DEALLOCATE PREPARE r69;
SET @q70=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_driver' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_driver' AND COLUMN_NAME='update_time')!='bigint','ALTER TABLE `cb_driver` CHANGE COLUMN `update_time_ts` `update_time` BIGINT NOT NULL COMMENT ''最后修改时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r70 FROM @q70;EXECUTE r70;DEALLOCATE PREPARE r70;
SET @q71=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_vehicle' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_vehicle' AND COLUMN_NAME='create_time')!='bigint','ALTER TABLE `cb_vehicle` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''车辆录入时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r71 FROM @q71;EXECUTE r71;DEALLOCATE PREPARE r71;
SET @q72=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_vehicle' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_vehicle' AND COLUMN_NAME='update_time')!='bigint','ALTER TABLE `cb_vehicle` CHANGE COLUMN `update_time_ts` `update_time` BIGINT NOT NULL COMMENT ''最后修改时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r72 FROM @q72;EXECUTE r72;DEALLOCATE PREPARE r72;
SET @q73=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_dispatch_order' AND COLUMN_NAME='pickup_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_dispatch_order' AND COLUMN_NAME='pickup_time')!='bigint','ALTER TABLE `cb_dispatch_order` CHANGE COLUMN `pickup_time_ts` `pickup_time` BIGINT NOT NULL COMMENT ''预约接送时间（会员选择的上车时间）（UTC 秒级时间戳）''','SELECT 1');
PREPARE r73 FROM @q73;EXECUTE r73;DEALLOCATE PREPARE r73;
SET @q74=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_dispatch_order' AND COLUMN_NAME='actual_pickup_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_dispatch_order' AND COLUMN_NAME='actual_pickup_time')!='bigint','ALTER TABLE `cb_dispatch_order` CHANGE COLUMN `actual_pickup_time_ts` `actual_pickup_time` BIGINT NULL COMMENT ''实际接到乘客时间（司机操作"已接到"时记录）（UTC 秒级时间戳）''','SELECT 1');
PREPARE r74 FROM @q74;EXECUTE r74;DEALLOCATE PREPARE r74;
SET @q75=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_dispatch_order' AND COLUMN_NAME='finish_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_dispatch_order' AND COLUMN_NAME='finish_time')!='bigint','ALTER TABLE `cb_dispatch_order` CHANGE COLUMN `finish_time_ts` `finish_time` BIGINT NULL COMMENT ''行程完成时间（司机操作"已送达"时记录）（UTC 秒级时间戳）''','SELECT 1');
PREPARE r75 FROM @q75;EXECUTE r75;DEALLOCATE PREPARE r75;
SET @q76=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_dispatch_order' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_dispatch_order' AND COLUMN_NAME='create_time')!='bigint','ALTER TABLE `cb_dispatch_order` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''派车单创建时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r76 FROM @q76;EXECUTE r76;DEALLOCATE PREPARE r76;
SET @q77=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_dispatch_order' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_dispatch_order' AND COLUMN_NAME='update_time')!='bigint','ALTER TABLE `cb_dispatch_order` CHANGE COLUMN `update_time_ts` `update_time` BIGINT NOT NULL COMMENT ''最后修改时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r77 FROM @q77;EXECUTE r77;DEALLOCATE PREPARE r77;
SET @q78=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_walkin_session' AND COLUMN_NAME='check_in_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_walkin_session' AND COLUMN_NAME='check_in_time')!='bigint','ALTER TABLE `cb_walkin_session` CHANGE COLUMN `check_in_time_ts` `check_in_time` BIGINT NOT NULL COMMENT ''签到时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r78 FROM @q78;EXECUTE r78;DEALLOCATE PREPARE r78;
SET @q79=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_walkin_session' AND COLUMN_NAME='check_out_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_walkin_session' AND COLUMN_NAME='check_out_time')!='bigint','ALTER TABLE `cb_walkin_session` CHANGE COLUMN `check_out_time_ts` `check_out_time` BIGINT NULL COMMENT ''签出时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r79 FROM @q79;EXECUTE r79;DEALLOCATE PREPARE r79;
SET @q80=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_walkin_session' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_walkin_session' AND COLUMN_NAME='create_time')!='bigint','ALTER TABLE `cb_walkin_session` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''创建时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r80 FROM @q80;EXECUTE r80;DEALLOCATE PREPARE r80;
SET @q81=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_walkin_session' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_walkin_session' AND COLUMN_NAME='update_time')!='bigint','ALTER TABLE `cb_walkin_session` CHANGE COLUMN `update_time_ts` `update_time` BIGINT NOT NULL COMMENT ''更新时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r81 FROM @q81;EXECUTE r81;DEALLOCATE PREPARE r81;
SET @q82=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_payment_record' AND COLUMN_NAME='pay_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_payment_record' AND COLUMN_NAME='pay_time')!='bigint','ALTER TABLE `cb_payment_record` CHANGE COLUMN `pay_time_ts` `pay_time` BIGINT NULL COMMENT ''支付时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r82 FROM @q82;EXECUTE r82;DEALLOCATE PREPARE r82;
SET @q83=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_payment_record' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_payment_record' AND COLUMN_NAME='create_time')!='bigint','ALTER TABLE `cb_payment_record` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''创建时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r83 FROM @q83;EXECUTE r83;DEALLOCATE PREPARE r83;
SET @q84=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_vehicle_dispatch' AND COLUMN_NAME='depart_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_vehicle_dispatch' AND COLUMN_NAME='depart_time')!='bigint','ALTER TABLE `cb_vehicle_dispatch` CHANGE COLUMN `depart_time_ts` `depart_time` BIGINT NULL COMMENT ''出发时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r84 FROM @q84;EXECUTE r84;DEALLOCATE PREPARE r84;
SET @q85=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_vehicle_dispatch' AND COLUMN_NAME='return_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_vehicle_dispatch' AND COLUMN_NAME='return_time')!='bigint','ALTER TABLE `cb_vehicle_dispatch` CHANGE COLUMN `return_time_ts` `return_time` BIGINT NULL COMMENT ''返回时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r85 FROM @q85;EXECUTE r85;DEALLOCATE PREPARE r85;
SET @q86=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_vehicle_dispatch' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_vehicle_dispatch' AND COLUMN_NAME='create_time')!='bigint','ALTER TABLE `cb_vehicle_dispatch` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''创建时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r86 FROM @q86;EXECUTE r86;DEALLOCATE PREPARE r86;
SET @q87=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_vehicle_dispatch' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_vehicle_dispatch' AND COLUMN_NAME='update_time')!='bigint','ALTER TABLE `cb_vehicle_dispatch` CHANGE COLUMN `update_time_ts` `update_time` BIGINT NOT NULL COMMENT ''更新时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r87 FROM @q87;EXECUTE r87;DEALLOCATE PREPARE r87;
SET @q88=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_finance_expense' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_finance_expense' AND COLUMN_NAME='create_time')!='bigint','ALTER TABLE `cb_finance_expense` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''创建时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r88 FROM @q88;EXECUTE r88;DEALLOCATE PREPARE r88;
SET @q89=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_finance_expense' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_finance_expense' AND COLUMN_NAME='update_time')!='bigint','ALTER TABLE `cb_finance_expense` CHANGE COLUMN `update_time_ts` `update_time` BIGINT NOT NULL COMMENT ''更新时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r89 FROM @q89;EXECUTE r89;DEALLOCATE PREPARE r89;
SET @q90=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_finance_salary' AND COLUMN_NAME='pay_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_finance_salary' AND COLUMN_NAME='pay_time')!='bigint','ALTER TABLE `cb_finance_salary` CHANGE COLUMN `pay_time_ts` `pay_time` BIGINT NULL COMMENT ''发薪时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r90 FROM @q90;EXECUTE r90;DEALLOCATE PREPARE r90;
SET @q91=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_finance_salary' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_finance_salary' AND COLUMN_NAME='create_time')!='bigint','ALTER TABLE `cb_finance_salary` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''创建时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r91 FROM @q91;EXECUTE r91;DEALLOCATE PREPARE r91;
SET @q92=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_finance_salary' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_finance_salary' AND COLUMN_NAME='update_time')!='bigint','ALTER TABLE `cb_finance_salary` CHANGE COLUMN `update_time_ts` `update_time` BIGINT NOT NULL COMMENT ''更新时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r92 FROM @q92;EXECUTE r92;DEALLOCATE PREPARE r92;
SET @q93=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician_settlement' AND COLUMN_NAME='paid_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician_settlement' AND COLUMN_NAME='paid_time')!='bigint','ALTER TABLE `cb_technician_settlement` CHANGE COLUMN `paid_time_ts` `paid_time` BIGINT NULL COMMENT ''打款时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r93 FROM @q93;EXECUTE r93;DEALLOCATE PREPARE r93;
SET @q94=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician_settlement' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician_settlement' AND COLUMN_NAME='create_time')!='bigint','ALTER TABLE `cb_technician_settlement` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''创建时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r94 FROM @q94;EXECUTE r94;DEALLOCATE PREPARE r94;
SET @q95=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician_settlement' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician_settlement' AND COLUMN_NAME='update_time')!='bigint','ALTER TABLE `cb_technician_settlement` CHANGE COLUMN `update_time_ts` `update_time` BIGINT NOT NULL COMMENT ''更新时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r95 FROM @q95;EXECUTE r95;DEALLOCATE PREPARE r95;
SET @q96=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician_settlement_item' AND COLUMN_NAME='service_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician_settlement_item' AND COLUMN_NAME='service_time')!='bigint','ALTER TABLE `cb_technician_settlement_item` CHANGE COLUMN `service_time_ts` `service_time` BIGINT NULL COMMENT ''服务时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r96 FROM @q96;EXECUTE r96;DEALLOCATE PREPARE r96;
SET @q97=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_commission_rule' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_commission_rule' AND COLUMN_NAME='create_time')!='bigint','ALTER TABLE `cb_commission_rule` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''创建时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r97 FROM @q97;EXECUTE r97;DEALLOCATE PREPARE r97;
SET @q98=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_commission_rule' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_commission_rule' AND COLUMN_NAME='update_time')!='bigint','ALTER TABLE `cb_commission_rule` CHANGE COLUMN `update_time_ts` `update_time` BIGINT NOT NULL COMMENT ''更新时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r98 FROM @q98;EXECUTE r98;DEALLOCATE PREPARE r98;
SET @q99=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order_item' AND COLUMN_NAME='start_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order_item' AND COLUMN_NAME='start_time')!='bigint','ALTER TABLE `cb_order_item` CHANGE COLUMN `start_time_ts` `start_time` BIGINT NULL COMMENT ''服务开始时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r99 FROM @q99;EXECUTE r99;DEALLOCATE PREPARE r99;
SET @q100=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order_item' AND COLUMN_NAME='end_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order_item' AND COLUMN_NAME='end_time')!='bigint','ALTER TABLE `cb_order_item` CHANGE COLUMN `end_time_ts` `end_time` BIGINT NULL COMMENT ''服务结束时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r100 FROM @q100;EXECUTE r100;DEALLOCATE PREPARE r100;
SET @q101=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order_item' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order_item' AND COLUMN_NAME='create_time')!='bigint','ALTER TABLE `cb_order_item` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''创建时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r101 FROM @q101;EXECUTE r101;DEALLOCATE PREPARE r101;
SET @q102=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order_item' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order_item' AND COLUMN_NAME='update_time')!='bigint','ALTER TABLE `cb_order_item` CHANGE COLUMN `update_time_ts` `update_time` BIGINT NOT NULL COMMENT ''更新时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r102 FROM @q102;EXECUTE r102;DEALLOCATE PREPARE r102;
SET @q103=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician_service_price' AND COLUMN_NAME='create_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician_service_price' AND COLUMN_NAME='create_time')!='bigint','ALTER TABLE `cb_technician_service_price` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''创建时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r103 FROM @q103;EXECUTE r103;DEALLOCATE PREPARE r103;
SET @q104=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician_service_price' AND COLUMN_NAME='update_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician_service_price' AND COLUMN_NAME='update_time')!='bigint','ALTER TABLE `cb_technician_service_price` CHANGE COLUMN `update_time_ts` `update_time` BIGINT NOT NULL COMMENT ''更新时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r104 FROM @q104;EXECUTE r104;DEALLOCATE PREPARE r104;
SET @q105=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_oper_log' AND COLUMN_NAME='oper_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_oper_log' AND COLUMN_NAME='oper_time')!='bigint','ALTER TABLE `sys_oper_log` CHANGE COLUMN `oper_time_ts` `oper_time` BIGINT NULL COMMENT ''操作时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r105 FROM @q105;EXECUTE r105;DEALLOCATE PREPARE r105;
SET @q106=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='merchant_announcement_read' AND COLUMN_NAME='read_time_ts')>0 AND (SELECT IFNULL(DATA_TYPE,'') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='merchant_announcement_read' AND COLUMN_NAME='read_time')!='bigint','ALTER TABLE `merchant_announcement_read` CHANGE COLUMN `read_time_ts` `read_time` BIGINT NULL COMMENT ''已读时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r106 FROM @q106;EXECUTE r106;DEALLOCATE PREPARE r106;

SELECT 'fixD 完成' AS result;

-- ── migrate_v5_3_fix.sql ─────────────────────────────────────────────────────────
-- migrate_v5_3_fix.sql
-- 修复：将所有残留 _ts 列重命名为原列名（或在原列已存在时删除孤立 _ts）
-- 修正了 dtype() 中 IFNULL 放错位置的 bug（列不存在时子查询返回 NULL 而非 ''）
--
SET NAMES utf8mb4;

SET @q1=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_i18n' AND COLUMN_NAME='create_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_i18n' AND COLUMN_NAME='create_time'),'')!='bigint','ALTER TABLE `sys_i18n` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''创建时间，自动填充（UTC 秒级时间戳）''','SELECT 1');
PREPARE r1 FROM @q1;EXECUTE r1;DEALLOCATE PREPARE r1;
SET @q2=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_i18n' AND COLUMN_NAME='create_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_i18n' AND COLUMN_NAME='create_time'),'')='bigint','ALTER TABLE `sys_i18n` DROP COLUMN `create_time_ts`','SELECT 1');
PREPARE r2 FROM @q2;EXECUTE r2;DEALLOCATE PREPARE r2;
SET @q3=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_i18n' AND COLUMN_NAME='update_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_i18n' AND COLUMN_NAME='update_time'),'')!='bigint','ALTER TABLE `sys_i18n` CHANGE COLUMN `update_time_ts` `update_time` BIGINT NOT NULL COMMENT ''最后修改时间，自动更新（UTC 秒级时间戳）''','SELECT 1');
PREPARE r3 FROM @q3;EXECUTE r3;DEALLOCATE PREPARE r3;
SET @q4=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_i18n' AND COLUMN_NAME='update_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_i18n' AND COLUMN_NAME='update_time'),'')='bigint','ALTER TABLE `sys_i18n` DROP COLUMN `update_time_ts`','SELECT 1');
PREPARE r4 FROM @q4;EXECUTE r4;DEALLOCATE PREPARE r4;
SET @q5=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_dict_type' AND COLUMN_NAME='create_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_dict_type' AND COLUMN_NAME='create_time'),'')!='bigint','ALTER TABLE `sys_dict_type` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''创建时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r5 FROM @q5;EXECUTE r5;DEALLOCATE PREPARE r5;
SET @q6=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_dict_type' AND COLUMN_NAME='create_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_dict_type' AND COLUMN_NAME='create_time'),'')='bigint','ALTER TABLE `sys_dict_type` DROP COLUMN `create_time_ts`','SELECT 1');
PREPARE r6 FROM @q6;EXECUTE r6;DEALLOCATE PREPARE r6;
SET @q7=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_dict_type' AND COLUMN_NAME='update_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_dict_type' AND COLUMN_NAME='update_time'),'')!='bigint','ALTER TABLE `sys_dict_type` CHANGE COLUMN `update_time_ts` `update_time` BIGINT NOT NULL COMMENT ''最后修改时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r7 FROM @q7;EXECUTE r7;DEALLOCATE PREPARE r7;
SET @q8=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_dict_type' AND COLUMN_NAME='update_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_dict_type' AND COLUMN_NAME='update_time'),'')='bigint','ALTER TABLE `sys_dict_type` DROP COLUMN `update_time_ts`','SELECT 1');
PREPARE r8 FROM @q8;EXECUTE r8;DEALLOCATE PREPARE r8;
SET @q9=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_dict' AND COLUMN_NAME='create_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_dict' AND COLUMN_NAME='create_time'),'')!='bigint','ALTER TABLE `sys_dict` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''创建时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r9 FROM @q9;EXECUTE r9;DEALLOCATE PREPARE r9;
SET @q10=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_dict' AND COLUMN_NAME='create_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_dict' AND COLUMN_NAME='create_time'),'')='bigint','ALTER TABLE `sys_dict` DROP COLUMN `create_time_ts`','SELECT 1');
PREPARE r10 FROM @q10;EXECUTE r10;DEALLOCATE PREPARE r10;
SET @q11=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_dict' AND COLUMN_NAME='update_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_dict' AND COLUMN_NAME='update_time'),'')!='bigint','ALTER TABLE `sys_dict` CHANGE COLUMN `update_time_ts` `update_time` BIGINT NOT NULL COMMENT ''最后修改时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r11 FROM @q11;EXECUTE r11;DEALLOCATE PREPARE r11;
SET @q12=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_dict' AND COLUMN_NAME='update_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_dict' AND COLUMN_NAME='update_time'),'')='bigint','ALTER TABLE `sys_dict` DROP COLUMN `update_time_ts`','SELECT 1');
PREPARE r12 FROM @q12;EXECUTE r12;DEALLOCATE PREPARE r12;
SET @q13=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_config' AND COLUMN_NAME='create_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_config' AND COLUMN_NAME='create_time'),'')!='bigint','ALTER TABLE `sys_config` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''创建时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r13 FROM @q13;EXECUTE r13;DEALLOCATE PREPARE r13;
SET @q14=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_config' AND COLUMN_NAME='create_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_config' AND COLUMN_NAME='create_time'),'')='bigint','ALTER TABLE `sys_config` DROP COLUMN `create_time_ts`','SELECT 1');
PREPARE r14 FROM @q14;EXECUTE r14;DEALLOCATE PREPARE r14;
SET @q15=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_config' AND COLUMN_NAME='update_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_config' AND COLUMN_NAME='update_time'),'')!='bigint','ALTER TABLE `sys_config` CHANGE COLUMN `update_time_ts` `update_time` BIGINT NOT NULL COMMENT ''最后修改时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r15 FROM @q15;EXECUTE r15;DEALLOCATE PREPARE r15;
SET @q16=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_config' AND COLUMN_NAME='update_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_config' AND COLUMN_NAME='update_time'),'')='bigint','ALTER TABLE `sys_config` DROP COLUMN `update_time_ts`','SELECT 1');
PREPARE r16 FROM @q16;EXECUTE r16;DEALLOCATE PREPARE r16;
SET @q17=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_user' AND COLUMN_NAME='last_login_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_user' AND COLUMN_NAME='last_login_time'),'')!='bigint','ALTER TABLE `sys_user` CHANGE COLUMN `last_login_time_ts` `last_login_time` BIGINT NULL COMMENT ''最后一次登录时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r17 FROM @q17;EXECUTE r17;DEALLOCATE PREPARE r17;
SET @q18=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_user' AND COLUMN_NAME='last_login_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_user' AND COLUMN_NAME='last_login_time'),'')='bigint','ALTER TABLE `sys_user` DROP COLUMN `last_login_time_ts`','SELECT 1');
PREPARE r18 FROM @q18;EXECUTE r18;DEALLOCATE PREPARE r18;
SET @q19=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_user' AND COLUMN_NAME='create_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_user' AND COLUMN_NAME='create_time'),'')!='bigint','ALTER TABLE `sys_user` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''账号创建时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r19 FROM @q19;EXECUTE r19;DEALLOCATE PREPARE r19;
SET @q20=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_user' AND COLUMN_NAME='create_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_user' AND COLUMN_NAME='create_time'),'')='bigint','ALTER TABLE `sys_user` DROP COLUMN `create_time_ts`','SELECT 1');
PREPARE r20 FROM @q20;EXECUTE r20;DEALLOCATE PREPARE r20;
SET @q21=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_user' AND COLUMN_NAME='update_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_user' AND COLUMN_NAME='update_time'),'')!='bigint','ALTER TABLE `sys_user` CHANGE COLUMN `update_time_ts` `update_time` BIGINT NOT NULL COMMENT ''最后修改时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r21 FROM @q21;EXECUTE r21;DEALLOCATE PREPARE r21;
SET @q22=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_user' AND COLUMN_NAME='update_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_user' AND COLUMN_NAME='update_time'),'')='bigint','ALTER TABLE `sys_user` DROP COLUMN `update_time_ts`','SELECT 1');
PREPARE r22 FROM @q22;EXECUTE r22;DEALLOCATE PREPARE r22;
SET @q23=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_role' AND COLUMN_NAME='create_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_role' AND COLUMN_NAME='create_time'),'')!='bigint','ALTER TABLE `sys_role` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''创建时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r23 FROM @q23;EXECUTE r23;DEALLOCATE PREPARE r23;
SET @q24=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_role' AND COLUMN_NAME='create_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_role' AND COLUMN_NAME='create_time'),'')='bigint','ALTER TABLE `sys_role` DROP COLUMN `create_time_ts`','SELECT 1');
PREPARE r24 FROM @q24;EXECUTE r24;DEALLOCATE PREPARE r24;
SET @q25=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_role' AND COLUMN_NAME='update_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_role' AND COLUMN_NAME='update_time'),'')!='bigint','ALTER TABLE `sys_role` CHANGE COLUMN `update_time_ts` `update_time` BIGINT NOT NULL COMMENT ''最后修改时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r25 FROM @q25;EXECUTE r25;DEALLOCATE PREPARE r25;
SET @q26=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_role' AND COLUMN_NAME='update_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_role' AND COLUMN_NAME='update_time'),'')='bigint','ALTER TABLE `sys_role` DROP COLUMN `update_time_ts`','SELECT 1');
PREPARE r26 FROM @q26;EXECUTE r26;DEALLOCATE PREPARE r26;
SET @q27=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_permission' AND COLUMN_NAME='create_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_permission' AND COLUMN_NAME='create_time'),'')!='bigint','ALTER TABLE `sys_permission` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''创建时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r27 FROM @q27;EXECUTE r27;DEALLOCATE PREPARE r27;
SET @q28=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_permission' AND COLUMN_NAME='create_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_permission' AND COLUMN_NAME='create_time'),'')='bigint','ALTER TABLE `sys_permission` DROP COLUMN `create_time_ts`','SELECT 1');
PREPARE r28 FROM @q28;EXECUTE r28;DEALLOCATE PREPARE r28;
SET @q29=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_permission' AND COLUMN_NAME='update_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_permission' AND COLUMN_NAME='update_time'),'')!='bigint','ALTER TABLE `sys_permission` CHANGE COLUMN `update_time_ts` `update_time` BIGINT NOT NULL COMMENT ''最后修改时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r29 FROM @q29;EXECUTE r29;DEALLOCATE PREPARE r29;
SET @q30=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_permission' AND COLUMN_NAME='update_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_permission' AND COLUMN_NAME='update_time'),'')='bigint','ALTER TABLE `sys_permission` DROP COLUMN `update_time_ts`','SELECT 1');
PREPARE r30 FROM @q30;EXECUTE r30;DEALLOCATE PREPARE r30;
SET @q31=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_operation_log' AND COLUMN_NAME='create_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_operation_log' AND COLUMN_NAME='create_time'),'')!='bigint','ALTER TABLE `sys_operation_log` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''操作发生时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r31 FROM @q31;EXECUTE r31;DEALLOCATE PREPARE r31;
SET @q32=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_operation_log' AND COLUMN_NAME='create_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_operation_log' AND COLUMN_NAME='create_time'),'')='bigint','ALTER TABLE `sys_operation_log` DROP COLUMN `create_time_ts`','SELECT 1');
PREPARE r32 FROM @q32;EXECUTE r32;DEALLOCATE PREPARE r32;
SET @q33=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_member' AND COLUMN_NAME='register_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_member' AND COLUMN_NAME='register_time'),'')!='bigint','ALTER TABLE `cb_member` CHANGE COLUMN `register_time_ts` `register_time` BIGINT NOT NULL COMMENT ''注册时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r33 FROM @q33;EXECUTE r33;DEALLOCATE PREPARE r33;
SET @q34=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_member' AND COLUMN_NAME='register_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_member' AND COLUMN_NAME='register_time'),'')='bigint','ALTER TABLE `cb_member` DROP COLUMN `register_time_ts`','SELECT 1');
PREPARE r34 FROM @q34;EXECUTE r34;DEALLOCATE PREPARE r34;
SET @q35=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_member' AND COLUMN_NAME='last_login_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_member' AND COLUMN_NAME='last_login_time'),'')!='bigint','ALTER TABLE `cb_member` CHANGE COLUMN `last_login_time_ts` `last_login_time` BIGINT NULL COMMENT ''最后一次登录时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r35 FROM @q35;EXECUTE r35;DEALLOCATE PREPARE r35;
SET @q36=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_member' AND COLUMN_NAME='last_login_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_member' AND COLUMN_NAME='last_login_time'),'')='bigint','ALTER TABLE `cb_member` DROP COLUMN `last_login_time_ts`','SELECT 1');
PREPARE r36 FROM @q36;EXECUTE r36;DEALLOCATE PREPARE r36;
SET @q37=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_member' AND COLUMN_NAME='create_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_member' AND COLUMN_NAME='create_time'),'')!='bigint','ALTER TABLE `cb_member` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''记录创建时间（同 register_time，由 MyBatis-Plus 自动填充）（UTC 秒级时间戳）''','SELECT 1');
PREPARE r37 FROM @q37;EXECUTE r37;DEALLOCATE PREPARE r37;
SET @q38=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_member' AND COLUMN_NAME='create_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_member' AND COLUMN_NAME='create_time'),'')='bigint','ALTER TABLE `cb_member` DROP COLUMN `create_time_ts`','SELECT 1');
PREPARE r38 FROM @q38;EXECUTE r38;DEALLOCATE PREPARE r38;
SET @q39=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_member' AND COLUMN_NAME='update_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_member' AND COLUMN_NAME='update_time'),'')!='bigint','ALTER TABLE `cb_member` CHANGE COLUMN `update_time_ts` `update_time` BIGINT NOT NULL COMMENT ''记录最后修改时间，自动更新（UTC 秒级时间戳）''','SELECT 1');
PREPARE r39 FROM @q39;EXECUTE r39;DEALLOCATE PREPARE r39;
SET @q40=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_member' AND COLUMN_NAME='update_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_member' AND COLUMN_NAME='update_time'),'')='bigint','ALTER TABLE `cb_member` DROP COLUMN `update_time_ts`','SELECT 1');
PREPARE r40 FROM @q40;EXECUTE r40;DEALLOCATE PREPARE r40;
SET @q41=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician' AND COLUMN_NAME='create_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician' AND COLUMN_NAME='create_time'),'')!='bigint','ALTER TABLE `cb_technician` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''申请入驻时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r41 FROM @q41;EXECUTE r41;DEALLOCATE PREPARE r41;
SET @q42=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician' AND COLUMN_NAME='create_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician' AND COLUMN_NAME='create_time'),'')='bigint','ALTER TABLE `cb_technician` DROP COLUMN `create_time_ts`','SELECT 1');
PREPARE r42 FROM @q42;EXECUTE r42;DEALLOCATE PREPARE r42;
SET @q43=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician' AND COLUMN_NAME='update_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician' AND COLUMN_NAME='update_time'),'')!='bigint','ALTER TABLE `cb_technician` CHANGE COLUMN `update_time_ts` `update_time` BIGINT NOT NULL COMMENT ''最后修改时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r43 FROM @q43;EXECUTE r43;DEALLOCATE PREPARE r43;
SET @q44=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician' AND COLUMN_NAME='update_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician' AND COLUMN_NAME='update_time'),'')='bigint','ALTER TABLE `cb_technician` DROP COLUMN `update_time_ts`','SELECT 1');
PREPARE r44 FROM @q44;EXECUTE r44;DEALLOCATE PREPARE r44;
SET @q45=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_merchant' AND COLUMN_NAME='create_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_merchant' AND COLUMN_NAME='create_time'),'')!='bigint','ALTER TABLE `cb_merchant` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''入驻申请时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r45 FROM @q45;EXECUTE r45;DEALLOCATE PREPARE r45;
SET @q46=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_merchant' AND COLUMN_NAME='create_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_merchant' AND COLUMN_NAME='create_time'),'')='bigint','ALTER TABLE `cb_merchant` DROP COLUMN `create_time_ts`','SELECT 1');
PREPARE r46 FROM @q46;EXECUTE r46;DEALLOCATE PREPARE r46;
SET @q47=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_merchant' AND COLUMN_NAME='update_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_merchant' AND COLUMN_NAME='update_time'),'')!='bigint','ALTER TABLE `cb_merchant` CHANGE COLUMN `update_time_ts` `update_time` BIGINT NOT NULL COMMENT ''最后修改时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r47 FROM @q47;EXECUTE r47;DEALLOCATE PREPARE r47;
SET @q48=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_merchant' AND COLUMN_NAME='update_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_merchant' AND COLUMN_NAME='update_time'),'')='bigint','ALTER TABLE `cb_merchant` DROP COLUMN `update_time_ts`','SELECT 1');
PREPARE r48 FROM @q48;EXECUTE r48;DEALLOCATE PREPARE r48;
SET @q49=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_service_category' AND COLUMN_NAME='create_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_service_category' AND COLUMN_NAME='create_time'),'')!='bigint','ALTER TABLE `cb_service_category` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''创建时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r49 FROM @q49;EXECUTE r49;DEALLOCATE PREPARE r49;
SET @q50=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_service_category' AND COLUMN_NAME='create_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_service_category' AND COLUMN_NAME='create_time'),'')='bigint','ALTER TABLE `cb_service_category` DROP COLUMN `create_time_ts`','SELECT 1');
PREPARE r50 FROM @q50;EXECUTE r50;DEALLOCATE PREPARE r50;
SET @q51=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_service_category' AND COLUMN_NAME='update_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_service_category' AND COLUMN_NAME='update_time'),'')!='bigint','ALTER TABLE `cb_service_category` CHANGE COLUMN `update_time_ts` `update_time` BIGINT NOT NULL COMMENT ''最后修改时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r51 FROM @q51;EXECUTE r51;DEALLOCATE PREPARE r51;
SET @q52=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_service_category' AND COLUMN_NAME='update_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_service_category' AND COLUMN_NAME='update_time'),'')='bigint','ALTER TABLE `cb_service_category` DROP COLUMN `update_time_ts`','SELECT 1');
PREPARE r52 FROM @q52;EXECUTE r52;DEALLOCATE PREPARE r52;
SET @q53=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_service_item' AND COLUMN_NAME='create_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_service_item' AND COLUMN_NAME='create_time'),'')!='bigint','ALTER TABLE `cb_service_item` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''创建时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r53 FROM @q53;EXECUTE r53;DEALLOCATE PREPARE r53;
SET @q54=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_service_item' AND COLUMN_NAME='create_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_service_item' AND COLUMN_NAME='create_time'),'')='bigint','ALTER TABLE `cb_service_item` DROP COLUMN `create_time_ts`','SELECT 1');
PREPARE r54 FROM @q54;EXECUTE r54;DEALLOCATE PREPARE r54;
SET @q55=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_service_item' AND COLUMN_NAME='update_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_service_item' AND COLUMN_NAME='update_time'),'')!='bigint','ALTER TABLE `cb_service_item` CHANGE COLUMN `update_time_ts` `update_time` BIGINT NOT NULL COMMENT ''最后修改时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r55 FROM @q55;EXECUTE r55;DEALLOCATE PREPARE r55;
SET @q56=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_service_item' AND COLUMN_NAME='update_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_service_item' AND COLUMN_NAME='update_time'),'')='bigint','ALTER TABLE `cb_service_item` DROP COLUMN `update_time_ts`','SELECT 1');
PREPARE r56 FROM @q56;EXECUTE r56;DEALLOCATE PREPARE r56;
SET @q57=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order' AND COLUMN_NAME='appoint_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order' AND COLUMN_NAME='appoint_time'),'')!='bigint','ALTER TABLE `cb_order` CHANGE COLUMN `appoint_time_ts` `appoint_time` BIGINT NOT NULL COMMENT ''预约服务开始时间（会员选择的上门时间）（UTC 秒级时间戳）''','SELECT 1');
PREPARE r57 FROM @q57;EXECUTE r57;DEALLOCATE PREPARE r57;
SET @q58=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order' AND COLUMN_NAME='appoint_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order' AND COLUMN_NAME='appoint_time'),'')='bigint','ALTER TABLE `cb_order` DROP COLUMN `appoint_time_ts`','SELECT 1');
PREPARE r58 FROM @q58;EXECUTE r58;DEALLOCATE PREPARE r58;
SET @q59=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order' AND COLUMN_NAME='start_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order' AND COLUMN_NAME='start_time'),'')!='bigint','ALTER TABLE `cb_order` CHANGE COLUMN `start_time_ts` `start_time` BIGINT NULL COMMENT ''实际开始服务时间（技师操作开始）（UTC 秒级时间戳）''','SELECT 1');
PREPARE r59 FROM @q59;EXECUTE r59;DEALLOCATE PREPARE r59;
SET @q60=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order' AND COLUMN_NAME='start_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order' AND COLUMN_NAME='start_time'),'')='bigint','ALTER TABLE `cb_order` DROP COLUMN `start_time_ts`','SELECT 1');
PREPARE r60 FROM @q60;EXECUTE r60;DEALLOCATE PREPARE r60;
SET @q61=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order' AND COLUMN_NAME='end_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order' AND COLUMN_NAME='end_time'),'')!='bigint','ALTER TABLE `cb_order` CHANGE COLUMN `end_time_ts` `end_time` BIGINT NULL COMMENT ''实际结束服务时间（技师操作完成）（UTC 秒级时间戳）''','SELECT 1');
PREPARE r61 FROM @q61;EXECUTE r61;DEALLOCATE PREPARE r61;
SET @q62=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order' AND COLUMN_NAME='end_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order' AND COLUMN_NAME='end_time'),'')='bigint','ALTER TABLE `cb_order` DROP COLUMN `end_time_ts`','SELECT 1');
PREPARE r62 FROM @q62;EXECUTE r62;DEALLOCATE PREPARE r62;
SET @q63=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order' AND COLUMN_NAME='pay_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order' AND COLUMN_NAME='pay_time'),'')!='bigint','ALTER TABLE `cb_order` CHANGE COLUMN `pay_time_ts` `pay_time` BIGINT NULL COMMENT ''实际支付完成时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r63 FROM @q63;EXECUTE r63;DEALLOCATE PREPARE r63;
SET @q64=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order' AND COLUMN_NAME='pay_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order' AND COLUMN_NAME='pay_time'),'')='bigint','ALTER TABLE `cb_order` DROP COLUMN `pay_time_ts`','SELECT 1');
PREPARE r64 FROM @q64;EXECUTE r64;DEALLOCATE PREPARE r64;
SET @q65=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order' AND COLUMN_NAME='create_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order' AND COLUMN_NAME='create_time'),'')!='bigint','ALTER TABLE `cb_order` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''下单时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r65 FROM @q65;EXECUTE r65;DEALLOCATE PREPARE r65;
SET @q66=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order' AND COLUMN_NAME='create_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order' AND COLUMN_NAME='create_time'),'')='bigint','ALTER TABLE `cb_order` DROP COLUMN `create_time_ts`','SELECT 1');
PREPARE r66 FROM @q66;EXECUTE r66;DEALLOCATE PREPARE r66;
SET @q67=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order' AND COLUMN_NAME='update_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order' AND COLUMN_NAME='update_time'),'')!='bigint','ALTER TABLE `cb_order` CHANGE COLUMN `update_time_ts` `update_time` BIGINT NOT NULL COMMENT ''最后修改时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r67 FROM @q67;EXECUTE r67;DEALLOCATE PREPARE r67;
SET @q68=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order' AND COLUMN_NAME='update_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order' AND COLUMN_NAME='update_time'),'')='bigint','ALTER TABLE `cb_order` DROP COLUMN `update_time_ts`','SELECT 1');
PREPARE r68 FROM @q68;EXECUTE r68;DEALLOCATE PREPARE r68;
SET @q69=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_review' AND COLUMN_NAME='reply_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_review' AND COLUMN_NAME='reply_time'),'')!='bigint','ALTER TABLE `cb_review` CHANGE COLUMN `reply_time_ts` `reply_time` BIGINT NULL COMMENT ''技师回复时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r69 FROM @q69;EXECUTE r69;DEALLOCATE PREPARE r69;
SET @q70=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_review' AND COLUMN_NAME='reply_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_review' AND COLUMN_NAME='reply_time'),'')='bigint','ALTER TABLE `cb_review` DROP COLUMN `reply_time_ts`','SELECT 1');
PREPARE r70 FROM @q70;EXECUTE r70;DEALLOCATE PREPARE r70;
SET @q71=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_review' AND COLUMN_NAME='create_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_review' AND COLUMN_NAME='create_time'),'')!='bigint','ALTER TABLE `cb_review` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''评价发布时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r71 FROM @q71;EXECUTE r71;DEALLOCATE PREPARE r71;
SET @q72=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_review' AND COLUMN_NAME='create_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_review' AND COLUMN_NAME='create_time'),'')='bigint','ALTER TABLE `cb_review` DROP COLUMN `create_time_ts`','SELECT 1');
PREPARE r72 FROM @q72;EXECUTE r72;DEALLOCATE PREPARE r72;
SET @q73=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_review' AND COLUMN_NAME='update_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_review' AND COLUMN_NAME='update_time'),'')!='bigint','ALTER TABLE `cb_review` CHANGE COLUMN `update_time_ts` `update_time` BIGINT NOT NULL COMMENT ''最后修改时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r73 FROM @q73;EXECUTE r73;DEALLOCATE PREPARE r73;
SET @q74=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_review' AND COLUMN_NAME='update_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_review' AND COLUMN_NAME='update_time'),'')='bigint','ALTER TABLE `cb_review` DROP COLUMN `update_time_ts`','SELECT 1');
PREPARE r74 FROM @q74;EXECUTE r74;DEALLOCATE PREPARE r74;
SET @q75=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_payment' AND COLUMN_NAME='refund_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_payment' AND COLUMN_NAME='refund_time'),'')!='bigint','ALTER TABLE `cb_payment` CHANGE COLUMN `refund_time_ts` `refund_time` BIGINT NULL COMMENT ''退款完成时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r75 FROM @q75;EXECUTE r75;DEALLOCATE PREPARE r75;
SET @q76=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_payment' AND COLUMN_NAME='refund_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_payment' AND COLUMN_NAME='refund_time'),'')='bigint','ALTER TABLE `cb_payment` DROP COLUMN `refund_time_ts`','SELECT 1');
PREPARE r76 FROM @q76;EXECUTE r76;DEALLOCATE PREPARE r76;
SET @q77=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_payment' AND COLUMN_NAME='create_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_payment' AND COLUMN_NAME='create_time'),'')!='bigint','ALTER TABLE `cb_payment` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''支付记录创建时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r77 FROM @q77;EXECUTE r77;DEALLOCATE PREPARE r77;
SET @q78=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_payment' AND COLUMN_NAME='create_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_payment' AND COLUMN_NAME='create_time'),'')='bigint','ALTER TABLE `cb_payment` DROP COLUMN `create_time_ts`','SELECT 1');
PREPARE r78 FROM @q78;EXECUTE r78;DEALLOCATE PREPARE r78;
SET @q79=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_payment' AND COLUMN_NAME='update_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_payment' AND COLUMN_NAME='update_time'),'')!='bigint','ALTER TABLE `cb_payment` CHANGE COLUMN `update_time_ts` `update_time` BIGINT NOT NULL COMMENT ''最后修改时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r79 FROM @q79;EXECUTE r79;DEALLOCATE PREPARE r79;
SET @q80=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_payment' AND COLUMN_NAME='update_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_payment' AND COLUMN_NAME='update_time'),'')='bigint','ALTER TABLE `cb_payment` DROP COLUMN `update_time_ts`','SELECT 1');
PREPARE r80 FROM @q80;EXECUTE r80;DEALLOCATE PREPARE r80;
SET @q81=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_wallet' AND COLUMN_NAME='created_at_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_wallet' AND COLUMN_NAME='created_at'),'')!='bigint','ALTER TABLE `cb_wallet` CHANGE COLUMN `created_at_ts` `created_at` BIGINT NOT NULL COMMENT ''创建时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r81 FROM @q81;EXECUTE r81;DEALLOCATE PREPARE r81;
SET @q82=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_wallet' AND COLUMN_NAME='created_at_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_wallet' AND COLUMN_NAME='created_at'),'')='bigint','ALTER TABLE `cb_wallet` DROP COLUMN `created_at_ts`','SELECT 1');
PREPARE r82 FROM @q82;EXECUTE r82;DEALLOCATE PREPARE r82;
SET @q83=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_wallet' AND COLUMN_NAME='updated_at_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_wallet' AND COLUMN_NAME='updated_at'),'')!='bigint','ALTER TABLE `cb_wallet` CHANGE COLUMN `updated_at_ts` `updated_at` BIGINT NOT NULL COMMENT ''最后更新时间（用作乐观锁版本号）（UTC 秒级时间戳）''','SELECT 1');
PREPARE r83 FROM @q83;EXECUTE r83;DEALLOCATE PREPARE r83;
SET @q84=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_wallet' AND COLUMN_NAME='updated_at_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_wallet' AND COLUMN_NAME='updated_at'),'')='bigint','ALTER TABLE `cb_wallet` DROP COLUMN `updated_at_ts`','SELECT 1');
PREPARE r84 FROM @q84;EXECUTE r84;DEALLOCATE PREPARE r84;
SET @q85=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_wallet_record' AND COLUMN_NAME='create_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_wallet_record' AND COLUMN_NAME='create_time'),'')!='bigint','ALTER TABLE `cb_wallet_record` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''流水产生时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r85 FROM @q85;EXECUTE r85;DEALLOCATE PREPARE r85;
SET @q86=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_wallet_record' AND COLUMN_NAME='create_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_wallet_record' AND COLUMN_NAME='create_time'),'')='bigint','ALTER TABLE `cb_wallet_record` DROP COLUMN `create_time_ts`','SELECT 1');
PREPARE r86 FROM @q86;EXECUTE r86;DEALLOCATE PREPARE r86;
SET @q87=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_coupon_template' AND COLUMN_NAME='start_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_coupon_template' AND COLUMN_NAME='start_time'),'')!='bigint','ALTER TABLE `cb_coupon_template` CHANGE COLUMN `start_time_ts` `start_time` BIGINT NULL COMMENT ''绝对有效期开始时间（与 valid_days 二选一）（UTC 秒级时间戳）''','SELECT 1');
PREPARE r87 FROM @q87;EXECUTE r87;DEALLOCATE PREPARE r87;
SET @q88=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_coupon_template' AND COLUMN_NAME='start_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_coupon_template' AND COLUMN_NAME='start_time'),'')='bigint','ALTER TABLE `cb_coupon_template` DROP COLUMN `start_time_ts`','SELECT 1');
PREPARE r88 FROM @q88;EXECUTE r88;DEALLOCATE PREPARE r88;
SET @q89=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_coupon_template' AND COLUMN_NAME='end_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_coupon_template' AND COLUMN_NAME='end_time'),'')!='bigint','ALTER TABLE `cb_coupon_template` CHANGE COLUMN `end_time_ts` `end_time` BIGINT NULL COMMENT ''绝对有效期结束时间（与 valid_days 二选一）（UTC 秒级时间戳）''','SELECT 1');
PREPARE r89 FROM @q89;EXECUTE r89;DEALLOCATE PREPARE r89;
SET @q90=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_coupon_template' AND COLUMN_NAME='end_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_coupon_template' AND COLUMN_NAME='end_time'),'')='bigint','ALTER TABLE `cb_coupon_template` DROP COLUMN `end_time_ts`','SELECT 1');
PREPARE r90 FROM @q90;EXECUTE r90;DEALLOCATE PREPARE r90;
SET @q91=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_coupon_template' AND COLUMN_NAME='create_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_coupon_template' AND COLUMN_NAME='create_time'),'')!='bigint','ALTER TABLE `cb_coupon_template` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''创建时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r91 FROM @q91;EXECUTE r91;DEALLOCATE PREPARE r91;
SET @q92=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_coupon_template' AND COLUMN_NAME='create_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_coupon_template' AND COLUMN_NAME='create_time'),'')='bigint','ALTER TABLE `cb_coupon_template` DROP COLUMN `create_time_ts`','SELECT 1');
PREPARE r92 FROM @q92;EXECUTE r92;DEALLOCATE PREPARE r92;
SET @q93=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_coupon_template' AND COLUMN_NAME='update_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_coupon_template' AND COLUMN_NAME='update_time'),'')!='bigint','ALTER TABLE `cb_coupon_template` CHANGE COLUMN `update_time_ts` `update_time` BIGINT NOT NULL COMMENT ''最后修改时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r93 FROM @q93;EXECUTE r93;DEALLOCATE PREPARE r93;
SET @q94=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_coupon_template' AND COLUMN_NAME='update_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_coupon_template' AND COLUMN_NAME='update_time'),'')='bigint','ALTER TABLE `cb_coupon_template` DROP COLUMN `update_time_ts`','SELECT 1');
PREPARE r94 FROM @q94;EXECUTE r94;DEALLOCATE PREPARE r94;
SET @q95=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_member_coupon' AND COLUMN_NAME='use_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_member_coupon' AND COLUMN_NAME='use_time'),'')!='bigint','ALTER TABLE `cb_member_coupon` CHANGE COLUMN `use_time_ts` `use_time` BIGINT NULL COMMENT ''实际使用时间（status=1时填写）（UTC 秒级时间戳）''','SELECT 1');
PREPARE r95 FROM @q95;EXECUTE r95;DEALLOCATE PREPARE r95;
SET @q96=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_member_coupon' AND COLUMN_NAME='use_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_member_coupon' AND COLUMN_NAME='use_time'),'')='bigint','ALTER TABLE `cb_member_coupon` DROP COLUMN `use_time_ts`','SELECT 1');
PREPARE r96 FROM @q96;EXECUTE r96;DEALLOCATE PREPARE r96;
SET @q97=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_member_coupon' AND COLUMN_NAME='expire_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_member_coupon' AND COLUMN_NAME='expire_time'),'')!='bigint','ALTER TABLE `cb_member_coupon` CHANGE COLUMN `expire_time_ts` `expire_time` BIGINT NOT NULL COMMENT ''过期时间（根据模板 valid_days 或 end_time 计算后写入）（UTC 秒级时间戳）''','SELECT 1');
PREPARE r97 FROM @q97;EXECUTE r97;DEALLOCATE PREPARE r97;
SET @q98=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_member_coupon' AND COLUMN_NAME='expire_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_member_coupon' AND COLUMN_NAME='expire_time'),'')='bigint','ALTER TABLE `cb_member_coupon` DROP COLUMN `expire_time_ts`','SELECT 1');
PREPARE r98 FROM @q98;EXECUTE r98;DEALLOCATE PREPARE r98;
SET @q99=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_member_coupon' AND COLUMN_NAME='create_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_member_coupon' AND COLUMN_NAME='create_time'),'')!='bigint','ALTER TABLE `cb_member_coupon` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''领取时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r99 FROM @q99;EXECUTE r99;DEALLOCATE PREPARE r99;
SET @q100=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_member_coupon' AND COLUMN_NAME='create_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_member_coupon' AND COLUMN_NAME='create_time'),'')='bigint','ALTER TABLE `cb_member_coupon` DROP COLUMN `create_time_ts`','SELECT 1');
PREPARE r100 FROM @q100;EXECUTE r100;DEALLOCATE PREPARE r100;
SET @q101=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_address' AND COLUMN_NAME='create_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_address' AND COLUMN_NAME='create_time'),'')!='bigint','ALTER TABLE `cb_address` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''创建时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r101 FROM @q101;EXECUTE r101;DEALLOCATE PREPARE r101;
SET @q102=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_address' AND COLUMN_NAME='create_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_address' AND COLUMN_NAME='create_time'),'')='bigint','ALTER TABLE `cb_address` DROP COLUMN `create_time_ts`','SELECT 1');
PREPARE r102 FROM @q102;EXECUTE r102;DEALLOCATE PREPARE r102;
SET @q103=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_address' AND COLUMN_NAME='update_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_address' AND COLUMN_NAME='update_time'),'')!='bigint','ALTER TABLE `cb_address` CHANGE COLUMN `update_time_ts` `update_time` BIGINT NOT NULL COMMENT ''最后修改时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r103 FROM @q103;EXECUTE r103;DEALLOCATE PREPARE r103;
SET @q104=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_address' AND COLUMN_NAME='update_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_address' AND COLUMN_NAME='update_time'),'')='bigint','ALTER TABLE `cb_address` DROP COLUMN `update_time_ts`','SELECT 1');
PREPARE r104 FROM @q104;EXECUTE r104;DEALLOCATE PREPARE r104;
SET @q105=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician_schedule' AND COLUMN_NAME='create_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician_schedule' AND COLUMN_NAME='create_time'),'')!='bigint','ALTER TABLE `cb_technician_schedule` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''创建时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r105 FROM @q105;EXECUTE r105;DEALLOCATE PREPARE r105;
SET @q106=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician_schedule' AND COLUMN_NAME='create_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician_schedule' AND COLUMN_NAME='create_time'),'')='bigint','ALTER TABLE `cb_technician_schedule` DROP COLUMN `create_time_ts`','SELECT 1');
PREPARE r106 FROM @q106;EXECUTE r106;DEALLOCATE PREPARE r106;
SET @q107=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_banner' AND COLUMN_NAME='start_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_banner' AND COLUMN_NAME='start_time'),'')!='bigint','ALTER TABLE `cb_banner` CHANGE COLUMN `start_time_ts` `start_time` BIGINT NULL COMMENT ''生效开始时间（为空则立即生效）（UTC 秒级时间戳）''','SELECT 1');
PREPARE r107 FROM @q107;EXECUTE r107;DEALLOCATE PREPARE r107;
SET @q108=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_banner' AND COLUMN_NAME='start_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_banner' AND COLUMN_NAME='start_time'),'')='bigint','ALTER TABLE `cb_banner` DROP COLUMN `start_time_ts`','SELECT 1');
PREPARE r108 FROM @q108;EXECUTE r108;DEALLOCATE PREPARE r108;
SET @q109=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_banner' AND COLUMN_NAME='end_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_banner' AND COLUMN_NAME='end_time'),'')!='bigint','ALTER TABLE `cb_banner` CHANGE COLUMN `end_time_ts` `end_time` BIGINT NULL COMMENT ''生效结束时间（为空则永久有效）（UTC 秒级时间戳）''','SELECT 1');
PREPARE r109 FROM @q109;EXECUTE r109;DEALLOCATE PREPARE r109;
SET @q110=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_banner' AND COLUMN_NAME='end_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_banner' AND COLUMN_NAME='end_time'),'')='bigint','ALTER TABLE `cb_banner` DROP COLUMN `end_time_ts`','SELECT 1');
PREPARE r110 FROM @q110;EXECUTE r110;DEALLOCATE PREPARE r110;
SET @q111=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_banner' AND COLUMN_NAME='create_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_banner' AND COLUMN_NAME='create_time'),'')!='bigint','ALTER TABLE `cb_banner` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''创建时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r111 FROM @q111;EXECUTE r111;DEALLOCATE PREPARE r111;
SET @q112=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_banner' AND COLUMN_NAME='create_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_banner' AND COLUMN_NAME='create_time'),'')='bigint','ALTER TABLE `cb_banner` DROP COLUMN `create_time_ts`','SELECT 1');
PREPARE r112 FROM @q112;EXECUTE r112;DEALLOCATE PREPARE r112;
SET @q113=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_banner' AND COLUMN_NAME='update_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_banner' AND COLUMN_NAME='update_time'),'')!='bigint','ALTER TABLE `cb_banner` CHANGE COLUMN `update_time_ts` `update_time` BIGINT NOT NULL COMMENT ''最后修改时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r113 FROM @q113;EXECUTE r113;DEALLOCATE PREPARE r113;
SET @q114=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_banner' AND COLUMN_NAME='update_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_banner' AND COLUMN_NAME='update_time'),'')='bigint','ALTER TABLE `cb_banner` DROP COLUMN `update_time_ts`','SELECT 1');
PREPARE r114 FROM @q114;EXECUTE r114;DEALLOCATE PREPARE r114;
SET @q115=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_nav' AND COLUMN_NAME='create_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_nav' AND COLUMN_NAME='create_time'),'')!='bigint','ALTER TABLE `cb_nav` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''创建时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r115 FROM @q115;EXECUTE r115;DEALLOCATE PREPARE r115;
SET @q116=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_nav' AND COLUMN_NAME='create_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_nav' AND COLUMN_NAME='create_time'),'')='bigint','ALTER TABLE `cb_nav` DROP COLUMN `create_time_ts`','SELECT 1');
PREPARE r116 FROM @q116;EXECUTE r116;DEALLOCATE PREPARE r116;
SET @q117=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_nav' AND COLUMN_NAME='update_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_nav' AND COLUMN_NAME='update_time'),'')!='bigint','ALTER TABLE `cb_nav` CHANGE COLUMN `update_time_ts` `update_time` BIGINT NOT NULL COMMENT ''最后修改时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r117 FROM @q117;EXECUTE r117;DEALLOCATE PREPARE r117;
SET @q118=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_nav' AND COLUMN_NAME='update_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_nav' AND COLUMN_NAME='update_time'),'')='bigint','ALTER TABLE `cb_nav` DROP COLUMN `update_time_ts`','SELECT 1');
PREPARE r118 FROM @q118;EXECUTE r118;DEALLOCATE PREPARE r118;
SET @q119=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_icon' AND COLUMN_NAME='create_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_icon' AND COLUMN_NAME='create_time'),'')!='bigint','ALTER TABLE `cb_icon` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''创建时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r119 FROM @q119;EXECUTE r119;DEALLOCATE PREPARE r119;
SET @q120=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_icon' AND COLUMN_NAME='create_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_icon' AND COLUMN_NAME='create_time'),'')='bigint','ALTER TABLE `cb_icon` DROP COLUMN `create_time_ts`','SELECT 1');
PREPARE r120 FROM @q120;EXECUTE r120;DEALLOCATE PREPARE r120;
SET @q121=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_icon' AND COLUMN_NAME='update_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_icon' AND COLUMN_NAME='update_time'),'')!='bigint','ALTER TABLE `cb_icon` CHANGE COLUMN `update_time_ts` `update_time` BIGINT NOT NULL COMMENT ''最后修改时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r121 FROM @q121;EXECUTE r121;DEALLOCATE PREPARE r121;
SET @q122=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_icon' AND COLUMN_NAME='update_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_icon' AND COLUMN_NAME='update_time'),'')='bigint','ALTER TABLE `cb_icon` DROP COLUMN `update_time_ts`','SELECT 1');
PREPARE r122 FROM @q122;EXECUTE r122;DEALLOCATE PREPARE r122;
SET @q123=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_tag' AND COLUMN_NAME='create_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_tag' AND COLUMN_NAME='create_time'),'')!='bigint','ALTER TABLE `cb_tag` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''创建时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r123 FROM @q123;EXECUTE r123;DEALLOCATE PREPARE r123;
SET @q124=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_tag' AND COLUMN_NAME='create_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_tag' AND COLUMN_NAME='create_time'),'')='bigint','ALTER TABLE `cb_tag` DROP COLUMN `create_time_ts`','SELECT 1');
PREPARE r124 FROM @q124;EXECUTE r124;DEALLOCATE PREPARE r124;
SET @q125=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_im_session' AND COLUMN_NAME='last_msg_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_im_session' AND COLUMN_NAME='last_msg_time'),'')!='bigint','ALTER TABLE `cb_im_session` CHANGE COLUMN `last_msg_time_ts` `last_msg_time` BIGINT NULL COMMENT ''最后一条消息发送时间（用于会话列表按时间倒序）（UTC 秒级时间戳）''','SELECT 1');
PREPARE r125 FROM @q125;EXECUTE r125;DEALLOCATE PREPARE r125;
SET @q126=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_im_session' AND COLUMN_NAME='last_msg_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_im_session' AND COLUMN_NAME='last_msg_time'),'')='bigint','ALTER TABLE `cb_im_session` DROP COLUMN `last_msg_time_ts`','SELECT 1');
PREPARE r126 FROM @q126;EXECUTE r126;DEALLOCATE PREPARE r126;
SET @q127=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_im_session' AND COLUMN_NAME='create_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_im_session' AND COLUMN_NAME='create_time'),'')!='bigint','ALTER TABLE `cb_im_session` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''会话创建时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r127 FROM @q127;EXECUTE r127;DEALLOCATE PREPARE r127;
SET @q128=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_im_session' AND COLUMN_NAME='create_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_im_session' AND COLUMN_NAME='create_time'),'')='bigint','ALTER TABLE `cb_im_session` DROP COLUMN `create_time_ts`','SELECT 1');
PREPARE r128 FROM @q128;EXECUTE r128;DEALLOCATE PREPARE r128;
SET @q129=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_im_session' AND COLUMN_NAME='update_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_im_session' AND COLUMN_NAME='update_time'),'')!='bigint','ALTER TABLE `cb_im_session` CHANGE COLUMN `update_time_ts` `update_time` BIGINT NOT NULL COMMENT ''最后消息更新时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r129 FROM @q129;EXECUTE r129;DEALLOCATE PREPARE r129;
SET @q130=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_im_session' AND COLUMN_NAME='update_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_im_session' AND COLUMN_NAME='update_time'),'')='bigint','ALTER TABLE `cb_im_session` DROP COLUMN `update_time_ts`','SELECT 1');
PREPARE r130 FROM @q130;EXECUTE r130;DEALLOCATE PREPARE r130;
SET @q131=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_im_message' AND COLUMN_NAME='create_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_im_message' AND COLUMN_NAME='create_time'),'')!='bigint','ALTER TABLE `cb_im_message` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''消息发送时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r131 FROM @q131;EXECUTE r131;DEALLOCATE PREPARE r131;
SET @q132=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_im_message' AND COLUMN_NAME='create_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_im_message' AND COLUMN_NAME='create_time'),'')='bigint','ALTER TABLE `cb_im_message` DROP COLUMN `create_time_ts`','SELECT 1');
PREPARE r132 FROM @q132;EXECUTE r132;DEALLOCATE PREPARE r132;
SET @q133=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_notification' AND COLUMN_NAME='create_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_notification' AND COLUMN_NAME='create_time'),'')!='bigint','ALTER TABLE `cb_notification` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''通知推送时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r133 FROM @q133;EXECUTE r133;DEALLOCATE PREPARE r133;
SET @q134=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_notification' AND COLUMN_NAME='create_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_notification' AND COLUMN_NAME='create_time'),'')='bigint','ALTER TABLE `cb_notification` DROP COLUMN `create_time_ts`','SELECT 1');
PREPARE r134 FROM @q134;EXECUTE r134;DEALLOCATE PREPARE r134;
SET @q135=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_login_log' AND COLUMN_NAME='create_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_login_log' AND COLUMN_NAME='create_time'),'')!='bigint','ALTER TABLE `cb_login_log` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''登录时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r135 FROM @q135;EXECUTE r135;DEALLOCATE PREPARE r135;
SET @q136=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_login_log' AND COLUMN_NAME='create_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_login_log' AND COLUMN_NAME='create_time'),'')='bigint','ALTER TABLE `cb_login_log` DROP COLUMN `create_time_ts`','SELECT 1');
PREPARE r136 FROM @q136;EXECUTE r136;DEALLOCATE PREPARE r136;
SET @q137=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_driver' AND COLUMN_NAME='create_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_driver' AND COLUMN_NAME='create_time'),'')!='bigint','ALTER TABLE `cb_driver` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''申请注册时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r137 FROM @q137;EXECUTE r137;DEALLOCATE PREPARE r137;
SET @q138=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_driver' AND COLUMN_NAME='create_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_driver' AND COLUMN_NAME='create_time'),'')='bigint','ALTER TABLE `cb_driver` DROP COLUMN `create_time_ts`','SELECT 1');
PREPARE r138 FROM @q138;EXECUTE r138;DEALLOCATE PREPARE r138;
SET @q139=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_driver' AND COLUMN_NAME='update_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_driver' AND COLUMN_NAME='update_time'),'')!='bigint','ALTER TABLE `cb_driver` CHANGE COLUMN `update_time_ts` `update_time` BIGINT NOT NULL COMMENT ''最后修改时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r139 FROM @q139;EXECUTE r139;DEALLOCATE PREPARE r139;
SET @q140=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_driver' AND COLUMN_NAME='update_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_driver' AND COLUMN_NAME='update_time'),'')='bigint','ALTER TABLE `cb_driver` DROP COLUMN `update_time_ts`','SELECT 1');
PREPARE r140 FROM @q140;EXECUTE r140;DEALLOCATE PREPARE r140;
SET @q141=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_vehicle' AND COLUMN_NAME='create_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_vehicle' AND COLUMN_NAME='create_time'),'')!='bigint','ALTER TABLE `cb_vehicle` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''车辆录入时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r141 FROM @q141;EXECUTE r141;DEALLOCATE PREPARE r141;
SET @q142=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_vehicle' AND COLUMN_NAME='create_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_vehicle' AND COLUMN_NAME='create_time'),'')='bigint','ALTER TABLE `cb_vehicle` DROP COLUMN `create_time_ts`','SELECT 1');
PREPARE r142 FROM @q142;EXECUTE r142;DEALLOCATE PREPARE r142;
SET @q143=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_vehicle' AND COLUMN_NAME='update_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_vehicle' AND COLUMN_NAME='update_time'),'')!='bigint','ALTER TABLE `cb_vehicle` CHANGE COLUMN `update_time_ts` `update_time` BIGINT NOT NULL COMMENT ''最后修改时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r143 FROM @q143;EXECUTE r143;DEALLOCATE PREPARE r143;
SET @q144=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_vehicle' AND COLUMN_NAME='update_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_vehicle' AND COLUMN_NAME='update_time'),'')='bigint','ALTER TABLE `cb_vehicle` DROP COLUMN `update_time_ts`','SELECT 1');
PREPARE r144 FROM @q144;EXECUTE r144;DEALLOCATE PREPARE r144;
SET @q145=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_dispatch_order' AND COLUMN_NAME='pickup_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_dispatch_order' AND COLUMN_NAME='pickup_time'),'')!='bigint','ALTER TABLE `cb_dispatch_order` CHANGE COLUMN `pickup_time_ts` `pickup_time` BIGINT NOT NULL COMMENT ''预约接送时间（会员选择的上车时间）（UTC 秒级时间戳）''','SELECT 1');
PREPARE r145 FROM @q145;EXECUTE r145;DEALLOCATE PREPARE r145;
SET @q146=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_dispatch_order' AND COLUMN_NAME='pickup_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_dispatch_order' AND COLUMN_NAME='pickup_time'),'')='bigint','ALTER TABLE `cb_dispatch_order` DROP COLUMN `pickup_time_ts`','SELECT 1');
PREPARE r146 FROM @q146;EXECUTE r146;DEALLOCATE PREPARE r146;
SET @q147=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_dispatch_order' AND COLUMN_NAME='actual_pickup_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_dispatch_order' AND COLUMN_NAME='actual_pickup_time'),'')!='bigint','ALTER TABLE `cb_dispatch_order` CHANGE COLUMN `actual_pickup_time_ts` `actual_pickup_time` BIGINT NULL COMMENT ''实际接到乘客时间（司机操作"已接到"时记录）（UTC 秒级时间戳）''','SELECT 1');
PREPARE r147 FROM @q147;EXECUTE r147;DEALLOCATE PREPARE r147;
SET @q148=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_dispatch_order' AND COLUMN_NAME='actual_pickup_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_dispatch_order' AND COLUMN_NAME='actual_pickup_time'),'')='bigint','ALTER TABLE `cb_dispatch_order` DROP COLUMN `actual_pickup_time_ts`','SELECT 1');
PREPARE r148 FROM @q148;EXECUTE r148;DEALLOCATE PREPARE r148;
SET @q149=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_dispatch_order' AND COLUMN_NAME='finish_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_dispatch_order' AND COLUMN_NAME='finish_time'),'')!='bigint','ALTER TABLE `cb_dispatch_order` CHANGE COLUMN `finish_time_ts` `finish_time` BIGINT NULL COMMENT ''行程完成时间（司机操作"已送达"时记录）（UTC 秒级时间戳）''','SELECT 1');
PREPARE r149 FROM @q149;EXECUTE r149;DEALLOCATE PREPARE r149;
SET @q150=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_dispatch_order' AND COLUMN_NAME='finish_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_dispatch_order' AND COLUMN_NAME='finish_time'),'')='bigint','ALTER TABLE `cb_dispatch_order` DROP COLUMN `finish_time_ts`','SELECT 1');
PREPARE r150 FROM @q150;EXECUTE r150;DEALLOCATE PREPARE r150;
SET @q151=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_dispatch_order' AND COLUMN_NAME='create_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_dispatch_order' AND COLUMN_NAME='create_time'),'')!='bigint','ALTER TABLE `cb_dispatch_order` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''派车单创建时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r151 FROM @q151;EXECUTE r151;DEALLOCATE PREPARE r151;
SET @q152=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_dispatch_order' AND COLUMN_NAME='create_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_dispatch_order' AND COLUMN_NAME='create_time'),'')='bigint','ALTER TABLE `cb_dispatch_order` DROP COLUMN `create_time_ts`','SELECT 1');
PREPARE r152 FROM @q152;EXECUTE r152;DEALLOCATE PREPARE r152;
SET @q153=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_dispatch_order' AND COLUMN_NAME='update_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_dispatch_order' AND COLUMN_NAME='update_time'),'')!='bigint','ALTER TABLE `cb_dispatch_order` CHANGE COLUMN `update_time_ts` `update_time` BIGINT NOT NULL COMMENT ''最后修改时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r153 FROM @q153;EXECUTE r153;DEALLOCATE PREPARE r153;
SET @q154=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_dispatch_order' AND COLUMN_NAME='update_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_dispatch_order' AND COLUMN_NAME='update_time'),'')='bigint','ALTER TABLE `cb_dispatch_order` DROP COLUMN `update_time_ts`','SELECT 1');
PREPARE r154 FROM @q154;EXECUTE r154;DEALLOCATE PREPARE r154;
SET @q155=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_walkin_session' AND COLUMN_NAME='check_in_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_walkin_session' AND COLUMN_NAME='check_in_time'),'')!='bigint','ALTER TABLE `cb_walkin_session` CHANGE COLUMN `check_in_time_ts` `check_in_time` BIGINT NOT NULL COMMENT ''签到时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r155 FROM @q155;EXECUTE r155;DEALLOCATE PREPARE r155;
SET @q156=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_walkin_session' AND COLUMN_NAME='check_in_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_walkin_session' AND COLUMN_NAME='check_in_time'),'')='bigint','ALTER TABLE `cb_walkin_session` DROP COLUMN `check_in_time_ts`','SELECT 1');
PREPARE r156 FROM @q156;EXECUTE r156;DEALLOCATE PREPARE r156;
SET @q157=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_walkin_session' AND COLUMN_NAME='check_out_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_walkin_session' AND COLUMN_NAME='check_out_time'),'')!='bigint','ALTER TABLE `cb_walkin_session` CHANGE COLUMN `check_out_time_ts` `check_out_time` BIGINT NULL COMMENT ''签出时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r157 FROM @q157;EXECUTE r157;DEALLOCATE PREPARE r157;
SET @q158=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_walkin_session' AND COLUMN_NAME='check_out_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_walkin_session' AND COLUMN_NAME='check_out_time'),'')='bigint','ALTER TABLE `cb_walkin_session` DROP COLUMN `check_out_time_ts`','SELECT 1');
PREPARE r158 FROM @q158;EXECUTE r158;DEALLOCATE PREPARE r158;
SET @q159=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_walkin_session' AND COLUMN_NAME='create_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_walkin_session' AND COLUMN_NAME='create_time'),'')!='bigint','ALTER TABLE `cb_walkin_session` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''创建时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r159 FROM @q159;EXECUTE r159;DEALLOCATE PREPARE r159;
SET @q160=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_walkin_session' AND COLUMN_NAME='create_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_walkin_session' AND COLUMN_NAME='create_time'),'')='bigint','ALTER TABLE `cb_walkin_session` DROP COLUMN `create_time_ts`','SELECT 1');
PREPARE r160 FROM @q160;EXECUTE r160;DEALLOCATE PREPARE r160;
SET @q161=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_walkin_session' AND COLUMN_NAME='update_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_walkin_session' AND COLUMN_NAME='update_time'),'')!='bigint','ALTER TABLE `cb_walkin_session` CHANGE COLUMN `update_time_ts` `update_time` BIGINT NOT NULL COMMENT ''更新时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r161 FROM @q161;EXECUTE r161;DEALLOCATE PREPARE r161;
SET @q162=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_walkin_session' AND COLUMN_NAME='update_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_walkin_session' AND COLUMN_NAME='update_time'),'')='bigint','ALTER TABLE `cb_walkin_session` DROP COLUMN `update_time_ts`','SELECT 1');
PREPARE r162 FROM @q162;EXECUTE r162;DEALLOCATE PREPARE r162;
SET @q163=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_payment_record' AND COLUMN_NAME='pay_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_payment_record' AND COLUMN_NAME='pay_time'),'')!='bigint','ALTER TABLE `cb_payment_record` CHANGE COLUMN `pay_time_ts` `pay_time` BIGINT NULL COMMENT ''支付时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r163 FROM @q163;EXECUTE r163;DEALLOCATE PREPARE r163;
SET @q164=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_payment_record' AND COLUMN_NAME='pay_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_payment_record' AND COLUMN_NAME='pay_time'),'')='bigint','ALTER TABLE `cb_payment_record` DROP COLUMN `pay_time_ts`','SELECT 1');
PREPARE r164 FROM @q164;EXECUTE r164;DEALLOCATE PREPARE r164;
SET @q165=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_payment_record' AND COLUMN_NAME='create_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_payment_record' AND COLUMN_NAME='create_time'),'')!='bigint','ALTER TABLE `cb_payment_record` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''创建时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r165 FROM @q165;EXECUTE r165;DEALLOCATE PREPARE r165;
SET @q166=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_payment_record' AND COLUMN_NAME='create_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_payment_record' AND COLUMN_NAME='create_time'),'')='bigint','ALTER TABLE `cb_payment_record` DROP COLUMN `create_time_ts`','SELECT 1');
PREPARE r166 FROM @q166;EXECUTE r166;DEALLOCATE PREPARE r166;
SET @q167=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_vehicle_dispatch' AND COLUMN_NAME='depart_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_vehicle_dispatch' AND COLUMN_NAME='depart_time'),'')!='bigint','ALTER TABLE `cb_vehicle_dispatch` CHANGE COLUMN `depart_time_ts` `depart_time` BIGINT NULL COMMENT ''出发时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r167 FROM @q167;EXECUTE r167;DEALLOCATE PREPARE r167;
SET @q168=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_vehicle_dispatch' AND COLUMN_NAME='depart_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_vehicle_dispatch' AND COLUMN_NAME='depart_time'),'')='bigint','ALTER TABLE `cb_vehicle_dispatch` DROP COLUMN `depart_time_ts`','SELECT 1');
PREPARE r168 FROM @q168;EXECUTE r168;DEALLOCATE PREPARE r168;
SET @q169=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_vehicle_dispatch' AND COLUMN_NAME='return_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_vehicle_dispatch' AND COLUMN_NAME='return_time'),'')!='bigint','ALTER TABLE `cb_vehicle_dispatch` CHANGE COLUMN `return_time_ts` `return_time` BIGINT NULL COMMENT ''返回时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r169 FROM @q169;EXECUTE r169;DEALLOCATE PREPARE r169;
SET @q170=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_vehicle_dispatch' AND COLUMN_NAME='return_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_vehicle_dispatch' AND COLUMN_NAME='return_time'),'')='bigint','ALTER TABLE `cb_vehicle_dispatch` DROP COLUMN `return_time_ts`','SELECT 1');
PREPARE r170 FROM @q170;EXECUTE r170;DEALLOCATE PREPARE r170;
SET @q171=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_vehicle_dispatch' AND COLUMN_NAME='create_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_vehicle_dispatch' AND COLUMN_NAME='create_time'),'')!='bigint','ALTER TABLE `cb_vehicle_dispatch` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''创建时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r171 FROM @q171;EXECUTE r171;DEALLOCATE PREPARE r171;
SET @q172=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_vehicle_dispatch' AND COLUMN_NAME='create_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_vehicle_dispatch' AND COLUMN_NAME='create_time'),'')='bigint','ALTER TABLE `cb_vehicle_dispatch` DROP COLUMN `create_time_ts`','SELECT 1');
PREPARE r172 FROM @q172;EXECUTE r172;DEALLOCATE PREPARE r172;
SET @q173=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_vehicle_dispatch' AND COLUMN_NAME='update_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_vehicle_dispatch' AND COLUMN_NAME='update_time'),'')!='bigint','ALTER TABLE `cb_vehicle_dispatch` CHANGE COLUMN `update_time_ts` `update_time` BIGINT NOT NULL COMMENT ''更新时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r173 FROM @q173;EXECUTE r173;DEALLOCATE PREPARE r173;
SET @q174=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_vehicle_dispatch' AND COLUMN_NAME='update_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_vehicle_dispatch' AND COLUMN_NAME='update_time'),'')='bigint','ALTER TABLE `cb_vehicle_dispatch` DROP COLUMN `update_time_ts`','SELECT 1');
PREPARE r174 FROM @q174;EXECUTE r174;DEALLOCATE PREPARE r174;
SET @q175=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_finance_expense' AND COLUMN_NAME='create_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_finance_expense' AND COLUMN_NAME='create_time'),'')!='bigint','ALTER TABLE `cb_finance_expense` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''创建时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r175 FROM @q175;EXECUTE r175;DEALLOCATE PREPARE r175;
SET @q176=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_finance_expense' AND COLUMN_NAME='create_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_finance_expense' AND COLUMN_NAME='create_time'),'')='bigint','ALTER TABLE `cb_finance_expense` DROP COLUMN `create_time_ts`','SELECT 1');
PREPARE r176 FROM @q176;EXECUTE r176;DEALLOCATE PREPARE r176;
SET @q177=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_finance_expense' AND COLUMN_NAME='update_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_finance_expense' AND COLUMN_NAME='update_time'),'')!='bigint','ALTER TABLE `cb_finance_expense` CHANGE COLUMN `update_time_ts` `update_time` BIGINT NOT NULL COMMENT ''更新时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r177 FROM @q177;EXECUTE r177;DEALLOCATE PREPARE r177;
SET @q178=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_finance_expense' AND COLUMN_NAME='update_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_finance_expense' AND COLUMN_NAME='update_time'),'')='bigint','ALTER TABLE `cb_finance_expense` DROP COLUMN `update_time_ts`','SELECT 1');
PREPARE r178 FROM @q178;EXECUTE r178;DEALLOCATE PREPARE r178;
SET @q179=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_finance_salary' AND COLUMN_NAME='pay_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_finance_salary' AND COLUMN_NAME='pay_time'),'')!='bigint','ALTER TABLE `cb_finance_salary` CHANGE COLUMN `pay_time_ts` `pay_time` BIGINT NULL COMMENT ''发薪时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r179 FROM @q179;EXECUTE r179;DEALLOCATE PREPARE r179;
SET @q180=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_finance_salary' AND COLUMN_NAME='pay_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_finance_salary' AND COLUMN_NAME='pay_time'),'')='bigint','ALTER TABLE `cb_finance_salary` DROP COLUMN `pay_time_ts`','SELECT 1');
PREPARE r180 FROM @q180;EXECUTE r180;DEALLOCATE PREPARE r180;
SET @q181=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_finance_salary' AND COLUMN_NAME='create_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_finance_salary' AND COLUMN_NAME='create_time'),'')!='bigint','ALTER TABLE `cb_finance_salary` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''创建时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r181 FROM @q181;EXECUTE r181;DEALLOCATE PREPARE r181;
SET @q182=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_finance_salary' AND COLUMN_NAME='create_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_finance_salary' AND COLUMN_NAME='create_time'),'')='bigint','ALTER TABLE `cb_finance_salary` DROP COLUMN `create_time_ts`','SELECT 1');
PREPARE r182 FROM @q182;EXECUTE r182;DEALLOCATE PREPARE r182;
SET @q183=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_finance_salary' AND COLUMN_NAME='update_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_finance_salary' AND COLUMN_NAME='update_time'),'')!='bigint','ALTER TABLE `cb_finance_salary` CHANGE COLUMN `update_time_ts` `update_time` BIGINT NOT NULL COMMENT ''更新时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r183 FROM @q183;EXECUTE r183;DEALLOCATE PREPARE r183;
SET @q184=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_finance_salary' AND COLUMN_NAME='update_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_finance_salary' AND COLUMN_NAME='update_time'),'')='bigint','ALTER TABLE `cb_finance_salary` DROP COLUMN `update_time_ts`','SELECT 1');
PREPARE r184 FROM @q184;EXECUTE r184;DEALLOCATE PREPARE r184;
SET @q185=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician_settlement' AND COLUMN_NAME='paid_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician_settlement' AND COLUMN_NAME='paid_time'),'')!='bigint','ALTER TABLE `cb_technician_settlement` CHANGE COLUMN `paid_time_ts` `paid_time` BIGINT NULL COMMENT ''打款时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r185 FROM @q185;EXECUTE r185;DEALLOCATE PREPARE r185;
SET @q186=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician_settlement' AND COLUMN_NAME='paid_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician_settlement' AND COLUMN_NAME='paid_time'),'')='bigint','ALTER TABLE `cb_technician_settlement` DROP COLUMN `paid_time_ts`','SELECT 1');
PREPARE r186 FROM @q186;EXECUTE r186;DEALLOCATE PREPARE r186;
SET @q187=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician_settlement' AND COLUMN_NAME='create_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician_settlement' AND COLUMN_NAME='create_time'),'')!='bigint','ALTER TABLE `cb_technician_settlement` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''创建时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r187 FROM @q187;EXECUTE r187;DEALLOCATE PREPARE r187;
SET @q188=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician_settlement' AND COLUMN_NAME='create_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician_settlement' AND COLUMN_NAME='create_time'),'')='bigint','ALTER TABLE `cb_technician_settlement` DROP COLUMN `create_time_ts`','SELECT 1');
PREPARE r188 FROM @q188;EXECUTE r188;DEALLOCATE PREPARE r188;
SET @q189=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician_settlement' AND COLUMN_NAME='update_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician_settlement' AND COLUMN_NAME='update_time'),'')!='bigint','ALTER TABLE `cb_technician_settlement` CHANGE COLUMN `update_time_ts` `update_time` BIGINT NOT NULL COMMENT ''更新时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r189 FROM @q189;EXECUTE r189;DEALLOCATE PREPARE r189;
SET @q190=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician_settlement' AND COLUMN_NAME='update_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician_settlement' AND COLUMN_NAME='update_time'),'')='bigint','ALTER TABLE `cb_technician_settlement` DROP COLUMN `update_time_ts`','SELECT 1');
PREPARE r190 FROM @q190;EXECUTE r190;DEALLOCATE PREPARE r190;
SET @q191=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician_settlement_item' AND COLUMN_NAME='service_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician_settlement_item' AND COLUMN_NAME='service_time'),'')!='bigint','ALTER TABLE `cb_technician_settlement_item` CHANGE COLUMN `service_time_ts` `service_time` BIGINT NULL COMMENT ''服务时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r191 FROM @q191;EXECUTE r191;DEALLOCATE PREPARE r191;
SET @q192=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician_settlement_item' AND COLUMN_NAME='service_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician_settlement_item' AND COLUMN_NAME='service_time'),'')='bigint','ALTER TABLE `cb_technician_settlement_item` DROP COLUMN `service_time_ts`','SELECT 1');
PREPARE r192 FROM @q192;EXECUTE r192;DEALLOCATE PREPARE r192;
SET @q193=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_commission_rule' AND COLUMN_NAME='create_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_commission_rule' AND COLUMN_NAME='create_time'),'')!='bigint','ALTER TABLE `cb_commission_rule` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''创建时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r193 FROM @q193;EXECUTE r193;DEALLOCATE PREPARE r193;
SET @q194=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_commission_rule' AND COLUMN_NAME='create_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_commission_rule' AND COLUMN_NAME='create_time'),'')='bigint','ALTER TABLE `cb_commission_rule` DROP COLUMN `create_time_ts`','SELECT 1');
PREPARE r194 FROM @q194;EXECUTE r194;DEALLOCATE PREPARE r194;
SET @q195=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_commission_rule' AND COLUMN_NAME='update_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_commission_rule' AND COLUMN_NAME='update_time'),'')!='bigint','ALTER TABLE `cb_commission_rule` CHANGE COLUMN `update_time_ts` `update_time` BIGINT NOT NULL COMMENT ''更新时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r195 FROM @q195;EXECUTE r195;DEALLOCATE PREPARE r195;
SET @q196=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_commission_rule' AND COLUMN_NAME='update_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_commission_rule' AND COLUMN_NAME='update_time'),'')='bigint','ALTER TABLE `cb_commission_rule` DROP COLUMN `update_time_ts`','SELECT 1');
PREPARE r196 FROM @q196;EXECUTE r196;DEALLOCATE PREPARE r196;
SET @q197=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order_item' AND COLUMN_NAME='start_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order_item' AND COLUMN_NAME='start_time'),'')!='bigint','ALTER TABLE `cb_order_item` CHANGE COLUMN `start_time_ts` `start_time` BIGINT NULL COMMENT ''服务开始时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r197 FROM @q197;EXECUTE r197;DEALLOCATE PREPARE r197;
SET @q198=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order_item' AND COLUMN_NAME='start_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order_item' AND COLUMN_NAME='start_time'),'')='bigint','ALTER TABLE `cb_order_item` DROP COLUMN `start_time_ts`','SELECT 1');
PREPARE r198 FROM @q198;EXECUTE r198;DEALLOCATE PREPARE r198;
SET @q199=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order_item' AND COLUMN_NAME='end_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order_item' AND COLUMN_NAME='end_time'),'')!='bigint','ALTER TABLE `cb_order_item` CHANGE COLUMN `end_time_ts` `end_time` BIGINT NULL COMMENT ''服务结束时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r199 FROM @q199;EXECUTE r199;DEALLOCATE PREPARE r199;
SET @q200=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order_item' AND COLUMN_NAME='end_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order_item' AND COLUMN_NAME='end_time'),'')='bigint','ALTER TABLE `cb_order_item` DROP COLUMN `end_time_ts`','SELECT 1');
PREPARE r200 FROM @q200;EXECUTE r200;DEALLOCATE PREPARE r200;
SET @q201=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order_item' AND COLUMN_NAME='create_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order_item' AND COLUMN_NAME='create_time'),'')!='bigint','ALTER TABLE `cb_order_item` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''创建时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r201 FROM @q201;EXECUTE r201;DEALLOCATE PREPARE r201;
SET @q202=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order_item' AND COLUMN_NAME='create_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order_item' AND COLUMN_NAME='create_time'),'')='bigint','ALTER TABLE `cb_order_item` DROP COLUMN `create_time_ts`','SELECT 1');
PREPARE r202 FROM @q202;EXECUTE r202;DEALLOCATE PREPARE r202;
SET @q203=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order_item' AND COLUMN_NAME='update_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order_item' AND COLUMN_NAME='update_time'),'')!='bigint','ALTER TABLE `cb_order_item` CHANGE COLUMN `update_time_ts` `update_time` BIGINT NOT NULL COMMENT ''更新时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r203 FROM @q203;EXECUTE r203;DEALLOCATE PREPARE r203;
SET @q204=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order_item' AND COLUMN_NAME='update_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_order_item' AND COLUMN_NAME='update_time'),'')='bigint','ALTER TABLE `cb_order_item` DROP COLUMN `update_time_ts`','SELECT 1');
PREPARE r204 FROM @q204;EXECUTE r204;DEALLOCATE PREPARE r204;
SET @q205=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician_service_price' AND COLUMN_NAME='create_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician_service_price' AND COLUMN_NAME='create_time'),'')!='bigint','ALTER TABLE `cb_technician_service_price` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''创建时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r205 FROM @q205;EXECUTE r205;DEALLOCATE PREPARE r205;
SET @q206=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician_service_price' AND COLUMN_NAME='create_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician_service_price' AND COLUMN_NAME='create_time'),'')='bigint','ALTER TABLE `cb_technician_service_price` DROP COLUMN `create_time_ts`','SELECT 1');
PREPARE r206 FROM @q206;EXECUTE r206;DEALLOCATE PREPARE r206;
SET @q207=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician_service_price' AND COLUMN_NAME='update_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician_service_price' AND COLUMN_NAME='update_time'),'')!='bigint','ALTER TABLE `cb_technician_service_price` CHANGE COLUMN `update_time_ts` `update_time` BIGINT NOT NULL COMMENT ''更新时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r207 FROM @q207;EXECUTE r207;DEALLOCATE PREPARE r207;
SET @q208=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician_service_price' AND COLUMN_NAME='update_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_technician_service_price' AND COLUMN_NAME='update_time'),'')='bigint','ALTER TABLE `cb_technician_service_price` DROP COLUMN `update_time_ts`','SELECT 1');
PREPARE r208 FROM @q208;EXECUTE r208;DEALLOCATE PREPARE r208;
SET @q209=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_oper_log' AND COLUMN_NAME='oper_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_oper_log' AND COLUMN_NAME='oper_time'),'')!='bigint','ALTER TABLE `sys_oper_log` CHANGE COLUMN `oper_time_ts` `oper_time` BIGINT NULL COMMENT ''操作时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r209 FROM @q209;EXECUTE r209;DEALLOCATE PREPARE r209;
SET @q210=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_oper_log' AND COLUMN_NAME='oper_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_oper_log' AND COLUMN_NAME='oper_time'),'')='bigint','ALTER TABLE `sys_oper_log` DROP COLUMN `oper_time_ts`','SELECT 1');
PREPARE r210 FROM @q210;EXECUTE r210;DEALLOCATE PREPARE r210;
SET @q211=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='merchant_announcement_read' AND COLUMN_NAME='read_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='merchant_announcement_read' AND COLUMN_NAME='read_time'),'')!='bigint','ALTER TABLE `merchant_announcement_read` CHANGE COLUMN `read_time_ts` `read_time` BIGINT NULL COMMENT ''已读时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r211 FROM @q211;EXECUTE r211;DEALLOCATE PREPARE r211;
SET @q212=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='merchant_announcement_read' AND COLUMN_NAME='read_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='merchant_announcement_read' AND COLUMN_NAME='read_time'),'')='bigint','ALTER TABLE `merchant_announcement_read` DROP COLUMN `read_time_ts`','SELECT 1');
PREPARE r212 FROM @q212;EXECUTE r212;DEALLOCATE PREPARE r212;

SELECT 'migrate_v5_3_fix 完成' AS result;

-- ── migrate_v5_4_remaining.sql ─────────────────────────────────────────────────────────
-- migrate_v5_4_remaining.sql  剩余 8 个仍是 datetime 表的完整迁移
SET NAMES utf8mb4;

SET @q1=IF(IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_merchant_staff' AND COLUMN_NAME='create_time'),'')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_merchant_staff' AND COLUMN_NAME='create_time_ts')=0,'ALTER TABLE `cb_merchant_staff` ADD COLUMN `create_time_ts` BIGINT NOT NULL DEFAULT 0 COMMENT ''创建时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r1 FROM @q1;EXECUTE r1;DEALLOCATE PREPARE r1;
SET @q2=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_merchant_staff' AND COLUMN_NAME='create_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_merchant_staff' AND COLUMN_NAME='create_time'),'')='datetime','UPDATE `cb_merchant_staff` SET `create_time_ts`=UNIX_TIMESTAMP(`create_time`)','SELECT 1');
PREPARE r2 FROM @q2;EXECUTE r2;DEALLOCATE PREPARE r2;
SET @q3=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_merchant_staff' AND COLUMN_NAME='create_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_merchant_staff' AND COLUMN_NAME='create_time'),'')='datetime','ALTER TABLE `cb_merchant_staff` DROP COLUMN `create_time`','SELECT 1');
PREPARE r3 FROM @q3;EXECUTE r3;DEALLOCATE PREPARE r3;
SET @q4=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_merchant_staff' AND COLUMN_NAME='create_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_merchant_staff' AND COLUMN_NAME='create_time'),'')!='bigint','ALTER TABLE `cb_merchant_staff` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''创建时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r4 FROM @q4;EXECUTE r4;DEALLOCATE PREPARE r4;
SET @q5=IF(IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_merchant_staff' AND COLUMN_NAME='update_time'),'')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_merchant_staff' AND COLUMN_NAME='update_time_ts')=0,'ALTER TABLE `cb_merchant_staff` ADD COLUMN `update_time_ts` BIGINT NOT NULL DEFAULT 0 COMMENT ''更新时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r5 FROM @q5;EXECUTE r5;DEALLOCATE PREPARE r5;
SET @q6=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_merchant_staff' AND COLUMN_NAME='update_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_merchant_staff' AND COLUMN_NAME='update_time'),'')='datetime','UPDATE `cb_merchant_staff` SET `update_time_ts`=UNIX_TIMESTAMP(`update_time`)','SELECT 1');
PREPARE r6 FROM @q6;EXECUTE r6;DEALLOCATE PREPARE r6;
SET @q7=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_merchant_staff' AND COLUMN_NAME='update_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_merchant_staff' AND COLUMN_NAME='update_time'),'')='datetime','ALTER TABLE `cb_merchant_staff` DROP COLUMN `update_time`','SELECT 1');
PREPARE r7 FROM @q7;EXECUTE r7;DEALLOCATE PREPARE r7;
SET @q8=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_merchant_staff' AND COLUMN_NAME='update_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='cb_merchant_staff' AND COLUMN_NAME='update_time'),'')!='bigint','ALTER TABLE `cb_merchant_staff` CHANGE COLUMN `update_time_ts` `update_time` BIGINT NOT NULL COMMENT ''更新时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r8 FROM @q8;EXECUTE r8;DEALLOCATE PREPARE r8;
SET @q9=IF(IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='merchant_announcement' AND COLUMN_NAME='create_time'),'')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='merchant_announcement' AND COLUMN_NAME='create_time_ts')=0,'ALTER TABLE `merchant_announcement` ADD COLUMN `create_time_ts` BIGINT NOT NULL DEFAULT 0 COMMENT ''创建时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r9 FROM @q9;EXECUTE r9;DEALLOCATE PREPARE r9;
SET @q10=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='merchant_announcement' AND COLUMN_NAME='create_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='merchant_announcement' AND COLUMN_NAME='create_time'),'')='datetime','UPDATE `merchant_announcement` SET `create_time_ts`=UNIX_TIMESTAMP(`create_time`)','SELECT 1');
PREPARE r10 FROM @q10;EXECUTE r10;DEALLOCATE PREPARE r10;
SET @q11=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='merchant_announcement' AND COLUMN_NAME='create_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='merchant_announcement' AND COLUMN_NAME='create_time'),'')='datetime','ALTER TABLE `merchant_announcement` DROP COLUMN `create_time`','SELECT 1');
PREPARE r11 FROM @q11;EXECUTE r11;DEALLOCATE PREPARE r11;
SET @q12=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='merchant_announcement' AND COLUMN_NAME='create_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='merchant_announcement' AND COLUMN_NAME='create_time'),'')!='bigint','ALTER TABLE `merchant_announcement` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''创建时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r12 FROM @q12;EXECUTE r12;DEALLOCATE PREPARE r12;
SET @q13=IF(IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='merchant_announcement' AND COLUMN_NAME='update_time'),'')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='merchant_announcement' AND COLUMN_NAME='update_time_ts')=0,'ALTER TABLE `merchant_announcement` ADD COLUMN `update_time_ts` BIGINT NOT NULL DEFAULT 0 COMMENT ''更新时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r13 FROM @q13;EXECUTE r13;DEALLOCATE PREPARE r13;
SET @q14=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='merchant_announcement' AND COLUMN_NAME='update_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='merchant_announcement' AND COLUMN_NAME='update_time'),'')='datetime','UPDATE `merchant_announcement` SET `update_time_ts`=UNIX_TIMESTAMP(`update_time`)','SELECT 1');
PREPARE r14 FROM @q14;EXECUTE r14;DEALLOCATE PREPARE r14;
SET @q15=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='merchant_announcement' AND COLUMN_NAME='update_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='merchant_announcement' AND COLUMN_NAME='update_time'),'')='datetime','ALTER TABLE `merchant_announcement` DROP COLUMN `update_time`','SELECT 1');
PREPARE r15 FROM @q15;EXECUTE r15;DEALLOCATE PREPARE r15;
SET @q16=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='merchant_announcement' AND COLUMN_NAME='update_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='merchant_announcement' AND COLUMN_NAME='update_time'),'')!='bigint','ALTER TABLE `merchant_announcement` CHANGE COLUMN `update_time_ts` `update_time` BIGINT NOT NULL COMMENT ''更新时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r16 FROM @q16;EXECUTE r16;DEALLOCATE PREPARE r16;
SET @q17=IF(IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_dept' AND COLUMN_NAME='create_time'),'')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_dept' AND COLUMN_NAME='create_time_ts')=0,'ALTER TABLE `sys_dept` ADD COLUMN `create_time_ts` BIGINT NOT NULL DEFAULT 0 COMMENT ''创建时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r17 FROM @q17;EXECUTE r17;DEALLOCATE PREPARE r17;
SET @q18=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_dept' AND COLUMN_NAME='create_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_dept' AND COLUMN_NAME='create_time'),'')='datetime','UPDATE `sys_dept` SET `create_time_ts`=UNIX_TIMESTAMP(`create_time`)','SELECT 1');
PREPARE r18 FROM @q18;EXECUTE r18;DEALLOCATE PREPARE r18;
SET @q19=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_dept' AND COLUMN_NAME='create_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_dept' AND COLUMN_NAME='create_time'),'')='datetime','ALTER TABLE `sys_dept` DROP COLUMN `create_time`','SELECT 1');
PREPARE r19 FROM @q19;EXECUTE r19;DEALLOCATE PREPARE r19;
SET @q20=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_dept' AND COLUMN_NAME='create_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_dept' AND COLUMN_NAME='create_time'),'')!='bigint','ALTER TABLE `sys_dept` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''创建时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r20 FROM @q20;EXECUTE r20;DEALLOCATE PREPARE r20;
SET @q21=IF(IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_dept' AND COLUMN_NAME='update_time'),'')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_dept' AND COLUMN_NAME='update_time_ts')=0,'ALTER TABLE `sys_dept` ADD COLUMN `update_time_ts` BIGINT NOT NULL DEFAULT 0 COMMENT ''更新时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r21 FROM @q21;EXECUTE r21;DEALLOCATE PREPARE r21;
SET @q22=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_dept' AND COLUMN_NAME='update_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_dept' AND COLUMN_NAME='update_time'),'')='datetime','UPDATE `sys_dept` SET `update_time_ts`=UNIX_TIMESTAMP(`update_time`)','SELECT 1');
PREPARE r22 FROM @q22;EXECUTE r22;DEALLOCATE PREPARE r22;
SET @q23=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_dept' AND COLUMN_NAME='update_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_dept' AND COLUMN_NAME='update_time'),'')='datetime','ALTER TABLE `sys_dept` DROP COLUMN `update_time`','SELECT 1');
PREPARE r23 FROM @q23;EXECUTE r23;DEALLOCATE PREPARE r23;
SET @q24=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_dept' AND COLUMN_NAME='update_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_dept' AND COLUMN_NAME='update_time'),'')!='bigint','ALTER TABLE `sys_dept` CHANGE COLUMN `update_time_ts` `update_time` BIGINT NOT NULL COMMENT ''更新时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r24 FROM @q24;EXECUTE r24;DEALLOCATE PREPARE r24;
SET @q25=IF(IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_dept_menu' AND COLUMN_NAME='create_time'),'')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_dept_menu' AND COLUMN_NAME='create_time_ts')=0,'ALTER TABLE `sys_dept_menu` ADD COLUMN `create_time_ts` BIGINT NOT NULL DEFAULT 0 COMMENT ''创建时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r25 FROM @q25;EXECUTE r25;DEALLOCATE PREPARE r25;
SET @q26=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_dept_menu' AND COLUMN_NAME='create_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_dept_menu' AND COLUMN_NAME='create_time'),'')='datetime','UPDATE `sys_dept_menu` SET `create_time_ts`=UNIX_TIMESTAMP(`create_time`)','SELECT 1');
PREPARE r26 FROM @q26;EXECUTE r26;DEALLOCATE PREPARE r26;
SET @q27=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_dept_menu' AND COLUMN_NAME='create_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_dept_menu' AND COLUMN_NAME='create_time'),'')='datetime','ALTER TABLE `sys_dept_menu` DROP COLUMN `create_time`','SELECT 1');
PREPARE r27 FROM @q27;EXECUTE r27;DEALLOCATE PREPARE r27;
SET @q28=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_dept_menu' AND COLUMN_NAME='create_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_dept_menu' AND COLUMN_NAME='create_time'),'')!='bigint','ALTER TABLE `sys_dept_menu` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''创建时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r28 FROM @q28;EXECUTE r28;DEALLOCATE PREPARE r28;
SET @q29=IF(IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_notice' AND COLUMN_NAME='create_time'),'')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_notice' AND COLUMN_NAME='create_time_ts')=0,'ALTER TABLE `sys_notice` ADD COLUMN `create_time_ts` BIGINT NOT NULL DEFAULT 0 COMMENT ''创建时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r29 FROM @q29;EXECUTE r29;DEALLOCATE PREPARE r29;
SET @q30=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_notice' AND COLUMN_NAME='create_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_notice' AND COLUMN_NAME='create_time'),'')='datetime','UPDATE `sys_notice` SET `create_time_ts`=UNIX_TIMESTAMP(`create_time`)','SELECT 1');
PREPARE r30 FROM @q30;EXECUTE r30;DEALLOCATE PREPARE r30;
SET @q31=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_notice' AND COLUMN_NAME='create_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_notice' AND COLUMN_NAME='create_time'),'')='datetime','ALTER TABLE `sys_notice` DROP COLUMN `create_time`','SELECT 1');
PREPARE r31 FROM @q31;EXECUTE r31;DEALLOCATE PREPARE r31;
SET @q32=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_notice' AND COLUMN_NAME='create_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_notice' AND COLUMN_NAME='create_time'),'')!='bigint','ALTER TABLE `sys_notice` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''创建时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r32 FROM @q32;EXECUTE r32;DEALLOCATE PREPARE r32;
SET @q33=IF(IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_notice' AND COLUMN_NAME='update_time'),'')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_notice' AND COLUMN_NAME='update_time_ts')=0,'ALTER TABLE `sys_notice` ADD COLUMN `update_time_ts` BIGINT NOT NULL DEFAULT 0 COMMENT ''更新时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r33 FROM @q33;EXECUTE r33;DEALLOCATE PREPARE r33;
SET @q34=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_notice' AND COLUMN_NAME='update_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_notice' AND COLUMN_NAME='update_time'),'')='datetime','UPDATE `sys_notice` SET `update_time_ts`=UNIX_TIMESTAMP(`update_time`)','SELECT 1');
PREPARE r34 FROM @q34;EXECUTE r34;DEALLOCATE PREPARE r34;
SET @q35=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_notice' AND COLUMN_NAME='update_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_notice' AND COLUMN_NAME='update_time'),'')='datetime','ALTER TABLE `sys_notice` DROP COLUMN `update_time`','SELECT 1');
PREPARE r35 FROM @q35;EXECUTE r35;DEALLOCATE PREPARE r35;
SET @q36=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_notice' AND COLUMN_NAME='update_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_notice' AND COLUMN_NAME='update_time'),'')!='bigint','ALTER TABLE `sys_notice` CHANGE COLUMN `update_time_ts` `update_time` BIGINT NOT NULL COMMENT ''更新时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r36 FROM @q36;EXECUTE r36;DEALLOCATE PREPARE r36;
SET @q37=IF(IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_position' AND COLUMN_NAME='create_time'),'')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_position' AND COLUMN_NAME='create_time_ts')=0,'ALTER TABLE `sys_position` ADD COLUMN `create_time_ts` BIGINT NOT NULL DEFAULT 0 COMMENT ''创建时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r37 FROM @q37;EXECUTE r37;DEALLOCATE PREPARE r37;
SET @q38=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_position' AND COLUMN_NAME='create_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_position' AND COLUMN_NAME='create_time'),'')='datetime','UPDATE `sys_position` SET `create_time_ts`=UNIX_TIMESTAMP(`create_time`)','SELECT 1');
PREPARE r38 FROM @q38;EXECUTE r38;DEALLOCATE PREPARE r38;
SET @q39=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_position' AND COLUMN_NAME='create_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_position' AND COLUMN_NAME='create_time'),'')='datetime','ALTER TABLE `sys_position` DROP COLUMN `create_time`','SELECT 1');
PREPARE r39 FROM @q39;EXECUTE r39;DEALLOCATE PREPARE r39;
SET @q40=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_position' AND COLUMN_NAME='create_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_position' AND COLUMN_NAME='create_time'),'')!='bigint','ALTER TABLE `sys_position` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''创建时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r40 FROM @q40;EXECUTE r40;DEALLOCATE PREPARE r40;
SET @q41=IF(IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_position' AND COLUMN_NAME='update_time'),'')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_position' AND COLUMN_NAME='update_time_ts')=0,'ALTER TABLE `sys_position` ADD COLUMN `update_time_ts` BIGINT NOT NULL DEFAULT 0 COMMENT ''更新时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r41 FROM @q41;EXECUTE r41;DEALLOCATE PREPARE r41;
SET @q42=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_position' AND COLUMN_NAME='update_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_position' AND COLUMN_NAME='update_time'),'')='datetime','UPDATE `sys_position` SET `update_time_ts`=UNIX_TIMESTAMP(`update_time`)','SELECT 1');
PREPARE r42 FROM @q42;EXECUTE r42;DEALLOCATE PREPARE r42;
SET @q43=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_position' AND COLUMN_NAME='update_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_position' AND COLUMN_NAME='update_time'),'')='datetime','ALTER TABLE `sys_position` DROP COLUMN `update_time`','SELECT 1');
PREPARE r43 FROM @q43;EXECUTE r43;DEALLOCATE PREPARE r43;
SET @q44=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_position' AND COLUMN_NAME='update_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_position' AND COLUMN_NAME='update_time'),'')!='bigint','ALTER TABLE `sys_position` CHANGE COLUMN `update_time_ts` `update_time` BIGINT NOT NULL COMMENT ''更新时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r44 FROM @q44;EXECUTE r44;DEALLOCATE PREPARE r44;
SET @q45=IF(IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_position_menu' AND COLUMN_NAME='create_time'),'')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_position_menu' AND COLUMN_NAME='create_time_ts')=0,'ALTER TABLE `sys_position_menu` ADD COLUMN `create_time_ts` BIGINT NOT NULL DEFAULT 0 COMMENT ''创建时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r45 FROM @q45;EXECUTE r45;DEALLOCATE PREPARE r45;
SET @q46=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_position_menu' AND COLUMN_NAME='create_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_position_menu' AND COLUMN_NAME='create_time'),'')='datetime','UPDATE `sys_position_menu` SET `create_time_ts`=UNIX_TIMESTAMP(`create_time`)','SELECT 1');
PREPARE r46 FROM @q46;EXECUTE r46;DEALLOCATE PREPARE r46;
SET @q47=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_position_menu' AND COLUMN_NAME='create_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_position_menu' AND COLUMN_NAME='create_time'),'')='datetime','ALTER TABLE `sys_position_menu` DROP COLUMN `create_time`','SELECT 1');
PREPARE r47 FROM @q47;EXECUTE r47;DEALLOCATE PREPARE r47;
SET @q48=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_position_menu' AND COLUMN_NAME='create_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_position_menu' AND COLUMN_NAME='create_time'),'')!='bigint','ALTER TABLE `sys_position_menu` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''创建时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r48 FROM @q48;EXECUTE r48;DEALLOCATE PREPARE r48;
SET @q49=IF(IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_staff_menu' AND COLUMN_NAME='create_time'),'')='datetime' AND (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_staff_menu' AND COLUMN_NAME='create_time_ts')=0,'ALTER TABLE `sys_staff_menu` ADD COLUMN `create_time_ts` BIGINT NOT NULL DEFAULT 0 COMMENT ''创建时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r49 FROM @q49;EXECUTE r49;DEALLOCATE PREPARE r49;
SET @q50=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_staff_menu' AND COLUMN_NAME='create_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_staff_menu' AND COLUMN_NAME='create_time'),'')='datetime','UPDATE `sys_staff_menu` SET `create_time_ts`=UNIX_TIMESTAMP(`create_time`)','SELECT 1');
PREPARE r50 FROM @q50;EXECUTE r50;DEALLOCATE PREPARE r50;
SET @q51=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_staff_menu' AND COLUMN_NAME='create_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_staff_menu' AND COLUMN_NAME='create_time'),'')='datetime','ALTER TABLE `sys_staff_menu` DROP COLUMN `create_time`','SELECT 1');
PREPARE r51 FROM @q51;EXECUTE r51;DEALLOCATE PREPARE r51;
SET @q52=IF((SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_staff_menu' AND COLUMN_NAME='create_time_ts')>0 AND IFNULL((SELECT DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='sys_staff_menu' AND COLUMN_NAME='create_time'),'')!='bigint','ALTER TABLE `sys_staff_menu` CHANGE COLUMN `create_time_ts` `create_time` BIGINT NOT NULL COMMENT ''创建时间（UTC 秒级时间戳）''','SELECT 1');
PREPARE r52 FROM @q52;EXECUTE r52;DEALLOCATE PREPARE r52;

SELECT 'migrate_v5_4_remaining 完成' AS result;

-- ── migrate_v5_5_order_item_tech.sql ─────────────────────────────────────────────────────────
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

-- ── migrate_v5_6_walkin_service_start_time.sql ─────────────────────────────────────────────────────────
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

-- ── migrate_v5_7_admin_menus.sql ─────────────────────────────────────────────────────────
-- ═══════════════════════════════════════════════════════════════════════════
-- Migration v5.7 — 管理端菜单路径全量修复 & 新功能菜单补全
--
-- 背景：前端路由从 /admin/xxx 风格重构为 /operation/xxx、/xxx 等新式路径，
--       但 sys_permission 表中的管理端菜单路径未同步更新，导致点击菜单后
--       React Outlet 无法匹配路由，内容区呈现空白。
--
-- 修复策略：
--   1. STEP 1 — 更新已有菜单的错误路径（按名称匹配，安全幂等）
--   2. STEP 2 — 确保全量目录节点存在（REPLACE INTO 高ID区间 9000-9050）
--   3. STEP 3 — 确保全量菜单节点存在（REPLACE INTO 高ID区间 9051-9150）
--   4. STEP 4 — 授权给 SUPER_ADMIN 角色（INSERT IGNORE）
-- ═══════════════════════════════════════════════════════════════════════════

SET NAMES utf8mb4;

-- ─────────────────────────────────────────────────────────────────────────────
-- STEP 1: 更新已有路径错误的菜单项（按名称精确匹配，安全）
-- ─────────────────────────────────────────────────────────────────────────────

-- 数据看板
UPDATE sys_permission SET path='/dashboard'
WHERE portal_type=0 AND type=2 AND deleted=0 AND (name='数据看板' OR name='仪表板' OR name='首页')
  AND path NOT IN ('/dashboard');

-- 会员管理
UPDATE sys_permission SET path='/users'
WHERE portal_type=0 AND type=2 AND deleted=0 AND name IN ('会员管理','用户管理','会员列表')
  AND path NOT IN ('/users');

-- 技师管理
UPDATE sys_permission SET path='/technicians'
WHERE portal_type=0 AND type=2 AND deleted=0 AND name IN ('技师管理','技师列表')
  AND path NOT IN ('/technicians');

-- 技师审核
UPDATE sys_permission SET path='/technicians/audit'
WHERE portal_type=0 AND type=2 AND deleted=0 AND name IN ('技师审核','审核列表','入驻审核')
  AND path NOT IN ('/technicians/audit');

-- 商户管理
UPDATE sys_permission SET path='/merchants'
WHERE portal_type=0 AND type=2 AND deleted=0 AND name IN ('商户管理','商户列表')
  AND path NOT IN ('/merchants');

-- 在线订单
UPDATE sys_permission SET path='/orders'
WHERE portal_type=0 AND type=2 AND deleted=0 AND name IN ('在线订单','订单列表','订单管理')
  AND path NOT IN ('/orders', '/walkin');

-- 订单历史
UPDATE sys_permission SET path='/orders/history'
WHERE portal_type=0 AND type=2 AND deleted=0 AND name IN ('历史订单','订单历史','已完成订单')
  AND path NOT IN ('/orders/history');

-- 门店订单
UPDATE sys_permission SET path='/walkin'
WHERE portal_type=0 AND type=2 AND deleted=0 AND name IN ('门店订单','散客接待','上门服务')
  AND path NOT IN ('/walkin');

-- 服务类目（旧：/admin/category、/system/category等）
UPDATE sys_permission SET path='/operation/category', icon='AppstoreOutlined'
WHERE portal_type=0 AND type=2 AND deleted=0
  AND (name IN ('服务项目','服务类目','服务分类') OR (path LIKE '%category%' AND path NOT LIKE '%merchant%'))
  AND path NOT IN ('/operation/category');

-- Banner管理（旧：/admin/banner、/system/banner等）
UPDATE sys_permission SET path='/operation/banner', icon='PictureOutlined'
WHERE portal_type=0 AND type=2 AND deleted=0
  AND (name IN ('Banner管理','轮播图','横幅管理','首页轮播') OR (path LIKE '%banner%' AND path NOT LIKE '%merchant%' AND path NOT LIKE '%system%'))
  AND path NOT IN ('/operation/banner');

-- 评价管理
UPDATE sys_permission SET path='/operation/reviews', icon='StarOutlined'
WHERE portal_type=0 AND type=2 AND deleted=0 AND name IN ('评价管理','用户评价','评论管理')
  AND path NOT IN ('/operation/reviews');

-- 车辆管理
UPDATE sys_permission SET path='/vehicles'
WHERE portal_type=0 AND type=2 AND deleted=0 AND name IN ('车辆管理','车辆列表')
  AND path NOT IN ('/vehicles', '/vehicles/dispatch');

-- 派车记录
UPDATE sys_permission SET path='/vehicles/dispatch'
WHERE portal_type=0 AND type=2 AND deleted=0 AND name IN ('派车记录','调度记录','车辆调度')
  AND path NOT IN ('/vehicles/dispatch');

-- 优惠券
UPDATE sys_permission SET path='/coupons'
WHERE portal_type=0 AND type=2 AND deleted=0 AND name IN ('优惠券','优惠券管理','优惠管理')
  AND path NOT IN ('/coupons');

-- 财务管理/收入统计
UPDATE sys_permission SET path='/finance'
WHERE portal_type=0 AND type=2 AND deleted=0 AND name IN ('财务管理','收入统计','财务报表')
  AND path NOT IN ('/finance', '/finance/overview', '/finance/income', '/finance/expense', '/finance/salary', '/finance/settlement');

-- 财务概览
UPDATE sys_permission SET path='/finance/overview'
WHERE portal_type=0 AND type=2 AND deleted=0 AND name IN ('财务概览','收支概览','财务总览')
  AND path NOT IN ('/finance/overview');

-- 员工管理（旧：/admin/staff 可能已是对的）
UPDATE sys_permission SET path='/admin/staff'
WHERE portal_type=0 AND type=2 AND deleted=0 AND name IN ('员工管理','员工列表')
  AND path NOT IN ('/admin/staff');

-- 职位管理
UPDATE sys_permission SET path='/admin/positions'
WHERE portal_type=0 AND type=2 AND deleted=0 AND name IN ('职位管理','岗位管理','职位列表')
  AND path NOT IN ('/admin/positions');

-- 角色权限
UPDATE sys_permission SET path='/system/roles'
WHERE portal_type=0 AND type=2 AND deleted=0 AND name IN ('角色权限','角色管理','角色列表')
  AND path NOT IN ('/system/roles');

-- 菜单管理
UPDATE sys_permission SET path='/admin/menus'
WHERE portal_type=0 AND type=2 AND deleted=0 AND name IN ('菜单管理','菜单配置','菜单列表')
  AND path NOT IN ('/admin/menus');

-- 权限配置
UPDATE sys_permission SET path='/system/permissions'
WHERE portal_type=0 AND type=2 AND deleted=0 AND name IN ('权限配置','权限管理','权限树')
  AND path NOT IN ('/system/permissions');

-- 部门管理
UPDATE sys_permission SET path='/system/dept'
WHERE portal_type=0 AND type=2 AND deleted=0 AND name IN ('部门管理','部门列表','组织架构')
  AND path NOT IN ('/system/dept');

-- 数据字典
UPDATE sys_permission SET path='/system/dict'
WHERE portal_type=0 AND type=2 AND deleted=0 AND name IN ('数据字典','字典管理','字典列表')
  AND path NOT IN ('/system/dict');

-- 系统参数
UPDATE sys_permission SET path='/system/param'
WHERE portal_type=0 AND type=2 AND deleted=0 AND name IN ('系统参数','参数配置','参数管理')
  AND path NOT IN ('/system/param');

-- 通知公告
UPDATE sys_permission SET path='/system/notice'
WHERE portal_type=0 AND type=2 AND deleted=0 AND name IN ('通知公告','公告管理','系统公告')
  AND path NOT IN ('/system/notice');

-- 操作日志
UPDATE sys_permission SET path='/system/log'
WHERE portal_type=0 AND type=2 AND deleted=0 AND name IN ('操作日志','日志管理','系统日志')
  AND path NOT IN ('/system/log');

-- 币种管理
UPDATE sys_permission SET path='/system/currency'
WHERE portal_type=0 AND type=2 AND deleted=0 AND name IN ('币种管理','货币管理','结算币种')
  AND path NOT IN ('/system/currency');

-- 监控：在线用户
UPDATE sys_permission SET path='/monitor/online'
WHERE portal_type=0 AND type=2 AND deleted=0 AND name IN ('在线用户','在线列表')
  AND path NOT IN ('/monitor/online');

-- 监控：定时任务
UPDATE sys_permission SET path='/monitor/job'
WHERE portal_type=0 AND type=2 AND deleted=0 AND name IN ('定时任务','任务调度','计划任务')
  AND path NOT IN ('/monitor/job');

-- 监控：服务器
UPDATE sys_permission SET path='/monitor/server'
WHERE portal_type=0 AND type=2 AND deleted=0 AND name IN ('服务器监控','服务器信息','系统监控')
  AND path NOT IN ('/monitor/server');

-- 监控：缓存
UPDATE sys_permission SET path='/monitor/cache'
WHERE portal_type=0 AND type=2 AND deleted=0 AND name IN ('缓存监控','缓存管理','Redis监控')
  AND path NOT IN ('/monitor/cache');

-- ─────────────────────────────────────────────────────────────────────────────
-- STEP 2: 确保目录节点存在（REPLACE INTO，ID范围 9001-9010，portal_type=0）
-- 若已有同名目录则通过 ID 确保存在；REPLACE INTO 对不存在的ID做插入，已存在则替换
-- ─────────────────────────────────────────────────────────────────────────────

INSERT IGNORE INTO sys_permission
    (id, parent_id, name, code, type, path, component, icon, sort, portal_type, visible, status, deleted)
VALUES
-- 目录节点（type=1，无 path）
(9001, 0, '用户管理', NULL, 1, NULL, NULL, 'TeamOutlined',       10, 0, 1, 1, 0),
(9002, 0, '订单管理', NULL, 1, NULL, NULL, 'OrderedListOutlined', 20, 0, 1, 1, 0),
(9003, 0, '运营管理', NULL, 1, NULL, NULL, 'AppstoreOutlined',    30, 0, 1, 1, 0),
(9004, 0, '财务管理', NULL, 1, NULL, NULL, 'DollarOutlined',      40, 0, 1, 1, 0),
(9005, 0, '系统管理', NULL, 1, NULL, NULL, 'SettingOutlined',     50, 0, 1, 1, 0),
(9006, 0, '监控管理', NULL, 1, NULL, NULL, 'DesktopOutlined',     60, 0, 1, 1, 0);

-- ─────────────────────────────────────────────────────────────────────────────
-- STEP 3: 确保菜单节点存在（INSERT IGNORE，ID范围 9051-9120）
-- 只补全缺失的菜单项；已存在的同 path 菜单不会被影响
-- ─────────────────────────────────────────────────────────────────────────────

-- 先确定目录 ID 变量（使用刚插入的 9001-9006 或者找已有同名目录）
SET @d_user    = IFNULL((SELECT id FROM sys_permission WHERE portal_type=0 AND type=1 AND deleted=0 AND name='用户管理' ORDER BY id LIMIT 1), 9001);
SET @d_order   = IFNULL((SELECT id FROM sys_permission WHERE portal_type=0 AND type=1 AND deleted=0 AND name='订单管理' ORDER BY id LIMIT 1), 9002);
SET @d_ops     = IFNULL((SELECT id FROM sys_permission WHERE portal_type=0 AND type=1 AND deleted=0 AND name='运营管理' ORDER BY id LIMIT 1), 9003);
SET @d_finance = IFNULL((SELECT id FROM sys_permission WHERE portal_type=0 AND type=1 AND deleted=0 AND name='财务管理' ORDER BY id LIMIT 1), 9004);
SET @d_system  = IFNULL((SELECT id FROM sys_permission WHERE portal_type=0 AND type=1 AND deleted=0 AND name='系统管理' ORDER BY id LIMIT 1), 9005);
SET @d_monitor = IFNULL((SELECT id FROM sys_permission WHERE portal_type=0 AND type=1 AND deleted=0 AND name='监控管理' ORDER BY id LIMIT 1), 9006);

-- 数据看板（顶级菜单）
INSERT IGNORE INTO sys_permission (id, parent_id, name, code, type, path, icon, sort, portal_type, visible, status, deleted)
VALUES (9051, 0, '数据看板', NULL, 2, '/dashboard', 'DashboardOutlined', 1, 0, 1, 1, 0);

-- 用户管理子菜单
INSERT IGNORE INTO sys_permission (id, parent_id, name, code, type, path, icon, sort, portal_type, visible, status, deleted)
VALUES
(9052, @d_user, '会员管理',   NULL, 2, '/users',              'UserOutlined',    1, 0, 1, 1, 0),
(9053, @d_user, '技师管理',   NULL, 2, '/technicians',        'TeamOutlined',    2, 0, 1, 1, 0),
(9054, @d_user, '技师审核',   NULL, 2, '/technicians/audit',  'AuditOutlined',   3, 0, 1, 1, 0),
(9055, @d_user, '商户管理',   NULL, 2, '/merchants',          'ShopOutlined',    4, 0, 1, 1, 0);

-- 订单管理子菜单
INSERT IGNORE INTO sys_permission (id, parent_id, name, code, type, path, icon, sort, portal_type, visible, status, deleted)
VALUES
(9056, @d_order, '在线订单', NULL, 2, '/orders',         'OrderedListOutlined', 1, 0, 1, 1, 0),
(9057, @d_order, '历史订单', NULL, 2, '/orders/history', 'FileTextOutlined',    2, 0, 1, 1, 0),
(9058, @d_order, '门店订单', NULL, 2, '/walkin',         'IdcardOutlined',      3, 0, 1, 1, 0);

-- 运营管理子菜单
INSERT IGNORE INTO sys_permission (id, parent_id, name, code, type, path, icon, sort, portal_type, visible, status, deleted)
VALUES
(9059, @d_ops, '服务类目',  NULL, 2, '/operation/category', 'AppstoreOutlined',    1, 0, 1, 1, 0),
(9060, @d_ops, 'Banner管理',NULL, 2, '/operation/banner',   'PictureOutlined',     2, 0, 1, 1, 0),
(9061, @d_ops, '评价管理',  NULL, 2, '/operation/reviews',  'StarOutlined',        3, 0, 1, 1, 0),
(9062, @d_ops, '车辆管理',  NULL, 2, '/vehicles',           'CarOutlined',         4, 0, 1, 1, 0),
(9063, @d_ops, '派车记录',  NULL, 2, '/vehicles/dispatch',  'FileTextOutlined',    5, 0, 1, 1, 0),
(9064, @d_ops, '优惠券',    NULL, 2, '/coupons',            'TagsOutlined',        6, 0, 1, 1, 0);

-- 财务管理子菜单
INSERT IGNORE INTO sys_permission (id, parent_id, name, code, type, path, icon, sort, portal_type, visible, status, deleted)
VALUES
(9065, @d_finance, '财务概览',  NULL, 2, '/finance/overview',   'BarChartOutlined',    1, 0, 1, 1, 0),
(9066, @d_finance, '收入统计',  NULL, 2, '/finance',            'DollarOutlined',      2, 0, 1, 1, 0),
(9067, @d_finance, '收入记录',  NULL, 2, '/finance/income',     'BankOutlined',        3, 0, 1, 1, 0),
(9068, @d_finance, '支出管理',  NULL, 2, '/finance/expense',    'MinusCircleOutlined', 4, 0, 1, 1, 0),
(9069, @d_finance, '薪资管理',  NULL, 2, '/finance/salary',     'IdcardOutlined',      5, 0, 1, 1, 0),
(9070, @d_finance, '技师结算',  NULL, 2, '/finance/settlement', 'AuditOutlined',       6, 0, 1, 1, 0);

-- 系统管理子菜单
INSERT IGNORE INTO sys_permission (id, parent_id, name, code, type, path, icon, sort, portal_type, visible, status, deleted)
VALUES
(9071, @d_system, '员工管理',  NULL, 2, '/admin/staff',        'IdcardOutlined',   1, 0, 1, 1, 0),
(9072, @d_system, '职位管理',  NULL, 2, '/admin/positions',    'SolutionOutlined', 2, 0, 1, 1, 0),
(9073, @d_system, '部门管理',  NULL, 2, '/system/dept',        'ApartmentOutlined',3, 0, 1, 1, 0),
(9074, @d_system, '角色权限',  NULL, 2, '/system/roles',       'KeyOutlined',      4, 0, 1, 1, 0),
(9075, @d_system, '菜单管理',  NULL, 2, '/admin/menus',        'MenuOutlined',     5, 0, 1, 1, 0),
(9076, @d_system, '权限配置',  NULL, 2, '/system/permissions', 'SafetyOutlined',   6, 0, 1, 1, 0),
(9077, @d_system, '数据字典',  NULL, 2, '/system/dict',        'DatabaseOutlined', 7, 0, 1, 1, 0),
(9078, @d_system, '系统参数',  NULL, 2, '/system/param',       'SettingOutlined',  8, 0, 1, 1, 0),
(9079, @d_system, '通知公告',  NULL, 2, '/system/notice',      'NotificationOutlined', 9, 0, 1, 1, 0),
(9080, @d_system, '操作日志',  NULL, 2, '/system/log',         'AuditOutlined',   10, 0, 1, 1, 0),
(9081, @d_system, '币种管理',  NULL, 2, '/system/currency',    'GlobalOutlined',  11, 0, 1, 1, 0);

-- 监控管理子菜单
INSERT IGNORE INTO sys_permission (id, parent_id, name, code, type, path, icon, sort, portal_type, visible, status, deleted)
VALUES
(9082, @d_monitor, '在线用户',   NULL, 2, '/monitor/online',  'UserOutlined',    1, 0, 1, 1, 0),
(9083, @d_monitor, '定时任务',   NULL, 2, '/monitor/job',     'ClockCircleOutlined', 2, 0, 1, 1, 0),
(9084, @d_monitor, '服务器监控', NULL, 2, '/monitor/server',  'DesktopOutlined', 3, 0, 1, 1, 0),
(9085, @d_monitor, '缓存监控',   NULL, 2, '/monitor/cache',   'DatabaseOutlined',4, 0, 1, 1, 0);

-- ─────────────────────────────────────────────────────────────────────────────
-- STEP 4: 将新增菜单授权给 SUPER_ADMIN 角色
-- ─────────────────────────────────────────────────────────────────────────────

INSERT IGNORE INTO sys_role_permission (role_id, permission_id)
SELECT r.id, p.id
FROM sys_role r
JOIN sys_permission p ON p.id BETWEEN 9001 AND 9120 AND p.deleted = 0
WHERE r.role_code = 'SUPER_ADMIN' AND r.deleted = 0
  AND NOT EXISTS (
    SELECT 1 FROM sys_role_permission rp
    WHERE rp.role_id = r.id AND rp.permission_id = p.id
  );

-- ─────────────────────────────────────────────────────────────────────────────
-- 注意：商户端（portal_type=1）菜单修复请使用 migrate_v5_8_merchant_portal_fix.sql
--       本文件仅处理管理员端（portal_type=0）
-- ─────────────────────────────────────────────────────────────────────────────

-- ─────────────────────────────────────────────────────────────────────────────
-- 验证结果（仅管理员端）
-- ─────────────────────────────────────────────────────────────────────────────
SELECT
    id,
    name,
    path,
    type,
    portal_type,
    icon,
    sort,
    CASE WHEN deleted=0 THEN '✅启用' ELSE '❌已删除' END AS status_label
FROM sys_permission
WHERE portal_type = 0 AND type = 2 AND deleted = 0
ORDER BY sort, id;

SELECT 'Migration v5.7 complete: Admin (portal_type=0) menu paths fixed, missing menus added.' AS result;

-- ── migrate_v5_8_merchant_portal_fix.sql ─────────────────────────────────────────────────────────
-- ═══════════════════════════════════════════════════════════════════════════
-- Migration v5.8 — 商户端全量修复
--
-- 修复内容：
--   1. 确保 cb_service_category 拥有 merchant_id / source_category_id 字段
--   2. 确保商户端所有菜单路径正确，与前端路由完全对齐
--   3. 补全任何缺失的商户端菜单节点
-- ═══════════════════════════════════════════════════════════════════════════

SET NAMES utf8mb4;

-- ─────────────────────────────────────────────────────────────────────────────
-- STEP 1: 确保 cb_service_category 含商户化字段
-- ─────────────────────────────────────────────────────────────────────────────

DROP PROCEDURE IF EXISTS _fix_service_category_cols;
DELIMITER $$
CREATE PROCEDURE _fix_service_category_cols()
BEGIN
    -- merchant_id
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME   = 'cb_service_category'
          AND COLUMN_NAME  = 'merchant_id'
    ) THEN
        ALTER TABLE `cb_service_category`
            ADD COLUMN `merchant_id` BIGINT NULL
                COMMENT '归属商户 ID（NULL = 平台公共类目）'
                AFTER `id`;
    END IF;

    -- source_category_id（写时复制来源）
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME   = 'cb_service_category'
          AND COLUMN_NAME  = 'source_category_id'
    ) THEN
        -- 优先插在 merchant_id 之后，兼容不同排列
        ALTER TABLE `cb_service_category`
            ADD COLUMN `source_category_id` BIGINT NULL
                COMMENT '写时复制来源：商户私有副本记录平台原始类目 ID'
                AFTER `merchant_id`;
    END IF;

    -- price / duration / is_special（migrate_v4_4 应已添加，保险起见）
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME   = 'cb_service_category'
          AND COLUMN_NAME  = 'price'
    ) THEN
        ALTER TABLE `cb_service_category`
            ADD COLUMN `price`      DECIMAL(10,2) NULL COMMENT '服务基础指导价'        AFTER `icon`,
            ADD COLUMN `duration`   INT           NULL COMMENT '标准服务时长（分钟）'   AFTER `price`,
            ADD COLUMN `is_special` TINYINT(1) NOT NULL DEFAULT 0
                COMMENT '是否特殊项目(0=常规,1=特殊)'                                   AFTER `duration`;
    END IF;
END$$
DELIMITER ;
CALL _fix_service_category_cols();
DROP PROCEDURE IF EXISTS _fix_service_category_cols;

SELECT '✅ cb_service_category 字段修复完成' AS step1;

-- ─────────────────────────────────────────────────────────────────────────────
-- STEP 2: 修复商户端菜单路径（按菜单名匹配，安全幂等）
-- ─────────────────────────────────────────────────────────────────────────────

-- 数据看板
UPDATE sys_permission SET path='/merchant/dashboard'
WHERE portal_type=1 AND type=2 AND deleted=0 AND name IN ('数据看板','首页','仪表板')
  AND path NOT IN ('/merchant/dashboard');

-- 在线订单
UPDATE sys_permission SET path='/merchant/orders'
WHERE portal_type=1 AND type=2 AND deleted=0 AND name IN ('在线订单','订单列表','订单管理')
  AND path NOT IN ('/merchant/orders','/merchant/orders/history');

-- 历史记录
UPDATE sys_permission SET path='/merchant/orders/history'
WHERE portal_type=1 AND type=2 AND deleted=0 AND name IN ('历史记录','历史订单','已完成订单')
  AND path NOT IN ('/merchant/orders/history');

-- 散客接待
UPDATE sys_permission SET path='/merchant/walkin'
WHERE portal_type=1 AND type=2 AND deleted=0 AND name IN ('散客接待','门店接待','上门服务')
  AND path NOT IN ('/merchant/walkin');

-- 服务项目
UPDATE sys_permission SET path='/merchant/operation/category'
WHERE portal_type=1 AND type=2 AND deleted=0
  AND (name IN ('服务项目','服务分类','服务类目') OR path LIKE '%category%')
  AND path NOT IN ('/merchant/operation/category');

-- 评价管理
UPDATE sys_permission SET path='/merchant/operation/reviews'
WHERE portal_type=1 AND type=2 AND deleted=0 AND name IN ('评价管理','用户评价','评论管理')
  AND path NOT IN ('/merchant/operation/reviews');

-- 通知公告（店内）
UPDATE sys_permission SET path='/merchant/operation/notices'
WHERE portal_type=1 AND type=2 AND deleted=0 AND name IN ('通知公告','店内公告','门店通知')
  AND path NOT IN ('/merchant/operation/notices','/merchant/announce/internal','/merchant/announce/customer');

-- 首页轮播
UPDATE sys_permission SET path='/merchant/operation/banner'
WHERE portal_type=1 AND type=2 AND deleted=0
  AND (name IN ('首页轮播','轮播图','Banner管理') OR path LIKE '%banner%')
  AND path NOT IN ('/merchant/operation/banner');

-- 会员管理
UPDATE sys_permission SET path='/merchant/members'
WHERE portal_type=1 AND type=2 AND deleted=0 AND name IN ('会员管理','会员列表')
  AND path NOT IN ('/merchant/members');

-- 技师管理
UPDATE sys_permission SET path='/merchant/technicians'
WHERE portal_type=1 AND type=2 AND deleted=0 AND name IN ('技师管理','技师列表')
  AND path NOT IN ('/merchant/technicians');

-- 车辆列表
UPDATE sys_permission SET path='/merchant/vehicles'
WHERE portal_type=1 AND type=2 AND deleted=0 AND name IN ('车辆列表','车辆管理') AND id != 1032
  AND path NOT IN ('/merchant/vehicles','/merchant/vehicles/dispatch');

-- 派车记录
UPDATE sys_permission SET path='/merchant/vehicles/dispatch'
WHERE portal_type=1 AND type=2 AND deleted=0 AND name IN ('派车记录','调度记录','车辆调度')
  AND path NOT IN ('/merchant/vehicles/dispatch');

-- 优惠券管理
UPDATE sys_permission SET path='/merchant/coupons'
WHERE portal_type=1 AND type=2 AND deleted=0 AND name IN ('优惠券管理','优惠券','营销券')
  AND path NOT IN ('/merchant/coupons');

-- 财务概览
UPDATE sys_permission SET path='/merchant/finance/overview'
WHERE portal_type=1 AND type=2 AND deleted=0 AND name IN ('财务概览','收支概览','财务总览')
  AND path NOT IN ('/merchant/finance/overview');

-- 收入统计 / 收入记录
UPDATE sys_permission SET path='/merchant/finance'
WHERE portal_type=1 AND type=2 AND deleted=0 AND name IN ('收入统计','财务统计','综合财务') AND id=1050
  AND path NOT IN ('/merchant/finance');

-- 收入记录（新菜单）
UPDATE sys_permission SET path='/merchant/finance/income'
WHERE portal_type=1 AND type=2 AND deleted=0 AND name IN ('收入记录','收款流水')
  AND path NOT IN ('/merchant/finance/income');

-- 支出管理
UPDATE sys_permission SET path='/merchant/finance/expense'
WHERE portal_type=1 AND type=2 AND deleted=0 AND name IN ('支出管理','费用管理','支出记录')
  AND path NOT IN ('/merchant/finance/expense');

-- 薪资 / 工资管理
UPDATE sys_permission SET path='/merchant/finance/salary'
WHERE portal_type=1 AND type=2 AND deleted=0 AND name IN ('工资管理','薪资管理','员工薪资')
  AND path NOT IN ('/merchant/finance/salary');

-- 技师结算
UPDATE sys_permission SET path='/merchant/finance/settlement'
WHERE portal_type=1 AND type=2 AND deleted=0 AND name IN ('技师结算','结算管理','技师工资')
  AND path NOT IN ('/merchant/finance/settlement');

-- 提现审核
UPDATE sys_permission SET path='/merchant/finance/withdraw'
WHERE portal_type=1 AND type=2 AND deleted=0 AND name IN ('提现审核','提现管理')
  AND path NOT IN ('/merchant/finance/withdraw');

-- 基本资料（商户设置）
UPDATE sys_permission SET path='/merchant/profile'
WHERE portal_type=1 AND type=2 AND deleted=0 AND name IN ('基本资料','商户资料','店铺设置') AND id != 1019
  AND path NOT IN ('/merchant/profile');

-- 结算币种
UPDATE sys_permission SET path='/merchant/settings/currency'
WHERE portal_type=1 AND type=2 AND deleted=0 AND name IN ('结算币种','币种配置','货币管理')
  AND path NOT IN ('/merchant/settings/currency');

-- 内部公告
UPDATE sys_permission SET path='/merchant/announce/internal'
WHERE portal_type=1 AND type=2 AND deleted=0 AND name IN ('内部公告','员工公告')
  AND path NOT IN ('/merchant/announce/internal');

-- 客户公告
UPDATE sys_permission SET path='/merchant/announce/customer'
WHERE portal_type=1 AND type=2 AND deleted=0 AND name IN ('客户公告','会员公告')
  AND path NOT IN ('/merchant/announce/customer');

-- 员工管理
UPDATE sys_permission SET path='/merchant/perm/staff'
WHERE portal_type=1 AND type=2 AND deleted=0 AND name IN ('员工管理','员工列表')
  AND path NOT IN ('/merchant/perm/staff');

-- 角色权限
UPDATE sys_permission SET path='/merchant/perm/roles'
WHERE portal_type=1 AND type=2 AND deleted=0 AND name IN ('角色权限','角色管理')
  AND path NOT IN ('/merchant/perm/roles');

-- 部门管理
UPDATE sys_permission SET path='/merchant/perm/dept'
WHERE portal_type=1 AND type=2 AND deleted=0 AND name IN ('部门管理','部门列表')
  AND path NOT IN ('/merchant/perm/dept');

-- 职位管理
UPDATE sys_permission SET path='/merchant/perm/positions'
WHERE portal_type=1 AND type=2 AND deleted=0 AND name IN ('职位管理','岗位管理')
  AND path NOT IN ('/merchant/perm/positions');

-- 历史订单（migrate_v5_7 可能误插了管理端路径，修正为商户端）
UPDATE sys_permission SET path='/merchant/orders/history'
WHERE portal_type=1 AND type=2 AND deleted=0 AND name IN ('历史订单','订单历史')
  AND path NOT IN ('/merchant/orders/history');

SELECT '✅ 商户端菜单路径修复完成' AS step2;

-- ─────────────────────────────────────────────────────────────────────────────
-- STEP 3: 补全缺失的商户端菜单节点（INSERT IGNORE，ID从 2000 起，不与已有 1000-1210 冲突）
-- ─────────────────────────────────────────────────────────────────────────────

-- 先确保目录节点存在
INSERT IGNORE INTO sys_permission
    (id, parent_id, name, code, type, path, component, icon, sort, portal_type, visible, status, deleted)
VALUES
-- 公告管理 目录（id=1000 已在 migrate_v3_4 存在）
(1000, 0, '公告管理',  NULL, 1, NULL, NULL, 'SoundOutlined',      3, 1, 1, 1, 0),
-- 运营管理 目录
(1001, 0, '运营管理',  NULL, 1, NULL, NULL, 'AppstoreOutlined',   4, 1, 1, 1, 0),
-- 营销管理 目录
(1002, 0, '营销管理',  NULL, 1, NULL, NULL, 'RocketOutlined',     5, 1, 1, 1, 0),
-- 财务管理 目录
(1003, 0, '财务管理',  NULL, 1, NULL, NULL, 'DollarOutlined',     6, 1, 1, 1, 0),
-- 权限管理 目录
(1004, 0, '权限管理',  NULL, 1, NULL, NULL, 'LockOutlined',       7, 1, 1, 1, 0),
-- 订单管理 目录（v4_3 改为 type=1）
(1011, 0, '订单管理',  NULL, 1, NULL, NULL, 'OrderedListOutlined',2, 1, 1, 1, 0),
-- 车辆管理 目录（v4_3 改为 type=1）
(1032, 1001, '车辆管理', NULL, 1, NULL, NULL, 'CarOutlined',      3, 1, 1, 1, 0),
-- 商户设置 目录（v4_3 改为 type=1）
(1019, 0, '商户设置',  NULL, 1, NULL, NULL, 'SettingOutlined',    9, 1, 1, 1, 0);

-- 补全菜单叶节点（只补缺失的）
INSERT IGNORE INTO sys_permission
    (id, parent_id, name, code, type, path, component, icon, sort, portal_type, visible, status, deleted)
VALUES
-- ── 数据看板（顶级）
(1010, 0,    '数据看板', NULL, 2, '/merchant/dashboard',             NULL, 'DashboardOutlined',   1, 1, 1, 1, 0),
-- ── 订单管理 子菜单
(1100, 1011, '在线订单', NULL, 2, '/merchant/orders',                NULL, 'OrderedListOutlined', 1, 1, 1, 1, 0),
(1101, 1011, '历史记录', NULL, 2, '/merchant/orders/history',        NULL, 'FileTextOutlined',    2, 1, 1, 1, 0),
-- ── 散客接待（顶级）
(1102, 0,    '散客接待', NULL, 2, '/merchant/walkin',                NULL, 'IdcardOutlined',     30, 1, 1, 1, 0),
-- ── 运营管理 子菜单
(1030, 1001, '会员管理', NULL, 2, '/merchant/members',               NULL, 'UserOutlined',        1, 1, 1, 1, 0),
(1031, 1001, '技师管理', NULL, 2, '/merchant/technicians',           NULL, 'TeamOutlined',        2, 1, 1, 1, 0),
(1033, 1001, '服务项目', NULL, 2, '/merchant/operation/category',    NULL, 'AppstoreOutlined',    4, 1, 1, 1, 0),
(1034, 1001, '评价管理', NULL, 2, '/merchant/operation/reviews',     NULL, 'StarOutlined',        5, 1, 1, 1, 0),
(1035, 1001, '通知公告', NULL, 2, '/merchant/operation/notices',     NULL, 'BellOutlined',        6, 1, 1, 1, 0),
-- ── 车辆管理 子菜单
(1103, 1032, '车辆列表', NULL, 2, '/merchant/vehicles',              NULL, 'CarOutlined',         1, 1, 1, 1, 0),
(1104, 1032, '派车记录', NULL, 2, '/merchant/vehicles/dispatch',     NULL, 'FileTextOutlined',    2, 1, 1, 1, 0),
-- ── 营销管理 子菜单
(1040, 1002, '首页轮播', NULL, 2, '/merchant/operation/banner',      NULL, 'PictureOutlined',     1, 1, 1, 1, 0),
(1041, 1002, '优惠券管理',NULL,2, '/merchant/coupons',               NULL, 'TagsOutlined',        2, 1, 1, 1, 0),
-- ── 财务管理 子菜单
(1105, 1003, '财务概览', NULL, 2, '/merchant/finance/overview',      NULL, 'BarChartOutlined',    1, 1, 1, 1, 0),
(1050, 1003, '收入统计', NULL, 2, '/merchant/finance',               NULL, 'BankOutlined',        2, 1, 1, 1, 0),
(1106, 1003, '收入记录', NULL, 2, '/merchant/finance/income',        NULL, 'DollarOutlined',      3, 1, 1, 1, 0),
(1107, 1003, '支出管理', NULL, 2, '/merchant/finance/expense',       NULL, 'MinusCircleOutlined', 4, 1, 1, 1, 0),
(1108, 1003, '工资管理', NULL, 2, '/merchant/finance/salary',        NULL, 'TeamOutlined',        5, 1, 1, 1, 0),
(1109, 1003, '技师结算', NULL, 2, '/merchant/finance/settlement',    NULL, 'BankOutlined',        6, 1, 1, 1, 0),
(1051, 1003, '提现审核', NULL, 2, '/merchant/finance/withdraw',      NULL, 'AuditOutlined',       7, 1, 1, 1, 0),
-- ── 商户设置 子菜单
(1111, 1019, '基本资料', NULL, 2, '/merchant/profile',               NULL, 'UserOutlined',        1, 1, 1, 1, 0),
(1112, 1019, '结算币种', NULL, 2, '/merchant/settings/currency',     NULL, 'GlobalOutlined',      2, 1, 1, 1, 0),
-- ── 公告管理 子菜单
(1020, 1000, '内部公告', NULL, 2, '/merchant/announce/internal',     NULL, 'TeamOutlined',        1, 1, 1, 1, 0),
(1021, 1000, '客户公告', NULL, 2, '/merchant/announce/customer',     NULL, 'UserOutlined',        2, 1, 1, 1, 0),
-- ── 权限管理 子菜单
(1060, 1004, '员工管理', NULL, 2, '/merchant/perm/staff',            NULL, 'IdcardOutlined',      1, 1, 1, 1, 0),
(1061, 1004, '角色权限', NULL, 2, '/merchant/perm/roles',            NULL, 'KeyOutlined',         2, 1, 1, 1, 0),
(1062, 1004, '部门管理', NULL, 2, '/merchant/perm/dept',             NULL, 'ApartmentOutlined',   3, 1, 1, 1, 0),
(1063, 1004, '职位管理', NULL, 2, '/merchant/perm/positions',        NULL, 'SolutionOutlined',    4, 1, 1, 1, 0);

SELECT '✅ 商户端菜单节点补全完成' AS step3;

-- ─────────────────────────────────────────────────────────────────────────────
-- STEP 4: 修正 id=1032 车辆管理由 type=2 变为 type=1（目录），清除路径
--         修正 id=1011 订单管理同理
--         修正 id=1019 商户设置同理
-- ─────────────────────────────────────────────────────────────────────────────
UPDATE sys_permission SET type=1, path=NULL WHERE id IN (1011, 1032, 1019) AND portal_type=1;

SELECT '✅ 目录节点 type 修正完成' AS step4;

-- ─────────────────────────────────────────────────────────────────────────────
-- STEP 5: 验证查询——查看所有商户端菜单
-- ─────────────────────────────────────────────────────────────────────────────
SELECT
    id,
    parent_id AS parentId,
    name,
    type,
    path,
    icon,
    sort,
    CASE WHEN deleted=0 THEN '✅启用' ELSE '❌删除' END AS state
FROM sys_permission
WHERE portal_type = 1 AND deleted = 0
ORDER BY sort ASC, id ASC;

SELECT 'Migration v5.8 complete: Merchant portal schema & menus fully fixed.' AS result;

-- ── migrate_v5_9_fix_walkin_start_time.sql ─────────────────────────────────────────────────────────
-- ═══════════════════════════════════════════════════════════════════════════
-- Migration v5.9 — 補全歷史散客 session 的 service_start_time
--
-- 舊版 startWalkin 接口未寫入 service_start_time。
-- 本腳本對所有 status IN (1,2)（服務中/待結算）且 service_start_time IS NULL
-- 的 session，用 check_in_time 作保底（最差情況是稍微偏大的已服務時間）。
--
-- 執行後重啟後端服務，App 再次進入專注模式即可讀到正確值。
-- ═══════════════════════════════════════════════════════════════════════════

SET NAMES utf8mb4;

-- 補全：服務中 / 待結算 且尚無 service_start_time 的 session
UPDATE cb_walkin_session
SET    service_start_time = check_in_time
WHERE  status IN (1, 2)
  AND  service_start_time IS NULL
  AND  deleted = 0;

SELECT CONCAT('已補全 ', ROW_COUNT(), ' 筆歷史 session 的 service_start_time') AS result;

-- ── migrate_v5_10_order_status_i18n.sql ─────────────────────────────────────────────────────────
-- ═══════════════════════════════════════════════════════════════════════════
-- Migration v5.10 — 将订单状态"待接单"更名为"预约订单" + 补全多语言标签
--
-- 实际表名：sys_dict（字段：label_zh / label_en / label_vi / label_km）
-- 影响：
--   sys_dict WHERE dict_type='order_status' AND dict_value='1'
--   label_zh : 待接单  →  预约订单
--   label_en : Waiting →  Appointment
--   label_vi : Chờ    →  Lịch hẹn
--   label_km : រង់ចាំ  →  ការណាត់ជួប
-- ═══════════════════════════════════════════════════════════════════════════

SET NAMES utf8mb4;

-- ── 主改动：status 1 重命名 ───────────────────────────────────────────────
UPDATE sys_dict
SET
    label_zh = '预约订单',
    label_en = 'Appointment',
    label_vi = 'Lịch hẹn',
    label_km = 'ការណាត់ជួប'
WHERE dict_type  = 'order_status'
  AND dict_value = '1';

-- ── 补全其余状态的多语言标签（仅填空值，不覆盖已有内容）─────────────────────
UPDATE sys_dict SET label_en = COALESCE(NULLIF(label_en,''), 'Pending Payment'), label_vi = COALESCE(NULLIF(label_vi,''), 'Chờ thanh toán'),  label_km = COALESCE(NULLIF(label_km,''), 'រង់ចាំការទូទាត់')  WHERE dict_type='order_status' AND dict_value='0';
UPDATE sys_dict SET label_en = COALESCE(NULLIF(label_en,''), 'Accepted'),        label_vi = COALESCE(NULLIF(label_vi,''), 'Đã tiếp nhận'),     label_km = COALESCE(NULLIF(label_km,''), 'ទទួលយកហើយ')         WHERE dict_type='order_status' AND dict_value='2';
UPDATE sys_dict SET label_en = COALESCE(NULLIF(label_en,''), 'On The Way'),      label_vi = COALESCE(NULLIF(label_vi,''), 'Đang đến'),          label_km = COALESCE(NULLIF(label_km,''), 'កំពុងធ្វើដំណើរ')     WHERE dict_type='order_status' AND dict_value='3';
UPDATE sys_dict SET label_en = COALESCE(NULLIF(label_en,''), 'Arrived'),         label_vi = COALESCE(NULLIF(label_vi,''), 'Đã đến'),            label_km = COALESCE(NULLIF(label_km,''), 'មកដល់ហើយ')          WHERE dict_type='order_status' AND dict_value='4';
UPDATE sys_dict SET label_en = COALESCE(NULLIF(label_en,''), 'In Service'),      label_vi = COALESCE(NULLIF(label_vi,''), 'Đang phục vụ'),      label_km = COALESCE(NULLIF(label_km,''), 'កំពុងបម្រើ')         WHERE dict_type='order_status' AND dict_value='5';
UPDATE sys_dict SET label_en = COALESCE(NULLIF(label_en,''), 'Completed'),       label_vi = COALESCE(NULLIF(label_vi,''), 'Hoàn thành'),        label_km = COALESCE(NULLIF(label_km,''), 'បានបញ្ចប់')           WHERE dict_type='order_status' AND dict_value='6';
UPDATE sys_dict SET label_en = COALESCE(NULLIF(label_en,''), 'Cancelled'),       label_vi = COALESCE(NULLIF(label_vi,''), 'Đã hủy'),            label_km = COALESCE(NULLIF(label_km,''), 'បានលុបចោល')          WHERE dict_type='order_status' AND dict_value='7';
UPDATE sys_dict SET label_en = COALESCE(NULLIF(label_en,''), 'Refunding'),       label_vi = COALESCE(NULLIF(label_vi,''), 'Đang hoàn tiền'),    label_km = COALESCE(NULLIF(label_km,''), 'កំពុងសង')            WHERE dict_type='order_status' AND dict_value='8';
UPDATE sys_dict SET label_en = COALESCE(NULLIF(label_en,''), 'Refunded'),        label_vi = COALESCE(NULLIF(label_vi,''), 'Đã hoàn tiền'),      label_km = COALESCE(NULLIF(label_km,''), 'បានសងប្រាក់')        WHERE dict_type='order_status' AND dict_value='9';

SELECT CONCAT('已更新 ', ROW_COUNT(), ' 行 order_status 字典数据') AS result;

-- ── migrate_v5_11_fix_order_item_duration.sql ─────────────────────────────────────────────────────────
-- ═══════════════════════════════════════════════════════════════════════════
-- Migration v5.11 — 补全 cb_order_item 中 service_duration = 0 的记录
--
-- 问题：部分在线订单服务项的 service_duration = 0（或 NULL），
--       导致 App 显示"面部护理 · 0分钟"等错误信息。
-- 原因：下单时服务分类未设置 duration，后来在后台补设了值，但历史数据未更新。
-- 修复：从 cb_service_category 中按 service_item_id 回填正确的时长。
-- ═══════════════════════════════════════════════════════════════════════════

SET NAMES utf8mb4;

-- 修复在线订单服务项时长
UPDATE cb_order_item oi
    JOIN cb_service_category cat ON cat.id = oi.service_item_id AND cat.deleted = 0
SET oi.service_duration = cat.duration
WHERE (oi.service_duration IS NULL OR oi.service_duration = 0)
  AND oi.service_item_id IS NOT NULL
  AND cat.duration IS NOT NULL
  AND cat.duration > 0
  AND oi.deleted = 0;

SELECT CONCAT('已补全 ', ROW_COUNT(), ' 条在线订单服务项时长') AS result;

-- 修复门店散客订单服务项时长（cb_order order_type=2）
UPDATE cb_order o
    JOIN cb_service_category cat ON cat.id = o.service_item_id AND cat.deleted = 0
SET o.service_duration = cat.duration
WHERE (o.service_duration IS NULL OR o.service_duration = 0)
  AND o.order_type = 2
  AND o.service_item_id IS NOT NULL
  AND cat.duration IS NOT NULL
  AND cat.duration > 0
  AND o.deleted = 0;

SELECT CONCAT('已补全 ', ROW_COUNT(), ' 条门店散客订单服务项时长') AS result;

-- ── migrate_v5_12_merchant_theme_color.sql ─────────────────────────────────────────────────────────
-- migrate_v5_12: 商户 App 主题色字段
-- 为每个商户添加可配置的 App 主题色（pink / ivory 或自定义 hex）
-- 默认值：pink（玫瑰粉）

ALTER TABLE cb_merchant
    ADD COLUMN IF NOT EXISTS theme_color VARCHAR(20) NOT NULL DEFAULT 'pink'
        COMMENT 'App主题色: pink=玫瑰粉, ivory=香槟金, 或自定义 #RRGGBB';

-- ── migrate_v5_13_order_service_item_default.sql ─────────────────────────────────────────────────────────
-- migrate_v5_13: 给 cb_order 所有后台手动建单可能为空的列补充默认值
-- 使用 ALTER COLUMN ... SET DEFAULT，只设默认值，不改类型，不触碰现有数据
-- 避免 MyBatis-Plus 跳过 null 字段时 MySQL 抛出 "doesn't have a default value"

ALTER TABLE cb_order
    ALTER COLUMN service_item_id  SET DEFAULT 0,
    ALTER COLUMN address_id       SET DEFAULT 0,
    ALTER COLUMN address_lat      SET DEFAULT 0,
    ALTER COLUMN address_lng      SET DEFAULT 0,
    ALTER COLUMN start_time       SET DEFAULT 0,
    ALTER COLUMN end_time         SET DEFAULT 0,
    ALTER COLUMN discount_amount  SET DEFAULT 0.00,
    ALTER COLUMN transport_fee    SET DEFAULT 0.00,
    ALTER COLUMN coupon_id        SET DEFAULT 0,
    ALTER COLUMN pay_type         SET DEFAULT 0,
    ALTER COLUMN pay_time         SET DEFAULT 0,
    ALTER COLUMN tech_income      SET DEFAULT 0.00,
    ALTER COLUMN platform_income  SET DEFAULT 0.00,
    ALTER COLUMN is_reviewed      SET DEFAULT 0;

-- ── fix_dict_dedup.sql ─────────────────────────────────────────────────────────
-- ============================================================
-- fix_dict_dedup.sql  安全去重 sys_dict 重复字典数据
--
-- 场景：migrate_v4_6_dict_seed.sql 执行了两次，每个
--       (dict_type, dict_value) 都出现两条完全相同的记录。
--
-- 安全策略：
--   ① 双重条件：id 更大 AND 内容与原始行完全一致，才判定为重复
--      → 手动新增的、内容不同的行绝不会被误删
--   ② 事务保护：DELETE 在事务内执行，确认结果后才 COMMIT，
--      中途任何疑问可立即 ROLLBACK
--   ③ 操作顺序：先看（步骤1）→ 再删（步骤2）→ 再验（步骤3）→ 最后提交
-- ============================================================


-- ════════════════════════════════════════════════════════════
-- 步骤1  预览将被删除的记录（只运行这一段，不要运行下面的事务）
--        结果全部是"内容与某条低 id 行完全相同"的行，核对无误再继续
-- ════════════════════════════════════════════════════════════
SELECT
    dup.id          AS `将删除_id`,
    dup.dict_type,
    dup.dict_value,
    dup.label_zh,
    orig.id         AS `保留的原始_id`
FROM sys_dict AS dup
INNER JOIN sys_dict AS orig
    ON  orig.dict_type  = dup.dict_type
    AND orig.dict_value = dup.dict_value
    AND orig.id         < dup.id          -- orig 是更早插入的那条
    AND orig.label_zh   = dup.label_zh    -- 内容完全相同才视为重复
    AND orig.label_en   = dup.label_en
    AND orig.label_vi   = dup.label_vi
    AND orig.label_km   = dup.label_km
    AND orig.label_ja   = dup.label_ja
    AND orig.label_ko   = dup.label_ko
ORDER BY dup.dict_type, dup.dict_value, dup.id;

-- 预期：查出的每一行都在截图里出现过的高 id 重复记录（如 539-542 等）
-- 若有任何意外行，停止操作，排查原因


-- ════════════════════════════════════════════════════════════
-- 步骤2  在事务内删除（确认步骤1结果无误后再执行）
-- ════════════════════════════════════════════════════════════
START TRANSACTION;

-- 2-A 再次确认：在事务内预览，条数与步骤1一致则继续
SELECT COUNT(*) AS `事务内_待删除数量`
FROM sys_dict AS dup
INNER JOIN sys_dict AS orig
    ON  orig.dict_type  = dup.dict_type
    AND orig.dict_value = dup.dict_value
    AND orig.id         < dup.id
    AND orig.label_zh   = dup.label_zh
    AND orig.label_en   = dup.label_en
    AND orig.label_vi   = dup.label_vi
    AND orig.label_km   = dup.label_km
    AND orig.label_ja   = dup.label_ja
    AND orig.label_ko   = dup.label_ko;

-- 2-B 执行删除（双重条件：id 更大 且 内容完全相同）
DELETE dup
FROM sys_dict AS dup
INNER JOIN sys_dict AS orig
    ON  orig.dict_type  = dup.dict_type
    AND orig.dict_value = dup.dict_value
    AND orig.id         < dup.id
    AND orig.label_zh   = dup.label_zh
    AND orig.label_en   = dup.label_en
    AND orig.label_vi   = dup.label_vi
    AND orig.label_km   = dup.label_km
    AND orig.label_ja   = dup.label_ja
    AND orig.label_ko   = dup.label_ko;

SELECT ROW_COUNT() AS `本次删除行数`;   -- 应与步骤1查出的数量相同


-- ════════════════════════════════════════════════════════════
-- 步骤3  验证（事务内执行，提交前最后确认）
-- ════════════════════════════════════════════════════════════

-- 3-A 应无重复——若有结果则说明还有问题，立即 ROLLBACK
SELECT
    dict_type,
    dict_value,
    COUNT(*) AS cnt
FROM sys_dict
GROUP BY dict_type, dict_value
HAVING cnt > 1
ORDER BY dict_type, dict_value;

-- 3-B 总记录数对比（第一次执行脚本后的正常数量）
SELECT COUNT(*) AS `sys_dict 当前总行数` FROM sys_dict;


-- ════════════════════════════════════════════════════════════
-- 步骤4  根据步骤3的结果二选一
-- ════════════════════════════════════════════════════════════

-- ✅ 步骤3 无重复、总行数正常 → 提交
COMMIT;

-- ❌ 步骤3 有异常 → 回滚，数据完全复原
-- ROLLBACK;


-- ════════════════════════════════════════════════════════════
-- 步骤5（可选）加唯一索引，防止以后再次重复插入
-- ════════════════════════════════════════════════════════════
-- ALTER TABLE sys_dict
--     ADD UNIQUE KEY uk_dict_type_value (dict_type, dict_value);
