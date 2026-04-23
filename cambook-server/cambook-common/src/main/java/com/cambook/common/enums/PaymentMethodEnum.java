package com.cambook.common.enums;

import java.util.Optional;

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

    /**
     * 按支付码查找，不存在时返回 {@link Optional#empty()}，调用方自行处理缺失逻辑。
     */
    public static Optional<PaymentMethodEnum> ofCode(int code) {
        for (PaymentMethodEnum m : values()) {
            if (m.code == code) return Optional.of(m);
        }
        return Optional.empty();
    }

    /**
     * 按支付码查找，不存在时抛出 {@link IllegalArgumentException}。
     * 用于支付方式已被校验合法但仍找不到时（属于系统数据不一致，应快速失败）。
     */
    public static PaymentMethodEnum ofCodeRequired(int code) {
        return ofCode(code).orElseThrow(
                () -> new IllegalArgumentException("不支持的支付方式 code: " + code));
    }
}
