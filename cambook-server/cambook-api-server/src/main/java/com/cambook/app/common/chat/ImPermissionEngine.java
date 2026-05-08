package com.cambook.app.common.chat;

import com.cambook.app.domain.enums.ImUserRole;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.dao.EmptyResultDataAccessException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

import java.util.*;
import java.util.concurrent.ConcurrentHashMap;

/**
 * IM 通信权限引擎
 *
 * <p><b>决策链（三层，短路优先）：</b>
 * <ol>
 *   <li>查 {@code im_chat_rule}（merchant_id = 当前商户）→ 商户自定义规则优先</li>
 *   <li>查 {@code im_chat_rule}（merchant_id = 0）→ 平台默认规则兜底</li>
 *   <li>内置 {@link #BUILT_IN_RULES} → 数据库无数据时的最终兜底</li>
 * </ol>
 *
 * <p><b>缓存策略：</b>允许角色集合（per merchantId+senderRole）本地 TTL 缓存 5 分钟，
 * 规则变更后调用 {@link #evictCache(Long)} 主动清除。
 *
 * <p><b>部门限制（MANAGER / STAFF）：</b>代码层额外校验，不在规则表冗余存储。
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class ImPermissionEngine {

    private final JdbcTemplate jdbc;

    // ── 内置默认规则（DB 无数据时的最终兜底）────────────────────────────────
    private static final Map<ImUserRole, Set<ImUserRole>> BUILT_IN_RULES = Map.of(
        ImUserRole.SUPER_ADMIN, EnumSet.allOf(ImUserRole.class),
        ImUserRole.OWNER,       EnumSet.allOf(ImUserRole.class),
        ImUserRole.MANAGER,     EnumSet.of(ImUserRole.OWNER, ImUserRole.MANAGER, ImUserRole.STAFF),
        ImUserRole.STAFF,       EnumSet.of(ImUserRole.MANAGER),
        ImUserRole.OPERATOR,    EnumSet.of(ImUserRole.TECHNICIAN, ImUserRole.MEMBER, ImUserRole.DRIVER, ImUserRole.OPERATOR),
        ImUserRole.MARKETING,   EnumSet.of(ImUserRole.TECHNICIAN, ImUserRole.MEMBER, ImUserRole.MARKETING),
        ImUserRole.TECHNICIAN,  EnumSet.of(ImUserRole.MEMBER, ImUserRole.OPERATOR, ImUserRole.MARKETING, ImUserRole.DRIVER),
        ImUserRole.DRIVER,      EnumSet.of(ImUserRole.TECHNICIAN, ImUserRole.OPERATOR),
        ImUserRole.MEMBER,      EnumSet.of(ImUserRole.TECHNICIAN, ImUserRole.OPERATOR, ImUserRole.MARKETING)
    );

    // ── 本地 TTL 缓存 ─────────────────────────────────────────────────────────
    /** 缓存 key: "merchantId:senderRole" */
    private final ConcurrentHashMap<String, CacheEntry> ruleCache = new ConcurrentHashMap<>();
    private static final long CACHE_TTL_MS = 300_000L; // 5 分钟

    private record CacheEntry(Set<String> roles, long expireAt) {
        boolean expired() { return System.currentTimeMillis() > expireAt; }
    }

    /** 主动清除商户的权限规则缓存（在规则更新时调用）。 */
    public void evictCache(Long merchantId) {
        String prefix = merchantId + ":";
        ruleCache.keySet().removeIf(k -> k.startsWith(prefix));
        log.debug("[Perm] 缓存已清除 merchantId={}", merchantId);
    }

    // ── 公开 API ──────────────────────────────────────────────────────────────

    /**
     * 校验 sender 是否有权限给 receiver 发消息。
     * 同时检查部门作用域（MANAGER/STAFF 只能在同部门内）。
     */
    public boolean canChat(String senderType, Long senderId,
                           String receiverType, Long receiverId,
                           Long merchantId) {
        if (senderType == null || senderId == null || receiverType == null || receiverId == null) {
            return false;
        }
        long mid = merchantId != null ? merchantId : 0L;

        ImUserRole senderRole   = getRole(senderType,   senderId,   mid);
        ImUserRole receiverRole = getRole(receiverType, receiverId, mid);

        if (!isRuleAllowed(senderRole, receiverRole, mid)) {
            log.debug("[Perm] 拒绝 {}[{}]({}) → {}[{}]({}) merchantId={}",
                senderRole, senderType, senderId, receiverRole, receiverType, receiverId, mid);
            return false;
        }

        // 部门作用域：MANAGER/STAFF 只能在同部门
        if (needsDeptCheck(senderRole, receiverRole)) {
            Long senderDept   = getDeptId(senderType,   senderId,   mid);
            Long receiverDept = getDeptId(receiverType, receiverId, mid);
            if (senderDept == null || !senderDept.equals(receiverDept)) {
                log.debug("[Perm] 跨部门拒绝 sender dept={} receiver dept={}", senderDept, receiverDept);
                return false;
            }
        }
        return true;
    }

    /** 获取用户的 IM 角色（优先 im_org_member，兜底 userType 推断）。 */
    public ImUserRole getRole(String userType, Long userId, Long merchantId) {
        if (userType == null || userId == null) return ImUserRole.MEMBER;
        long mid = merchantId != null ? merchantId : 0L;
        try {
            String role = jdbc.queryForObject(
                "SELECT im_role FROM im_org_member " +
                "WHERE user_type=? AND user_id=? AND merchant_id=? AND status=0",
                String.class, userType, userId, mid);
            ImUserRole r = ImUserRole.fromCode(role);
            return r != null ? r : ImUserRole.inferFromUserType(userType);
        } catch (EmptyResultDataAccessException e) {
            return ImUserRole.inferFromUserType(userType);
        }
    }

    /**
     * 获取 sender 可以联系的所有角色集合（用于构建通讯录）。
     * 结果带 TTL 缓存，5 分钟内重复调用直接返回内存。
     */
    public Set<String> getAllowedReceiverRoles(ImUserRole senderRole, Long merchantId) {
        long mid = merchantId != null ? merchantId : 0L;
        String cacheKey = mid + ":" + senderRole.name();

        CacheEntry cached = ruleCache.get(cacheKey);
        if (cached != null && !cached.expired()) return cached.roles();

        Set<String> roles = queryAllowedRoles(senderRole.name(), mid);
        if (roles.isEmpty()) {
            // 内置兜底
            Set<ImUserRole> builtIn = BUILT_IN_RULES.getOrDefault(senderRole, Collections.emptySet());
            roles = new LinkedHashSet<>();
            for (ImUserRole r : builtIn) roles.add(r.name());
        }

        ruleCache.put(cacheKey, new CacheEntry(Collections.unmodifiableSet(roles),
            System.currentTimeMillis() + CACHE_TTL_MS));
        return roles;
    }

    /** 获取用户的部门 ID（来自 im_org_member）。 */
    public Long getDeptId(String userType, Long userId, Long merchantId) {
        if (userType == null || userId == null) return null;
        long mid = merchantId != null ? merchantId : 0L;
        try {
            return jdbc.queryForObject(
                "SELECT dept_id FROM im_org_member " +
                "WHERE user_type=? AND user_id=? AND merchant_id=? AND status=0",
                Long.class, userType, userId, mid);
        } catch (EmptyResultDataAccessException e) {
            return null;
        }
    }

    // ── 私有方法 ──────────────────────────────────────────────────────────────

    private boolean isRuleAllowed(ImUserRole senderRole, ImUserRole receiverRole, long merchantId) {
        // 1. 商户自定义规则
        Boolean merchantRule = queryRule(senderRole.name(), receiverRole.name(), merchantId);
        if (merchantRule != null) return merchantRule;

        // 2. 平台默认规则
        if (merchantId != 0L) {
            Boolean platformRule = queryRule(senderRole.name(), receiverRole.name(), 0L);
            if (platformRule != null) return platformRule;
        }

        // 3. 内置兜底
        return BUILT_IN_RULES.getOrDefault(senderRole, Collections.emptySet()).contains(receiverRole);
    }

    private Boolean queryRule(String senderRole, String receiverRole, long merchantId) {
        try {
            Integer allowed = jdbc.queryForObject(
                "SELECT allowed FROM im_chat_rule " +
                "WHERE merchant_id=? AND sender_role=? AND receiver_role=?",
                Integer.class, merchantId, senderRole, receiverRole);
            return allowed != null ? allowed == 1 : null;
        } catch (EmptyResultDataAccessException e) {
            return null;
        }
    }

    private Set<String> queryAllowedRoles(String senderRole, long merchantId) {
        List<Map<String, Object>> rows = jdbc.queryForList(
            "SELECT receiver_role, allowed FROM im_chat_rule " +
            "WHERE merchant_id IN (0,?) AND sender_role=? " +
            "ORDER BY merchant_id DESC",
            merchantId, senderRole);

        Set<String> result = new LinkedHashSet<>();
        Set<String> seen   = new HashSet<>();
        for (var row : rows) {
            Object roleObj    = row.get("receiver_role");
            Object allowedObj = row.get("allowed");
            if (roleObj == null || allowedObj == null) continue;
            String role    = roleObj.toString();
            int    allowed = ((Number) allowedObj).intValue();
            if (seen.add(role) && allowed == 1) result.add(role);
        }
        return result;
    }

    private boolean needsDeptCheck(ImUserRole senderRole, ImUserRole receiverRole) {
        boolean senderScoped   = senderRole   == ImUserRole.MANAGER || senderRole   == ImUserRole.STAFF;
        boolean receiverScoped = receiverRole == ImUserRole.MANAGER || receiverRole == ImUserRole.STAFF;
        return senderScoped && receiverScoped;
    }
}
