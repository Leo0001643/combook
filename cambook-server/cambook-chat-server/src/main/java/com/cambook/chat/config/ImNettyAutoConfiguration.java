package com.cambook.chat.config;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.boot.autoconfigure.condition.ConditionalOnMissingBean;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.context.annotation.Configuration;

/**
 * cambook-chat-server Spring Boot 自动配置（通过 AutoConfiguration.imports 加载）
 */
@Configuration
@EnableConfigurationProperties(ImProperties.class)
@ComponentScan(basePackages = "com.cambook.chat")
public class ImNettyAutoConfiguration {

    @Bean
    @ConditionalOnMissingBean
    public ObjectMapper chatObjectMapper() {
        return new ObjectMapper();
    }
}
