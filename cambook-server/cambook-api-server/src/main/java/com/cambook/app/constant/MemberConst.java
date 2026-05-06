package com.cambook.app.constant;

/**
 * 会员相关常量
 *
 * @author CamBook
 */
public final class MemberConst {

    private MemberConst() {}

    public static final int STATUS_NORMAL  = 1;
    public static final int STATUS_BANNED  = 2;

    /** 用户类型：普通会员 */
    public static final String TYPE_MEMBER     = "member";
    /** 用户类型：技师 */
    public static final String TYPE_TECHNICIAN = "technician";
    /** 用户类型：商户 */
    public static final String TYPE_MERCHANT   = "merchant";

    /** 初始钱包余额 */
    public static final java.math.BigDecimal INIT_BALANCE = java.math.BigDecimal.ZERO;

    /** 默认头像 */
    public static final String DEFAULT_AVATAR = "https://cdn.cambook.com/avatar/default.png";
}
