package com.cambook.app.service.admin.impl;

import com.cambook.app.domain.vo.OnlineUserVO;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.util.ArrayList;
import java.util.List;
import java.util.Set;

/**
 * 在线用户 Session 管理（Redis KV 存储）
 *
 * <p>Key 格式：{@code cb:online:admin:{sessionId}}
 * TTL = JWT 有效期（默认 7 天）
 */
@Service
public class OnlineSessionService {

    private static final Logger log = LoggerFactory.getLogger(OnlineSessionService.class);
    private static final String KEY_PREFIX = "cb:online:admin:";

    private final StringRedisTemplate redis;
    private final ObjectMapper        objectMapper;

    public OnlineSessionService(StringRedisTemplate redis, ObjectMapper objectMapper) {
        this.redis        = redis;
        this.objectMapper = objectMapper;
    }

    /** 登录时写入 Session */
    public void saveSession(OnlineUserVO vo, long ttlSeconds) {
        try {
            String key  = KEY_PREFIX + vo.getSessionId();
            String json = objectMapper.writeValueAsString(vo);
            redis.opsForValue().set(key, json, Duration.ofSeconds(ttlSeconds));
        } catch (JsonProcessingException e) {
            log.error("[OnlineSession] save failed: {}", e.getMessage());
        }
    }

    /** 更新最后访问时间 */
    public void touchSession(String sessionId) {
        String key = KEY_PREFIX + sessionId;
        String json = redis.opsForValue().get(key);
        if (json == null) return;
        try {
            OnlineUserVO vo = objectMapper.readValue(json, OnlineUserVO.class);
            vo.setLastAccessTime(System.currentTimeMillis());
            redis.opsForValue().set(key, objectMapper.writeValueAsString(vo),
                    Duration.ofSeconds(getRemainTtl(key)));
        } catch (JsonProcessingException e) {
            log.warn("[OnlineSession] touch failed: {}", e.getMessage());
        }
    }

    /** 强退：删除 Session */
    public void removeSession(String sessionId) {
        redis.delete(KEY_PREFIX + sessionId);
    }

    /** 列出所有在线用户 */
    public List<OnlineUserVO> listAll() {
        Set<String> keys = redis.keys(KEY_PREFIX + "*");
        List<OnlineUserVO> result = new ArrayList<>();
        if (keys == null) return result;
        for (String key : keys) {
            String json = redis.opsForValue().get(key);
            if (json == null) continue;
            try {
                OnlineUserVO vo = objectMapper.readValue(json, OnlineUserVO.class);
                long remain = getRemainTtl(key);
                vo.setStatus(remain > 0 ? "online" : "timeout");
                result.add(vo);
            } catch (JsonProcessingException e) {
                log.warn("[OnlineSession] parse failed: {}", e.getMessage());
            }
        }
        result.sort((a, b) -> Long.compare(
                b.getLastAccessTime() == null ? 0 : b.getLastAccessTime(),
                a.getLastAccessTime() == null ? 0 : a.getLastAccessTime()
        ));
        return result;
    }

    private long getRemainTtl(String key) {
        Long ttl = redis.getExpire(key);
        return ttl == null ? 0 : ttl;
    }
}
