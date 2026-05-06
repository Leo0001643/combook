package com.cambook.db.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.cambook.db.entity.SysUser;

/**
 * <p>
 * 后台管理员账号表：支持账号密码登录，关联角色进行 RBAC 权限控制 Mapper 接口
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
public interface SysUserMapper extends BaseMapper<SysUser> {

}
