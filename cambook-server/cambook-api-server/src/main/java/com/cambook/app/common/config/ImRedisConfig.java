package com.cambook.app.common.config;

import com.cambook.chat.config.ImProperties;
import com.cambook.common.utils.SnowflakeGenerator;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.boot.autoconfigure.condition.ConditionalOnMissingBean;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.redis.connection.RedisConnectionFactory;
import org.springframework.data.redis.listener.RedisMessageListenerContainer;
import org.springframework.scheduling.annotation.EnableScheduling;

/**
 * IM 基础设施配置
 *
 * <p>职责：
 * <ul>
 *   <li>注册 Redis Pub/Sub 容器，用于跨节点消息转发</li>
 *   <li>注册全局唯一 SnowflakeGenerator Bean（由 ImProperties 提供节点参数）</li>
 *   <li>开启定时任务（ACK 重试调度器）</li>
 * </ul>
 */
@Configuration
@EnableScheduling
public class ImRedisConfig {

    @Bean
    public RedisMessageListenerContainer redisMessageListenerContainer(RedisConnectionFactory factory) {
        RedisMessageListenerContainer container = new RedisMessageListenerContainer();
        container.setConnectionFactory(factory);
        return container;
    }

    /** 全局唯一雪花 ID 生成器（线程安全，节点参数来自配置） */
    @Bean
    public SnowflakeGenerator snowflakeGenerator(ImProperties props) {
        return new SnowflakeGenerator(props.getDatacenterId(), props.getMachineId());
    }

    @Bean
    @ConditionalOnMissingBean
    public ObjectMapper objectMapper() {
        return new ObjectMapper();
    }
}
