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
 * 角色表：定义 RBAC 角色，一角色可关联多个权限，一管理员可持有多个角色
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
@Getter
@Setter
@ToString
@TableName("sys_role")
public class SysRole implements Serializable {

    private static final long serialVersionUID = 1L;

    /**
     * 主键，自增
     */
    @TableId(value = "id", type = IdType.AUTO)
    private Long id;

    /**
     * 角色编码（全局唯一，大写字母+下划线），如 SUPER_ADMIN / OPERATOR / AUDITOR
     */
    private String roleCode;

    /**
     * 角色名称（中文可读），如 超级管理员 / 运营人员
     */
    private String roleName;

    /**
     * 角色说明，描述该角色的职责范围
     */
    private String remark;

    /**
     * 排序权重，值越小越靠前
     */
    private Integer sort;

    /**
     * 状态：1=启用 0=停用
     */
    private Byte status;

    /**
     * 逻辑删除：0=正常 1=已删除
     */
    private Byte deleted;

    /**
     * 创建时间（UTC 秒级时间戳）
     */
    private Long createTime;

    /**
     * 最后修改时间（UTC 秒级时间戳）
     */
    private Long updateTime;
}
