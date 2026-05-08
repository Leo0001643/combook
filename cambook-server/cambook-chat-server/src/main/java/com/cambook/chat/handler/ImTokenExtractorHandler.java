package com.cambook.chat.handler;

import io.netty.channel.ChannelHandler;
import io.netty.channel.ChannelHandlerContext;
import io.netty.channel.ChannelInboundHandlerAdapter;
import io.netty.handler.codec.http.FullHttpRequest;
import io.netty.handler.codec.http.QueryStringDecoder;
import io.netty.util.AttributeKey;
import lombok.extern.slf4j.Slf4j;

import java.util.List;

/**
 * Netty pipeline 第一个 handler，在 HTTP Upgrade 阶段提取 URL 中的 {@code ?token=} 参数，
 * 存入 Channel Attribute，供后续 {@link ImWsHandler} 在握手完成时自动鉴权使用。
 *
 * <p>设计目标：让客户端可以像 {@code /ws/tech} 一样通过 URL Query Param 传递 JWT，
 * 无需在 WebSocket 建立后额外发送 AUTH 数据帧。
 *
 * <p>Pipeline 顺序：HttpServerCodec → HttpObjectAggregator → <b>ImTokenExtractorHandler</b>
 *              → ChunkedWriteHandler → IdleStateHandler → WebSocketServerProtocolHandler → ImWsHandler
 */
@Slf4j
@ChannelHandler.Sharable
public class ImTokenExtractorHandler extends ChannelInboundHandlerAdapter {

    /** Channel Attribute key — 存储从 URL 提取的原始 JWT 字符串 */
    public static final AttributeKey<String> ATTR_URL_TOKEN = AttributeKey.valueOf("im_url_token");

    @Override
    public void channelRead(ChannelHandlerContext ctx, Object msg) throws Exception {
        if (msg instanceof FullHttpRequest req) {
            String uri = req.uri();
            QueryStringDecoder decoder = new QueryStringDecoder(uri);
            List<String> tokens = decoder.parameters().get("token");
            if (tokens != null && !tokens.isEmpty()) {
                String token = tokens.get(0);
                ctx.channel().attr(ATTR_URL_TOKEN).set(token);
                log.info("[TokenExtractor] ✓ URL 提取 token channelId={} uri={} tokenLen={}",
                    ctx.channel().id(), uri, token.length());
            } else {
                log.warn("[TokenExtractor] ✗ URL 未携带 token channelId={} uri={}",
                    ctx.channel().id(), uri);
            }
        }
        super.channelRead(ctx, msg);
    }
}
