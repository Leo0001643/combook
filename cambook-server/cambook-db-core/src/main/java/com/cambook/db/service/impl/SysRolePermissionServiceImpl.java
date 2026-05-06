package com.cambook.db.service.impl;

import com.cambook.db.entity.SysRolePermission;
import com.cambook.db.mapper.SysRolePermissionMapper;
import com.cambook.db.service.ISysRolePermissionService;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.springframework.stereotype.Service;

/**
 * <p>
 * 角色权限关联表：多对多，记录角色拥有的权限项 服务实现类
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
@Service
public class SysRolePermissionServiceImpl extends ServiceImpl<SysRolePermissionMapper, SysRolePermission> implements ISysRolePermissionService {

}
