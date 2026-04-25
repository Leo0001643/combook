package com.cambook.app.websocket;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;

import java.util.Collection;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * WebSocket 会话注册中心（线程安全）。
 *
 * <p>维护当前所有在线技师的 WebSocket 会话，支持按 techId 精准推送。
 * 使用 {@link ConcurrentHashMap} 保证并发安全，不引入额外锁开销。
 */
@Component
public class TechWsRegistry {

    private static final Logger log = LoggerFactory.getLogger(TechWsRegistry.class);

    /** techId → WebSocketSession（一个技师只保留最新连接） */
    private final Map<Long, WebSocketSession> sessions = new ConcurrentHashMap<>();

    private final ObjectMapper objectMapper;

    public TechWsRegistry(ObjectMapper objectMapper) {
        this.objectMapper = objectMapper;
    }

    /**
     * 注册新连接。若同一技师已有旧连接，先关闭旧连接再注册新连接。
     *
     * <p>使用 ConcurrentHashMap 的 {@code compute} 保证 put + close 原子执行，
     * 避免"put 之后旧会话 close 触发 unregister 又移除了新会话"的竞态。
     */
    public void register(Long techId, WebSocketSession session) {
        sessions.compute(techId, (k, old) -> {
            if (old != null && old.isOpen()) {
                try { old.close(); } catch (Exception ignored) {}
            }
            return session;
        });
        log.info("[WsRegistry] 注册: techId={}, 在线人数={}", techId, sessions.size());
    }

    /**
     * 注销连接。仅当 registry 中存储的 session 与传入 session 相同时才移除，
     * 防止新连接建立后被旧连接关闭事件错误移除。
     */
    public void unregister(Long techId, WebSocketSession session) {
        boolean removed = sessions.remove(techId, session);
        if (removed) {
            log.info("[WsRegistry] 注销: techId={}, 在线人数={}", techId, sessions.size());
        }
    }

    /** 向指定技师推送消息（序列化为 JSON）。 */
    public void sendTo(Long techId, Object payload) {
        WebSocketSession session = sessions.get(techId);
        if (session == null || !session.isOpen()) return;
        try {
            String json = objectMapper.writeValueAsString(payload);
            synchronized (session) {
                session.sendMessage(new TextMessage(json));
            }
        } catch (Exception e) {
            log.warn("[WsRegistry] 推送失败 techId={}: {}", techId, e.getMessage());
        }
    }

    /** 获取所有在线 techId（用于定时全量推送）。 */
    public Collection<Long> onlineTechIds() {
        return sessions.keySet();
    }

    public int size() { return sessions.size(); }
}
