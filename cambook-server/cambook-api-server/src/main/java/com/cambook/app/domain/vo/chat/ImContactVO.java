package com.cambook.app.domain.vo.chat;

import lombok.Data;

/**
 * IM 联系人 VO
 */
@Data
public class ImContactVO {

    /** 用户类型（admin / merchant / staff / technician / member） */
    private String userType;

    /** 用户 ID */
    private Long userId;

    /** 显示名称 */
    private String name;

    /** 头像 URL */
    private String avatar;

    /** IM 角色码（OWNER / MANAGER / STAFF / OPERATOR / MARKETING / TECHNICIAN / DRIVER / MEMBER） */
    private String role;

    /** 角色显示名称 */
    private String roleLabel;

    /** 所属部门名称 */
    private String deptName;

    /** 职位名称 */
    private String positionName;

    /** 是否在线（来自 Redis） */
    private boolean online;

    /** 关联会话 ID（已存在时非空，方便前端直接打开） */
    private Long conversationId;
}
