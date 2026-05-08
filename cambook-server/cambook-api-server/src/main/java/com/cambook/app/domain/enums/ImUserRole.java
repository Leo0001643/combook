package com.cambook.app.domain.enums;

import java.util.Arrays;
import java.util.Optional;

/**
 * IM 用户角色枚举
 *
 * <p>角色权限层次（由高到低）：
 * <pre>
 *   SUPER_ADMIN  平台超管
 *       ↓
 *   OWNER        商户户主
 *       ↓
 *   MANAGER      部门主管/经理
 *       ↓
 *   STAFF        普通员工
 *   OPERATOR     运营
 *   MARKETING    营销
 *       ↓
 *   TECHNICIAN   技师
 *   DRIVER       司机/车队
 *       ↓
 *   MEMBER       会员
 * </pre>
 *
 * <p>默认角色推断（当 {@code im_org_member} 无显式配置时）：
 * <ul>
 *   <li>user_type=admin       → SUPER_ADMIN</li>
 *   <li>user_type=merchant    → OWNER（商户主账号）</li>
 *   <li>user_type=staff       → STAFF（可由管理员升级为 MANAGER/OPERATOR/MARKETING）</li>
 *   <li>user_type=technician  → TECHNICIAN</li>
 *   <li>user_type=member      → MEMBER</li>
 * </ul>
 */
public enum ImUserRole {

    SUPER_ADMIN("平台超管"),
    OWNER      ("商户户主"),
    MANAGER    ("部门主管"),
    STAFF      ("普通员工"),
    OPERATOR   ("运营人员"),
    MARKETING  ("营销人员"),
    TECHNICIAN ("技师"),
    DRIVER     ("司机/车队"),
    MEMBER     ("会员");

    private final String label;

    ImUserRole(String label) { this.label = label; }

    public String getLabel() { return label; }

    // ── 工厂方法 ──────────────────────────────────────────────────────────────

    /** 从字符串解析，忽略大小写；找不到返回 null */
    public static ImUserRole fromCode(String code) {
        if (code == null) return null;
        return Arrays.stream(values())
            .filter(r -> r.name().equalsIgnoreCase(code))
            .findFirst()
            .orElse(null);
    }

    /**
     * 根据用户类型推断默认角色（兜底逻辑，当 im_org_member 无配置时使用）。
     */
    public static ImUserRole inferFromUserType(String userType) {
        return Optional.ofNullable(userType).map(t -> switch (t.toLowerCase()) {
            case "admin"       -> SUPER_ADMIN;
            case "merchant"    -> OWNER;
            case "technician"  -> TECHNICIAN;
            case "member"      -> MEMBER;
            default            -> STAFF;   // staff / driver / 其他
        }).orElse(MEMBER);
    }
}
