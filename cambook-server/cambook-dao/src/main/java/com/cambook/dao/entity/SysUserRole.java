package com.cambook.dao.entity;

import lombok.Getter;
import lombok.Setter;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;

@TableName("sys_user_role")
@Getter
@Setter
public class SysUserRole {
    @TableId(type = IdType.AUTO)
    private Long id;
    private Long userId;
    private Long roleId;

    public Long getId()           { return id; }
    public void setId(Long v)     { this.id = v; }
    public Long getUserId()       { return userId; }
    public Long getRoleId()       { return roleId; }
}
