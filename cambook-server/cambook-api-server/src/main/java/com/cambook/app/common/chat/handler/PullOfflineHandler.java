package com.cambook.app.common.chat.handler;

import com.cambook.app.domain.vo.chat.ImMessageVO;
import com.cambook.app.service.chat.IImMessageService;
import com.cambook.chat.config.ImProperties;
import com.cambook.chat.protocol.ImCmd;
import com.cambook.chat.protocol.ImPacket;
import io.netty.channel.ChannelHandlerContext;
import io.netty.handler.codec.http.websocketx.TextWebSocketFrame;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * 拉取离线消息处理器
 */
@Component
@RequiredArgsConstructor
public class PullOfflineHandler implements ImPacketHandler {

    private final IImMessageService msgService;
    private final ImProperties      props;

    @Override
    public Set<Integer> cmds() { return Set.of(ImCmd.PULL_OFFLINE); }

    @Override
    @SuppressWarnings("unchecked")
    public void handle(ChannelHandlerContext ctx, String senderType, Long senderId, ImPacket packet) {
        long lastMsgId = packet.getBody() instanceof Map<?, ?> m && m.get("lastMsgId") instanceof Number n
            ? n.longValue() : 0L;
        List<ImMessageVO> msgs = msgService.pullOffline(senderType, senderId, lastMsgId, props.getOfflinePullLimit());
        ctx.writeAndFlush(new TextWebSocketFrame(
            ImPacket.of(ImCmd.OFFLINE_MSGS, Map.of("msgs", msgs, "count", msgs.size())).toJson()));
    }
}
