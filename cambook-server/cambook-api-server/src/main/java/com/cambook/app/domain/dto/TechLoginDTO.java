package com.cambook.app.domain.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Positive;
import lombok.Data;

/**
 * 技师端登录请求
 *
 * <p>支持两种登录方式：
 * <ul>
 *   <li>{@code techId}  —— 技师编号 + 密码</li>
 *   <li>{@code phone}   —— 手机号（国际格式）+ 密码</li>
 * </ul>
 *
 * <p>多租户隔离：客户端在打包时通过 {@code --dart-define=MERCHANT_ID=xxx} 将
 * 商户 ID 写入 APK/IPA，登录时随请求上传，服务端校验技师归属，防止跨商户登录。
 *
 * @author CamBook
 */
@Data
@Schema(description = "技师端登录请求")
public class TechLoginDTO {

    @NotNull(message = "{tech.login.merchantId.required}")
    @Positive(message = "{tech.login.merchantId.positive}")
    @Schema(description = "商户数字ID（由 App 打包时写入，用于多租户隔离）", example = "1")
    private Long merchantId;

    @NotBlank(message = "{tech.login.type.required}")
    @Pattern(regexp = "^(techId|phone)$", message = "{tech.login.type.invalid}")
    @Schema(description = "登录方式", allowableValues = {"techId", "phone"}, example = "techId")
    private String loginType;

    @NotBlank(message = "{tech.login.account.required}")
    @Schema(description = "技师编号（loginType=techId）或手机号（loginType=phone）", example = "T20240001")
    private String account;

    @NotBlank(message = "{tech.login.password.required}")
    @Schema(description = "登录密码", example = "Abc12345")
    private String password;

    @Schema(description = "语言偏好（zh/en/vi/km/ko/ja），默认 zh", example = "zh")
    private String lang;
}
