package com.cambook.common.enums;

import com.cambook.common.i18n.I18nContext;

import java.util.Collections;
import java.util.HashMap;
import java.util.Map;

/**
 * 全局响应码枚举
 *
 * <p>设计约定：
 * <ul>
 *   <li>每个枚举常量对应 {@code sys_i18n} 表一条（6语言）记录，{@code enum_code} = 枚举名</li>
 *   <li>启动时由 {@link com.cambook.common.i18n.I18nMessageLoader} 反射注入多语言消息</li>
 *   <li>运行时通过 {@link I18nContext} 获取当前语言，自动返回对应消息</li>
 * </ul>
 *
 * @author CamBook
 */
public enum CbCodeEnum {

    // ── 通用 ──────────────────────────────────────────────────────────────────
    SUCCESS(200),
    SERVER_ERROR(500),
    PARAM_ERROR(400),
    DATA_NOT_FOUND(404),
    TOKEN_INVALID(401),
    TOKEN_EXPIRED(401),
    NO_PERMISSION(403),
    REPEAT_SUBMIT(400),

    // ── 认证 / 登录 ───────────────────────────────────────────────────────────
    SMS_CODE_EXPIRED(40001),
    SMS_CODE_WRONG(40002),
    ACCOUNT_BANNED(40003),
    ACCOUNT_NOT_FOUND(40004),

    // ── 会员 ──────────────────────────────────────────────────────────────────
    MEMBER_NOT_FOUND(40010),

    // ── 技师 ──────────────────────────────────────────────────────────────────
    TECHNICIAN_NOT_FOUND(40020),
    TECHNICIAN_ALREADY_APPLIED(40021),
    TECHNICIAN_AUDIT_PENDING(40022),
    TECHNICIAN_OFFLINE(40023),
    TECHNICIAN_BUSY(40024),

    // ── 商户 ──────────────────────────────────────────────────────────────────
    MERCHANT_NOT_FOUND(40030),
    MERCHANT_AUDIT_PENDING(40031),

    // ── 订单 ──────────────────────────────────────────────────────────────────
    ORDER_NOT_FOUND(40040),
    ORDER_STATUS_ILLEGAL(40041),
    ORDER_CANNOT_CANCEL(40042),
    ORDER_ALREADY_REVIEWED(40043),

    // ── 支付 / 钱包 ───────────────────────────────────────────────────────────
    BALANCE_INSUFFICIENT(40050),
    PAYMENT_FAILED(40051),
    WITHDRAW_MIN_AMOUNT(40052),

    // ── 优惠券 ────────────────────────────────────────────────────────────────
    COUPON_NOT_FOUND(40060),
    COUPON_EXPIRED(40061),
    COUPON_USED(40062),
    COUPON_NOT_APPLICABLE(40063),
    COUPON_STOCK_EMPTY(40064),
    ;

    private final int httpStatus;

    /**
     * 多语言消息映射，key=语言码（zh/en/vi/km/ja/ko）
     * 由 I18nMessageLoader 在应用启动后注入，初始为空
     */
    private volatile Map<String, String> messages = Collections.emptyMap();

    CbCodeEnum(int httpStatus) {
        this.httpStatus = httpStatus;
    }

    public int httpStatus() {
        return httpStatus;
    }

    /** 按当前请求语言返回消息，兜底使用枚举名 */
    public String message() {
        String lang = I18nContext.getLang();
        String msg = messages.get(lang);
        if (msg == null) msg = messages.get("zh");
        return msg != null ? msg : name();
    }

    /** 由 I18nMessageLoader 调用，线程安全写入 */
    public void setMessages(Map<String, String> messages) {
        this.messages = new HashMap<>(messages);
    }
}
