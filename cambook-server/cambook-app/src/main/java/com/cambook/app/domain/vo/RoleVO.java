package com.cambook.app.domain.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.util.List;

/**
 * 角色视图
 *
 * @author CamBook
 */
@Data
@Schema(description = "角色信息")
public class RoleVO {

    @Schema(description = "角色 ID")
    private Long id;

    @Schema(description = "角色编码")
    private String roleCode;

    @Schema(description = "角色名称")
    private String roleName;

    @Schema(description = "备注")
    private String remark;

    @Schema(description = "排序")
    private Integer sort;

    @Schema(description = "状态：1启用 0停用")
    private Integer status;

    @Schema(description = "已分配权限 ID 列表")
    private List<Long> permissionIds;
}
