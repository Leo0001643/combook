package com.cambook.dao.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.cambook.dao.entity.SysPermission;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

import java.util.List;

/**
 * 权限/菜单 Mapper
 *
 * @author CamBook
 */
@Mapper
public interface SysPermissionMapper extends BaseMapper<SysPermission> {

    /**
     * 通过用户 ID 查询其所有角色下的权限标识（用于缓存）
     */
    @Select("SELECT DISTINCT p.code FROM sys_permission p " +
            "INNER JOIN sys_role_permission rp ON rp.permission_id = p.id " +
            "INNER JOIN sys_user_role ur ON ur.role_id = rp.role_id " +
            "WHERE ur.user_id = #{userId} " +
            "AND p.deleted = 0 AND p.status = 1 AND p.code IS NOT NULL")
    List<String> selectPermCodesByUserId(@Param("userId") Long userId);

    /**
     * 查询管理端所有可见菜单（portal_type=0），用于动态菜单构建
     */
    @Select("SELECT * FROM sys_permission " +
            "WHERE deleted = 0 AND status = 1 AND visible = 1 AND type IN (1, 2) AND portal_type = 0 " +
            "ORDER BY sort ASC")
    List<SysPermission> selectAllVisibleMenus();

    /**
     * 查询商户端所有可见菜单（portal_type=1），用于动态菜单构建与 RBAC 分配
     */
    @Select("SELECT * FROM sys_permission " +
            "WHERE deleted = 0 AND status = 1 AND visible = 1 AND type IN (1, 2) AND portal_type = 1 " +
            "ORDER BY sort ASC")
    List<SysPermission> selectAllVisibleMerchantMenus();

    /**
     * 按门户类型查询完整权限树（含按钮级），用于管理员权限配置页
     */
    @Select("SELECT * FROM sys_permission " +
            "WHERE deleted = 0 AND portal_type = #{portalType} " +
            "ORDER BY sort ASC")
    List<SysPermission> selectAllByPortalType(@Param("portalType") int portalType);

    /**
     * 查询指定用户可访问的菜单权限标识（type=1,2 且有 code）
     */
    @Select("SELECT DISTINCT p.code FROM sys_permission p " +
            "INNER JOIN sys_role_permission rp ON rp.permission_id = p.id " +
            "INNER JOIN sys_user_role ur ON ur.role_id = rp.role_id " +
            "WHERE ur.user_id = #{userId} " +
            "AND p.deleted = 0 AND p.status = 1 AND p.type IN (1, 2) AND p.code IS NOT NULL")
    List<String> selectMenuCodesByUserId(@Param("userId") Long userId);

    /**
     * 判断用户是否拥有 SUPER_ADMIN 角色（用于通配符权限注入）
     */
    @Select("SELECT COUNT(1) > 0 FROM sys_user_role ur " +
            "INNER JOIN sys_role r ON r.id = ur.role_id " +
            "WHERE ur.user_id = #{userId} AND r.role_code = 'SUPER_ADMIN' AND r.deleted = 0")
    boolean isSuperAdmin(@Param("userId") Long userId);
}
