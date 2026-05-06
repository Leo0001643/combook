package com.cambook.app.controller.merchant;

import com.cambook.app.common.annotation.RequireMerchant;
import com.cambook.app.common.security.MerchantOwnershipGuard;
import com.cambook.app.service.merchant.IMerchantMenuService;
import com.cambook.common.exception.BusinessException;
import com.cambook.common.result.Result;
import com.cambook.common.enums.CbCodeEnum;
import com.cambook.db.entity.*;
import com.cambook.db.service.*;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * 商户端 - RBAC权限分配
 *
 * <p>权限链：员工个人 → 职位 → 部门 → 全部菜单（就近匹配）
 */
@RequireMerchant
@Tag(name = "商户端 - 权限分配")
@RestController
@RequestMapping(value = "/merchant/perm", produces = MediaType.APPLICATION_JSON_VALUE)
@RequiredArgsConstructor
public class MerchantPermController {

    private final ISysDeptService         sysDeptService;
    private final ISysPositionService     sysPositionService;
    private final ICbMerchantStaffService cbMerchantStaffService;
    private final IMerchantMenuService    merchantMenuService;

    @Operation(summary = "获取全量可分配菜单 key 列表")
    @GetMapping(value = "/menus", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<List<String>> allMenus() {
        return Result.success(merchantMenuService.allMenuPaths());
    }

    // ── 部门权限 ──────────────────────────────────────────────────────────────

    @Operation(summary = "获取部门已分配菜单")
    @GetMapping(value = "/dept/{deptId}/menus", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<List<String>> getDeptMenus(@PathVariable Long deptId) {
        Long merchantId = MerchantOwnershipGuard.requireMerchantId();
        assertDeptOwner(deptId, merchantId);
        List<String> keys = merchantMenuService.getDeptMenuKeys(merchantId, deptId);
        return Result.success(keys.isEmpty() ? merchantMenuService.allMenuPaths() : keys);
    }

    @Operation(summary = "分配部门菜单（全量覆盖）")
    @PostMapping(value = "/dept/{deptId}/menus", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> assignDeptMenus(@PathVariable Long deptId, @RequestParam(required = false) List<String> menuKeys) {
        Long merchantId = MerchantOwnershipGuard.requireMerchantId();
        assertDeptOwner(deptId, merchantId);
        merchantMenuService.assignDeptMenus(merchantId, deptId, menuKeys != null ? menuKeys : List.of());
        return Result.success();
    }

    // ── 职位权限 ──────────────────────────────────────────────────────────────

    @Operation(summary = "获取职位已分配菜单")
    @GetMapping(value = "/position/{positionId}/menus", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<List<String>> getPositionMenus(@PathVariable Long positionId) {
        Long merchantId = MerchantOwnershipGuard.requireMerchantId();
        assertPositionOwner(positionId, merchantId);
        SysPosition pos = sysPositionService.getById(positionId);
        if (pos != null && Byte.valueOf((byte) 1).equals(pos.getFullAccess())) return Result.success(merchantMenuService.allMenuPaths());
        List<String> keys = merchantMenuService.getPositionMenuKeys(merchantId, positionId);
        if (!keys.isEmpty()) return Result.success(keys);
        if (pos != null && pos.getDeptId() != null) return getDeptMenus(pos.getDeptId());
        return Result.success(merchantMenuService.allMenuPaths());
    }

    @Operation(summary = "分配职位菜单（全量覆盖）")
    @PostMapping(value = "/position/{positionId}/menus", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> assignPositionMenus(@PathVariable Long positionId, @RequestParam(required = false) List<String> menuKeys) {
        Long merchantId = MerchantOwnershipGuard.requireMerchantId();
        assertPositionOwner(positionId, merchantId);
        merchantMenuService.assignPositionMenus(merchantId, positionId, menuKeys != null ? menuKeys : List.of());
        return Result.success();
    }

    // ── 员工权限 ──────────────────────────────────────────────────────────────

    @Operation(summary = "获取员工已分配菜单（个人覆盖；若未配置则返回继承链结果）")
    @GetMapping(value = "/staff/{staffId}/menus", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<List<String>> getStaffMenus(@PathVariable Long staffId) {
        Long merchantId = MerchantOwnershipGuard.requireMerchantId();
        assertStaffOwner(staffId, merchantId);
        CbMerchantStaff staff = cbMerchantStaffService.getById(staffId);
        if (staff != null && staff.getPositionId() != null) {
            SysPosition pos = sysPositionService.getById(staff.getPositionId());
            if (pos != null && Byte.valueOf((byte) 1).equals(pos.getFullAccess())) return Result.success(merchantMenuService.allMenuPaths());
        }
        List<String> keys = merchantMenuService.getStaffMenuKeys(merchantId, staffId);
        if (!keys.isEmpty()) return Result.success(keys);
        if (staff != null && staff.getPositionId() != null) return getPositionMenus(staff.getPositionId());
        if (staff != null && staff.getDeptId()     != null) return getDeptMenus(staff.getDeptId());
        return Result.success(merchantMenuService.allMenuPaths());
    }

    @Operation(summary = "分配员工菜单（个人覆盖，全量覆盖；传空列表清除个人配置）")
    @PostMapping(value = "/staff/{staffId}/menus", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> assignStaffMenus(@PathVariable Long staffId, @RequestParam(required = false) List<String> menuKeys) {
        Long merchantId = MerchantOwnershipGuard.requireMerchantId();
        assertStaffOwner(staffId, merchantId);
        merchantMenuService.assignStaffMenus(merchantId, staffId, menuKeys != null ? menuKeys : List.of());
        return Result.success();
    }

    @Operation(summary = "获取员工最终生效菜单（登录时调用）")
    @GetMapping(value = "/staff/{staffId}/effective-menus", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<List<String>> getEffectiveMenus(@PathVariable Long staffId) {
        MerchantOwnershipGuard.requireMerchantId();
        return getStaffMenus(staffId);
    }

    @Operation(summary = "获取指定部门下的职位列表")
    @GetMapping(value = "/dept/{deptId}/positions", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<List<SysPosition>> getDeptPositions(@PathVariable Long deptId) {
        Long merchantId = MerchantOwnershipGuard.requireMerchantId();
        return Result.success(merchantMenuService.getDeptPositions(merchantId, deptId));
    }

    // ── 私有辅助 ──────────────────────────────────────────────────────────────

    private void assertDeptOwner(Long deptId, Long merchantId) {
        SysDept dept = sysDeptService.getById(deptId);
        if (dept == null || !merchantId.equals(dept.getMerchantId())) throw new BusinessException(CbCodeEnum.NO_PERMISSION);
    }

    private void assertPositionOwner(Long positionId, Long merchantId) {
        SysPosition pos = sysPositionService.getById(positionId);
        if (pos == null || !merchantId.equals(pos.getMerchantId())) throw new BusinessException(CbCodeEnum.NO_PERMISSION);
    }

    private void assertStaffOwner(Long staffId, Long merchantId) {
        CbMerchantStaff staff = cbMerchantStaffService.getById(staffId);
        if (staff == null || !merchantId.equals(staff.getMerchantId())) throw new BusinessException(CbCodeEnum.NO_PERMISSION);
    }
}
