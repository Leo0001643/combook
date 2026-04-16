package com.cambook.common.enums;

/**
 * 支付方式枚举
 *
 * @author CamBook
 */
public enum PaymentMethodEnum {

    USDT(1,    "USDT"),
    ABA(2,     "ABA 网银"),
    WALLET(3,  "余额支付"),
    WECHAT(4,  "微信支付"),
    ALIPAY(5,  "支付宝"),
    CASH(6,    "线下现金");

    private final int code;
    private final String displayName;

    PaymentMethodEnum(int code, String displayName) {
        this.code        = code;
        this.displayName = displayName;
    }

    public int getCode()           { return code; }
    public String getDisplayName() { return displayName; }

    public static PaymentMethodEnum ofCode(int code) {
        for (PaymentMethodEnum m : values()) {
            if (m.code == code) return m;
        }
        return null;
    }
}
