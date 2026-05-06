package com.cambook.app.common.config;

import com.cambook.app.common.filter.AuthFilter;
import com.cambook.app.common.filter.RequestLogFilter;
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

    @Value("${cambook.im.local-store-path:/data/cambook/media}")
    private String mediaStorePath;

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

    /** 将本地上传目录映射到 /uploads/** URL 路径，IM 媒体目录映射到 /media/** */
    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        registry.addResourceHandler("/uploads/**")
                .addResourceLocations("file:" + uploadPath + "/");
        registry.addResourceHandler("/media/**")
                .addResourceLocations("file:" + mediaStorePath + "/");
    }

    /**
     * 请求日志过滤器（order=0，最先执行）
     *
     * <p>直接 new 实例而非注入 Bean，避免 Spring 再次自动注册造成双重执行。
     * 已跳过 Swagger / 静态资源路径。
     */
    @Bean
    public FilterRegistrationBean<RequestLogFilter> requestLogFilterRegistration() {
        FilterRegistrationBean<RequestLogFilter> bean = new FilterRegistrationBean<>(new RequestLogFilter());
        bean.addUrlPatterns("/*");
        bean.setOrder(0);   // 早于 AuthFilter（order=1）执行
        return bean;
    }

    /** 认证过滤器（order=1，在日志过滤器之后） */
    @Bean
    public FilterRegistrationBean<AuthFilter> authFilterRegistration(AuthFilter authFilter) {
        FilterRegistrationBean<AuthFilter> bean = new FilterRegistrationBean<>(authFilter);
        bean.addUrlPatterns("/app/*", "/admin/*", "/merchant/*", "/tech/*");
        bean.setOrder(1);
        return bean;
    }
}
