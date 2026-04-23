package com.cambook.common.i18n;

import jakarta.validation.MessageInterpolator;

import java.util.Locale;
import java.util.Map;

/**
 * 国际化校验消息插值器
 *
 * <p>包装默认的 {@link MessageInterpolator}，在每次插值时从
 * {@link I18nContext} 获取当前请求的语言，而非使用 JVM 默认 Locale，
 * 使 {@code @Valid} 注解的错误消息随请求 {@code Accept-Language} 动态变化。
 *
 * <p>注册方式（在 {@code ValidationConfig} 中）：
 * <pre>
 *   LocalValidatorFactoryBean factory = new LocalValidatorFactoryBean();
 *   factory.setMessageInterpolator(new I18nMessageInterpolator(
 *       new ResourceBundleMessageInterpolator()
 *   ));
 * </pre>
 *
 * @author CamBook
 */
public class I18nMessageInterpolator implements MessageInterpolator {

    /** 语言码 → Java Locale 映射（使用构造函数兼容 Java 11/17） */
    private static final Map<String, Locale> LOCALE_MAP = Map.of(
            "zh", Locale.SIMPLIFIED_CHINESE,
            "en", Locale.ENGLISH,
            "vi", new Locale("vi"),
            "km", new Locale("km"),
            "ja", Locale.JAPANESE,
            "ko", Locale.KOREAN
    );

    private final MessageInterpolator delegate;

    public I18nMessageInterpolator(MessageInterpolator delegate) {
        this.delegate = delegate;
    }

    @Override
    public String interpolate(String messageTemplate, Context context) {
        return delegate.interpolate(messageTemplate, context, resolveLocale());
    }

    @Override
    public String interpolate(String messageTemplate, Context context, Locale locale) {
        return delegate.interpolate(messageTemplate, context, locale);
    }

    /** 将 I18nContext 的语言码解析为 Java Locale，不在映射中则降级为中文 */
    private Locale resolveLocale() {
        return LOCALE_MAP.getOrDefault(I18nContext.getLang(), Locale.SIMPLIFIED_CHINESE);
    }
}
