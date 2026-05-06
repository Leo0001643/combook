package com.cambook.app.domain.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

/**
 * 部门新增/编辑 DTO
 */
@Data
@Schema(description = "部门保存请求")
public class DeptSaveDTO {

    @Schema(description = "ID（编辑时必填）")
    private Long id;

    @NotNull(message = "父级ID不能为空")
    @Schema(description = "父级部门ID，顶级为0")
    private Long parentId = 0L;

    @NotBlank(message = "部门名称不能为空")
    @Schema(description = "部门名称")
    private String name;

    @Schema(description = "排序值")
    private Integer sort = 0;

    @Schema(description = "负责人")
    private String leader;

    @Schema(description = "联系电话")
    private String phone;

    @Schema(description = "邮箱")
    private String email;

    @Schema(description = "状态：0停用 1启用（编辑时用）")
    private Integer status;
}
