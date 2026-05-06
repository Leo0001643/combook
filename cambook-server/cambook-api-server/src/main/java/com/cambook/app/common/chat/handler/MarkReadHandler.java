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
 * 标记会话已读处理器
 */
@Component
@RequiredArgsConstructor
public class MarkReadHandler implements ImPacketHandler {

    private final IImMessageService msgService;

    @Override
    public Set<Integer> cmds() { return Set.of(ImCmd.MARK_READ); }

    @Override
    @SuppressWarnings("unchecked")
    public void handle(ChannelHandlerContext ctx, String senderType, Long senderId, ImPacket packet) {
        if (!(packet.getBody() instanceof Map<?, ?> body)) return;
        Long convId      = ((Number) body.get("conversationId")).longValue();
        Long lastReadId  = ((Number) body.get("lastReadMsgId")).longValue();
        msgService.markRead(convId, senderType, senderId, lastReadId);
    }
}
