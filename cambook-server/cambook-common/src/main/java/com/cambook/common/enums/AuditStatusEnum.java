package com.cambook.common.enums;
import com.cambook.common.exception.BusinessException;

public enum AuditStatusEnum {

    PENDING((byte) 0),
    PASS((byte) 1),
    REJECT((byte) 2);

    private final byte code;

    AuditStatusEnum(byte code) {
        this.code = code;
    }

    public byte getCode()   { return code; }
    public byte byteCode()  { return code; }

    public static AuditStatusEnum from(Byte code) {
        if (code == null) return PENDING;
        for (AuditStatusEnum s : values()) {
            if (s.code == code) return s;
        }
        return PENDING;
    }

    public void check() {
        switch (this) {
            case PASS -> { }
            case REJECT -> throw new BusinessException(CbCodeEnum.TECHNICIAN_AUDIT_REJECTED);
            case PENDING -> throw new BusinessException(CbCodeEnum.TECHNICIAN_AUDIT_PENDING);
        }
    }
}