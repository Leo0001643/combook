package com.cambook.app.controller.merchant;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.cambook.app.common.annotation.RequireMerchant;
import com.cambook.app.common.security.MerchantOwnershipGuard;
import com.cambook.app.service.merchant.IMerchantMenuService;
import com.cambook.common.exception.BusinessException;
import com.cambook.common.result.Result;
import com.cambook.dao.entity.*;
import com.cambook.dao.mapper.*;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.util.*;
import java.util.stream.Collectors;

/**
 * 商户端 - RBAC权限分配
 *
 * <p>权限链：员工个人 → 职位 → 部门 → 全部菜单（就近匹配）
 * 即：若员工有个人菜单配置，则以员工为准；否则继承职位的；否则继承部门的；都没配则默认全部。
 */
@RequireMerchant
@Tag(name = "商户端 - 权限分配")
@RestController
@RequestMapping("/merchant/perm")
public class MerchantPermController {

    private final SysDeptMenuMapper     deptMenuMapper;
    private final SysPositionMenuMapper positionMenuMapper;
    private final SysStaffMenuMapper    staffMenuMapper;
    private final SysDeptMapper         deptMapper;
    private final SysPositionMapper     positionMapper;
    private final CbMerchantStaffMapper staffMapper;
    private final IMerchantMenuService  merchantMenuService;

    public MerchantPermController(SysDeptMenuMapper deptMenuMapper,
                                  SysPositionMenuMapper positionMenuMapper,
                                  SysStaffMenuMapper staffMenuMapper,
                                  SysDeptMapper deptMapper,
                                  SysPositionMapper positionMapper,
                                  CbMerchantStaffMapper staffMapper,
                                  IMerchantMenuService merchantMenuService) {
        this.deptMenuMapper      = deptMenuMapper;
        this.positionMenuMapper  = positionMenuMapper;
        this.staffMenuMapper     = staffMenuMapper;
        this.deptMapper          = deptMapper;
        this.positionMapper      = positionMapper;
        this.staffMapper         = staffMapper;
        this.merchantMenuService = merchantMenuService;
    }

    private List<String> allMenuKeys() {
        return merchantMenuService.allMenuPaths();
    }

    // ══════════════════════════════════════════════════════════
    // 全量菜单列表
    // ══════════════════════════════════════════════════════════

    @Operation(summary = "获取全量可分配菜单 key 列表")
    @GetMapping("/menus")
    public Result<List<String>> allMenus() {
        return Result.success(allMenuKeys());
    }

    // ══════════════════════════════════════════════════════════
    // 部门权限
    // ══════════════════════════════════════════════════════════

    @Operation(summary = "获取部门已分配菜单")
    @GetMapping("/dept/{deptId}/menus")
    public Result<List<String>> getDeptMenus(@PathVariable Long deptId) {
        Long merchantId = MerchantOwnershipGuard.requireMerchantId();
        assertDeptOwner(deptId, merchantId);
        List<String> keys = deptMenuMapper.selectList(
                        new LambdaQueryWrapper<SysDeptMenu>()
                                .eq(SysDeptMenu::getDeptId, deptId)
                                .eq(SysDeptMenu::getMerchantId, merchantId))
                .stream().map(SysDeptMenu::getMenuKey).collect(Collectors.toList());
        // 若从未配置，返回全量（默认全部）
        return Result.success(keys.isEmpty() ? allMenuKeys() : keys);
    }

    @Operation(summary = "分配部门菜单（全量覆盖）")
    @PostMapping("/dept/{deptId}/menus")
    @Transactional
    public Result<Void> assignDeptMenus(@PathVariable Long deptId,
                                        @RequestParam(required = false) List<String> menuKeys) {
        Long merchantId = MerchantOwnershipGuard.requireMerchantId();
        assertDeptOwner(deptId, merchantId);
        if (menuKeys == null) menuKeys = List.of();
        validateMenuKeys(menuKeys);
        // 删旧写新
        deptMenuMapper.delete(new LambdaQueryWrapper<SysDeptMenu>()
                .eq(SysDeptMenu::getDeptId, deptId)
                .eq(SysDeptMenu::getMerchantId, merchantId));
        for (String key : menuKeys) {
            SysDeptMenu row = new SysDeptMenu();
            row.setMerchantId(merchantId);
            row.setDeptId(deptId);
            row.setMenuKey(key);
            deptMenuMapper.insert(row);
        }
        return Result.success();
    }

    // ══════════════════════════════════════════════════════════
    // 职位权限
    // ══════════════════════════════════════════════════════════

    @Operation(summary = "获取职位已分配菜单")
    @GetMapping("/position/{positionId}/menus")
    public Result<List<String>> getPositionMenus(@PathVariable Long positionId) {
        Long merchantId = MerchantOwnershipGuard.requireMerchantId();
        assertPositionOwner(positionId, merchantId);
        // 全量权限职位（如总裁）：直接返回全部，无需查权限表
        SysPosition pos = positionMapper.selectById(positionId);
        if (pos != null && Integer.valueOf(1).equals(pos.getFullAccess())) {
            return Result.success(allMenuKeys());
        }
        List<String> keys = positionMenuMapper.selectList(
                        new LambdaQueryWrapper<SysPositionMenu>()
                                .eq(SysPositionMenu::getPositionId, positionId)
                                .eq(SysPositionMenu::getMerchantId, merchantId))
                .stream().map(SysPositionMenu::getMenuKey).collect(Collectors.toList());
        if (!keys.isEmpty()) return Result.success(keys);
        // 继承上级部门
        if (pos != null && pos.getDeptId() != null) {
            return getDeptMenus(pos.getDeptId());
        }
        return Result.success(allMenuKeys());
    }

    @Operation(summary = "分配职位菜单（全量覆盖）")
    @PostMapping("/position/{positionId}/menus")
    @Transactional
    public Result<Void> assignPositionMenus(@PathVariable Long positionId,
                                            @RequestParam(required = false) List<String> menuKeys) {
        Long merchantId = MerchantOwnershipGuard.requireMerchantId();
        assertPositionOwner(positionId, merchantId);
        if (menuKeys == null) menuKeys = List.of();
        validateMenuKeys(menuKeys);
        positionMenuMapper.delete(new LambdaQueryWrapper<SysPositionMenu>()
                .eq(SysPositionMenu::getPositionId, positionId)
                .eq(SysPositionMenu::getMerchantId, merchantId));
        for (String key : menuKeys) {
            SysPositionMenu row = new SysPositionMenu();
            row.setMerchantId(merchantId);
            row.setPositionId(positionId);
            row.setMenuKey(key);
            positionMenuMapper.insert(row);
        }
        return Result.success();
    }

    // ══════════════════════════════════════════════════════════
    // 员工权限（个人覆盖）
    // ══════════════════════════════════════════════════════════

    @Operation(summary = "获取员工已分配菜单（个人覆盖；若未配置则返回继承链结果）")
    @GetMapping("/staff/{staffId}/menus")
    public Result<List<String>> getStaffMenus(@PathVariable Long staffId) {
        Long merchantId = MerchantOwnershipGuard.requireMerchantId();
        assertStaffOwner(staffId, merchantId);
        CbMerchantStaff staff = staffMapper.selectById(staffId);
        // 若员工所属职位为全量权限（如总裁），个人配置也无需查 —— 直接全开
        if (staff != null && staff.getPositionId() != null) {
            SysPosition pos = positionMapper.selectById(staff.getPositionId());
            if (pos != null && Integer.valueOf(1).equals(pos.getFullAccess())) {
                return Result.success(allMenuKeys());
            }
        }
        List<String> keys = staffMenuMapper.selectList(
                        new LambdaQueryWrapper<SysStaffMenu>()
                                .eq(SysStaffMenu::getStaffId, staffId)
                                .eq(SysStaffMenu::getMerchantId, merchantId))
                .stream().map(SysStaffMenu::getMenuKey).collect(Collectors.toList());
        if (!keys.isEmpty()) return Result.success(keys);
        // 继承职位 → 部门
        if (staff != null && staff.getPositionId() != null) {
            return getPositionMenus(staff.getPositionId());
        }
        if (staff != null && staff.getDeptId() != null) {
            return getDeptMenus(staff.getDeptId());
        }
        return Result.success(allMenuKeys());
    }

    @Operation(summary = "分配员工菜单（个人覆盖，全量覆盖；传空列表清除个人配置）")
    @PostMapping("/staff/{staffId}/menus")
    @Transactional
    public Result<Void> assignStaffMenus(@PathVariable Long staffId,
                                         @RequestParam(required = false) List<String> menuKeys) {
        Long merchantId = MerchantOwnershipGuard.requireMerchantId();
        assertStaffOwner(staffId, merchantId);
        if (menuKeys == null) menuKeys = List.of();
        validateMenuKeys(menuKeys);
        staffMenuMapper.delete(new LambdaQueryWrapper<SysStaffMenu>()
                .eq(SysStaffMenu::getStaffId, staffId)
                .eq(SysStaffMenu::getMerchantId, merchantId));
        for (String key : menuKeys) {
            SysStaffMenu row = new SysStaffMenu();
            row.setMerchantId(merchantId);
            row.setStaffId(staffId);
            row.setMenuKey(key);
            staffMenuMapper.insert(row);
        }
        return Result.success();
    }

    /** 获取员工的生效菜单（权限链最终解析结果，用于员工登录后加载菜单） */
    @Operation(summary = "获取员工最终生效菜单（登录时调用）")
    @GetMapping("/staff/{staffId}/effective-menus")
    public Result<List<String>> getEffectiveMenus(@PathVariable Long staffId) {
        Long merchantId = MerchantOwnershipGuard.requireMerchantId();
        assertStaffOwner(staffId, merchantId);
        return getStaffMenus(staffId);
    }

    // ══════════════════════════════════════════════════════════
    // 获取部门下的职位（用于前端级联选择）
    // ══════════════════════════════════════════════════════════

    @Operation(summary = "获取指定部门下的职位列表")
    @GetMapping("/dept/{deptId}/positions")
    public Result<List<SysPosition>> getDeptPositions(@PathVariable Long deptId) {
        Long merchantId = MerchantOwnershipGuard.requireMerchantId();
        return Result.success(positionMapper.selectList(
                new LambdaQueryWrapper<SysPosition>()
                        .eq(SysPosition::getMerchantId, merchantId)
                        .eq(SysPosition::getDeptId, deptId)
                        .eq(SysPosition::getStatus, 1)
                        .orderByAsc(SysPosition::getSort)));
    }

    // ══════════════════════════════════════════════════════════
    // private helpers
    // ══════════════════════════════════════════════════════════

    private void assertDeptOwner(Long deptId, Long merchantId) {
        SysDept dept = deptMapper.selectById(deptId);
        if (dept == null || !merchantId.equals(dept.getMerchantId()))
            throw new BusinessException("部门不存在或无权操作");
    }

    private void assertPositionOwner(Long positionId, Long merchantId) {
        SysPosition pos = positionMapper.selectById(positionId);
        if (pos == null || !merchantId.equals(pos.getMerchantId()))
            throw new BusinessException("职位不存在或无权操作");
    }

    private void assertStaffOwner(Long staffId, Long merchantId) {
        CbMerchantStaff staff = staffMapper.selectById(staffId);
        if (staff == null || !merchantId.equals(staff.getMerchantId()))
            throw new BusinessException("员工不存在或无权操作");
    }

    private void validateMenuKeys(List<String> keys) {
        if (keys == null) return;
        // 菜单路径（以 '/' 开头）校验白名单；操作权限码（含 ':'）直接放行
        Set<String> validPaths = new HashSet<>(allMenuKeys());
        for (String k : keys) {
            if (k.startsWith("/") && !validPaths.contains(k)) {
                throw new BusinessException("非法菜单key: " + k);
            }
            // 操作权限码格式：module:action，无需与白名单比对
        }
    }
}
