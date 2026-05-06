package com.cambook.app.common.config;

import com.baomidou.mybatisplus.extension.plugins.MybatisPlusInterceptor;
import com.baomidou.mybatisplus.extension.plugins.inner.OptimisticLockerInnerInterceptor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * MyBatis-Plus 全局配置
 * <p>
 * 注：mybatis-plus 3.5.10+ 已移除 PaginationInnerInterceptor，
 * 分页功能由 spring-boot-autoconfigure 自动装配，无需手动注册。
 *
 * @author CamBook
 */
@Configuration
public class MybatisPlusConfig {

    /**
     * 乐观锁插件：update 时自动填充 @Version 字段，防止并发覆盖
     */
    @Bean
    public MybatisPlusInterceptor mybatisPlusInterceptor() {
        MybatisPlusInterceptor interceptor = new MybatisPlusInterceptor();
        interceptor.addInnerInterceptor(new OptimisticLockerInnerInterceptor());
        return interceptor;
    }
}
