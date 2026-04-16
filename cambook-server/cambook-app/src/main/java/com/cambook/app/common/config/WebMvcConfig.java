package com.cambook.app.common.config;

import com.cambook.app.common.filter.AuthFilter;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.web.servlet.FilterRegistrationBean;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

/**
 * Web MVC 全局配置
 *
 * @author CamBook
 */
@Configuration
public class WebMvcConfig implements WebMvcConfigurer {

    @Value("${cambook.upload.path}")
    private String uploadPath;

    @Autowired
    private MerchantEndpointInterceptor merchantEndpointInterceptor;

    @Override
    public void addCorsMappings(CorsRegistry registry) {
        registry.addMapping("/**")
            .allowedOriginPatterns("*")
            .allowedMethods("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS")
            .allowedHeaders("*")
            .allowCredentials(true)
            .maxAge(3600);
    }

    /** 注册商户端端点安全拦截器（纵深防御第一道防线） */
    @Override
    public void addInterceptors(InterceptorRegistry registry) {
        registry.addInterceptor(merchantEndpointInterceptor)
                .addPathPatterns("/admin/**", "/merchant/**");
    }

    /** 将本地上传目录映射到 /uploads/** URL 路径 */
    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        registry.addResourceHandler("/uploads/**")
                .addResourceLocations("file:" + uploadPath + "/");
    }

    @Bean
    public FilterRegistrationBean<AuthFilter> authFilterRegistration(AuthFilter authFilter) {
        FilterRegistrationBean<AuthFilter> bean = new FilterRegistrationBean<>(authFilter);
        bean.addUrlPatterns("/app/*", "/admin/*", "/merchant/*");
        bean.setOrder(1);
        return bean;
    }
}
