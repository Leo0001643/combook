package com.cambook.dao.entity;

import lombok.Getter;
import lombok.Setter;

import com.baomidou.mybatisplus.annotation.TableName;
import com.cambook.dao.entity.base.BaseEntity;

@TableName("sys_role")
@Getter
@Setter
public class SysRole extends BaseEntity {
    private String roleCode;
    private String roleName;
    private String remark;
    private Integer sort;
    private Integer status;

    public String  getRoleCode()                { return roleCode; }
    public void    setRoleCode(String v)        { this.roleCode = v; }
    public String  getRoleName()                { return roleName; }
    public void    setRoleName(String v)        { this.roleName = v; }
    public String  getRemark()                  { return remark; }
    public void    setRemark(String v)          { this.remark = v; }
    public void    setSort(Integer v)           { this.sort = v; }
    public void    setStatus(Integer v)         { this.status = v; }
}
