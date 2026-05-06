package com.cambook.db.service.impl;

import com.cambook.db.entity.SysRole;
import com.cambook.db.mapper.SysRoleMapper;
import com.cambook.db.service.ISysRoleService;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.springframework.stereotype.Service;

/**
 * <p>
 * 角色表：定义 RBAC 角色，一角色可关联多个权限，一管理员可持有多个角色 服务实现类
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
@Service
public class SysRoleServiceImpl extends ServiceImpl<SysRoleMapper, SysRole> implements ISysRoleService {

}
