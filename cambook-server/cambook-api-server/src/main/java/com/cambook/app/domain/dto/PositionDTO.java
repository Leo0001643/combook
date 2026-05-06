package com.cambook.app.domain.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Data;

/**
 * 职位新增/修改请求
 *
 * @author CamBook
 */
@Data
@Schema(description = "职位请求")
public class PositionDTO {

    @Schema(description = "职位 ID（修改时必填）")
    private Long id;

    @Schema(description = "所属部门ID")
    private Long deptId;

    @NotBlank(message = "职位名称不能为空")
    @Size(max = 50, message = "职位名称最多50字符")
    @Schema(description = "职位名称")
    private String name;

    @NotBlank(message = "职位编码不能为空")
    @Pattern(regexp = "^[A-Z][A-Z0-9_]{1,29}$", message = "编码须大写字母开头，仅含大写字母/数字/下划线，2-30位")
    @Schema(description = "职位编码（如 OP_DIRECTOR）")
    private String code;

    @Size(max = 200, message = "备注最多200字符")
    @Schema(description = "备注")
    private String remark;

    @Min(0) @Schema(description = "排序（越小越前）")
    private Integer sort;

    @Min(0) @Max(1) @Schema(description = "状态：1启用 0停用")
    private Integer status;

    @Min(0) @Max(1) @Schema(description = "全量权限：1=该职位拥有所有菜单（如总裁），0=按分配")
    private Integer fullAccess;
}
