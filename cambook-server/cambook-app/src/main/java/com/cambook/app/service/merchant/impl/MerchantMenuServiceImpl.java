package com.cambook.app.service.merchant.impl;

import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.cambook.app.constant.CacheKey;
import com.cambook.app.domain.vo.PermissionVO;
import com.cambook.app.event.MerchantMenuChangedEvent;
import com.cambook.app.service.merchant.IMerchantMenuService;
import com.cambook.dao.entity.*;
import com.cambook.dao.mapper.*;
import org.springframework.context.event.EventListener;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;

import java.util.*;
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
public class MerchantMenuServiceImpl implements IMerchantMenuService {

    private static final long CACHE_TTL_MINUTES = 30L;

    private final SysPermissionMapper  permissionMapper;
    private final SysPositionMapper    positionMapper;
    private final SysDeptMenuMapper    deptMenuMapper;
    private final SysPositionMenuMapper positionMenuMapper;
    private final SysStaffMenuMapper   staffMenuMapper;
    private final StringRedisTemplate  redisTemplate;

    public MerchantMenuServiceImpl(SysPermissionMapper permissionMapper,
                                   SysPositionMapper positionMapper,
                                   SysDeptMenuMapper deptMenuMapper,
                                   SysPositionMenuMapper positionMenuMapper,
                                   SysStaffMenuMapper staffMenuMapper,
                                   StringRedisTemplate redisTemplate) {
        this.permissionMapper  = permissionMapper;
        this.positionMapper    = positionMapper;
        this.deptMenuMapper    = deptMenuMapper;
        this.positionMenuMapper = positionMenuMapper;
        this.staffMenuMapper   = staffMenuMapper;
        this.redisTemplate     = redisTemplate;
    }

    // ── 全量菜单路径（含缓存） ────────────────────────────────────────────────

    @Override
    public List<String> allMenuPaths() {
        List<String> cached = redisTemplate.opsForList().range(CacheKey.MERCHANT_MENUS, 0, -1);
        if (cached != null && !cached.isEmpty()) return cached;

        List<String> paths = permissionMapper.selectAllVisibleMerchantMenus().stream()
                .filter(p -> p.getType() == 2 && p.getPath() != null)
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

    /**
     * 按 员工 → 职位 → 部门 → 全量 顺序取第一个非空配置。
     * 若职位为全量权限（fullAccess=1），直接返回 null（全量）。
     */
    @Override
    public List<String> resolveEffectivePaths(Long merchantId, CbMerchantStaff staff) {
        if (staff == null) return null;

        if (staff.getPositionId() != null) {
            SysPosition pos = positionMapper.selectById(staff.getPositionId());
            if (pos != null && Integer.valueOf(1).equals(pos.getFullAccess())) return null;
        }

        return Stream.of(
                        staffPaths(merchantId, staff.getId()),
                        positionPaths(merchantId, staff.getPositionId()),
                        deptPaths(merchantId, staff.getDeptId()))
                .filter(list -> !list.isEmpty())
                .findFirst()
                .orElse(null); // null = 全量兜底
    }

    // ── 操作权限码解析 ────────────────────────────────────────────────────────

    /**
     * 从 RBAC 链解析出的 key 列表中过滤出操作权限码（key 包含 ':' 且不以 '/' 开头）。
     * 商户主账号（staff=null）或全量权限职位返回 {@code ["*"]}。
     */
    @Override
    public List<String> resolveEffectiveCodes(Long merchantId, CbMerchantStaff staff) {
        if (staff == null) return List.of("*");
        List<String> allKeys = resolveEffectivePaths(merchantId, staff);
        if (allKeys == null) return List.of("*"); // 全量兜底
        return allKeys.stream()
                .filter(k -> k.contains(":") && !k.startsWith("/"))
                .collect(Collectors.toList());
    }

    // ── 菜单树构建 ────────────────────────────────────────────────────────────

    @Override
    public List<PermissionVO> buildMenuTree(List<String> paths) {
        List<SysPermission> allMenus = permissionMapper.selectAllVisibleMerchantMenus();
        if (paths == null) return PermissionVO.buildTree(allMenus);

        Set<String>         pathSet = new HashSet<>(paths);
        Map<Long, SysPermission> idMap = allMenus.stream()
                .collect(Collectors.toMap(SysPermission::getId, m -> m));

        Set<Long> accessIds = allMenus.stream()
                .filter(m -> m.getType() == 2 && m.getPath() != null && pathSet.contains(m.getPath()))
                .flatMap(m -> ancestorIds(m, idMap))
                .collect(Collectors.toSet());

        return PermissionVO.buildTree(
                allMenus.stream().filter(m -> accessIds.contains(m.getId())).collect(Collectors.toList()));
    }

    // ── 私有辅助方法 ─────────────────────────────────────────────────────────

    /** 叶菜单 + 所有祖先 ID 流，用于构建完整路径的菜单树 */
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
        return menuKeys(staffMenuMapper.selectList(
                Wrappers.<SysStaffMenu>lambdaQuery()
                        .eq(SysStaffMenu::getStaffId, staffId)
                        .eq(SysStaffMenu::getMerchantId, merchantId)),
                SysStaffMenu::getMenuKey);
    }

    private List<String> positionPaths(Long merchantId, Long positionId) {
        if (positionId == null) return List.of();
        return menuKeys(positionMenuMapper.selectList(
                Wrappers.<SysPositionMenu>lambdaQuery()
                        .eq(SysPositionMenu::getPositionId, positionId)
                        .eq(SysPositionMenu::getMerchantId, merchantId)),
                SysPositionMenu::getMenuKey);
    }

    private List<String> deptPaths(Long merchantId, Long deptId) {
        if (deptId == null) return List.of();
        return menuKeys(deptMenuMapper.selectList(
                Wrappers.<SysDeptMenu>lambdaQuery()
                        .eq(SysDeptMenu::getDeptId, deptId)
                        .eq(SysDeptMenu::getMerchantId, merchantId)),
                SysDeptMenu::getMenuKey);
    }

    private <T> List<String> menuKeys(List<T> rows, Function<T, String> extractor) {
        return rows.stream().map(extractor).collect(Collectors.toList());
    }
}
