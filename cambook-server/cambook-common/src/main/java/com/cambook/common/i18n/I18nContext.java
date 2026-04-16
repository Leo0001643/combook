package com.cambook.common.i18n;

import org.apache.commons.lang3.StringUtils;

/**
 * 国际化语言上下文（基于 ThreadLocal）
 *
 * <p>在 JwtAuthenticationFilter / I18nFilter 中读取 Accept-Language 请求头，
 * 调用 {@link #setLang(String)} 设置当前线程语言，响应结束后调用 {@link #clear()}。
 *
 * <p>支持语言码：zh / en / vi / km / ja / ko，不在列表内降级为 zh。
 *
 * @author CamBook
 */
public final class I18nContext {

    private static final ThreadLocal<String> LANG_HOLDER = new ThreadLocal<>();

    /** 支持的语言列表 */
    private static final java.util.Set<String> SUPPORTED_LANGS =
            java.util.Set.of("zh", "en", "vi", "km", "ja", "ko");

    private I18nContext() {}

    /**
     * 设置当前线程语言，非法语言码自动降级为 zh
     */
    public static void setLang(String lang) {
        if (StringUtils.isBlank(lang)) {
            LANG_HOLDER.set("zh");
            return;
        }
        // Accept-Language 可能是 zh-CN，取主语言标签
        String primary = lang.split("[,;_-]")[0].toLowerCase().trim();
        LANG_HOLDER.set(SUPPORTED_LANGS.contains(primary) ? primary : "zh");
    }

    /**
     * 获取当前线程语言，默认 zh
     */
    public static String getLang() {
        String lang = LANG_HOLDER.get();
        return lang != null ? lang : "zh";
    }

    /**
     * 请求结束后清理，防止内存泄漏
     */
    public static void clear() {
        LANG_HOLDER.remove();
    }
}
