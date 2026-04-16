package com.cambook.app.domain.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import lombok.Data;

/**
 * 商户端登录参数
 *
 * @author CamBook
 */
@Data
@Schema(description = "商户登录参数")
public class MerchantLoginDTO {

    @Schema(description = "商户编号（员工登录必填；商户主账号可留空）")
    private String merchantNo;

    @NotBlank(message = "账号不能为空")
    @Schema(description = "手机号或用户名", requiredMode = Schema.RequiredMode.REQUIRED)
    private String account;

    @NotBlank(message = "密码不能为空")
    @Schema(description = "登录密码", requiredMode = Schema.RequiredMode.REQUIRED)
    private String password;
}
