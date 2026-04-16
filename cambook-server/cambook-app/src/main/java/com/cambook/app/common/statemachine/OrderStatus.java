package com.cambook.app.common.statemachine;

import java.util.Arrays;
import java.util.Optional;

/**
 * 订单状态枚举
 *
 * <p>所有合法状态在此集中定义，状态流转规则统一由 {@link OrderStateMachine} 管理。
 * 禁止在业务代码中用魔法数字表示状态。
 *
 * @author CamBook
 */
public enum OrderStatus {

    /** 待支付 */
    PENDING_PAYMENT(0, "待支付"),
    /** 已支付，等待技师接单 */
    PENDING_ACCEPT(1, "待接单"),
    /** 技师已接单，前往服务中 */
    ACCEPTED(2, "已接单"),
    /** 服务进行中 */
    IN_SERVICE(3, "服务中"),
    /** 服务已完成，待评价 */
    COMPLETED(4, "已完成"),
    /** 用户取消 */
    CANCELLED(5, "已取消"),
    /** 平台/技师拒绝接单 */
    REJECTED(6, "已拒绝"),
    /** 已退款 */
    REFUNDED(7, "已退款");

    private final int    code;
    private final String desc;

    OrderStatus(int code, String desc) {
        this.code = code;
        this.desc = desc;
    }

    public int    getCode() { return code; }
    public String getDesc() { return desc; }

    public static Optional<OrderStatus> of(int code) {
        return Arrays.stream(values()).filter(s -> s.code == code).findFirst();
    }
}
