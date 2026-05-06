package com.cambook.app.common.statemachine;

import com.cambook.common.enums.CbCodeEnum;
import com.cambook.common.exception.BusinessException;
import org.springframework.stereotype.Component;

import java.util.EnumMap;
import java.util.EnumSet;
import java.util.Map;
import java.util.Set;

/**
 * 订单状态机（State Pattern）
 *
 * <p>设计原则：
 * <ul>
 *   <li>所有合法状态转换集中在此类，业务代码通过 {@link #transit} 统一触发</li>
 *   <li>新增状态只需在 {@link OrderStatus} 和 {@code TRANSITIONS} 中扩展，
 *       不修改调用方（开闭原则）</li>
 *   <li>非法转换立即抛出 {@link BusinessException}，杜绝脏数据</li>
 * </ul>
 *
 * <pre>
 * 合法状态流转图（状态码见 OrderStatus）：
 *
 *   PENDING_PAYMENT(0) ──支付──► PENDING_ACCEPT(1)
 *   PENDING_PAYMENT(0) ──超时──► CANCELLED(7)
 *
 *   PENDING_ACCEPT(1)  ──接单──► ACCEPTED(2)
 *   PENDING_ACCEPT(1)  ──取消──► CANCELLED(7)
 *
 *   ACCEPTED(2)        ──出发──► ARRIVING(3)
 *   ACCEPTED(2)        ──取消──► CANCELLED(7)
 *
 *   ARRIVING(3)        ──到达──► ARRIVED(4)
 *
 *   ARRIVED(4)         ──开始──► IN_SERVICE(5)
 *   ARRIVED(4)         ──取消──► CANCELLED(7)   （技师到达后客户临时取消，需扣违约金）
 *
 *   IN_SERVICE(5)      ──完成──► COMPLETED(6)
 *
 *   COMPLETED(6)       ──退款──► REFUNDING(8)
 *
 *   REFUNDING(8)       ──完成──► REFUNDED(9)
 *
 *   CANCELLED(7) / REFUNDED(9) 为终态，无后续转换
 * </pre>
 *
 * @author CamBook
 */
@Component
public class OrderStateMachine {

    private static final Map<OrderStatus, Set<OrderStatus>> TRANSITIONS;

    static {
        TRANSITIONS = new EnumMap<>(OrderStatus.class);
        TRANSITIONS.put(OrderStatus.PENDING_PAYMENT, EnumSet.of(OrderStatus.PENDING_ACCEPT, OrderStatus.CANCELLED));
        TRANSITIONS.put(OrderStatus.PENDING_ACCEPT, EnumSet.of(OrderStatus.ACCEPTED, OrderStatus.CANCELLED));
        TRANSITIONS.put(OrderStatus.ACCEPTED, EnumSet.of(OrderStatus.ARRIVING, OrderStatus.CANCELLED));
        TRANSITIONS.put(OrderStatus.ARRIVING, EnumSet.of(OrderStatus.ARRIVED));
        TRANSITIONS.put(OrderStatus.ARRIVED, EnumSet.of(OrderStatus.IN_SERVICE, OrderStatus.CANCELLED));
        TRANSITIONS.put(OrderStatus.IN_SERVICE, EnumSet.of(OrderStatus.COMPLETED));
        TRANSITIONS.put(OrderStatus.COMPLETED, EnumSet.of(OrderStatus.REFUNDING));
        TRANSITIONS.put(OrderStatus.REFUNDING, EnumSet.of(OrderStatus.REFUNDED));
        // CANCELLED(7) / REFUNDED(9) 为终态，无后续转换
    }

    /**
     * 检查并执行状态转换（合法则通过，非法则抛出业务异常）
     *
     * @param currentCode 当前状态码
     * @param targetCode  目标状态码
     * @throws BusinessException 非法转换
     */
    public void transit(int currentCode, int targetCode) {
        OrderStatus current = OrderStatus.of(currentCode).orElseThrow(() -> new BusinessException(CbCodeEnum.ORDER_STATUS_ILLEGAL));
        OrderStatus target  = OrderStatus.of(targetCode).orElseThrow(() -> new BusinessException(CbCodeEnum.ORDER_STATUS_ILLEGAL));
        Set<OrderStatus> allowed = TRANSITIONS.getOrDefault(current, EnumSet.noneOf(OrderStatus.class));
        if (!allowed.contains(target)) {
            throw new BusinessException(CbCodeEnum.ORDER_STATUS_ILLEGAL);
        }
    }

    /** 检查状态转换是否合法（不抛异常版，供条件分支使用） */
    public boolean canTransit(int currentCode, int targetCode) {
        return OrderStatus.of(currentCode)
                .map(cur -> {
                    Set<OrderStatus> allowed = TRANSITIONS.getOrDefault(cur, EnumSet.noneOf(OrderStatus.class));
                    return OrderStatus.of(targetCode).map(allowed::contains).orElse(false);
                })
                .orElse(false);
    }
}
