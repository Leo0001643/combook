package com.cambook.app.domain.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import lombok.Data;

/**
 * 短信验证码登录
 *
 * @author CamBook
 */
@Data
@Schema(description = "短信验证码登录")
public class LoginDTO {

    @NotBlank(message = "手机号不能为空")
    @Pattern(regexp = "^\\+?[1-9]\\d{6,14}$", message = "手机号格式不正确")
    @Schema(description = "手机号", example = "+85512345678")
    private String mobile;

    @NotBlank(message = "验证码不能为空")
    @Pattern(regexp = "^\\d{6}$", message = "验证码必须为6位数字")
    @Schema(description = "短信验证码", example = "888888")
    private String smsCode;

    @NotBlank(message = "用户类型不能为空")
    @Pattern(regexp = "^(member|technician|merchant)$", message = "用户类型不合法")
    @Schema(description = "用户类型", allowableValues = {"member", "technician", "merchant"})
    private String userType;
}
