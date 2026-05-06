package com.cambook.app.domain.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Data;

/**
 * 后台管理员登录
 *
 * @author CamBook
 */
@Data
@Schema(description = "管理员登录")
public class AdminLoginDTO {

    @NotBlank(message = "账号不能为空")
    @Pattern(regexp = "^[a-zA-Z0-9_]{4,32}$", message = "账号只能包含字母、数字、下划线，4-32位")
    @Schema(description = "登录账号", example = "admin")
    private String username;

    @NotBlank(message = "密码不能为空")
    @Size(min = 6, max = 50, message = "密码长度6-50位")
    @Schema(description = "登录密码")
    private String password;
}
