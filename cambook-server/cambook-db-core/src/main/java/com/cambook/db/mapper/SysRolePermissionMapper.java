package com.cambook.db.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.cambook.db.entity.SysRolePermission;

/**
 * <p>
 * 角色权限关联表：多对多，记录角色拥有的权限项 Mapper 接口
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
public interface SysRolePermissionMapper extends BaseMapper<SysRolePermission> {

}
