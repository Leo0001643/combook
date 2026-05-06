package com.cambook.app.common.security;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.Data;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.time.Duration;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 登录会话信息服务（Redis 存储）
 *
 * <p>登录时写入，登出/强制下线时删除。管理端列表通过批量 mGet 查询，
 * 展示技师是否在线（有活跃 Token）及最近登录设备、IP、时间。
 *
 * <p>Key 格式：{@code cb:auth:session:{userType}:{uid}}
 * TTL 与 JWT 有效期一致（7 天），过期自动清理无需手动维护。
 *
 * @author CamBook
 */
@Service
public class LoginSessionService {

    private static final Logger log = LoggerFactory.getLogger(LoginSessionService.class);

    /** Key 前缀 */
    private static final String KEY_PREFIX = "cb:auth:session:";

    /** TTL 与 JWT 最大有效期一致，Token 自然过期后 Redis 记录同步清理 */
    private static final Duration TTL = Duration.ofDays(7);

    private final StringRedisTemplate redis;
    private final ObjectMapper        objectMapper;

    public LoginSessionService(StringRedisTemplate redis, ObjectMapper objectMapper) {
        this.redis        = redis;
        this.objectMapper = objectMapper;
    }

    // ── 写 ────────────────────────────────────────────────────────────────────

    /**
     * 登录成功时记录会话信息
     *
     * @param userType  用户类型（technician / member / merchant / admin）
     * @param uid       用户主键 ID
     * @param clientIp  客户端 IP
     * @param userAgent 客户端 User-Agent（用于推断设备类型）
     */
    public void save(String userType, Long uid, String clientIp, String userAgent) {
        SessionInfo info = new SessionInfo();
        info.setLoginTime(System.currentTimeMillis() / 1000);
        info.setClientIp(clientIp != null ? clientIp : "unknown");
        info.setDevice(parseDevice(userAgent));
        info.setUserAgent(userAgent);
        try {
            redis.opsForValue().set(key(userType, uid), objectMapper.writeValueAsString(info), TTL);
        } catch (JsonProcessingException e) {
            log.warn("[Session] failed to serialize session for {}:{}", userType, uid, e);
        }
    }

    /**
     * 查询单个用户的登录会话信息，不存在则返回 {@code null}（表示未登录）
     */
    public SessionInfo get(String userType, Long uid) {
        String json = redis.opsForValue().get(key(userType, uid));
        return deserialize(json);
    }

    /**
     * 批量查询一组 uid 的登录会话（用于列表页，单次 mGet 减少 RTT）
     *
     * @param userType 用户类型
     * @param uids     用户 ID 列表
     * @return Map&lt;uid, SessionInfo&gt;，未登录的 uid 不在 Map 中
     */
    public Map<Long, SessionInfo> batchGet(String userType, List<Long> uids) {
        if (uids == null || uids.isEmpty()) return Collections.emptyMap();
        List<String> keys = uids.stream().map(uid -> key(userType, uid)).toList();
        List<String> values = redis.opsForValue().multiGet(keys);
        Map<Long, SessionInfo> result = new HashMap<>();
        if (values == null) return result;
        for (int i = 0; i < uids.size(); i++) {
            SessionInfo info = deserialize(values.get(i));
            if (info != null) result.put(uids.get(i), info);
        }
        return result;
    }

    /**
     * 登出或强制下线时移除会话记录
     */
    public void remove(String userType, Long uid) {
        redis.delete(key(userType, uid));
    }

    // ── 内部类 ─────────────────────────────────────────────────────────────────

    @Data
    public static class SessionInfo {
        /** 登录时间（Unix 秒） */
        private long   loginTime;
        /** 客户端 IP */
        private String clientIp;
        /** 设备描述（iOS / Android / Web / Unknown） */
        private String device;
        /** 原始 User-Agent（备用） */
        private String userAgent;
    }

    // ── private ───────────────────────────────────────────────────────────────

    private String key(String userType, Long uid) {
        return KEY_PREFIX + userType + ":" + uid;
    }

    private SessionInfo deserialize(String json) {
        if (json == null || json.isBlank()) return null;
        try {
            return objectMapper.readValue(json, SessionInfo.class);
        } catch (IOException e) {
            log.warn("[Session] failed to deserialize session: {}", e.getMessage());
            return null;
        }
    }

    /**
     * 从 User-Agent 中推断设备类型
     */
    private static String parseDevice(String ua) {
        if (ua == null || ua.isBlank()) return "Unknown";
        String lower = ua.toLowerCase();
        if (lower.contains("iphone") || lower.contains("ipad")) return "iOS";
        if (lower.contains("android"))                           return "Android";
        if (lower.contains("cambook-ios"))                       return "iOS";
        if (lower.contains("cambook-android"))                   return "Android";
        if (lower.contains("mozilla") || lower.contains("chrome") || lower.contains("safari")) return "Web";
        return "Unknown";
    }
}
