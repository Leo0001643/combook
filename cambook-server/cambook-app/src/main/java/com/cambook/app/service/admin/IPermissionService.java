package com.cambook.app.service.admin;

import com.cambook.app.domain.dto.PermissionDTO;
import com.cambook.app.domain.vo.PermissionVO;

import java.util.List;

/**
 * 权限管理服务
 *
 * @author CamBook
 */
public interface IPermissionService {

    /** 管理端权限完整树（portal_type=0，含按钮级，用于权限配置页） */
    List<PermissionVO> tree();

    /** 商户端菜单完整树（portal_type=1，用于权限配置页商户菜单 Tab） */
    List<PermissionVO> merchantMenuTree();

    void add(PermissionDTO dto);

    void edit(PermissionDTO dto);

    void delete(Long id);

    /**
     * 移动权限节点到指定父节点，并可同步更新排序值。
     *
     * <p>安全约束：
     * <ul>
     *   <li>禁止移动到自身</li>
     *   <li>禁止移动到自身的子孙节点（循环引用）</li>
     *   <li>类型兼容性：目录→目录/根，菜单→目录，操作→菜单</li>
     * </ul>
     *
     * @param id             被移动节点 ID
     * @param targetParentId 目标父节点 ID（0 表示根节点）
     * @param sort           新排序值（null 则不修改）
     */
    void move(Long id, Long targetParentId, Integer sort);

    /** 查询指定用户拥有的权限编码集合（含缓存） */
    List<String> getPermCodesByUserId(Long userId);

    /**
     * 根据用户权限构建动态菜单树（仅 type=1,2，SUPER_ADMIN 返回全部可见菜单）
     *
     * @param userId 管理员 ID
     * @return 菜单树（已过滤无权限项，目录无子节点时自动剔除）
     */
    List<PermissionVO> getMenuTreeByUserId(Long userId);
}
