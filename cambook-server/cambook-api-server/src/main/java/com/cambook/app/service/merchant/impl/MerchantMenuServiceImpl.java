package com.cambook.app.service.merchant.impl;

import com.cambook.app.constant.CacheKey;
import com.cambook.common.enums.CommonStatus;
import com.cambook.app.domain.vo.PermissionVO;
import com.cambook.app.event.MerchantMenuChangedEvent;
import com.cambook.app.service.admin.impl.PermissionService;
import com.cambook.app.service.merchant.IMerchantMenuService;
import com.cambook.db.entity.CbMerchantStaff;
import com.cambook.db.entity.SysDeptMenu;
import com.cambook.db.entity.SysPermission;
import com.cambook.db.entity.SysPosition;
import com.cambook.db.entity.SysPositionMenu;
import com.cambook.db.entity.SysStaffMenu;
import com.cambook.db.service.ISysDeptMenuService;
import com.cambook.db.service.ISysPermissionService;
import com.cambook.db.service.ISysPositionMenuService;
import com.cambook.db.service.ISysPositionService;
import com.cambook.db.service.ISysStaffMenuService;
import lombok.RequiredArgsConstructor;
import org.springframework.context.event.EventListener;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;

import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.concurrent.TimeUnit;
import java.util.function.Function;
import java.util.stream.Collectors;
import java.util.stream.Stream;

/**
 * 商户端菜单服务实现
 *
 * <p>缓存策略：商户端菜单路径列表存 Redis，TTL 30 分钟；
 * 管理员修改权限时通过 {@link MerchantMenuChangedEvent} 主动失效，零延迟生效。
 *
 * @author CamBook
 */
@Service
@RequiredArgsConstructor
public class MerchantMenuServiceImpl implements IMerchantMenuService {

    private static final long CACHE_TTL_MINUTES = 30L;
    private static final int  TYPE_MENU         = 2;

    private final ISysPermissionService  sysPermissionService;
    private final ISysPositionService    sysPositionService;
    private final ISysDeptMenuService    sysDeptMenuService;
    private final ISysPositionMenuService sysPositionMenuService;
    private final ISysStaffMenuService   sysStaffMenuService;
    private final PermissionService      permissionService;
    private final StringRedisTemplate    redisTemplate;

    // ── 全量菜单路径（含缓存） ────────────────────────────────────────────────

    @Override
    public List<String> allMenuPaths() {
        List<String> cached = redisTemplate.opsForList().range(CacheKey.MERCHANT_MENUS, 0, -1);
        if (cached != null && !cached.isEmpty()) return cached;

        List<String> paths = permissionService.allVisibleMerchantMenus().stream()
                .filter(p -> p.getType() == TYPE_MENU && p.getPath() != null)
                .map(SysPermission::getPath)
                .collect(Collectors.toList());

        if (!paths.isEmpty()) {
            redisTemplate.opsForList().rightPushAll(CacheKey.MERCHANT_MENUS, paths);
            redisTemplate.expire(CacheKey.MERCHANT_MENUS, CACHE_TTL_MINUTES, TimeUnit.MINUTES);
        }
        return paths;
    }

    @Override
    public void evictCache() {
        redisTemplate.delete(CacheKey.MERCHANT_MENUS);
    }

    @EventListener(MerchantMenuChangedEvent.class)
    void onMerchantMenuChanged() {
        evictCache();
    }

    // ── RBAC 链解析 ──────────────────────────────────────────────────────────

    @Override
    public List<String> resolveEffectivePaths(Long merchantId, CbMerchantStaff staff) {
        if (staff == null) return null;

        if (staff.getPositionId() != null) {
            SysPosition pos = sysPositionService.getById(staff.getPositionId());
            if (pos != null && Byte.valueOf((byte) 1).equals(pos.getFullAccess())) return null;
        }

        return Stream.of(
                        staffPaths(merchantId, staff.getId()),
                        positionPaths(merchantId, staff.getPositionId()),
                        deptPaths(merchantId, staff.getDeptId()))
                .filter(list -> !list.isEmpty())
                .findFirst()
                .orElse(null);
    }

    // ── 操作权限码解析 ────────────────────────────────────────────────────────

    @Override
    public List<String> resolveEffectiveCodes(Long merchantId, CbMerchantStaff staff) {
        if (staff == null) return List.of("*");
        List<String> allKeys = resolveEffectivePaths(merchantId, staff);
        if (allKeys == null) return List.of("*");
        return allKeys.stream()
                .filter(k -> k.contains(":") && !k.startsWith("/"))
                .collect(Collectors.toList());
    }

    // ── 菜单树构建 ────────────────────────────────────────────────────────────

    @Override
    public List<PermissionVO> buildMenuTree(List<String> paths) {
        List<SysPermission> allMenus = permissionService.allVisibleMerchantMenus();
        if (paths == null) return PermissionVO.buildTree(allMenus);

        Set<String>              pathSet = new HashSet<>(paths);
        Map<Long, SysPermission> idMap   = allMenus.stream()
                .collect(Collectors.toMap(SysPermission::getId, m -> m));

        Set<Long> accessIds = allMenus.stream()
                .filter(m -> m.getType() == TYPE_MENU && m.getPath() != null && pathSet.contains(m.getPath()))
                .flatMap(m -> ancestorIds(m, idMap))
                .collect(Collectors.toSet());

        return PermissionVO.buildTree(
                allMenus.stream().filter(m -> accessIds.contains(m.getId())).collect(Collectors.toList()));
    }

    // ── 私有辅助方法 ─────────────────────────────────────────────────────────

    private Stream<Long> ancestorIds(SysPermission leaf, Map<Long, SysPermission> idMap) {
        Set<Long> ids = new HashSet<>();
        ids.add(leaf.getId());
        long pid = leaf.getParentId() != null ? leaf.getParentId() : 0L;
        while (pid > 0 && idMap.containsKey(pid)) {
            ids.add(pid);
            pid = Optional.ofNullable(idMap.get(pid).getParentId()).orElse(0L);
        }
        return ids.stream();
    }

    private List<String> staffPaths(Long merchantId, Long staffId) {
        return sysStaffMenuService.lambdaQuery()
                .eq(SysStaffMenu::getStaffId, staffId)
                .eq(SysStaffMenu::getMerchantId, merchantId)
                .list()
                .stream().map(SysStaffMenu::getMenuKey).collect(Collectors.toList());
    }

    private List<String> positionPaths(Long merchantId, Long positionId) {
        if (positionId == null) return List.of();
        return sysPositionMenuService.lambdaQuery()
                .eq(SysPositionMenu::getPositionId, positionId)
                .eq(SysPositionMenu::getMerchantId, merchantId)
                .list()
                .stream().map(SysPositionMenu::getMenuKey).collect(Collectors.toList());
    }

    private List<String> deptPaths(Long merchantId, Long deptId) {
        if (deptId == null) return List.of();
        return sysDeptMenuService.lambdaQuery()
                .eq(SysDeptMenu::getDeptId, deptId).eq(SysDeptMenu::getMerchantId, merchantId)
                .list().stream().map(SysDeptMenu::getMenuKey).collect(Collectors.toList());
    }

    // ── RBAC 分配（事务原子替换）────────────────────────────────────────────────

    @Override
    @org.springframework.transaction.annotation.Transactional(rollbackFor = Exception.class)
    public void assignDeptMenus(Long merchantId, Long deptId, List<String> menuKeys) {
        validateMenuKeys(menuKeys);
        sysDeptMenuService.lambdaUpdate()
                .eq(SysDeptMenu::getDeptId, deptId).eq(SysDeptMenu::getMerchantId, merchantId).remove();
        for (String key : menuKeys) {
            SysDeptMenu row = new SysDeptMenu();
            row.setMerchantId(merchantId); row.setDeptId(deptId); row.setMenuKey(key);
            sysDeptMenuService.save(row);
        }
    }

    @Override
    @org.springframework.transaction.annotation.Transactional(rollbackFor = Exception.class)
    public void assignPositionMenus(Long merchantId, Long positionId, List<String> menuKeys) {
        validateMenuKeys(menuKeys);
        sysPositionMenuService.lambdaUpdate()
                .eq(SysPositionMenu::getPositionId, positionId).eq(SysPositionMenu::getMerchantId, merchantId).remove();
        for (String key : menuKeys) {
            SysPositionMenu row = new SysPositionMenu();
            row.setMerchantId(merchantId); row.setPositionId(positionId); row.setMenuKey(key);
            sysPositionMenuService.save(row);
        }
    }

    @Override
    @org.springframework.transaction.annotation.Transactional(rollbackFor = Exception.class)
    public void assignStaffMenus(Long merchantId, Long staffId, List<String> menuKeys) {
        validateMenuKeys(menuKeys);
        sysStaffMenuService.lambdaUpdate()
                .eq(SysStaffMenu::getStaffId, staffId).eq(SysStaffMenu::getMerchantId, merchantId).remove();
        for (String key : menuKeys) {
            SysStaffMenu row = new SysStaffMenu();
            row.setMerchantId(merchantId); row.setStaffId(staffId); row.setMenuKey(key);
            sysStaffMenuService.save(row);
        }
    }

    private void validateMenuKeys(List<String> keys) {
        if (keys == null || keys.isEmpty()) return;
        Set<String> validPaths = new HashSet<>(allMenuPaths());
        keys.stream().filter(k -> k.startsWith("/") && !validPaths.contains(k)).findFirst()
                .ifPresent(k -> { throw new com.cambook.common.exception.BusinessException("非法菜单key: " + k); });
    }

    // ── 权限查询（供 MerchantPermController 读取已分配权限）─────────────────

    @Override
    public List<String> getDeptMenuKeys(Long merchantId, Long deptId) {
        return sysDeptMenuService.lambdaQuery()
                .eq(SysDeptMenu::getDeptId, deptId).eq(SysDeptMenu::getMerchantId, merchantId)
                .list().stream().map(SysDeptMenu::getMenuKey).collect(Collectors.toList());
    }

    @Override
    public List<String> getPositionMenuKeys(Long merchantId, Long positionId) {
        return sysPositionMenuService.lambdaQuery()
                .eq(SysPositionMenu::getPositionId, positionId).eq(SysPositionMenu::getMerchantId, merchantId)
                .list().stream().map(SysPositionMenu::getMenuKey).collect(Collectors.toList());
    }

    @Override
    public List<String> getStaffMenuKeys(Long merchantId, Long staffId) {
        return sysStaffMenuService.lambdaQuery()
                .eq(SysStaffMenu::getStaffId, staffId).eq(SysStaffMenu::getMerchantId, merchantId)
                .list().stream().map(SysStaffMenu::getMenuKey).collect(Collectors.toList());
    }

    @Override
    public List<SysPosition> getDeptPositions(Long merchantId, Long deptId) {
        return sysPositionService.lambdaQuery()
                .eq(SysPosition::getMerchantId, merchantId).eq(SysPosition::getDeptId, deptId)
                .eq(SysPosition::getStatus, CommonStatus.ENABLED.getCode()).orderByAsc(SysPosition::getSort).list();
    }
}
