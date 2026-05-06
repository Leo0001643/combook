package com.cambook.chat.routing;

import com.cambook.chat.config.ImProperties;
import com.cambook.chat.protocol.ImPacket;
import com.cambook.chat.registry.ChannelRegistry;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Component;

import java.util.Map;
import java.util.concurrent.TimeUnit;

/**
 * 用户连接路由（本节点直推 / 跨节点 Redis Pub/Sub）
 *
 * <p>Redis Key 设计：
 * <ul>
 *   <li>{@code im:online:{userType}:{userId}} → nodeId（TTL 1h，心跳续期）</li>
 *   <li>{@code im:pubsub:{nodeId}} → Pub/Sub 频道名</li>
 * </ul>
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class UserRouter {

    private static final String KEY_ONLINE  = "im:online:%s:%d";
    private static final String KEY_PUBSUB  = "im:pubsub:%s";
    private static final int    ONLINE_TTL  = 3600;

    private final StringRedisTemplate redis;
    private final ImProperties        props;
    private final ChannelRegistry     registry;
    private final ObjectMapper        mapper;

    // ── 在线状态管理 ──────────────────────────────────────────────────────────

    public void online(String userType, Long userId) {
        redis.opsForValue().set(onlineKey(userType, userId), props.getNodeId(), ONLINE_TTL, TimeUnit.SECONDS);
    }

    public void refresh(String userType, Long userId) {
        redis.expire(onlineKey(userType, userId), ONLINE_TTL, TimeUnit.SECONDS);
    }

    public void offline(String userType, Long userId) {
        redis.delete(onlineKey(userType, userId));
    }

    public boolean isOnline(String userType, Long userId) {
        return Boolean.TRUE.equals(redis.hasKey(onlineKey(userType, userId)));
    }

    public String getNodeId(String userType, Long userId) {
        return redis.opsForValue().get(onlineKey(userType, userId));
    }

    // ── 消息路由投递 ──────────────────────────────────────────────────────────

    /**
     * 路由并投递消息：本节点直接推送，跨节点通过 Redis Pub/Sub 转发。
     *
     * @return true=已投递（用户在线），false=用户离线
     */
    public boolean route(String toUserType, Long toUserId, ImPacket packet) {
        String nodeId = getNodeId(toUserType, toUserId);
        if (nodeId == null) return false;

        if (props.getNodeId().equals(nodeId)) {
            return registry.send(toUserType, toUserId, packet);
        }
        try {
            String payload = mapper.writeValueAsString(
                Map.of("toUserType", toUserType, "toUserId", toUserId, "packet", packet.toJson()));
            redis.convertAndSend(pubSubChannel(nodeId), payload);
            return true;
        } catch (Exception e) {
            log.error("[Router] 跨节点路由失败 nodeId={}: {}", nodeId, e.getMessage());
            return false;
        }
    }

    // ── 静态工具方法 ──────────────────────────────────────────────────────────

    public static String onlineKey(String userType, Long userId) {
        return String.format(KEY_ONLINE, userType, userId);
    }

    public static String pubSubChannel(String nodeId) {
        return String.format(KEY_PUBSUB, nodeId);
    }
}
