package com.cambook.common.utils;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Component;

import java.time.Duration;
import java.util.concurrent.TimeUnit;

/**
 * Redis 分布式锁工具
 *
 * <p>基于 SET NX EX 实现轻量级分布式锁，适用于重复提交拦截、并发扣款等场景。
 * 高并发下推荐配合 Redisson（Redlock）使用；当前实现满足单 Redis 节点的强一致场景。
 *
 * <p>使用示例：
 * <pre>{@code
 * String lockKey = "order:create:" + memberId;
 * if (!lockUtils.tryLock(lockKey, 10)) {
 *     throw new BusinessException(CbCodeEnum.REPEAT_SUBMIT);
 * }
 * try {
 *     // 业务逻辑
 * } finally {
 *     lockUtils.unlock(lockKey);
 * }
 * }</pre>
 *
 * @author CamBook
 */
@Component
public class RedisLockUtils {

    private static final Logger log = LoggerFactory.getLogger(RedisLockUtils.class);

    private final StringRedisTemplate redisTemplate;

    public RedisLockUtils(StringRedisTemplate redisTemplate) {
        this.redisTemplate = redisTemplate;
    }

    /**
     * 尝试获取锁（非阻塞）
     *
     * @param key        锁键，建议格式：业务前缀:唯一标识（如 order:pay:userId）
     * @param expireSeconds 锁过期时间（秒），防止死锁
     * @return {@code true} 获取成功；{@code false} 锁被他人持有
     */
    public boolean tryLock(String key, long expireSeconds) {
        Boolean ok = redisTemplate.opsForValue()
                .setIfAbsent(key, "1", Duration.ofSeconds(expireSeconds));
        return Boolean.TRUE.equals(ok);
    }

    /**
     * 带重试的获取锁
     *
     * @param key          锁键
     * @param expireSeconds 锁过期时间
     * @param retryTimes   最大重试次数
     * @param retryInterval 每次重试间隔（毫秒）
     */
    public boolean tryLockWithRetry(String key, long expireSeconds,
                                    int retryTimes, long retryInterval) {
        for (int i = 0; i <= retryTimes; i++) {
            if (tryLock(key, expireSeconds)) return true;
            if (i < retryTimes) {
                try {
                    TimeUnit.MILLISECONDS.sleep(retryInterval);
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                    return false;
                }
            }
        }
        return false;
    }

    /**
     * 释放锁
     *
     * @param key 锁键
     */
    public void unlock(String key) {
        try {
            redisTemplate.delete(key);
        } catch (Exception e) {
            log.error("[RedisLock] 释放锁失败 key={}", key, e);
        }
    }

    /**
     * 续期（防止业务执行时间超过锁过期时间）
     */
    public boolean renew(String key, long expireSeconds) {
        return Boolean.TRUE.equals(
                redisTemplate.expire(key, Duration.ofSeconds(expireSeconds))
        );
    }
}
