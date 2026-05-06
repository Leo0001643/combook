package com.cambook.db.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.cambook.db.entity.SysPermission;
import org.apache.ibatis.annotations.Param;

import java.util.List;

/**
 * <p>
 * 权限菜单表：树形结构，三级（目录/菜单/按钮），实现 RBAC 到按钮级粒度 Mapper 接口
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
public interface SysPermissionMapper extends BaseMapper<SysPermission> {

    List<String>        selectPermCodesByUserId(@Param("userId") Long userId);
    List<String>        selectMenuCodesByUserId(@Param("userId") Long userId);
    List<SysPermission> selectAllVisibleMenus();
    List<SysPermission> selectAllVisibleMerchantMenus();
    List<SysPermission> selectAllByPortalType(@Param("portalType") int portalType);
    boolean             isSuperAdmin(@Param("userId") Long userId);
}
