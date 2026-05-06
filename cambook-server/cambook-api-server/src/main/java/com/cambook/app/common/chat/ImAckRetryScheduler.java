package com.cambook.app.common.chat;

import com.cambook.app.service.chat.IImMessageService;
import com.cambook.chat.config.ImProperties;
import com.cambook.chat.protocol.ImCmd;
import com.cambook.chat.protocol.ImPacket;
import com.cambook.chat.routing.UserRouter;
import com.cambook.common.utils.DateUtils;
import com.cambook.db.entity.ImMessage;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Map;

/**
 * ACK 超时重试调度器
 *
 * <p>每 30 秒扫描 status=1（已落库但未 ACK）的单聊消息，
 * 超过 {@code cambook.im.ack-timeout-seconds} 则重推；
 * 超过 {@code cambook.im.ack-max-retry} 次后标记为失败（status=9）。
 *
 * <p>批次大小由 {@code cambook.im.ack-retry-batch-size} 控制，防止扫表过载。
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class ImAckRetryScheduler {

    private final IImMessageService msgService;
    private final UserRouter        router;
    private final ImProperties      props;

    @Scheduled(fixedDelay = 30_000)
    public void retryUnacked() {
        long deadline = DateUtils.nowSecond() - props.getAckTimeoutSeconds();

        List<ImMessage> pending = msgService.lambdaQuery()
            .eq(ImMessage::getStatus, 1)
            .eq(ImMessage::getIsGroup, 0)
            .lt(ImMessage::getUpdateTime, deadline)
            .lt(ImMessage::getRetryCount, props.getAckMaxRetry())
            .last("LIMIT " + props.getAckRetryBatchSize())
            .list();

        if (pending.isEmpty()) return;
        log.info("[ACK-Retry] 批次扫描 {} 条未 ACK 单聊消息", pending.size());

        for (ImMessage msg : pending) {
            if (msg.getReceiverType() == null || msg.getReceiverId() == null) continue;
            long now = DateUtils.nowSecond();
            byte retry = (byte) (msg.getRetryCount() + 1);
            boolean pushed = router.route(msg.getReceiverType(), msg.getReceiverId(),
                retryPacket(msg, retry));
            byte status = pushed ? (byte) 2
                : retry >= props.getAckMaxRetry() ? (byte) 9 : (byte) 1;

            msgService.lambdaUpdate()
                .eq(ImMessage::getMsgId, msg.getMsgId())
                .set(ImMessage::getStatus, status)
                .set(ImMessage::getRetryCount, retry)
                .set(ImMessage::getUpdateTime, now).update();

            if (status == 9) log.warn("[ACK-Retry] 消息 {} 重试耗尽，标记失败", msg.getMsgId());
        }
    }

    private ImPacket retryPacket(ImMessage msg, byte retryCount) {
        return ImPacket.of(ImCmd.MSG_NOTIFY, String.valueOf(msg.getMsgId()), Map.of(
            "msgId", msg.getMsgId(), "conversationId", msg.getConversationId(),
            "senderType", msg.getSenderType(), "senderId", msg.getSenderId(),
            "msgType", msg.getMsgType(), "content", msg.getContent(),
            "createTime", msg.getCreateTime(), "retry", retryCount));
    }
}
