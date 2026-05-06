package com.cambook.db.service;

import com.cambook.db.entity.SysUser;
import com.baomidou.mybatisplus.extension.service.IService;

/**
 * <p>
 * 后台管理员账号表：支持账号密码登录，关联角色进行 RBAC 权限控制 服务类
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
public interface ISysUserService extends IService<SysUser> {

}
