package com.cambook.common.enums;

/**
 * 系统支持的语言枚举（6种）
 *
 * @author CamBook
 */
public enum LanguageEnum {

    ZH("zh",  "中文"),
    EN("en",  "English"),
    VI("vi",  "Tiếng Việt"),
    KM("km",  "ភាសាខ្មែរ"),
    JA("ja",  "日本語"),
    KO("ko",  "한국어");

    private final String code;
    private final String displayName;

    LanguageEnum(String code, String displayName) {
        this.code        = code;
        this.displayName = displayName;
    }

    public String getCode()        { return code; }
    public String getDisplayName() { return displayName; }

    public static LanguageEnum ofCode(String code) {
        if (code == null) return ZH;
        for (LanguageEnum lang : values()) {
            if (lang.code.equalsIgnoreCase(code)) return lang;
        }
        return ZH;
    }
}
