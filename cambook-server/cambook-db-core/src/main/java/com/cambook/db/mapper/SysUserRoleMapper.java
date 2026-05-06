package com.cambook.db.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.cambook.db.entity.SysUserRole;

/**
 * <p>
 * 管理员角色关联表：多对多，记录管理员所持有的角色 Mapper 接口
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
public interface SysUserRoleMapper extends BaseMapper<SysUserRole> {

}
