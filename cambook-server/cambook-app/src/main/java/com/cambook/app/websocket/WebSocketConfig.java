package com.cambook.app.websocket;

import org.springframework.context.annotation.Configuration;
import org.springframework.web.socket.config.annotation.EnableWebSocket;
import org.springframework.web.socket.config.annotation.WebSocketConfigurer;
import org.springframework.web.socket.config.annotation.WebSocketHandlerRegistry;

/**
 * WebSocket 配置 —— 注册技师端实时数据推送端点。
 *
 * <p>端点：{@code ws://host:8080/ws/tech?token=<jwt>}
 *
 * <p>安全性：握手阶段由 {@link WsAuthHandshakeInterceptor} 校验 JWT，
 * 未携带有效 Token 的连接请求会被直接拒绝（HTTP 403），不会建立 WS 会话。
 */
@Configuration
@EnableWebSocket
public class WebSocketConfig implements WebSocketConfigurer {

    private final TechWsHandler              handler;
    private final WsAuthHandshakeInterceptor interceptor;

    public WebSocketConfig(TechWsHandler handler, WsAuthHandshakeInterceptor interceptor) {
        this.handler     = handler;
        this.interceptor = interceptor;
    }

    @Override
    public void registerWebSocketHandlers(WebSocketHandlerRegistry registry) {
        registry.addHandler(handler, "/ws/tech")
                .addInterceptors(interceptor)
                .setAllowedOrigins("*");  // 生产环境按需收紧
    }
}
