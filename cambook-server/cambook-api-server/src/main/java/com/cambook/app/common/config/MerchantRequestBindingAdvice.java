package com.cambook.app.common.config;

import jakarta.servlet.http.HttpServletRequest;
import org.springframework.web.bind.WebDataBinder;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.InitBinder;

/**
 * 商户端请求绑定保护
 *
 * <p>对所有 {@code /merchant/*} 路径的请求，禁止客户端通过请求参数绑定
 * {@code merchantId} 字段，防止恶意篡改数据作用域。
 *
 * <p>即使攻击者在请求中注入 {@code ?merchantId=999}，该字段在商户端控制器收到
 * 的 DTO 中也不会被绑定。商户控制器随后会从 JWT 的 {@code MerchantContext}
 * 中强制注入正确的 merchantId，实现双重防护。
 *
 * @author CamBook
 */
@ControllerAdvice
public class MerchantRequestBindingAdvice {

    @InitBinder
    public void initBinder(WebDataBinder binder, HttpServletRequest request) {
        if (request.getRequestURI().startsWith("/merchant/")) {
            // 商户端接口禁止从请求参数绑定 merchantId，防止数据范围伪造
            binder.setDisallowedFields("merchantId");
        }
    }
}
