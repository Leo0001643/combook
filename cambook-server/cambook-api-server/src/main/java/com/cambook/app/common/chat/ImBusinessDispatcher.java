package com.cambook.app.common.chat;

import com.cambook.app.common.chat.handler.ImPacketHandler;
import com.cambook.app.domain.vo.chat.ImMessageVO;
import com.cambook.app.service.chat.IImMessageService;
import com.cambook.chat.config.ImProperties;
import com.cambook.chat.protocol.ImCmd;
import com.cambook.chat.protocol.ImPacket;
import com.cambook.chat.spi.ImDispatcher;
import io.netty.channel.ChannelHandlerContext;
import io.netty.handler.codec.http.websocketx.TextWebSocketFrame;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * IM 业务分发器（连接 Netty 网关层与 Spring 业务层）
 *
 * <p><b>开闭原则（OCP）</b>：新增命令类型只需添加一个实现了 {@link ImPacketHandler} 的
 * Spring Bean，无需修改此类。所有 Handler 在容器启动时自动注册。
 */
@Slf4j
@Component
public class ImBusinessDispatcher implements ImDispatcher {

    private final Map<Integer, ImPacketHandler> handlerMap;
    private final IImMessageService             msgService;
    private final ImProperties                  props;

    public ImBusinessDispatcher(List<ImPacketHandler> handlers, IImMessageService msgService, ImProperties props) {
        this.handlerMap = handlers.stream()
            .flatMap(h -> h.cmds().stream().map(cmd -> Map.entry(cmd, h)))
            .collect(Collectors.toMap(Map.Entry::getKey, Map.Entry::getValue, (a, b) -> a));
        this.msgService = msgService;
        this.props      = props;
        log.info("[Dispatcher] 已注册 {} 个命令处理器，覆盖 cmd: {}", handlers.size(), handlerMap.keySet());
    }

    // ── 上线/下线 ──────────────────────────────────────────────────────────────

    @Override
    public void onUserOnline(ChannelHandlerContext ctx, String userType, Long userId) {
        List<ImMessageVO> offline = msgService.pullOffline(userType, userId, 0L, props.getOfflinePullLimit());
        if (!offline.isEmpty()) {
            ctx.writeAndFlush(new TextWebSocketFrame(
                ImPacket.of(ImCmd.OFFLINE_MSGS, Map.of("msgs", offline, "count", offline.size())).toJson()));
            log.info("[Dispatcher] 推送离线消息 {}:{} count={}", userType, userId, offline.size());
        }
    }

    @Override
    public void onUserOffline(String userType, Long userId) {
        log.info("[Dispatcher] 用户下线 {}:{}", userType, userId);
    }

    // ── 消息路由（核心分发逻辑）──────────────────────────────────────────────

    @Override
    public void onMessage(ChannelHandlerContext ctx, String sender, ImPacket packet) {
        String[] parts      = sender.split(":", 2);
        String   senderType = parts[0];
        Long     senderId   = Long.parseLong(parts[1]);

        ImPacketHandler handler = handlerMap.get(packet.getCmd());
        if (handler == null) {
            log.warn("[Dispatcher] 未知 cmd={} sender={}", packet.getCmd(), sender);
            return;
        }
        try {
            handler.handle(ctx, senderType, senderId, packet);
        } catch (Exception e) {
            log.error("[Dispatcher] 处理异常 cmd={} sender={}: {}", packet.getCmd(), sender, e.getMessage(), e);
            ctx.writeAndFlush(new TextWebSocketFrame(ImPacket.error(e.getMessage()).toJson()));
        }
    }
}
