package com.cambook.db.service.impl;

import com.cambook.db.entity.SysUser;
import com.cambook.db.mapper.SysUserMapper;
import com.cambook.db.service.ISysUserService;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.springframework.stereotype.Service;

/**
 * <p>
 * 后台管理员账号表：支持账号密码登录，关联角色进行 RBAC 权限控制 服务实现类
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
@Service
public class SysUserServiceImpl extends ServiceImpl<SysUserMapper, SysUser> implements ISysUserService {

}
