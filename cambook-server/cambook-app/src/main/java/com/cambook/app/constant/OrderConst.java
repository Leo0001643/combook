package com.cambook.app.constant;

/**
 * 订单相关常量
 *
 * @author CamBook
 */
public final class OrderConst {

    private OrderConst() {}

    /** 订单状态 */
    public static final int STATUS_PENDING    = 1;  // 待接单
    public static final int STATUS_ACCEPTED   = 2;  // 已接单
    public static final int STATUS_EN_ROUTE   = 3;  // 技师前往
    public static final int STATUS_ARRIVED    = 4;  // 已到达
    public static final int STATUS_IN_SERVICE = 5;  // 服务中
    public static final int STATUS_DONE       = 6;  // 已完成
    public static final int STATUS_CANCELLED  = 7;  // 已取消
    public static final int STATUS_REFUNDING  = 8;  // 退款中
    public static final int STATUS_REFUNDED   = 9;  // 已退款

    /** 支付方式 */
    public static final int PAY_WECHAT  = 1;
    public static final int PAY_ALIPAY  = 2;
    public static final int PAY_WALLET  = 3;  // 钱包余额
    public static final int PAY_CASH    = 4;  // 线下现金

    /** 订单超时自动取消（分钟） */
    public static final int AUTO_CANCEL_MINUTES = 30;

    /** 服务完成后评价有效期（天） */
    public static final int REVIEW_EXPIRE_DAYS = 7;
}
