package com.cambook.app.controller.admin;

import com.cambook.app.service.admin.IAdminFinanceService;
import com.cambook.common.annotation.RequirePermission;
import com.cambook.common.result.PageResult;
import com.cambook.common.result.Result;
import com.cambook.db.entity.CbWallet;
import com.cambook.db.entity.CbWalletRecord;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/**
 * Admin 端 - 财务管理
 */
@Tag(name = "Admin - 财务管理")
@RestController
@RequestMapping(value = "/admin/finance", produces = MediaType.APPLICATION_JSON_VALUE)
@RequiredArgsConstructor
public class FinanceController {

    private final IAdminFinanceService adminFinanceService;

    @RequirePermission("finance:list")
    @Operation(summary = "财务统计概览")
    @GetMapping(value = "/overview", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Map<String, Object>> overview() {
        return Result.success(adminFinanceService.overview());
    }

    @RequirePermission("finance:list")
    @Operation(summary = "流水记录分页列表")
    @GetMapping(value = "/records", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<PageResult<CbWalletRecord>> records(
            @RequestParam(defaultValue = "1") int current, @RequestParam(defaultValue = "10") int size,
            @RequestParam(required = false) Integer userType, @RequestParam(required = false) Integer recordType) {
        return Result.success(adminFinanceService.records(current, size, recordType));
    }

    @RequirePermission("finance:list")
    @Operation(summary = "钱包列表")
    @GetMapping(value = "/wallets", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<PageResult<CbWallet>> wallets(
            @RequestParam(defaultValue = "1") int current, @RequestParam(defaultValue = "10") int size,
            @RequestParam(required = false) Integer userType) {
        return Result.success(adminFinanceService.wallets(current, size, userType));
    }
}
