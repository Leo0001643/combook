package com.cambook.db.service.impl;

import com.cambook.db.entity.SysPermission;
import com.cambook.db.mapper.SysPermissionMapper;
import com.cambook.db.service.ISysPermissionService;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.springframework.stereotype.Service;

/**
 * <p>
 * 权限菜单表：树形结构，三级（目录/菜单/按钮），实现 RBAC 到按钮级粒度 服务实现类
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
@Service
public class SysPermissionServiceImpl extends ServiceImpl<SysPermissionMapper, SysPermission> implements ISysPermissionService {

}
