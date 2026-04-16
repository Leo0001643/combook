package com.cambook.app.domain.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import lombok.Data;

/**
 * 发送短信验证码
 *
 * @author CamBook
 */
@Data
@Schema(description = "发送短信验证码")
public class SmsDTO {

    @NotBlank(message = "手机号不能为空")
    @Pattern(regexp = "^\\+?[1-9]\\d{6,14}$", message = "手机号格式不正确")
    @Schema(description = "手机号（国际格式）", example = "+85512345678")
    private String mobile;
}
