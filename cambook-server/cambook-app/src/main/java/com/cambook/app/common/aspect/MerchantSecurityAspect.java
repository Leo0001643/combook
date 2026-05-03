package com.cambook.app.common.aspect;

import com.cambook.common.context.AdminContext;
import com.cambook.common.context.MerchantContext;
import com.cambook.common.exception.BusinessException;
import jakarta.servlet.http.HttpServletRequest;
import org.aspectj.lang.JoinPoint;
import org.aspectj.lang.annotation.Aspect;
import org.aspectj.lang.annotation.Before;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;

/**
 * 商户端安全切面
 *
 * <p>对所有 {@code @RequireMerchant} 类/方法执行双重安全校验：
 * <ol>
 *   <li><b>身份校验</b>：MerchantContext 必须存在合法 merchantId（来自 JWT 解析）</li>
 *   <li><b>URI 校验</b>：请求路径必须以 {@code /merchant/} 开头，防止越权绕过</li>
 *   <li><b>越权防护</b>：Admin JWT 不能调用商户端接口，反之亦然</li>
 * </ol>
 *
 * <p>数据隔离职责在各 Service 层通过 merchantId 参数强制执行，本切面仅负责
 * "当前请求是否有资格以商户身份操作" 的鉴权检查。
 *
 * @author CamBook
 */
@Aspect
@Component
public class MerchantSecurityAspect {

    private static final Logger log = LoggerFactory.getLogger(MerchantSecurityAspect.class);

    @Before("@within(com.cambook.app.common.annotation.RequireMerchant) || " +
            "@annotation(com.cambook.app.common.annotation.RequireMerchant)")
    public void checkMerchantAuth(JoinPoint joinPoint) {
        // 1. Admin 不得调用商户端接口（防止 Admin JWT 越权）
        if (AdminContext.getUserId() != null) {
            log.warn("[MerchantSecurity] Admin account attempted to access merchant endpoint: {}", joinPoint.getSignature().toShortString());
            throw new BusinessException("管理员账号不得访问商户端接口");
        }

        // 2. 商户 merchantId 必须存在（JWT 解析成功）
        Long merchantId = MerchantContext.getMerchantId();
        if (merchantId == null) {
            log.warn("[MerchantSecurity] Unauthorized merchant access attempt: {}", joinPoint.getSignature().toShortString());
            throw new BusinessException("商户身份校验失败，请重新登录");
        }

        // 3. URI 强制校验：防止路由配置错误导致商户接口被非 /merchant/ 路径触发
        HttpServletRequest request = currentRequest();
        if (request != null) {
            String uri = request.getRequestURI();
            if (!uri.startsWith("/merchant/")) {
                log.error("[MerchantSecurity] Merchant endpoint reached via non-merchant URI: {} by merchantId={}", uri, merchantId);
                throw new BusinessException("非法请求路径");
            }
        }
        log.debug("[MerchantSecurity] Auth OK: merchantId={} → {}", merchantId, joinPoint.getSignature().toShortString());
    }

    private HttpServletRequest currentRequest() {
        try {
            ServletRequestAttributes attrs = (ServletRequestAttributes) RequestContextHolder.currentRequestAttributes();
            return attrs.getRequest();
        } catch (IllegalStateException e) {
            return null;
        }
    }
}
