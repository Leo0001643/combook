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
import io.netty.handler.codec.http.websocketx.WebSocketServerProtocolHandler;
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
        // Fallback: if HandshakeComplete was missed but URL token is present, auto-auth now
        if (ctx.channel().attr(ATTR_USER).get() == null) {
            String urlToken = ctx.channel().attr(ImTokenExtractorHandler.ATTR_URL_TOKEN).get();
            if (urlToken != null && !urlToken.isBlank()) {
                log.info("[WsHandler] 首帧触发 URL token 鉴权 channelId={}", ctx.channel().id());
                handleAuthToken(ctx, urlToken);
            }
        }

        String text = frame.text().trim();
        if (text.isEmpty()) return;

        ImPacket packet = ImPacket.fromJson(text);
        if (packet == null) {
            log.warn("[WsHandler] 无法解析的报文 channelId={} text={}", ctx.channel().id(), text);
            write(ctx, ImPacket.error("invalid packet"));
            return;
        }

        log.info("[WsHandler] ◀ cmd={} channelId={} user={}",
            packet.getCmd(), ctx.channel().id(), ctx.channel().attr(ATTR_USER).get());

        switch (packet.getCmd()) {
            case ImCmd.PING -> handlePing(ctx);
            case ImCmd.AUTH -> handleAuth(ctx, packet);
            default         -> handleBusiness(ctx, packet);
        }
    }

    // ── 连接打开 / 握手完成 / 心跳超时 ────────────────────────────────────────

    @Override
    public void channelActive(ChannelHandlerContext ctx) throws Exception {
        log.info("[WsHandler] ✓ TCP 连接建立 channelId={} remote={}",
            ctx.channel().id(), ctx.channel().remoteAddress());
        super.channelActive(ctx);
    }

    @Override
    public void userEventTriggered(ChannelHandlerContext ctx, Object evt) throws Exception {
        // Log every user-event so we can diagnose missing HandshakeComplete in production
        log.info("[WsHandler] userEvent={} channelId={}",
            evt.getClass().getSimpleName(), ctx.channel().id());
        if (evt instanceof WebSocketServerProtocolHandler.HandshakeComplete handshake) {
            String urlToken = ctx.channel().attr(ImTokenExtractorHandler.ATTR_URL_TOKEN).get();
            log.info("[WsHandler] ✓ WebSocket 握手完成 channelId={} reqUri={} urlTokenPresent={}",
                ctx.channel().id(), handshake.requestUri(),
                urlToken != null && !urlToken.isBlank());
            if (urlToken != null && !urlToken.isBlank()) {
                handleAuthToken(ctx, urlToken);
            } else {
                log.warn("[WsHandler] 握手完成但 URL 未携带 token，等待 AUTH 帧 channelId={}",
                    ctx.channel().id());
            }
        } else if (evt instanceof IdleStateEvent idle && idle.state() == IdleState.READER_IDLE) {
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
        log.info("[WsHandler] ✗ 连接关闭 channelId={} user={}", ctx.channel().id(), user);
        if (user == null) return;
        String[] p = user.split(":", 2);
        String userType = p[0];
        Long   userId   = Long.parseLong(p[1]);
        registry.unregister(userType, userId, ctx.channel());
        router.offline(userType, userId);
        dispatcher.onUserOffline(userType, userId);
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
        handleAuthToken(ctx, token);
    }

    /**
     * 统一鉴权逻辑（供 AUTH 数据帧和 URL token 自动鉴权共用）。
     *
     * <p>JWT claim 兼容两种 key：
     * <ul>
     *   <li>{@code "uid"} — 技师/会员 JWT（TechnicianAuthServiceImpl 使用）</li>
     *   <li>{@code "userId"} — 预留兼容其他来源</li>
     * </ul>
     */
    private void handleAuthToken(ChannelHandlerContext ctx, String token) {
        // 已鉴权则跳过（握手完成事件可能重复触发）
        if (ctx.channel().attr(ATTR_USER).get() != null) return;

        Claims claims = jwtUtils.parseToken(token);
        if (claims == null) {
            write(ctx, ImPacket.error("invalid token")); ctx.close(); return;
        }

        String userType = claims.get("userType", String.class);
        // 兼容 "uid"（技师/会员 JWT）和 "userId"（其他来源）
        Object rawUid = claims.get("uid");
        if (rawUid == null) rawUid = claims.get("userId");
        Long userId = rawUid instanceof Number n ? n.longValue() : null;

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
