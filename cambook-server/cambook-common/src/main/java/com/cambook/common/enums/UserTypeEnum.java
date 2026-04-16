package com.cambook.common.enums;

/**
 * 用户类型枚举
 *
 * @author CamBook
 */
public enum UserTypeEnum {

    MEMBER("member",         "会员"),
    TECHNICIAN("technician", "技师"),
    MERCHANT("merchant",     "商户"),
    ADMIN("admin",           "管理员");

    private final String code;
    private final String displayName;

    UserTypeEnum(String code, String displayName) {
        this.code        = code;
        this.displayName = displayName;
    }

    public String getCode()        { return code; }
    public String getDisplayName() { return displayName; }

    public static UserTypeEnum ofCode(String code) {
        if (code == null) return null;
        for (UserTypeEnum t : values()) {
            if (t.code.equals(code)) return t;
        }
        return null;
    }
}
