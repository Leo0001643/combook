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
('TECHNICIAN_NOT_FOUND','zh','技师信息不存在'),
('TECHNICIAN_NOT_FOUND','en','Technician not found'),
('TECHNICIAN_NOT_FOUND','vi','Không tìm thấy kỹ thuật viên'),
('TECHNICIAN_NOT_FOUND','km','រកមិនឃើញបច្ចេកទេស'),
('TECHNICIAN_NOT_FOUND','ja','技師情報が見つかりません'),
('TECHNICIAN_NOT_FOUND','ko','기술자를 찾을 수 없습니다'),
-- TECHNICIAN_ALREADY_APPLIED
('TECHNICIAN_ALREADY_APPLIED','zh','您已提交过入驻申请，请耐心等待审核'),
('TECHNICIAN_ALREADY_APPLIED','en','You have already submitted an application, please wait for review'),
('TECHNICIAN_ALREADY_APPLIED','vi','Bạn đã nộp đơn đăng ký, vui lòng chờ xét duyệt'),
('TECHNICIAN_ALREADY_APPLIED','km','អ្នកបានដាក់ពាក្យស្នើសុំហើយ សូមរង់ចាំការពិនិត្យ'),
('TECHNICIAN_ALREADY_APPLIED','ja','すでに申請を提出しました。審査をお待ちください'),
('TECHNICIAN_ALREADY_APPLIED','ko','이미 신청서를 제출했습니다. 심사를 기다려 주세요'),
-- TECHNICIAN_AUDIT_PENDING
('TECHNICIAN_AUDIT_PENDING','zh','技师资料审核中，请耐心等待'),
('TECHNICIAN_AUDIT_PENDING','en','Your application is under review, please wait patiently'),
('TECHNICIAN_AUDIT_PENDING','vi','Đơn đăng ký đang được xem xét, vui lòng chờ'),
('TECHNICIAN_AUDIT_PENDING','km','ពាក្យស្នើសុំកំពុងស្ថិតក្រោមការពិនិត្យ'),
('TECHNICIAN_AUDIT_PENDING','ja','申請は審査中です。しばらくお待ちください'),
('TECHNICIAN_AUDIT_PENDING','ko','신청서가 심사 중입니다. 잠시 기다려 주세요'),
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
