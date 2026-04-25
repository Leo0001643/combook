package com.cambook.app.websocket;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.util.Collection;

/**
 * 定时推送调度器 —— 每 5 秒向所有在线技师推送最新首页数据。
 *
 * <p>轮询频率固定 5 秒，采用 fixedDelay 避免任务堆积。
 * 实际推送在各技师的线程内独立完成，不互相阻塞。
 * 日志统一写入 cambook-schedule.log（SCHEDULE 命名 logger）。
 */
@Component
public class TechWsPushScheduler {

    /** 定时任务专用命名 logger，对应 logback-spring.xml 中的 SCHEDULE appender */
    private static final Logger log = LoggerFactory.getLogger("SCHEDULE");

    private final TechWsRegistry registry;
    private final TechWsHandler  handler;

    public TechWsPushScheduler(TechWsRegistry registry, TechWsHandler handler) {
        this.registry = registry;
        this.handler  = handler;
    }

    @Scheduled(fixedDelay = 5000)
    public void pushAll() {
        Collection<Long> techIds = registry.onlineTechIds();
        if (techIds.isEmpty()) return;
        log.debug("[WsPush] 推送 {} 位在线技师", techIds.size());
        techIds.forEach(techId -> {
            try {
                handler.pushHomeData(techId);
            } catch (Exception e) {
                log.warn("[WsPush] techId={} 推送异常: {}", techId, e.getMessage());
            }
        });
    }
}
