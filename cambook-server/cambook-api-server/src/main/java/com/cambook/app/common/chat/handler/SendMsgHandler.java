package com.cambook.app.common.chat.handler;

import com.cambook.app.domain.dto.chat.ImSendDTO;
import com.cambook.app.service.chat.IImMessageService;
import com.cambook.chat.protocol.ImCmd;
import com.cambook.chat.protocol.ImPacket;
import io.netty.channel.ChannelHandlerContext;
import io.netty.handler.codec.http.websocketx.TextWebSocketFrame;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.Map;
import java.util.Set;

/**
 * 单聊消息发送处理器
 */
@Component
@RequiredArgsConstructor
public class SendMsgHandler implements ImPacketHandler {

    private final IImMessageService msgService;

    @Override
    public Set<Integer> cmds() { return Set.of(ImCmd.SEND_MSG); }

    @Override
    public void handle(ChannelHandlerContext ctx, String senderType, Long senderId, ImPacket packet) {
        Long msgId = msgService.sendMessage(senderType, senderId, packet.bodyAs(ImSendDTO.class));
        ctx.writeAndFlush(new TextWebSocketFrame(
            ImPacket.of(ImCmd.MSG_DELIVERED, String.valueOf(msgId), Map.of("msgId", msgId)).toJson()));
    }
}
