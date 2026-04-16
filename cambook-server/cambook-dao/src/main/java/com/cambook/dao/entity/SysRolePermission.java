package com.cambook.dao.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;

@TableName("sys_role_permission")
public class SysRolePermission {
    @TableId(type = IdType.AUTO)
    private Long id;
    private Long roleId;
    private Long permissionId;

    public Long getId()              { return id; }
    public void setId(Long v)        { this.id = v; }
    public Long getRoleId()          { return roleId; }
    public void setRoleId(Long v)    { this.roleId = v; }
    public Long getPermissionId()    { return permissionId; }
    public void setPermissionId(Long v){ this.permissionId = v; }
}
