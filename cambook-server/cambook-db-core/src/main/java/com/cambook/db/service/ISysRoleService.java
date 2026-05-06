package com.cambook.db.service;

import com.cambook.db.entity.SysRole;
import com.baomidou.mybatisplus.extension.service.IService;

/**
 * <p>
 * 角色表：定义 RBAC 角色，一角色可关联多个权限，一管理员可持有多个角色 服务类
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
public interface ISysRoleService extends IService<SysRole> {

}
