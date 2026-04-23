package com.cambook.dao.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.cambook.dao.entity.SysPermission;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

/**
 * 权限/菜单 Mapper
 *
 * @author CamBook
 */
@Mapper
public interface SysPermissionMapper extends BaseMapper<SysPermission> {

    /** 查询用户所有角色下的权限标识（用于缓存），SQL 见 SysPermissionMapper.xml */
    List<String> selectPermCodesByUserId(@Param("userId") Long userId);

    /** 查询管理端所有可见菜单（portal_type=0），SQL 见 SysPermissionMapper.xml */
    List<SysPermission> selectAllVisibleMenus();

    /** 查询商户端所有可见菜单（portal_type=1），SQL 见 SysPermissionMapper.xml */
    List<SysPermission> selectAllVisibleMerchantMenus();

    /** 按门户类型查询完整权限树（含按钮级），SQL 见 SysPermissionMapper.xml */
    List<SysPermission> selectAllByPortalType(@Param("portalType") int portalType);

    /** 查询用户可访问的菜单权限标识（type=1,2），SQL 见 SysPermissionMapper.xml */
    List<String> selectMenuCodesByUserId(@Param("userId") Long userId);

    /** 判断用户是否拥有 SUPER_ADMIN 角色，SQL 见 SysPermissionMapper.xml */
    boolean isSuperAdmin(@Param("userId") Long userId);
}
