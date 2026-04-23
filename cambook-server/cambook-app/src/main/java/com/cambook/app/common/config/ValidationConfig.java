package com.cambook.app.common.config;

import com.cambook.common.i18n.I18nMessageInterpolator;
import org.hibernate.validator.messageinterpolation.ResourceBundleMessageInterpolator;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.validation.beanvalidation.LocalValidatorFactoryBean;

/**
 * 校验器全局配置
 *
 * <p>注册自定义 {@link I18nMessageInterpolator}，使 {@code @Valid} 注解
 * 的错误消息根据请求的 {@code Accept-Language} 动态返回对应语言文案。
 *
 * <p>消息文件位于 cambook-common 资源目录：
 * <ul>
 *   <li>{@code ValidationMessages.properties}    —— 默认（中文）</li>
 *   <li>{@code ValidationMessages_en.properties} —— 英文</li>
 *   <li>{@code ValidationMessages_vi.properties} —— 越南文</li>
 *   <li>{@code ValidationMessages_km.properties} —— 高棉文</li>
 *   <li>{@code ValidationMessages_ja.properties} —— 日文</li>
 *   <li>{@code ValidationMessages_ko.properties} —— 韩文</li>
 * </ul>
 *
 * @author CamBook
 */
@Configuration
public class ValidationConfig {

    @Bean
    public LocalValidatorFactoryBean validator() {
        LocalValidatorFactoryBean factory = new LocalValidatorFactoryBean();
        factory.setMessageInterpolator(
            new I18nMessageInterpolator(new ResourceBundleMessageInterpolator())
        );
        return factory;
    }
}
