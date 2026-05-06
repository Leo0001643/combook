package com.cambook.app.service.admin.impl;

import com.cambook.app.constant.CacheKey;
import com.cambook.app.domain.dto.PermissionDTO;
import com.cambook.app.domain.vo.PermissionVO;
import com.cambook.app.event.MerchantMenuChangedEvent;
import com.cambook.app.service.admin.IPermissionService;
import com.cambook.common.enums.CbCodeEnum;
import com.cambook.common.exception.BusinessException;
import com.cambook.db.entity.SysPermission;
import com.cambook.db.entity.SysRole;
import com.cambook.db.entity.SysRolePermission;
import com.cambook.db.entity.SysUserRole;
import com.cambook.db.service.ISysPermissionService;
import com.cambook.db.service.ISysRolePermissionService;
import com.cambook.db.service.ISysRoleService;
import com.cambook.db.service.ISysUserRoleService;
import lombok.RequiredArgsConstructor;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Collections;
import java.util.HashSet;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Queue;
import java.util.Set;
import java.util.concurrent.TimeUnit;
import java.util.stream.Collectors;
import com.cambook.common.enums.CommonStatus;

/**
 * 权限管理服务实现
 *
 * <p>权限体系三层架构：
 * <pre>
 *   目录(type=1) → 菜单(type=2) → 按钮/接口(type=3)
 * </pre>
 * SUPER_ADMIN 拥有通配符 {@code *}，绕过所有权限检查并获取全量菜单。
 *
 * @author CamBook
 */
@Service
@RequiredArgsConstructor
public class PermissionService implements IPermissionService {

    private static final long   PERM_CACHE_TTL = 30L;
    private static final String WILDCARD       = "*";
    private static final String ROLE_SUPER_ADMIN = "SUPER_ADMIN";
    private static final int    TYPE_DIR    = 1;
    private static final int    TYPE_MENU   = 2;
    private static final int    TYPE_BUTTON = 3;
    private static final int    VISIBLE     = 1;

    private final ISysPermissionService     sysPermissionService;
    private final ISysUserRoleService       sysUserRoleService;
    private final ISysRoleService           sysRoleService;
    private final ISysRolePermissionService sysRolePermissionService;
    private final StringRedisTemplate       redisTemplate;
    private final ApplicationEventPublisher eventPublisher;

    // ── 公共查询 ──────────────────────────────────────────────────────────────

    @Override
    public List<PermissionVO> tree() {
        return PermissionVO.buildTree(allByPortalType(0));
    }

    @Override
    public List<PermissionVO> merchantMenuTree() {
        return PermissionVO.buildTree(allByPortalType(1));
    }

    // ── CRUD ──────────────────────────────────────────────────────────────────

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void add(PermissionDTO dto) {
        SysPermission p = new SysPermission();
        p.setParentId(dto.getParentId() != null ? dto.getParentId() : 0L);
        p.setName(dto.getName());
        p.setCode(dto.getCode());
        p.setType(dto.getType() == null ? null : dto.getType().byteValue());
        p.setPath(dto.getPath());
        p.setComponent(dto.getComponent());
        p.setIcon(dto.getIcon());
        p.setSort(dto.getSort() != null ? dto.getSort() : 0);
        p.setVisible(dto.getVisible() != null ? dto.getVisible().byteValue() : CommonStatus.ENABLED.byteCode());
        p.setPortalType(dto.getPortalType() != null ? dto.getPortalType().byteValue() : (byte)0);
        p.setStatus(CommonStatus.ENABLED.byteCode());
        sysPermissionService.save(p);
        publishIfMerchant(p.getPortalType() != null ? p.getPortalType().intValue() : null);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void edit(PermissionDTO dto) {
        SysPermission p = Optional.ofNullable(sysPermissionService.getById(dto.getId()))
                .orElseThrow(() -> new BusinessException(CbCodeEnum.DATA_NOT_FOUND));

        String newIcon = (dto.getIcon() != null && !dto.getIcon().isBlank()) ? dto.getIcon() : p.getIcon();

        sysPermissionService.lambdaUpdate()
                .set(SysPermission::getName,      dto.getName())
                .set(SysPermission::getCode,      dto.getCode())
                .set(SysPermission::getType,      dto.getType())
                .set(SysPermission::getPath,      dto.getPath())
                .set(SysPermission::getComponent, dto.getComponent())
                .set(SysPermission::getIcon,      newIcon)
                .set(SysPermission::getSort,      dto.getSort())
                .set(SysPermission::getVisible, dto.getVisible() == null ? null : dto.getVisible().byteValue())
                .eq(SysPermission::getId, dto.getId())
                .update();
        publishIfMerchant(p.getPortalType() != null ? p.getPortalType().intValue() : null);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void delete(Long id) {
        SysPermission p = sysPermissionService.getById(id);
        sysPermissionService.lambdaUpdate()
                .set(SysPermission::getDeleted, (byte)1)
                .eq(SysPermission::getId, id)
                .update();
        if (p != null) publishIfMerchant(p.getPortalType() != null ? p.getPortalType().intValue() : null);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void move(Long id, Long targetParentId, Integer sort) {
        SysPermission node = Optional.ofNullable(sysPermissionService.getById(id))
                .orElseThrow(() -> new BusinessException(CbCodeEnum.DATA_NOT_FOUND));

        if (id.equals(targetParentId)) throw new BusinessException(CbCodeEnum.PERM_MOVE_TO_SELF);

        if (targetParentId != null && targetParentId != 0 && isDescendant(id, targetParentId)) {
            throw new BusinessException(CbCodeEnum.PERM_MOVE_TO_DESCENDANT);
        }

        if (targetParentId != null && targetParentId != 0) {
            SysPermission targetParent = Optional.ofNullable(sysPermissionService.getById(targetParentId))
                    .orElseThrow(() -> new BusinessException("目标父节点不存在"));
            validateTypeCompatibility(node.getType(), targetParent.getType());
        } else if (node.getType() != TYPE_DIR) {
            throw new BusinessException(CbCodeEnum.PERM_NODE_PLACEMENT_INVALID);
        }

        sysPermissionService.lambdaUpdate()
                .set(SysPermission::getParentId, targetParentId != null ? targetParentId : 0L)
                .set(sort != null, SysPermission::getSort, sort)
                .eq(SysPermission::getId, id)
                .update();

        publishIfMerchant(node.getPortalType() != null ? node.getPortalType().intValue() : null);
    }

    // ── 权限码（缓存） ─────────────────────────────────────────────────────────

    @Override
    public List<String> getPermCodesByUserId(Long userId) {
        if (isSuperAdmin(userId)) return List.of(WILDCARD);

        String cacheKey = CacheKey.ADMIN_PERMS + userId;
        List<String> cached = redisTemplate.opsForList().range(cacheKey, 0, -1);
        if (cached != null && !cached.isEmpty()) return cached;

        List<String> codes = resolvePermCodesByUserId(userId);
        if (!codes.isEmpty()) {
            redisTemplate.opsForList().rightPushAll(cacheKey, codes);
            redisTemplate.expire(cacheKey, PERM_CACHE_TTL, TimeUnit.MINUTES);
        }
        return codes;
    }

    // ── 动态菜单树 ────────────────────────────────────────────────────────────

    @Override
    public List<PermissionVO> getMenuTreeByUserId(Long userId) {
        List<SysPermission> allMenus = allVisibleMenus();

        List<String> permCodes = getPermCodesByUserId(userId);
        if (permCodes.contains(WILDCARD)) {
            return PermissionVO.buildTree(allMenus);
        }

        Set<String>  permSet   = new HashSet<>(permCodes);
        Set<Long>    accessIds = resolveAccessibleIds(allMenus, permSet);
        List<SysPermission> filtered = allMenus.stream()
                .filter(m -> accessIds.contains(m.getId()))
                .collect(Collectors.toList());

        return PermissionVO.buildTree(filtered);
    }

    // ── 私有：lambdaQuery 替代自定义 Mapper SQL ───────────────────────────────

    /** 按门户类型查全量权限 */
    private List<SysPermission> allByPortalType(int portalType) {
        return sysPermissionService.lambdaQuery()
                .eq(SysPermission::getPortalType, portalType)
                .eq(SysPermission::getDeleted, 0)
                .orderByAsc(SysPermission::getSort)
                .list();
    }

    /** 全量可见菜单（type=1,2，visible=1） */
    private List<SysPermission> allVisibleMenus() {
        return sysPermissionService.lambdaQuery()
                .in(SysPermission::getType, List.of(TYPE_DIR, TYPE_MENU))
                .eq(SysPermission::getVisible, VISIBLE)
                .eq(SysPermission::getDeleted, 0)
                .orderByAsc(SysPermission::getSort)
                .list();
    }

    /** 商户端全量可见菜单 */
    public List<SysPermission> allVisibleMerchantMenus() {
        return sysPermissionService.lambdaQuery()
                .eq(SysPermission::getPortalType, 1)
                .in(SysPermission::getType, List.of(TYPE_DIR, TYPE_MENU))
                .eq(SysPermission::getVisible, VISIBLE)
                .eq(SysPermission::getDeleted, 0)
                .orderByAsc(SysPermission::getSort)
                .list();
    }

    /** 判断是否超级管理员（拥有 SUPER_ADMIN 角色） */
    private boolean isSuperAdmin(Long userId) {
        List<Long> roleIds = sysUserRoleService.lambdaQuery()
                .eq(SysUserRole::getUserId, userId)
                .list()
                .stream().map(SysUserRole::getRoleId).collect(Collectors.toList());
        if (roleIds.isEmpty()) return false;
        return sysRoleService.lambdaQuery()
                .in(SysRole::getId, roleIds)
                .eq(SysRole::getRoleCode, ROLE_SUPER_ADMIN)
                .exists();
    }

    /** 多步骤解析用户权限码：用户→角色→角色权限→权限码 */
    private List<String> resolvePermCodesByUserId(Long userId) {
        List<Long> roleIds = sysUserRoleService.lambdaQuery()
                .eq(SysUserRole::getUserId, userId)
                .list()
                .stream().map(SysUserRole::getRoleId).collect(Collectors.toList());
        if (roleIds.isEmpty()) return Collections.emptyList();

        List<Long> permIds = sysRolePermissionService.lambdaQuery()
                .in(SysRolePermission::getRoleId, roleIds)
                .list()
                .stream().map(SysRolePermission::getPermissionId).collect(Collectors.toList());
        if (permIds.isEmpty()) return Collections.emptyList();

        return sysPermissionService.lambdaQuery()
                .in(SysPermission::getId, permIds)
                .isNotNull(SysPermission::getCode)
                .eq(SysPermission::getDeleted, 0)
                .list()
                .stream().map(SysPermission::getCode).collect(Collectors.toList());
    }

    /** BFS 判断 checkId 是否是 ancestorId 的子孙节点 */
    private boolean isDescendant(Long ancestorId, Long checkId) {
        Queue<Long> queue = new LinkedList<>();
        queue.add(ancestorId);
        while (!queue.isEmpty()) {
            Long current = queue.poll();
            List<SysPermission> children = sysPermissionService.lambdaQuery()
                    .eq(SysPermission::getParentId, current)
                    .eq(SysPermission::getDeleted, 0)
                    .list();
            for (SysPermission child : children) {
                if (child.getId().equals(checkId)) return true;
                queue.add(child.getId());
            }
        }
        return false;
    }

    private void validateTypeCompatibility(int nodeType, int parentType) {
        if (nodeType == TYPE_DIR && parentType != TYPE_DIR) throw new BusinessException(CbCodeEnum.PERM_NODE_PLACEMENT_INVALID);
        if (nodeType == TYPE_MENU && parentType != TYPE_DIR) throw new BusinessException(CbCodeEnum.PERM_NODE_PLACEMENT_INVALID);
        if (nodeType == TYPE_BUTTON && parentType != TYPE_MENU) throw new BusinessException(CbCodeEnum.PERM_NODE_PLACEMENT_INVALID);
    }

    private void publishIfMerchant(Integer portalType) {
        if (portalType != null && portalType == 1) {
            eventPublisher.publishEvent(new MerchantMenuChangedEvent(this));
        }
    }

    /**
     * 两步扩散算法：
     * <ol>
     *   <li>找出用户有权访问的叶菜单（type=2）</li>
     *   <li>向上追溯其所有祖先目录，保证目录不为空</li>
     * </ol>
     */
    private Set<Long> resolveAccessibleIds(List<SysPermission> allMenus, Set<String> permCodes) {
        Map<Long, SysPermission> idMap = allMenus.stream()
                .collect(Collectors.toMap(SysPermission::getId, m -> m));

        Set<Long> result = new HashSet<>();
        for (SysPermission m : allMenus) {
            if (m.getType() != TYPE_MENU) continue;
            if (m.getCode() == null || permCodes.contains(m.getCode())) {
                result.add(m.getId());
                long pid = m.getParentId() != null ? m.getParentId() : 0L;
                while (pid > 0 && idMap.containsKey(pid)) {
                    result.add(pid);
                    SysPermission parent = idMap.get(pid);
                    pid = parent.getParentId() != null ? parent.getParentId() : 0L;
                }
            }
        }
        return result;
    }
}
