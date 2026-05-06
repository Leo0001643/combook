package com.cambook.chat.handler;

import com.cambook.chat.config.ImProperties;
import com.cambook.chat.protocol.ImCmd;
import com.cambook.chat.protocol.ImPacket;
import com.cambook.chat.registry.ChannelRegistry;
import com.cambook.chat.routing.UserRouter;
import com.cambook.chat.spi.ImDispatcher;
import com.cambook.common.utils.JwtUtils;
import io.jsonwebtoken.Claims;
import io.netty.channel.ChannelHandler;
import io.netty.channel.ChannelHandlerContext;
import io.netty.channel.SimpleChannelInboundHandler;
import io.netty.handler.codec.http.websocketx.TextWebSocketFrame;
import io.netty.handler.timeout.IdleState;
import io.netty.handler.timeout.IdleStateEvent;
import io.netty.util.AttributeKey;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

/**
 * Netty WebSocket 核心 Handler（纯网络层，不含任何业务逻辑）
 *
 * <p>职责：JWT 鉴权、心跳管理、Channel 生命周期、将消息委托给 {@link ImDispatcher}。
 *
 * <p>Pipeline: HttpServerCodec → HttpObjectAggregator → ChunkedWriteHandler
 *              → IdleStateHandler(readerIdle) → WebSocketServerProtocolHandler → ImWsHandler
 */
@Slf4j
@Component
@RequiredArgsConstructor
@ChannelHandler.Sharable
public class ImWsHandler extends SimpleChannelInboundHandler<TextWebSocketFrame> {

    static final AttributeKey<String> ATTR_USER = AttributeKey.valueOf("im_user");

    private final JwtUtils        jwtUtils;
    private final ChannelRegistry registry;
    private final UserRouter      router;
    private final ImDispatcher    dispatcher;
    private final ImProperties    props;

    // ── 消息路由 ──────────────────────────────────────────────────────────────

    @Override
    protected void channelRead0(ChannelHandlerContext ctx, TextWebSocketFrame frame) {
        String text = frame.text().trim();
        if (text.isEmpty()) return;

        ImPacket packet = ImPacket.fromJson(text);
        if (packet == null) { write(ctx, ImPacket.error("invalid packet")); return; }

        switch (packet.getCmd()) {
            case ImCmd.PING -> handlePing(ctx);
            case ImCmd.AUTH -> handleAuth(ctx, packet);
            default         -> handleBusiness(ctx, packet);
        }
    }

    // ── 心跳超时（关键修复：IdleStateHandler 触发 userEventTriggered）────────

    @Override
    public void userEventTriggered(ChannelHandlerContext ctx, Object evt) throws Exception {
        if (evt instanceof IdleStateEvent idle && idle.state() == IdleState.READER_IDLE) {
            String user = ctx.channel().attr(ATTR_USER).get();
            log.warn("[WsHandler] 心跳超时，强制断开 user={} channelId={}", user, ctx.channel().id());
            write(ctx, ImPacket.error("heartbeat timeout"));
            ctx.close();
        } else {
            super.userEventTriggered(ctx, evt);
        }
    }

    // ── 连接生命周期 ──────────────────────────────────────────────────────────

    @Override
    public void channelInactive(ChannelHandlerContext ctx) {
        String user = ctx.channel().attr(ATTR_USER).get();
        if (user == null) return;
        String[] p = user.split(":", 2);
        String userType = p[0];
        Long   userId   = Long.parseLong(p[1]);
        registry.unregister(userType, userId, ctx.channel());
        router.offline(userType, userId);
        dispatcher.onUserOffline(userType, userId);
        log.info("[WsHandler] 断开下线 user={}", user);
    }

    @Override
    public void exceptionCaught(ChannelHandlerContext ctx, Throwable cause) {
        log.warn("[WsHandler] 异常 channelId={}: {}", ctx.channel().id(), cause.getMessage());
        ctx.close();
    }

    // ── 处理方法 ──────────────────────────────────────────────────────────────

    private void handlePing(ChannelHandlerContext ctx) {
        String user = ctx.channel().attr(ATTR_USER).get();
        if (user != null) {
            String[] p = user.split(":", 2);
            router.refresh(p[0], Long.parseLong(p[1]));
        }
        write(ctx, ImPacket.pong());
    }

    private void handleBusiness(ChannelHandlerContext ctx, ImPacket packet) {
        if (ctx.channel().attr(ATTR_USER).get() == null) {
            write(ctx, ImPacket.error("not authenticated"));
            ctx.close();
            return;
        }
        dispatcher.onMessage(ctx, ctx.channel().attr(ATTR_USER).get(), packet);
    }

    private void handleAuth(ChannelHandlerContext ctx, ImPacket packet) {
        String token = packet.getBody() instanceof String s ? s : null;
        if (token == null || token.isBlank()) {
            write(ctx, ImPacket.error("token required")); ctx.close(); return;
        }

        Claims claims = jwtUtils.parseToken(token);
        if (claims == null) {
            write(ctx, ImPacket.error("invalid token")); ctx.close(); return;
        }

        String userType = claims.get("userType", String.class);
        Long   userId   = claims.get("userId", Long.class);
        if (userType == null || userId == null) {
            write(ctx, ImPacket.error("bad token payload")); ctx.close(); return;
        }

        registry.register(userType, userId, ctx.channel());
        router.online(userType, userId);
        ctx.channel().attr(ATTR_USER).set(ChannelRegistry.key(userType, userId));
        write(ctx, ImPacket.authOk(userId, userType));

        log.info("[WsHandler] 鉴权成功 {}:{} channelId={}", userType, userId, ctx.channel().id());
        dispatcher.onUserOnline(ctx, userType, userId);
    }

    private static void write(ChannelHandlerContext ctx, ImPacket packet) {
        ctx.writeAndFlush(new TextWebSocketFrame(packet.toJson()));
    }
}
