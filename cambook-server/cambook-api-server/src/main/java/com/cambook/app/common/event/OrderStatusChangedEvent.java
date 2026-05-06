package com.cambook.app.common.event;
import lombok.Getter;
import lombok.Setter;
import org.springframework.context.ApplicationEvent;

/**
 * 订单状态变更事件（观察者模式）
 *
 * <p>状态机完成状态转换后发布此事件，解耦业务通知逻辑。
 * 监听方通过 {@code @EventListener} 异步处理推送、钱包扣款等副作用。
 *
 * @author CamBook
 */
@Getter
@Setter
public class OrderStatusChangedEvent extends ApplicationEvent {
    private final Long   orderId;
    private final Long   memberId;
    private final Long   technicianId;
    private final int    fromStatus;
    private final int    toStatus;

    public OrderStatusChangedEvent(Object source, Long orderId, Long memberId, Long technicianId, int fromStatus, int toStatus) {
        super(source);
        this.orderId      = orderId;
        this.memberId     = memberId;
        this.technicianId = technicianId;
        this.fromStatus   = fromStatus;
        this.toStatus     = toStatus;
    }
}
