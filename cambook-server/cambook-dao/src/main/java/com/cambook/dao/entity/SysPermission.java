package com.cambook.dao.entity;

import lombok.Getter;
import lombok.Setter;

import com.baomidou.mybatisplus.annotation.TableName;
import com.cambook.dao.entity.base.BaseEntity;

/**
 * 权限菜单表（目录 / 菜单 / 按钮三级，RBAC）
 *
 * @author CamBook
 */
@TableName("sys_permission")
@Getter
@Setter
public class SysPermission extends BaseEntity {

    private Long parentId;
    private String name;
    /**
     * 权限标识，遵循"模块:操作"格式，例如：
     * <pre>
     *   member:list / member:add / order:delete
     * </pre>
     */
    private String code;
    /** 类型：1目录 2菜单 3按钮/操作 */
    private Integer type;
    private String path;
    private String component;
    private String icon;
    private Integer sort;
    /** 所属门户：0=管理端 1=商户端 */
    private Integer portalType;
    /** 是否显示在菜单：1显示 0隐藏 */
    private Integer visible;
    /** 状态：1启用 0停用 */
    private Integer status;

    public Long getParentId()   { return parentId; }
    public String getName()     { return name; }
    public String getCode()     { return code; }
    public Integer getType()    { return type; }
    public String getPath()     { return path; }
    public String getComponent(){ return component; }
    public String getIcon()     { return icon; }
    public Integer getSort()       { return sort; }
    public Integer getVisible()    { return visible; }
    public Integer getStatus()  { return status; }

    public void setParentId(Long parentId)     { this.parentId = parentId; }
    public void setName(String name)           { this.name = name; }
    public void setCode(String code)           { this.code = code; }
    public void setType(Integer type)          { this.type = type; }
    public void setPath(String path)           { this.path = path; }
    public void setIcon(String icon)           { this.icon = icon; }
    public void setSort(Integer sort)             { this.sort = sort; }
    public void setVisible(Integer visible)       { this.visible = visible; }
    public void setStatus(Integer status)      { this.status = status; }
}
