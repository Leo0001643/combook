package com.cambook.app.domain.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Data;

/**
 * 新增 / 修改权限（Admin）
 *
 * @author CamBook
 */
@Data
@Schema(description = "权限请求")
public class PermissionDTO {

    @Schema(description = "主键（修改时必填）")
    private Long id;

    @Schema(description = "父节点 ID（新增时必填，根节点传0；修改时忽略，父节点变更请使用 /move 接口）")
    private Long parentId;

    @NotBlank(message = "权限名称不能为空")
    @Size(min = 1, max = 50, message = "权限名称1-50字符")
    @Schema(description = "权限名称")
    private String name;

    @Pattern(regexp = "^[a-z]+:[a-z]+$", message = "权限编码格式：模块:操作，如 member:list")
    @Schema(description = "权限编码，如 member:list")
    private String code;

    @NotNull(message = "类型不能为空")
    @Min(value = 1) @Max(value = 3)
    @Schema(description = "类型：1目录 2菜单 3按钮")
    private Integer type;

    @Schema(description = "前端路由路径")
    private String path;

    @Schema(description = "前端组件路径")
    private String component;

    @Schema(description = "图标")
    private String icon;

    @Min(value = 0) @Schema(description = "排序（越小越前）")
    private Integer sort;

    @Min(0) @Max(1) @Schema(description = "是否显示：1显示 0隐藏")
    private Integer visible;

    @Min(0) @Max(1) @Schema(description = "门户类型：0=管理端 1=商户端，默认0")
    private Integer portalType;
}
