package com.cambook.app.constant;

/**
 * Redis 缓存 Key 常量
 * 格式：cb:{模块}:{业务}:{变量}
 *
 * @author CamBook
 */
public final class CacheKey {

    private CacheKey() {}

    /** 短信验证码：cb:sms:{mobile} TTL 5min */
    public static final String SMS_CODE        = "cb:sms:";

    /** App 端 JWT Token 黑名单（主动登出）：cb:token:black:{token前缀} */
    public static final String TOKEN_BLACKLIST = "cb:token:black:";

    /** 管理员权限集合：cb:admin:perms:{userId} TTL 30min */
    public static final String ADMIN_PERMS     = "cb:admin:perms:";

    /** 管理员角色 ID 列表：cb:admin:roles:{userId} TTL 30min */
    public static final String ADMIN_ROLES     = "cb:admin:roles:";

    /** 技师实时位置：cb:tech:location:{techId} TTL 10min */
    public static final String TECH_LOCATION   = "cb:tech:location:";

    /** 订单防重：cb:order:lock:{memberIdserviceItemId} TTL 60s */
    public static final String ORDER_LOCK      = "cb:order:lock:";

    /** 系统配置缓存：cb:config:{group}:{key} TTL 10min */
    public static final String SYS_CONFIG      = "cb:config:";

    /** 商户端全量菜单路径列表：cb:merchant:menus TTL 30min，权限变更时主动失效 */
    public static final String MERCHANT_MENUS  = "cb:merchant:menus";
}
