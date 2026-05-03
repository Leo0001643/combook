package com.cambook.app.common.filter;

import com.cambook.common.context.AdminContext;
import com.cambook.common.context.MemberContext;
import com.cambook.common.context.MerchantContext;
import com.cambook.app.service.admin.IPermissionService;
import com.cambook.common.i18n.I18nContext;
import com.cambook.common.utils.JwtUtils;
import io.jsonwebtoken.Claims;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.apache.commons.lang3.StringUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.lang.NonNull;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.Set;

/**
 * 统一认证过滤器
 *
 * <p>职责：
 * <ol>
 *   <li>读取 {@code Accept-Language}，设置 {@link I18nContext} 请求语言</li>
 *   <li>解析 Bearer Token，区分 App（/app/**）和 Admin（/admin/**）路径</li>
 *   <li>App 端：注入 {@link MemberContext}（memberId / userType / lang）</li>
 *   <li>Admin 端：注入 {@link AdminContext}（userId / username / permissions）</li>
 *   <li>请求结束清理所有 ThreadLocal，防止内存泄漏</li>
 * </ol>
 *
 * @author CamBook
 */
@Component
public class AuthFilter extends OncePerRequestFilter {

    private static final Logger log = LoggerFactory.getLogger(AuthFilter.class);

    private static final String HEADER_AUTH = "Authorization";
    private static final String BEARER      = "Bearer ";
    private static final String HEADER_LANG = "Accept-Language";

    private final JwtUtils            jwtUtils;
    private final IPermissionService  permissionService;

    public AuthFilter(JwtUtils jwtUtils, IPermissionService permissionService) {
        this.jwtUtils          = jwtUtils;
        this.permissionService = permissionService;
    }

    @Override
    protected void doFilterInternal(@NonNull HttpServletRequest request, @NonNull HttpServletResponse response, @NonNull FilterChain filterChain) throws ServletException, IOException {
        try {
            I18nContext.setLang(request.getHeader(HEADER_LANG));

            String token = extractToken(request);
            if (StringUtils.isNotBlank(token)) {
                Claims claims = jwtUtils.parseToken(token);
                if (claims != null) {
                    String userType = claims.get("userType", String.class);
                    String uri = request.getRequestURI();

                    if ("merchant".equals(userType)) {
                        // 商户 JWT：只允许填充商户 Context，禁止携带商户 Token 访问 admin 接口
                        // （即使 URI=/admin/**，也不能获得 AdminContext，防止纵向越权）
                        if (uri.startsWith("/merchant/")) {
                            fillMerchantContext(claims);
                        }
                        // merchant 访问 /admin/** 时不填充任何 Context → 拦截器会拒绝
                    } else if ("admin".equals(userType) || "ADMIN".equals(userType)) {
                        // 管理员 JWT：只允许填充 Admin Context
                        if (uri.startsWith("/admin/")) {
                            fillAdminContext(claims);
                        }
                        // admin 访问 /merchant/** 时不填充 MerchantContext → 拦截器会拒绝
                    } else {
                        // App 用户 JWT（member）
                        fillMemberContext(claims);
                    }
                }
            }

            filterChain.doFilter(request, response);

        } finally {
            I18nContext.clear();
            MemberContext.clear();
            AdminContext.clear();
            MerchantContext.clear();
        }
    }

    // ── private ─────────────────────────────────────────────────────────────

    private String extractToken(HttpServletRequest request) {
        String auth = request.getHeader(HEADER_AUTH);
        if (StringUtils.isBlank(auth) || !auth.startsWith(BEARER)) return null;
        return auth.substring(BEARER.length());
    }

    private void fillMemberContext(Claims claims) {
        Object rawUid = claims.get("uid");
        Long memberId = rawUid instanceof Number ? ((Number) rawUid).longValue() : null;
        String userType = claims.get("userType", String.class);
        String lang = claims.get("lang", String.class);

        MemberContext.MemberInfo info = new MemberContext.MemberInfo();
        info.setMemberId(memberId);
        info.setUserType(userType);
        info.setLang(lang);
        MemberContext.set(info);
    }

    private void fillMerchantContext(Claims claims) {
        // JWT 小整数可能以 Integer 存储，统一用 Number 转换避免 ClassCastException
        Object rawUid     = claims.get("uid");
        Object rawStaffId = claims.get("staffId");
        Long merchantId   = rawUid     instanceof Number ? ((Number) rawUid).longValue()     : null;
        Long staffId      = rawStaffId instanceof Number ? ((Number) rawStaffId).longValue() : null;
        String merchantName = claims.get("merchantName", String.class);
        String mobile       = claims.get("mobile", String.class);

        MerchantContext.MerchantInfo info = new MerchantContext.MerchantInfo();
        info.setMerchantId(merchantId);
        info.setMerchantName(merchantName);
        info.setMobile(mobile);
        info.setStaffId(staffId);
        MerchantContext.set(info);

        log.debug("[Auth] merchant={} id={} staffId={}", merchantName, merchantId, staffId);
    }

    private void fillAdminContext(Claims claims) {
        Object rawUid = claims.get("uid");
        Long userId = rawUid instanceof Number ? ((Number) rawUid).longValue() : null;
        String username = claims.get("username", String.class);
        Set<String> perms = new java.util.HashSet<>(permissionService.getPermCodesByUserId(userId));

        AdminContext.AdminInfo info = new AdminContext.AdminInfo();
        info.setUserId(userId);
        info.setUsername(username);
        info.setPermissions(perms);
        AdminContext.set(info);
        log.debug("[Auth] admin={} perms={}", username, perms.size());
    }
}
