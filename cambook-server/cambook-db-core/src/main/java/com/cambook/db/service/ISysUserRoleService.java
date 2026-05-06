package com.cambook.db.service;

import com.cambook.db.entity.SysUserRole;
import com.baomidou.mybatisplus.extension.service.IService;

/**
 * <p>
 * 管理员角色关联表：多对多，记录管理员所持有的角色 服务类
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
public interface ISysUserRoleService extends IService<SysUserRole> {

}
