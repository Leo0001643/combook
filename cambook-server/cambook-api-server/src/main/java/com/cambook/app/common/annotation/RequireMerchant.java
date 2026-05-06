package com.cambook.app.common.annotation;

import java.lang.annotation.*;

/**
 * 商户身份鉴权注解
 *
 * <p>标注在商户端控制器类或方法上，由 {@code MerchantSecurityAspect} 自动校验：
 * <ol>
 *   <li>MerchantContext 中存在合法 merchantId（JWT 解析成功）</li>
 *   <li>请求 URI 必须以 /merchant/ 开头（防止绕过）</li>
 * </ol>
 *
 * @author CamBook
 */
@Target({ElementType.TYPE, ElementType.METHOD})
@Retention(RetentionPolicy.RUNTIME)
@Documented
public @interface RequireMerchant {
}
