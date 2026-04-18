package com.cambook.app.service.admin.impl;

import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.cambook.app.constant.CacheKey;
import com.cambook.app.domain.dto.PermissionDTO;
import com.cambook.app.domain.vo.PermissionVO;
import com.cambook.app.event.MerchantMenuChangedEvent;
import com.cambook.app.service.admin.IPermissionService;
import com.cambook.common.enums.CbCodeEnum;
import com.cambook.common.exception.BusinessException;
import com.cambook.dao.entity.SysPermission;
import com.cambook.dao.mapper.SysPermissionMapper;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;
import java.util.concurrent.TimeUnit;
import java.util.stream.Collectors;

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
public class PermissionService implements IPermissionService {

    private static final long   PERM_CACHE_TTL  = 30L;
    private static final String WILDCARD        = "*";

    private final SysPermissionMapper    permissionMapper;
    private final StringRedisTemplate    redisTemplate;
    private final ApplicationEventPublisher eventPublisher;

    public PermissionService(SysPermissionMapper permissionMapper,
                             StringRedisTemplate redisTemplate,
                             ApplicationEventPublisher eventPublisher) {
        this.permissionMapper = permissionMapper;
        this.redisTemplate    = redisTemplate;
        this.eventPublisher   = eventPublisher;
    }

    // ── 公共查询 ──────────────────────────────────────────────────────────────

    @Override
    public List<PermissionVO> tree() {
        return PermissionVO.buildTree(permissionMapper.selectAllByPortalType(0));
    }

    @Override
    public List<PermissionVO> merchantMenuTree() {
        return PermissionVO.buildTree(permissionMapper.selectAllByPortalType(1));
    }

    // ── CRUD ──────────────────────────────────────────────────────────────────

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void add(PermissionDTO dto) {
        SysPermission p = new SysPermission();
        p.setParentId(dto.getParentId() != null ? dto.getParentId() : 0L);
        p.setName(dto.getName());
        p.setCode(dto.getCode());
        p.setType(dto.getType());
        p.setPath(dto.getPath());
        p.setComponent(dto.getComponent());
        p.setIcon(dto.getIcon());
        p.setSort(dto.getSort() != null ? dto.getSort() : 0);
        p.setVisible(dto.getVisible() != null ? dto.getVisible() : 1);
        p.setPortalType(dto.getPortalType() != null ? dto.getPortalType() : 0);
        p.setStatus(1);
        permissionMapper.insert(p);
        publishIfMerchant(p.getPortalType());
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void edit(PermissionDTO dto) {
        SysPermission p = permissionMapper.selectById(dto.getId());
        if (p == null) throw new BusinessException(CbCodeEnum.DATA_NOT_FOUND);

        // icon 仅在用户明确传值（非空白）时才更新，防止编辑排序/可见性时意外清空已配置的图标
        String newIcon = (dto.getIcon() != null && !dto.getIcon().isBlank())
                ? dto.getIcon() : p.getIcon();

        permissionMapper.update(
                Wrappers.<SysPermission>lambdaUpdate()
                        .set(SysPermission::getName,      dto.getName())
                        .set(SysPermission::getCode,      dto.getCode())
                        .set(SysPermission::getType,      dto.getType())
                        .set(SysPermission::getPath,      dto.getPath())
                        .set(SysPermission::getComponent, dto.getComponent())
                        .set(SysPermission::getIcon,      newIcon)
                        .set(SysPermission::getSort,      dto.getSort())
                        .set(SysPermission::getVisible,   dto.getVisible())
                        .eq(SysPermission::getId, dto.getId()));
        publishIfMerchant(p.getPortalType());
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void delete(Long id) {
        SysPermission p = permissionMapper.selectById(id);
        permissionMapper.update(
                Wrappers.<SysPermission>lambdaUpdate()
                        .set(SysPermission::getDeleted, 1)
                        .eq(SysPermission::getId, id));
        if (p != null) publishIfMerchant(p.getPortalType());
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void move(Long id, Long targetParentId, Integer sort) {
        SysPermission node = permissionMapper.selectById(id);
        if (node == null) throw new BusinessException(CbCodeEnum.DATA_NOT_FOUND);

        // 禁止移动到自身
        if (id.equals(targetParentId)) {
            throw new BusinessException("不能将节点移动到自身");
        }

        // 禁止移动到子孙节点（循环引用检测）
        if (targetParentId != null && targetParentId != 0 && isDescendant(id, targetParentId)) {
            throw new BusinessException("不能将节点移动到其子孙节点下");
        }

        // 验证目标父节点类型兼容性
        if (targetParentId != null && targetParentId != 0) {
            SysPermission targetParent = permissionMapper.selectById(targetParentId);
            if (targetParent == null) throw new BusinessException("目标父节点不存在");
            validateTypeCompatibility(node.getType(), targetParent.getType());
        } else if (node.getType() != 1) {
            // 根节点只接受目录（type=1）
            throw new BusinessException("只有目录类型的节点才能放置在根节点下");
        }

        permissionMapper.update(
                Wrappers.<SysPermission>lambdaUpdate()
                        .set(SysPermission::getParentId, targetParentId != null ? targetParentId : 0L)
                        .set(sort != null, SysPermission::getSort, sort)
                        .eq(SysPermission::getId, id));

        publishIfMerchant(node.getPortalType());
    }

    /** BFS 判断 checkId 是否是 ancestorId 的子孙节点 */
    private boolean isDescendant(Long ancestorId, Long checkId) {
        Queue<Long> queue = new LinkedList<>();
        queue.add(ancestorId);
        while (!queue.isEmpty()) {
            Long current = queue.poll();
            List<SysPermission> children = permissionMapper.selectList(
                    Wrappers.<SysPermission>lambdaQuery()
                            .eq(SysPermission::getParentId, current)
                            .eq(SysPermission::getDeleted,  0));
            for (SysPermission child : children) {
                if (child.getId().equals(checkId)) return true;
                queue.add(child.getId());
            }
        }
        return false;
    }

    /** 校验子节点类型与父节点类型的兼容关系 */
    private void validateTypeCompatibility(int nodeType, int parentType) {
        if (nodeType == 1 && parentType != 1) {
            throw new BusinessException("目录只能放置在根节点或其他目录下");
        }
        if (nodeType == 2 && parentType != 1) {
            throw new BusinessException("菜单只能放置在目录下");
        }
        if (nodeType == 3 && parentType != 2) {
            throw new BusinessException("操作权限只能放置在菜单下");
        }
    }

    /** 若为商户端权限，发布菜单变更事件，触发缓存失效 */
    private void publishIfMerchant(Integer portalType) {
        if (Integer.valueOf(1).equals(portalType)) {
            eventPublisher.publishEvent(new MerchantMenuChangedEvent(this));
        }
    }

    // ── 权限码（缓存） ─────────────────────────────────────────────────────────

    @Override
    public List<String> getPermCodesByUserId(Long userId) {
        // SUPER_ADMIN 直接返回通配符，绕过所有 RBAC 检查并获取全量菜单 / 全量按钮
        if (permissionMapper.isSuperAdmin(userId)) {
            return List.of(WILDCARD);
        }

        String cacheKey = CacheKey.ADMIN_PERMS + userId;
        List<String> cached = redisTemplate.opsForList().range(cacheKey, 0, -1);
        if (cached != null && !cached.isEmpty()) return cached;

        List<String> codes = permissionMapper.selectPermCodesByUserId(userId);
        if (!codes.isEmpty()) {
            redisTemplate.opsForList().rightPushAll(cacheKey, codes);
            redisTemplate.expire(cacheKey, PERM_CACHE_TTL, TimeUnit.MINUTES);
        }
        return codes;
    }

    // ── 动态菜单树 ────────────────────────────────────────────────────────────

    /**
     * 根据用户权限返回菜单树（type=1,2）。
     *
     * <ul>
     *   <li>SUPER_ADMIN（含 {@code *}）→ 全量可见菜单</li>
     *   <li>普通角色 → 仅包含用户有 code 的叶菜单，空目录自动剔除</li>
     * </ul>
     */
    @Override
    public List<PermissionVO> getMenuTreeByUserId(Long userId) {
        List<SysPermission> allMenus = permissionMapper.selectAllVisibleMenus();

        List<String> permCodes = getPermCodesByUserId(userId);
        if (permCodes.contains(WILDCARD)) {
            return PermissionVO.buildTree(allMenus);
        }

        Set<String> permSet    = new HashSet<>(permCodes);
        Set<Long>   accessIds  = resolveAccessibleIds(allMenus, permSet);
        List<SysPermission> filtered = allMenus.stream()
                .filter(m -> accessIds.contains(m.getId()))
                .collect(Collectors.toList());

        return PermissionVO.buildTree(filtered);
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
            if (m.getType() != 2) continue;
            // 叶菜单无 code 或 code 在权限集内 → 可访问
            if (m.getCode() == null || permCodes.contains(m.getCode())) {
                result.add(m.getId());
                // 向上追溯父节点
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
