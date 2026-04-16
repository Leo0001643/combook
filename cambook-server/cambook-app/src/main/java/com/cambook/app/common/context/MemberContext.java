package com.cambook.app.common.context;

/**
 * App 端用户请求上下文（ThreadLocal 持有）
 *
 * <p>由 {@link com.cambook.app.common.filter.AuthFilter} 在解析 Token 后设置，
 * 请求结束时必须调用 {@link #clear()} 防止内存泄漏。
 *
 * @author CamBook
 */
public final class MemberContext {

    private static final ThreadLocal<MemberInfo> HOLDER = new ThreadLocal<>();

    private MemberContext() {}

    public static void set(MemberInfo info) { HOLDER.set(info); }
    public static MemberInfo get()          { return HOLDER.get(); }
    public static void clear()              { HOLDER.remove(); }

    public static Long getMemberId() {
        MemberInfo info = HOLDER.get();
        return info != null ? info.memberId : null;
    }

    /** 获取当前登录用户 ID（getMemberId 的语义别名，兼容旧代码） */
    public static Long currentId() {
        return getMemberId();
    }

    public static String getUserType() {
        MemberInfo info = HOLDER.get();
        return info != null ? info.userType : null;
    }

    public static String getLang() {
        MemberInfo info = HOLDER.get();
        return info != null ? info.lang : null;
    }

    // ── inner class ───────────────────────────────────────────────────────────

    public static final class MemberInfo {

        private Long memberId;
        /** 用户类型：member / technician / merchant */
        private String userType;
        private String lang;

        public Long getMemberId()   { return memberId; }
        public String getUserType() { return userType; }
        public String getLang()     { return lang; }

        public void setMemberId(Long memberId)   { this.memberId = memberId; }
        public void setUserType(String userType) { this.userType = userType; }
        public void setLang(String lang)         { this.lang = lang; }
    }
}
