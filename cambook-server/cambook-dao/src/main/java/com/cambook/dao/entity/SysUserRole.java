package com.cambook.dao.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;

@TableName("sys_user_role")
public class SysUserRole {
    @TableId(type = IdType.AUTO)
    private Long id;
    private Long userId;
    private Long roleId;

    public Long getId()           { return id; }
    public void setId(Long v)     { this.id = v; }
    public Long getUserId()       { return userId; }
    public void setUserId(Long v) { this.userId = v; }
    public Long getRoleId()       { return roleId; }
    public void setRoleId(Long v) { this.roleId = v; }
}
