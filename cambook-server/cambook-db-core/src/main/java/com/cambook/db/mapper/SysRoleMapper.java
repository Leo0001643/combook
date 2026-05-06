package com.cambook.db.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.cambook.db.entity.SysRole;

/**
 * <p>
 * 角色表：定义 RBAC 角色，一角色可关联多个权限，一管理员可持有多个角色 Mapper 接口
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
public interface SysRoleMapper extends BaseMapper<SysRole> {

}
