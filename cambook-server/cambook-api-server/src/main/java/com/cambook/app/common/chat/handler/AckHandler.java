package com.cambook.app.common.chat.handler;

import com.cambook.app.service.chat.IImMessageService;
import com.cambook.chat.protocol.ImCmd;
import com.cambook.chat.protocol.ImPacket;
import io.netty.channel.ChannelHandlerContext;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.Map;
import java.util.Set;

/**
 * 消息 ACK 处理器（单聊 + 群聊）
 */
@Component
@RequiredArgsConstructor
public class AckHandler implements ImPacketHandler {

    private final IImMessageService msgService;

    @Override
    public Set<Integer> cmds() { return Set.of(ImCmd.MSG_ACK, ImCmd.GROUP_ACK); }

    @Override
    @SuppressWarnings("unchecked")
    public void handle(ChannelHandlerContext ctx, String senderType, Long senderId, ImPacket packet) {
        Long msgId = packet.getMsgId() != null
            ? Long.parseLong(packet.getMsgId())
            : packet.getBody() instanceof Map<?, ?> m && m.get("msgId") instanceof Number n
              ? n.longValue() : null;
        if (msgId != null) msgService.handleAck(msgId, senderType, senderId);
    }
}
