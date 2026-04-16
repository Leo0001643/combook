package com.cambook.app.domain.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Data;

import java.util.List;

/**
 * 新增 / 修改角色（Admin）
 *
 * @author CamBook
 */
@Data
@Schema(description = "角色请求")
public class RoleDTO {

    @Schema(description = "主键（修改时必填）")
    private Long id;

    @NotBlank(message = "角色编码不能为空")
    @Pattern(regexp = "^[A-Z][A-Z0-9_]{1,49}$", message = "角色编码只能是大写字母、数字、下划线，且以大写字母开头")
    @Schema(description = "角色编码，如 OPERATOR", example = "OPERATOR")
    private String roleCode;

    @NotBlank(message = "角色名称不能为空")
    @Size(min = 2, max = 50, message = "角色名称2-50字符")
    @Schema(description = "角色名称", example = "运营人员")
    private String roleName;

    @Schema(description = "备注")
    private String remark;

    @Schema(description = "排序")
    private Integer sort;

    @NotEmpty(message = "权限列表不能为空")
    @Schema(description = "权限 ID 列表")
    private List<Long> permissionIds;
}
