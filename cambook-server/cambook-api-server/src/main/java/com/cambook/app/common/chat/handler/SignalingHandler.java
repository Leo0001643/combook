package com.cambook.app.common.chat.handler;

import com.cambook.chat.protocol.ImCmd;
import com.cambook.chat.protocol.ImPacket;
import com.cambook.chat.routing.UserRouter;
import io.netty.channel.ChannelHandlerContext;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.util.Map;
import java.util.Set;

/**
 * WebRTC 信令透传处理器
 *
 * <p>IM 服务不参与通话业务，仅负责将信令包转发至目标用户的 Netty 节点。
 * 新增信令命令只需在 {@link ImCmd#SIGNALING_CMDS} 中注册，此处理器自动生效（开闭原则）。
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class SignalingHandler implements ImPacketHandler {

    private final UserRouter router;

    @Override
    public Set<Integer> cmds() { return ImCmd.SIGNALING_CMDS; }

    @Override
    @SuppressWarnings("unchecked")
    public void handle(ChannelHandlerContext ctx, String senderType, Long senderId, ImPacket packet) {
        if (!(packet.getBody() instanceof Map<?, ?> body)) return;
        String targetType = (String) body.get("targetType");
        Long   targetId   = body.get("targetId") instanceof Number n ? n.longValue() : null;
        if (targetType == null || targetId == null) return;

        boolean sent = router.route(targetType, targetId, ImPacket.of(packet.getCmd(), packet.getMsgId(), body));
        log.info("[Signaling] cmd={} {}:{} -> {}:{} sent={}", packet.getCmd(),
            senderType, senderId, targetType, targetId, sent);
    }
}
