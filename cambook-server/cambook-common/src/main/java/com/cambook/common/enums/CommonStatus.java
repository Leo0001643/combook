package com.cambook.common.enums;

import lombok.Getter;

/**
 * 通用实体启用/禁用状态枚举
 *
 * <p>适用于所有业务实体（商户、员工、货币、职位、权限等）的 {@code status} 字段：
 * <pre>
 *   0  禁用 / 封禁   DISABLED
 *   1  启用 / 正常   ENABLED
 * </pre>
 *
 * @author CamBook
 */
@Getter
public enum CommonStatus {

    DISABLED(0, "禁用"),
    ENABLED (1, "启用");

    private final int    code;
    private final String desc;

    CommonStatus(int code, String desc) {
        this.code = code;
        this.desc = desc;
    }

    /** Returns the code as {@code byte} for entity fields typed {@code Byte}. */
    public byte byteCode() { return (byte) code; }

    public boolean isDisabled() { return this == DISABLED; }
    public boolean isEnabled()  { return this == ENABLED;  }
}
