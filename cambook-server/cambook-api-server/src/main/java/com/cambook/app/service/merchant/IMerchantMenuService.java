package com.cambook.app.service.merchant;

import com.cambook.app.domain.vo.PermissionVO;
import com.cambook.db.entity.CbMerchantStaff;

import java.util.List;

/**
 * 商户端菜单服务
 *
 * <p>职责单一（SRP）：
 * <ul>
 *   <li>从数据库（含 Redis 缓存）读取商户端全量菜单路径</li>
 *   <li>按 RBAC 链（员工 → 职位 → 部门 → 全量）解析有效路径</li>
 *   <li>将有效路径集合构建为前端可用的 {@link PermissionVO} 菜单树</li>
 * </ul>
 *
 * <p>开闭原则（OCP）：新增商户端菜单只需在数据库写入记录，
 * 无需修改任何 Java 代码；RBAC 链规则变化只在此服务内修改。
 *
 * @author CamBook
 */
public interface IMerchantMenuService {

    /**
     * 商户端全量菜单路径（Redis 缓存，TTL 30 分钟）
     *
     * @return 所有 portal_type=1、type=2、status=1 的菜单路由路径，如 /merchant/dashboard
     */
    List<String> allMenuPaths();

    /**
     * 按 RBAC 链解析员工有效菜单路径
     *
     * <p>优先级：员工个人配置 → 职位配置 → 部门配置 → 全量兜底
     *
     * @param merchantId 商户 ID（数据隔离）
     * @param staff      员工记录；传 {@code null} 表示商户主账号，直接返回 {@code null}（全量）
     * @return 有效路径列表；{@code null} 表示拥有全量菜单权限
     */
    List<String> resolveEffectivePaths(Long merchantId, CbMerchantStaff staff);

    /**
     * 按 RBAC 链解析员工有效操作权限码（type=3 operation codes）
     *
     * <p>复用 {@link #resolveEffectivePaths} 取得全量 key，再过滤出包含 ':' 的操作码。
     *
     * @param merchantId 商户 ID
     * @param staff      员工记录；传 {@code null} 表示商户主账号，直接返回 {@code ["*"]}
     * @return 操作权限码列表；商户主账号返回 {@code ["*"]} 表示全量
     */
    List<String> resolveEffectiveCodes(Long merchantId, CbMerchantStaff staff);

    /**
     * 将有效路径集合转为商户端菜单树
     *
     * @param paths 有效路径集合；{@code null} 表示返回全量菜单树
     * @return 前端所需的 {@link PermissionVO} 树形结构
     */
    List<PermissionVO> buildMenuTree(List<String> paths);

    /** 主动失效 Redis 菜单缓存（由 {@link com.cambook.app.event.MerchantMenuChangedEvent} 触发） */
    void evictCache();

    // ── RBAC 分配（含事务，供 MerchantPermController 调用）──────────────────

    void assignDeptMenus(Long merchantId, Long deptId, java.util.List<String> menuKeys);

    void assignPositionMenus(Long merchantId, Long positionId, java.util.List<String> menuKeys);

    void assignStaffMenus(Long merchantId, Long staffId, java.util.List<String> menuKeys);

    // ── 权限查询（供 MerchantPermController 读取已分配权限）─────────────────

    java.util.List<String> getDeptMenuKeys(Long merchantId, Long deptId);

    java.util.List<String> getPositionMenuKeys(Long merchantId, Long positionId);

    java.util.List<String> getStaffMenuKeys(Long merchantId, Long staffId);

    java.util.List<com.cambook.db.entity.SysPosition> getDeptPositions(Long merchantId, Long deptId);
}
