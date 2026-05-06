package com.cambook.app.websocket;

import com.cambook.app.domain.vo.HomeStatsVO;
import com.cambook.app.domain.vo.ScheduleItemVO;
import com.cambook.app.service.technician.ITechHomeService;
import com.cambook.common.context.MemberContext;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.CloseStatus;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;
import org.springframework.web.socket.handler.TextWebSocketHandler;

import java.util.List;
import java.util.Map;

/**
 * 技师端 WebSocket 消息处理器。
 *
 * <p>职责：
 * <ul>
 *   <li>连接建立时注册会话并立即推送一次首页数据</li>
 *   <li>收到 PING 时回复 PONG（保活）</li>
 *   <li>连接关闭时注销会话</li>
 * </ul>
 *
 * <p>定时推送由 {@link TechWsPushScheduler} 独立完成，遵循单一职责原则。
 */
@Component
public class TechWsHandler extends TextWebSocketHandler {

    private static final Logger log = LoggerFactory.getLogger(TechWsHandler.class);

    private final TechWsRegistry    registry;
    private final ITechHomeService  homeService;

    public TechWsHandler(TechWsRegistry registry, ITechHomeService homeService) {
        this.registry    = registry;
        this.homeService = homeService;
    }

    // ── 连接生命周期 ──────────────────────────────────────────────────────────

    @Override
    public void afterConnectionEstablished(WebSocketSession session) {
        Long techId = techId(session);
        if (techId == null) { closeQuietly(session); return; }
        registry.register(techId, session);
        // 连接成功立即推送一次，无需等 5 秒
        pushHomeData(techId);
    }

    @Override
    public void afterConnectionClosed(WebSocketSession session, CloseStatus status) {
        Long techId = techId(session);
        // compare-and-remove：只有在 registry 中存的还是这个 session 才移除，
        // 防止新连接建立后被旧连接的关闭事件错误清除
        if (techId != null) registry.unregister(techId, session);
        log.info("[WsHandler] 连接关闭: techId={}, status={}", techId, status);
    }

    @Override
    public void handleTransportError(WebSocketSession session, Throwable error) {
        log.warn("[WsHandler] 传输异常: techId={}, err={}", techId(session), error.getMessage());
        closeQuietly(session);
    }

    // ── 消息处理 ──────────────────────────────────────────────────────────────

    @Override
    protected void handleTextMessage(WebSocketSession session, TextMessage message) {
        String payload = message.getPayload().trim();
        Long techId = techId(session);
        if ("PING".equalsIgnoreCase(payload) && techId != null) {
            registry.sendTo(techId, WsMessage.pong());
        }
        // 可扩展更多客户端→服务端指令
    }

    // ── 内部方法 ──────────────────────────────────────────────────────────────

    /** 组装并推送首页数据（stats + schedule + pendingCount）。 */
    public void pushHomeData(Long techId) {
        try {
            MemberContext.MemberInfo info = new MemberContext.MemberInfo();
            info.setMemberId(techId);
            info.setUserType("technician");
            MemberContext.set(info);
            HomeStatsVO stats = homeService.getStats();
            List<ScheduleItemVO> schedule = homeService.getTodaySchedule();
            Long pendingCount = homeService.getPendingOrderCount();
            MemberContext.clear();

            Map<String, Object> data = Map.of(
                "stats",        stats,
                "schedule",     schedule,
                "pendingCount", pendingCount
            );
            registry.sendTo(techId, WsMessage.homeData(data));
        } catch (Exception e) {
            log.warn("[WsHandler] 推送首页数据失败 techId={}: {}", techId, e.getMessage());
            MemberContext.clear();
        }
    }

    // ── helpers ───────────────────────────────────────────────────────────────

    private Long techId(WebSocketSession session) {
        return (Long) session.getAttributes().get("techId");
    }

    private void closeQuietly(WebSocketSession session) {
        try { if (session.isOpen()) session.close(); } catch (Exception ignored) {}
    }
}
