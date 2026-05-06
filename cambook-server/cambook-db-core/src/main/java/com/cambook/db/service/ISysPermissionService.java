package com.cambook.db.service;

import com.cambook.db.entity.SysPermission;
import com.baomidou.mybatisplus.extension.service.IService;

/**
 * <p>
 * 权限菜单表：树形结构，三级（目录/菜单/按钮），实现 RBAC 到按钮级粒度 服务类
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
public interface ISysPermissionService extends IService<SysPermission> {

}
