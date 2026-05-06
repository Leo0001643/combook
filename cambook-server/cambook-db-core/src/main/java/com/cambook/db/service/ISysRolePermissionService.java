package com.cambook.db.service;

import com.cambook.db.entity.SysRolePermission;
import com.baomidou.mybatisplus.extension.service.IService;

/**
 * <p>
 * 角色权限关联表：多对多，记录角色拥有的权限项 服务类
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
public interface ISysRolePermissionService extends IService<SysRolePermission> {

}
