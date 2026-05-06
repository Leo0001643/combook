package com.cambook.db.service.impl;

import com.cambook.db.entity.SysUserRole;
import com.cambook.db.mapper.SysUserRoleMapper;
import com.cambook.db.service.ISysUserRoleService;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.springframework.stereotype.Service;

/**
 * <p>
 * 管理员角色关联表：多对多，记录管理员所持有的角色 服务实现类
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
@Service
public class SysUserRoleServiceImpl extends ServiceImpl<SysUserRoleMapper, SysUserRole> implements ISysUserRoleService {

}
