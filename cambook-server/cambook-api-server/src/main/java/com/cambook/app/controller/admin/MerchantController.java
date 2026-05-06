package com.cambook.app.controller.admin;

import com.cambook.app.domain.dto.MerchantCreateDTO;
import com.cambook.app.service.admin.IAdminMerchantService;
import com.cambook.common.annotation.RequirePermission;
import com.cambook.common.result.PageResult;
import com.cambook.common.result.Result;
import com.cambook.db.entity.CbMerchant;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;

/**
 * Admin 端 - 商户管理
 */
@Tag(name = "Admin - 商户管理")
@RestController
@RequestMapping(value = "/admin/merchant", produces = MediaType.APPLICATION_JSON_VALUE)
@RequiredArgsConstructor
public class MerchantController {

    private final IAdminMerchantService adminMerchantService;

    @RequirePermission("merchant:edit")
    @Operation(summary = "后台新增商户")
    @PostMapping(value = "/create", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<CbMerchant> create(@Valid @RequestBody MerchantCreateDTO dto) {
        return Result.success(adminMerchantService.create(dto));
    }

    @RequirePermission("merchant:list")
    @Operation(summary = "商户分页列表")
    @GetMapping(value = "/list", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<PageResult<CbMerchant>> list(
            @RequestParam(defaultValue = "1") int current, @RequestParam(defaultValue = "10") int size,
            @RequestParam(required = false) String keyword, @RequestParam(required = false) String city,
            @RequestParam(required = false) Integer status, @RequestParam(required = false) Integer auditStatus) {
        return Result.success(adminMerchantService.page(current, size, keyword, city, status, auditStatus));
    }

    @RequirePermission("merchant:list")
    @Operation(summary = "商户详情")
    @GetMapping(value = "/{id}", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<CbMerchant> detail(@PathVariable Long id) {
        return Result.success(adminMerchantService.detail(id));
    }

    @RequirePermission("merchant:edit")
    @Operation(summary = "修改商户状态")
    @PatchMapping(value = "/{id}/status", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> updateStatus(@PathVariable Long id, @RequestParam Integer status) {
        adminMerchantService.updateStatus(id, status);
        return Result.success();
    }

    @RequirePermission("merchant:edit")
    @Operation(summary = "审核商户")
    @PatchMapping(value = "/{id}/audit", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> audit(@PathVariable Long id, @RequestParam Integer auditStatus, @RequestParam(required = false) String rejectReason) {
        adminMerchantService.audit(id, auditStatus, rejectReason);
        return Result.success();
    }

    @RequirePermission("merchant:edit")
    @Operation(summary = "修改佣金比例")
    @PatchMapping(value = "/{id}/commission", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> updateCommission(@PathVariable Long id, @RequestParam BigDecimal commissionRate) {
        adminMerchantService.updateCommission(id, commissionRate);
        return Result.success();
    }

    @RequirePermission("merchant:delete")
    @Operation(summary = "删除商户")
    @DeleteMapping(value = "/{id}", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> delete(@PathVariable Long id) {
        adminMerchantService.delete(id);
        return Result.success();
    }
}
