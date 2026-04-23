package com.cambook.common.context;

import lombok.Data;

/**
 * 商户请求上下文（ThreadLocal 持有）
 *
 * <p>由 {@link com.cambook.app.common.filter.AuthFilter} 在解析商户 Token 后设置，
 * 请求结束时必须调用 {@link #clear()} 防止内存泄漏。
 *
 * @author CamBook
 */
public final class MerchantContext {

    private static final ThreadLocal<MerchantInfo> HOLDER = new ThreadLocal<>();

    private MerchantContext() {}

    public static void set(MerchantInfo info) { HOLDER.set(info); }
    public static MerchantInfo get()          { return HOLDER.get(); }
    public static void clear()                { HOLDER.remove(); }

    public static Long getMerchantId() {
        MerchantInfo info = HOLDER.get();
        return info != null ? info.merchantId : null;
    }

    public static String getMerchantName() {
        MerchantInfo info = HOLDER.get();
        return info != null ? info.merchantName : null;
    }

    public static String getMobile() {
        MerchantInfo info = HOLDER.get();
        return info != null ? info.mobile : null;
    }

    /**
     * 员工 ID（员工账号登录时非空；商户主账号登录时为 null）
     */
    public static Long getStaffId() {
        MerchantInfo info = HOLDER.get();
        return info != null ? info.staffId : null;
    }

    /** 是否为员工账号（非商户主）登录 */
    public static boolean isStaff() {
        MerchantInfo info = HOLDER.get();
        return info != null && info.staffId != null;
    }

    public static boolean isMerchant() {
        return HOLDER.get() != null;
    }

    // ── inner VO ─────────────────────────────────────────────────────────────

    @Data
    public static final class MerchantInfo {
        private Long   merchantId;
        private String merchantName;
        private String mobile;
        /** 员工 ID；商户主登录时为 null */
        private Long   staffId;
    }
}
