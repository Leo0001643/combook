package com.cambook.app.service.admin;

import com.cambook.app.domain.dto.RoleDTO;
import com.cambook.app.domain.vo.RoleVO;

import java.util.List;

/**
 * 角色管理服务
 *
 * @author CamBook
 */
public interface IRoleService {

    List<RoleVO> list();

    void add(RoleDTO dto);

    void edit(RoleDTO dto);

    void delete(Long id);

    /** 查询角色已分配的权限 ID 列表 */
    List<Long> getPermissionIds(Long roleId);

    /** 保存角色-权限关联（全量替换，同时清理相关用户权限缓存） */
    void savePermissions(Long roleId, List<Long> permissionIds);
}
