package com.cambook.app.domain.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Data;

import java.util.List;

/**
 * 员工（管理员）新增/修改请求
 *
 * @author CamBook
 */
@Data
@Schema(description = "员工请求")
public class StaffDTO {

    @Schema(description = "用户 ID（修改时必填）")
    private Long id;

    @NotBlank(message = "账号不能为空")
    @Pattern(regexp = "^[a-zA-Z0-9_]{4,32}$", message = "账号4-32位，仅含字母/数字/下划线")
    @Schema(description = "登录账号")
    private String username;

    @Size(min = 6, max = 32, message = "密码6-32位")
    @Schema(description = "登录密码（新增必填，修改留空则不修改）")
    private String password;

    @Size(max = 20, message = "真实姓名最多20字符")
    @Schema(description = "真实姓名")
    private String realName;

    @Email(message = "邮箱格式不正确")
    @Schema(description = "邮箱")
    private String email;

    @Pattern(regexp = "^1[3-9]\\d{9}$", message = "手机号格式不正确")
    @Schema(description = "手机号")
    private String mobile;

    @Schema(description = "职位 ID")
    private Long positionId;

    @Min(0) @Max(1) @Schema(description = "状态：1正常 0停用")
    private Integer status;

    @Schema(description = "分配的角色 ID 列表")
    private List<Long> roleIds;
}
