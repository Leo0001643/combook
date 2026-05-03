package com.cambook.app.common.event;

import com.cambook.app.common.statemachine.OrderStatus;
import com.cambook.app.websocket.TechWsHandler;
import com.cambook.app.websocket.TechWsRegistry;
import com.cambook.app.websocket.WsMessage;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.event.EventListener;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Component;

import java.util.Map;

/**
 * 订单事件监听器
 *
 * <p>所有副作用（消息推送、余额变更、技师状态重置）均在此处异步处理，
 * 与核心业务完全解耦（观察者模式）。
 * 新增通知渠道只需在此追加方法，不影响订单服务（开闭原则）。
 *
 * @author CamBook
 */
@Component
public class OrderEventListener {

    private static final Logger log = LoggerFactory.getLogger(OrderEventListener.class);

    private final TechWsRegistry registry;
    private final TechWsHandler  wsHandler;

    public OrderEventListener(TechWsRegistry registry, TechWsHandler wsHandler) {
        this.registry  = registry;
        this.wsHandler = wsHandler;
    }

    /**
     * 异步处理订单状态变更通知
     *
     * <p>使用 {@code @Async} 避免阻塞主事务，需在启动类上添加 {@code @EnableAsync}。
     */
    @Async
    @EventListener
    public void onOrderStatusChanged(OrderStatusChangedEvent event) {
        log.info("[Order Event] orderId={} {} → {}",
                event.getOrderId(), event.getFromStatus(), event.getToStatus());

        int to = event.getToStatus();

        if (to == OrderStatus.PENDING_ACCEPT.getCode()) {
            // 订单支付成功 → 推送"派单中"通知给用户，广播给附近技师
            pushToMember(event.getMemberId(), "订单已支付，正在为您匹配技师");
            broadcastToNearbyTechnicians(event.getOrderId(), event.getTechnicianId());
        } else if (to == OrderStatus.ACCEPTED.getCode()) {
            // 技师接单 → 通知用户技师已接单
            pushToMember(event.getMemberId(), "技师已接单，正在赶来中");
        } else if (to == OrderStatus.IN_SERVICE.getCode()) {
            // 开始服务 → 通知用户服务开始
            pushToMember(event.getMemberId(), "技师已到达，服务开始");
        } else if (to == OrderStatus.COMPLETED.getCode()) {
            // 服务完成 → 通知用户评价，结算技师收益
            pushToMember(event.getMemberId(), "服务已完成，请对本次服务进行评价");
            settleTechnicianEarnings(event.getTechnicianId(), event.getOrderId());
        } else if (to == OrderStatus.CANCELLED.getCode()) {
            // 订单取消 → 根据规则决定是否退款
            log.info("[Order Event] 订单取消，触发退款检查 orderId={}", event.getOrderId());
        } else if (to == OrderStatus.REFUNDED.getCode()) {
            // 退款成功 → 通知用户
            pushToMember(event.getMemberId(), "退款已处理，请注意查收");
        }
    }

    // ── 私有方法（实际接入推送 SDK / 微信 / FCM 等） ─────────────────────────

    private void pushToMember(Long memberId, String content) {
        // TODO: 接入推送服务（FCM / APNs / 极光推送）
        log.info("[Push → Member] memberId={} msg={}", memberId, content);
    }

    private void broadcastToNearbyTechnicians(Long orderId, Long technicianId) {
        log.info("[Broadcast] 新订单 WS 推送 orderId={} techId={} 在线人数={}",
                orderId, technicianId, registry.size());
        Map<String, Object> payload = Map.of("orderId", orderId);

        if (technicianId != null) {
            // 已指定技师：精准推送
            log.info("[Broadcast] 精准推送 orderId={} → techId={}", orderId, technicianId);
            registry.sendTo(technicianId, WsMessage.newOrder(payload));
            wsHandler.pushHomeData(technicianId);
        } else {
            // 未指定技师（散客 / 管理员创建）：广播给所有在线技师
            var onlineIds = registry.onlineTechIds();
            if (onlineIds.isEmpty()) {
                log.warn("[Broadcast] 当前无在线技师，orderId={} 无法推送 NEW_ORDER", orderId);
                return;
            }
            for (Long onlineTechId : onlineIds) {
                log.info("[Broadcast] 广播新订单 orderId={} → techId={}", orderId, onlineTechId);
                registry.sendTo(onlineTechId, WsMessage.newOrder(payload));
                wsHandler.pushHomeData(onlineTechId);
            }
        }
    }

    private void settleTechnicianEarnings(Long technicianId, Long orderId) {
        // TODO: 异步结算技师服务收益到钱包
        log.info("[Settle] 技师结算 technicianId={} orderId={}", technicianId, orderId);
    }
}
