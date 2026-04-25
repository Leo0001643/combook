package com.cambook.app.websocket;

import com.cambook.common.utils.JwtUtils;
import io.jsonwebtoken.Claims;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.server.ServerHttpRequest;
import org.springframework.http.server.ServerHttpResponse;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.WebSocketHandler;
import org.springframework.web.socket.server.HandshakeInterceptor;

import java.util.Map;

/**
 * WebSocket 握手拦截器 —— 在 HTTP Upgrade 阶段校验 JWT。
 *
 * <p>客户端通过 URL Query 参数传入 Token：
 * {@code ws://host:8080/ws/tech?token=eyJ...}
 *
 * <p>校验通过后，将 {@code techId} 和 {@code merchantId} 写入
 * {@code attributes} Map，供 {@link TechWsHandler} 使用。
 */
@Component
public class WsAuthHandshakeInterceptor implements HandshakeInterceptor {

    private static final Logger log = LoggerFactory.getLogger(WsAuthHandshakeInterceptor.class);

    private final JwtUtils jwtUtils;

    public WsAuthHandshakeInterceptor(JwtUtils jwtUtils) {
        this.jwtUtils = jwtUtils;
    }

    @Override
    public boolean beforeHandshake(ServerHttpRequest request, ServerHttpResponse response,
                                   WebSocketHandler wsHandler, Map<String, Object> attributes) {
        String query = request.getURI().getQuery();
        String token = parseToken(query);
        if (token == null) {
            log.warn("[WS] 握手被拒：缺少 token，uri={}", request.getURI());
            return false;
        }
        Claims claims = jwtUtils.parseToken(token);
        if (claims == null) {
            log.warn("[WS] 握手被拒：token 无效");
            return false;
        }
        Object uid        = claims.get("uid");
        Object merchantId = claims.get("merchantId");
        if (uid == null || merchantId == null) {
            log.warn("[WS] 握手被拒：token 缺少 uid/merchantId");
            return false;
        }
        attributes.put("techId",     toLong(uid));
        attributes.put("merchantId", toLong(merchantId));
        attributes.put("token",      token);
        log.info("[WS] 握手通过：techId={}", uid);
        return true;
    }

    @Override
    public void afterHandshake(ServerHttpRequest request, ServerHttpResponse response,
                               WebSocketHandler wsHandler, Exception exception) {}

    // ── helpers ───────────────────────────────────────────────────────────────

    private String parseToken(String query) {
        if (query == null) return null;
        for (String part : query.split("&")) {
            if (part.startsWith("token=")) return part.substring(6);
        }
        return null;
    }

    private Long toLong(Object val) {
        if (val instanceof Number n) return n.longValue();
        try { return Long.parseLong(val.toString()); } catch (Exception e) { return null; }
    }
}
