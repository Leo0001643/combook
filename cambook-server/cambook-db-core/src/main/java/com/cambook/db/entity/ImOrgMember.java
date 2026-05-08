package com.cambook.db.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Getter;
import lombok.Setter;
import lombok.ToString;

import java.io.Serializable;

/**
 * <p>
 * IM 组织成员表：用户 → IM角色 映射，构建无好友通讯录体系
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-06
 */
@Getter
@Setter
@ToString
@TableName("im_org_member")
public class ImOrgMember implements Serializable {

    private static final long serialVersionUID = 1L;

    /**
     * 主键
     */
    @TableId(value = "id", type = IdType.AUTO)
    private Long id;

    /**
     * 所属商户 ID，0 = 平台超管
     */
    private Long merchantId;

    /**
     * 用户类型: admin / merchant / staff / technician / member
     */
    private String userType;

    /**
     * 用户 ID（对应各业务表主键）
     */
    private Long userId;

    /**
     * IM 角色: SUPER_ADMIN / OWNER / MANAGER / STAFF / OPERATOR / MARKETING / TECHNICIAN / DRIVER / MEMBER
     */
    private String imRole;

    /**
     * 所属部门 ID（用于 MANAGER/STAFF 的同部门过滤）
     */
    private Long deptId;

    /**
     * 自定义显示名称（覆盖用户表本名）
     */
    private String displayName;

    /**
     * 状态: 0=启用 1=禁用
     */
    private Byte status;

    /**
     * 创建时间（Unix 秒）
     */
    private Long createTime;

    /**
     * 更新时间（Unix 秒）
     */
    private Long updateTime;
}
