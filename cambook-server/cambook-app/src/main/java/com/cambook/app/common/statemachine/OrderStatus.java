package com.cambook.app.common.statemachine;

import java.util.Arrays;
import java.util.Optional;

/**
 * 订单状态枚举
 *
 * <p>状态码与数据库 {@code cb_order.status} 字段完全对齐：
 * <pre>
 *   0  待支付    PENDING_PAYMENT
 *   1  待接单    PENDING_ACCEPT   （已支付，等待技师接单）
 *   2  已接单    ACCEPTED
 *   3  前往中    ARRIVING         （技师出发前往服务地点）
 *   4  已到达    ARRIVED          （技师到达，准备开始）
 *   5  服务中    IN_SERVICE
 *   6  已完成    COMPLETED        （服务结束，待结算）
 *   7  已取消    CANCELLED
 *   8  退款中    REFUNDING
 *   9  已退款    REFUNDED
 * </pre>
 *
 * <p>所有状态流转规则由 {@link OrderStateMachine} 集中管理，
 * 禁止在业务代码中用魔法数字表示状态。
 *
 * @author CamBook
 */
public enum OrderStatus {

    PENDING_PAYMENT(0, "待支付"),
    PENDING_ACCEPT (1, "待接单"),
    ACCEPTED       (2, "已接单"),
    ARRIVING       (3, "前往中"),
    ARRIVED        (4, "已到达"),
    IN_SERVICE     (5, "服务中"),
    COMPLETED      (6, "已完成"),
    CANCELLED      (7, "已取消"),
    REFUNDING      (8, "退款中"),
    REFUNDED       (9, "已退款");

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
