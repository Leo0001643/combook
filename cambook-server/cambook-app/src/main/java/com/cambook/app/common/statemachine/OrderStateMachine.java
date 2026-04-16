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
 * 合法状态流转图：
 * PENDING_PAYMENT → PENDING_ACCEPT (支付成功)
 * PENDING_PAYMENT → CANCELLED      (支付超时取消)
 * PENDING_ACCEPT  → ACCEPTED       (技师接单)
 * PENDING_ACCEPT  → REJECTED       (技师拒绝)
 * PENDING_ACCEPT  → CANCELLED      (用户取消待接单订单)
 * ACCEPTED        → IN_SERVICE     (技师开始服务)
 * ACCEPTED        → CANCELLED      (用户取消已接单订单，需扣除违约金)
 * IN_SERVICE      → COMPLETED      (服务结束)
 * COMPLETED       → REFUNDED       (申请退款成功)
 * REJECTED        → REFUNDED       (拒单自动退款)
 * </pre>
 *
 * @author CamBook
 */
@Component
public class OrderStateMachine {

    private static final Map<OrderStatus, Set<OrderStatus>> TRANSITIONS;

    static {
        TRANSITIONS = new EnumMap<>(OrderStatus.class);
        TRANSITIONS.put(OrderStatus.PENDING_PAYMENT,
                EnumSet.of(OrderStatus.PENDING_ACCEPT, OrderStatus.CANCELLED));
        TRANSITIONS.put(OrderStatus.PENDING_ACCEPT,
                EnumSet.of(OrderStatus.ACCEPTED, OrderStatus.REJECTED, OrderStatus.CANCELLED));
        TRANSITIONS.put(OrderStatus.ACCEPTED,
                EnumSet.of(OrderStatus.IN_SERVICE, OrderStatus.CANCELLED));
        TRANSITIONS.put(OrderStatus.IN_SERVICE,
                EnumSet.of(OrderStatus.COMPLETED));
        TRANSITIONS.put(OrderStatus.COMPLETED,
                EnumSet.of(OrderStatus.REFUNDED));
        TRANSITIONS.put(OrderStatus.REJECTED,
                EnumSet.of(OrderStatus.REFUNDED));
        // CANCELLED / REFUNDED 是终态，无后续转换
    }

    /**
     * 检查并执行状态转换
     *
     * @param currentCode 当前状态码
     * @param targetCode  目标状态码
     * @throws BusinessException 非法转换
     */
    public void transit(int currentCode, int targetCode) {
        OrderStatus current = OrderStatus.of(currentCode)
                .orElseThrow(() -> new BusinessException(CbCodeEnum.ORDER_STATUS_ILLEGAL));
        OrderStatus target  = OrderStatus.of(targetCode)
                .orElseThrow(() -> new BusinessException(CbCodeEnum.ORDER_STATUS_ILLEGAL));

        Set<OrderStatus> allowed = TRANSITIONS.getOrDefault(current, EnumSet.noneOf(OrderStatus.class));
        if (!allowed.contains(target)) {
            throw new BusinessException(CbCodeEnum.ORDER_STATUS_ILLEGAL);
        }
    }

    /** 检查状态转换是否合法（不抛异常版本，供判断分支使用） */
    public boolean canTransit(int currentCode, int targetCode) {
        return OrderStatus.of(currentCode)
                .map(cur -> {
                    Set<OrderStatus> allowed = TRANSITIONS.getOrDefault(cur, EnumSet.noneOf(OrderStatus.class));
                    return OrderStatus.of(targetCode).map(allowed::contains).orElse(false);
                })
                .orElse(false);
    }
}
