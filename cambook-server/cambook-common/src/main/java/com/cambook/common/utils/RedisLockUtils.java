package com.cambook.common.utils;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.data.redis.core.script.DefaultRedisScript;
import org.springframework.stereotype.Component;

import java.time.Duration;
import java.util.Collections;
import java.util.UUID;
import java.util.concurrent.TimeUnit;

/**
 * Redis 分布式锁工具
 *
 * <p><b>锁类型说明：</b>
 * <ul>
 *   <li><b>简单锁</b>（{@link #tryLock} / {@link #unlock}）：适用于单次短事务防重提交，
 *       业务执行时间远小于锁超时时间，到期前必然释放，无锁超时释放风险。</li>
 *   <li><b>持有者锁</b>（{@link #tryLockOwned} / {@link #unlockOwned}）：持有者 token 写入锁值，
 *       释放时通过 Lua 脚本原子比较，只有持有者才能释放，杜绝误删他人锁。
 *       适用于扣款、幂等写等对锁安全性要求高的场景。</li>
 * </ul>
 *
 * <p>高并发集群场景推荐使用 Redisson（RedLock），本工具类适合单 Redis 节点部署。
 *
 * <p>使用示例（持有者锁）：
 * <pre>{@code
 * String token = lockUtils.tryLockOwned("order:pay:" + orderId, 30);
 * if (token == null) throw new BusinessException(CbCodeEnum.REPEAT_SUBMIT);
 * try {
 *     // 业务逻辑
 * } finally {
 *     lockUtils.unlockOwned("order:pay:" + orderId, token);
 * }
 * }</pre>
 *
 * @author CamBook
 */
@Component
public class RedisLockUtils {

    private static final Logger log = LoggerFactory.getLogger(RedisLockUtils.class);

    /** Lua：仅当值匹配时才删除，保证原子性，防止误删他人锁 */
    private static final DefaultRedisScript<Long> UNLOCK_SCRIPT = new DefaultRedisScript<>(
            "if redis.call('get', KEYS[1]) == ARGV[1] then " +
            "  return redis.call('del', KEYS[1]) " +
            "else " +
            "  return 0 " +
            "end",
            Long.class
    );

    private final StringRedisTemplate redisTemplate;

    public RedisLockUtils(StringRedisTemplate redisTemplate) {
        this.redisTemplate = redisTemplate;
    }

    // ── 简单锁（适合防重提交等短事务场景） ────────────────────────────────────

    /**
     * 尝试获取简单锁（非阻塞）
     *
     * @param key           锁键，建议格式：业务前缀:唯一标识（如 order:create:userId）
     * @param expireSeconds 锁过期时间（秒），防止死锁
     * @return {@code true} 获取成功；{@code false} 锁被占用
     */
    public boolean tryLock(String key, long expireSeconds) {
        Boolean ok = redisTemplate.opsForValue()
                .setIfAbsent(key, "1", Duration.ofSeconds(expireSeconds));
        return Boolean.TRUE.equals(ok);
    }

    /**
     * 释放简单锁
     *
     * <p>注意：不校验持有者，仅适用于业务执行时间远小于锁超时的场景。
     * 如需安全释放，请使用 {@link #unlockOwned}。
     */
    public void unlock(String key) {
        try {
            redisTemplate.delete(key);
        } catch (Exception e) {
            log.error("[RedisLock] 释放锁失败 key={}", key, e);
        }
    }

    // ── 持有者锁（安全释放，防误删） ──────────────────────────────────────────

    /**
     * 尝试获取持有者锁
     *
     * @param key           锁键
     * @param expireSeconds 锁过期时间（秒）
     * @return 持有者 token（成功时，需保存用于释放）；{@code null} 表示锁被占用
     */
    public String tryLockOwned(String key, long expireSeconds) {
        String token = UUID.randomUUID().toString();
        Boolean ok = redisTemplate.opsForValue()
                .setIfAbsent(key, token, Duration.ofSeconds(expireSeconds));
        return Boolean.TRUE.equals(ok) ? token : null;
    }

    /**
     * 释放持有者锁（Lua 原子比较删除）
     *
     * <p>只有 token 匹配时才释放，彻底杜绝误删他人锁。
     *
     * @param key   锁键
     * @param token {@link #tryLockOwned} 返回的持有者 token
     * @return {@code true} 释放成功；{@code false} token 不匹配（锁已被他人持有或已过期）
     */
    public boolean unlockOwned(String key, String token) {
        try {
            Long result = redisTemplate.execute(UNLOCK_SCRIPT,
                    Collections.singletonList(key), token);
            return Long.valueOf(1L).equals(result);
        } catch (Exception e) {
            log.error("[RedisLock] 释放持有者锁异常 key={}", key, e);
            return false;
        }
    }

    // ── 重试 & 续期 ───────────────────────────────────────────────────────────

    /**
     * 带重试的获取持有者锁
     *
     * @param key           锁键
     * @param expireSeconds 锁过期时间（秒）
     * @param retryTimes    最大重试次数
     * @param retryIntervalMs 每次重试间隔（毫秒）
     * @return 持有者 token；{@code null} 表示所有重试均失败
     */
    public String tryLockOwnedWithRetry(String key, long expireSeconds,
                                        int retryTimes, long retryIntervalMs) {
        for (int i = 0; i <= retryTimes; i++) {
            String token = tryLockOwned(key, expireSeconds);
            if (token != null) return token;
            if (i < retryTimes) {
                try {
                    TimeUnit.MILLISECONDS.sleep(retryIntervalMs);
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                    return null;
                }
            }
        }
        return null;
    }

    /**
     * 续期（防止业务执行时间超过锁过期时间，配合持有者锁使用）
     *
     * @param key           锁键
     * @param expireSeconds 新的过期时间（秒）
     * @return {@code true} 续期成功（key 仍存在）；{@code false} key 已过期
     */
    public boolean renew(String key, long expireSeconds) {
        return Boolean.TRUE.equals(redisTemplate.expire(key, Duration.ofSeconds(expireSeconds)));
    }
}
