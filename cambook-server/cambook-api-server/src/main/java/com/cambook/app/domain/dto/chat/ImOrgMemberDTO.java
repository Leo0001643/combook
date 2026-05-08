package com.cambook.app.domain.dto.chat;

import lombok.Data;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

/**
 * 设置/更新组织成员 IM 角色 DTO
 */
@Data
public class ImOrgMemberDTO {

    @NotBlank(message = "用户类型不能为空")
    private String userType;

    @NotNull(message = "用户ID不能为空")
    private Long userId;

    @NotBlank(message = "IM角色不能为空")
    private String imRole;

    /** 所属部门 ID（MANAGER/STAFF 必填） */
    private Long deptId;

    /** 自定义显示名称（可选，不填则使用用户表本名） */
    private String displayName;
}
