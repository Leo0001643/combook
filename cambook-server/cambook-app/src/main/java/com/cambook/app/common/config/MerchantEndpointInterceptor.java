package com.cambook.app.common.config;

import com.cambook.common.context.AdminContext;
import com.cambook.common.context.MerchantContext;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.MediaType;
import org.springframework.lang.NonNull;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.HandlerInterceptor;

import java.util.Map;

/**
 * 商户端端点拦截器（网关级别安全）
 *
 * <p>在 Spring MVC Handler 处理前执行以下校验：
 * <ol>
 *   <li>Admin JWT 不得访问 {@code /merchant/**}（防止管理员 Token 横向越权）</li>
 *   <li>Merchant JWT 不得访问 {@code /admin/**}（防止商户 Token 纵向越权）</li>
 *   <li>无身份 Token 的请求对受保护路径返回 401</li>
 * </ol>
 *
 * <p>与 {@code MerchantSecurityAspect} 形成纵深防御（Defense in Depth）：
 * 本拦截器是第一道防线（网关层），AOP 切面是第二道防线（业务层）。
 *
 * @author CamBook
 */
@Component
public class MerchantEndpointInterceptor implements HandlerInterceptor {

    private static final Logger log = LoggerFactory.getLogger(MerchantEndpointInterceptor.class);

    private final ObjectMapper objectMapper;

    public MerchantEndpointInterceptor(ObjectMapper objectMapper) {
        this.objectMapper = objectMapper;
    }

    @Override
    public boolean preHandle(@NonNull HttpServletRequest request, @NonNull HttpServletResponse response, @NonNull Object handler) throws Exception {
        String uri = request.getRequestURI();

        // ── 规则1：Admin 身份不得访问商户端接口 ──────────────────────────────
        if (uri.startsWith("/merchant/") && !uri.equals("/merchant/auth/login")) {
            if (AdminContext.getUserId() != null) {
                log.warn("[Security] Admin(id={}) attempted to access merchant endpoint: {}", AdminContext.getUserId(), uri);
                writeError(response, 403, "管理员账号不得访问商户端接口");
                return false;
            }
            // 登录接口外的商户端接口必须有有效 merchantId
            if (MerchantContext.getMerchantId() == null) {
                writeError(response, 401, "请先登录商户账号");
                return false;
            }
        }

        // ── 规则2：Merchant 身份不得访问管理员接口 ────────────────────────────
        if (uri.startsWith("/admin/")) {
            if (MerchantContext.getMerchantId() != null) {
                log.warn("[Security] Merchant(id={}) attempted to access admin endpoint: {}", MerchantContext.getMerchantId(), uri);
                writeError(response, 403, "商户账号不得访问管理员接口");
                return false;
            }
        }
        return true;
    }

    private void writeError(HttpServletResponse response, int status, String message) throws Exception {
        response.setStatus(status);
        response.setContentType(MediaType.APPLICATION_JSON_VALUE);
        response.setCharacterEncoding("UTF-8");
        response.getWriter().write(objectMapper.writeValueAsString(Map.of("code", status, "message", message, "success", false)));
    }
}
