package com.cambook.app.common.config;

import io.swagger.v3.oas.models.Components;
import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Contact;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.info.License;
import io.swagger.v3.oas.models.security.SecurityRequirement;
import io.swagger.v3.oas.models.security.SecurityScheme;
import org.springdoc.core.models.GroupedOpenApi;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * Knife4j / OpenAPI 3 配置
 *
 * <p>文档地址：http://localhost:8080/doc.html
 *
 * @author CamBook
 */
@Configuration
public class SwaggerConfig {

    private static final String SECURITY_SCHEME_NAME = "Bearer Token";

    /** 全局 OpenAPI 元信息 + JWT 安全配置 */
    @Bean
    public OpenAPI openAPI() {
        return new OpenAPI()
                .info(new Info()
                        .title("CamBook API 文档")
                        .description("柬埔寨按摩到家平台接口文档\n\n" +
                                "- **App 端**：`/app/**`\n" +
                                "- **管理端**：`/admin/**`\n\n" +
                                "认证方式：请求头 `Authorization: Bearer <token>`")
                        .version("v3.0.0")
                        .contact(new Contact()
                                .name("CamBook Team")
                                .email("dev@cambook.io"))
                        .license(new License().name("Private").url("#")))
                .addSecurityItem(new SecurityRequirement().addList(SECURITY_SCHEME_NAME))
                .components(new Components()
                        .addSecuritySchemes(SECURITY_SCHEME_NAME,
                                new SecurityScheme()
                                        .name(SECURITY_SCHEME_NAME)
                                        .type(SecurityScheme.Type.HTTP)
                                        .scheme("bearer")
                                        .bearerFormat("JWT")
                                        .description("从 /app/auth/login 或 /admin/auth/login 获取 token")
                        ));
    }

    /** App 端接口分组 */
    @Bean
    public GroupedOpenApi appApi() {
        return GroupedOpenApi.builder()
                .group("App 端")
                .pathsToMatch("/app/**")
                .build();
    }

    /** 管理端接口分组 */
    @Bean
    public GroupedOpenApi adminApi() {
        return GroupedOpenApi.builder()
                .group("管理端")
                .pathsToMatch("/admin/**")
                .build();
    }
}
