package com.cambook.common.context;

import lombok.Data;

import java.util.Collections;
import java.util.Set;

/**
 * 管理员请求上下文（ThreadLocal 持有）
 *
 * <p>由 {@link com.cambook.app.common.filter.AuthFilter} 在解析 Token 后设置，
 * 请求结束时必须调用 {@link #clear()} 防止内存泄漏。
 *
 * @author CamBook
 */
public final class AdminContext {

    private static final ThreadLocal<AdminInfo> HOLDER = new ThreadLocal<>();

    private AdminContext() {}

    public static void set(AdminInfo info)   { HOLDER.set(info); }
    public static AdminInfo get()            { return HOLDER.get(); }
    public static void clear()               { HOLDER.remove(); }

    public static Long getUserId() {
        AdminInfo info = HOLDER.get();
        return info != null ? info.userId : null;
    }

    public static String getUsername() {
        AdminInfo info = HOLDER.get();
        return info != null ? info.username : null;
    }

    public static Set<String> getPermissions() {
        AdminInfo info = HOLDER.get();
        return info != null ? info.permissions : Collections.emptySet();
    }

    // ── inner VO ─────────────────────────────────────────────────────────────

    @Data
    public static final class AdminInfo {
        private Long userId;
        private String username;
        /** 权限标识集合，如 {"member:list", "order:delete"} */
        private Set<String> permissions;
    }
}
