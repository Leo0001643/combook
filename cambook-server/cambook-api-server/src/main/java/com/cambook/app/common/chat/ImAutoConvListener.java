package com.cambook.app.common.chat;

import com.cambook.app.service.chat.IImContactService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.event.EventListener;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Component;

/**
 * IM 自动建会话监听器
 *
 * <p>监听业务事件（订单创建/技师接单/运营分配），
 * 异步触发自动建立 IM 会话，使双方「不加好友即可出现聊天入口」。
 *
 * <h3>使用方式</h3>
 * <p>在订单/技师等业务 Service 中注入 {@link org.springframework.context.ApplicationEventPublisher}
 * 并发布对应事件：
 * <pre>
 *   // 技师接单时
 *   eventPublisher.publishEvent(new ImAutoConvEvent(
 *       "technician", technicianId,
 *       "member",     memberId,
 *       merchantId,   "技师 " + techName + " 已接受您的预约，现在可以直接联系"
 *   ));
 * </pre>
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class ImAutoConvListener {

    private final IImContactService contactService;

    /**
     * 处理自动建会话事件（异步，不阻塞业务主流程）。
     */
    @Async
    @EventListener
    public void onAutoConvEvent(ImAutoConvEvent event) {
        try {
            Long convId = contactService.autoCreateConversation(
                event.senderType(), event.senderId(),
                event.receiverType(), event.receiverId(),
                event.merchantId(), event.sysNote());
            log.info("[AutoConv] 事件驱动建会话 convId={} {}:{} ↔ {}:{}",
                convId, event.senderType(), event.senderId(),
                event.receiverType(), event.receiverId());
        } catch (Exception e) {
            log.warn("[AutoConv] 自动建会话失败: {}", e.getMessage());
        }
    }

    // ── 事件载体 ──────────────────────────────────────────────────────────────

    /**
     * IM 自动建会话事件。
     *
     * @param senderType   发起方用户类型
     * @param senderId     发起方 ID
     * @param receiverType 接收方用户类型
     * @param receiverId   接收方 ID
     * @param merchantId   商户 ID
     * @param sysNote      系统通知文本（可选，推送给接收方的第一条系统消息）
     */
    public record ImAutoConvEvent(
        String senderType,
        Long   senderId,
        String receiverType,
        Long   receiverId,
        Long   merchantId,
        String sysNote
    ) {}
}
