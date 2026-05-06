package com.cambook.app.common.statemachine;

import lombok.Getter;

import java.util.Arrays;
import java.util.Optional;

/**
 * 门店散客接待（cb_walkin_session.status）状态枚举
 *
 * <p>状态码与数据库 {@code cb_walkin_session.status} 字段完全对齐：
 * <pre>
 *   0  已录入/待接单   CHECKED_IN    （会员到店，等待技师接单）
 *   1  服务中          IN_SERVICE    （技师已接单并开始服务）
 *   2  服务完成待结算  SERVICE_DONE  （技师完成服务，等待前台收款结算）
 *   3  已结算          SETTLED       （前台收款完成，形成收款闭环）
 *   4  已取消          CANCELLED
 * </pre>
 *
 * <p>收款闭环说明：
 * <ul>
 *   <li>技师端 APP "完成服务" → {@link #SERVICE_DONE}（技师工作结束）</li>
 *   <li>商户端前台收款后     → {@link #SETTLED}（收入正式计入今日收入）</li>
 * </ul>
 *
 * <p>关联 cb_order.status 使用 {@link OrderStatus} 枚举，状态码完全复用在线订单语义：
 * ACCEPTED(2)=待服务, IN_SERVICE(5)=服务中, COMPLETED(6)=已完成, CANCELLED(7)=已取消。
 *
 * @author CamBook
 */
@Getter
public enum WalkinSessionStatus {

    CHECKED_IN  (0, "已录入/待接单"),
    IN_SERVICE  (1, "服务中"),
    SERVICE_DONE(2, "服务完成/待结算"),
    SETTLED     (3, "已结算"),
    CANCELLED   (4, "已取消");

    private final int    code;
    private final String desc;

    WalkinSessionStatus(int code, String desc) {
        this.code = code;
        this.desc = desc;
    }

    /** 终态：不允许再变更 */
    public boolean isTerminal() {
        return this == SETTLED || this == CANCELLED;
    }

    public static Optional<WalkinSessionStatus> of(int code) {
        return Arrays.stream(values()).filter(s -> s.code == code).findFirst();
    }
}
