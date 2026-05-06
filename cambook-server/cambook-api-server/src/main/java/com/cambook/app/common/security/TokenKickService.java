package com.cambook.app.common.security;

import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;

import java.time.Duration;

/**
 * Token 强制失效服务（按用户维度）
 *
 * <p>设计策略：不做全量 Token 黑名单（避免 Redis 存储 N 个 Token），
 * 而是为每个用户记录一个「踢出时间戳」。
 * {@link com.cambook.app.common.filter.AuthFilter} 在每次请求时比对：
 * <pre>
 *   token.issuedAt  <= kickTimestamp  →  拒绝（TOKEN_INVALID）
 *   token.issuedAt  >  kickTimestamp  →  放行
 * </pre>
 *
 * <p>好处：
 * <ul>
 *   <li>单次写 Redis 即可踢出该用户所有设备上所有旧 Token</li>
 *   <li>踢出后新登录颁发的 Token（issuedAt 更新）自动生效，无需额外处理</li>
 *   <li>Key TTL 与 JWT 有效期一致，自动过期无需手动清理</li>
 * </ul>
 *
 * @author CamBook
 */
@Service
public class TokenKickService {

    /** Key 格式：cb:auth:kick:{userType}:{uid}，值为 Unix 秒时间戳 */
    private static final String KEY_PREFIX = "cb:auth:kick:";

    /** Key TTL 与 JWT 最大有效期保持一致（7 天），过后自动清理 */
    private static final Duration TTL = Duration.ofDays(7);

    private final StringRedisTemplate redis;

    public TokenKickService(StringRedisTemplate redis) {
        this.redis = redis;
    }

    /**
     * 踢出指定用户（使其所有在当前时间之前签发的 Token 立即失效）。
     *
     * @param userType 用户类型：technician / member / merchant / admin
     * @param uid      用户主键 ID
     */
    public void kick(String userType, Long uid) {
        redis.opsForValue().set(key(userType, uid), String.valueOf(System.currentTimeMillis() / 1000), TTL);
    }

    /**
     * 查询踢出时间戳（Unix 秒），不存在时返回 0（表示未被踢出）。
     *
     * @param userType 用户类型
     * @param uid      用户主键 ID
     * @return 踢出时间戳（Unix 秒），0 表示从未被踢出
     */
    public long getKickTimestamp(String userType, Long uid) {
        String val = redis.opsForValue().get(key(userType, uid));
        if (val == null) return 0L;
        try {
            return Long.parseLong(val);
        } catch (NumberFormatException e) {
            return 0L;
        }
    }

    /**
     * 清除踢出记录（用户主动重新登录后可调用，减少 Redis 查询）。
     * 可选调用，不调用也无副作用（旧 key 会自然过期）。
     */
    public void clearKick(String userType, Long uid) {
        redis.delete(key(userType, uid));
    }

    private String key(String userType, Long uid) {
        return KEY_PREFIX + userType + ":" + uid;
    }
}
