package com.cambook.app.controller.admin;

import com.cambook.app.service.admin.IAdminCurrencyService;
import com.cambook.common.annotation.RequirePermission;
import com.cambook.common.result.Result;
import com.cambook.db.entity.SysCurrency;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

/**
 * 超级管理员 — 币种管理
 */
@Tag(name = "Admin - 币种管理")
@RestController
@RequestMapping(value = "/admin/currency", produces = MediaType.APPLICATION_JSON_VALUE)
@RequiredArgsConstructor
public class CurrencyController {

    private final IAdminCurrencyService adminCurrencyService;

    @Operation(summary = "获取全部币种列表")
    @GetMapping(value = "/list", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<List<SysCurrency>> list(@RequestParam(required = false) Integer status) {
        return Result.success(adminCurrencyService.list(status));
    }

    @Operation(summary = "新增币种")
    @PostMapping(produces = MediaType.APPLICATION_JSON_VALUE)
    @RequirePermission("currency:add")
    public Result<Void> add(@RequestBody SysCurrency currency) {
        adminCurrencyService.add(currency);
        return Result.success();
    }

    @Operation(summary = "编辑币种基本信息（不含汇率）")
    @PutMapping(produces = MediaType.APPLICATION_JSON_VALUE)
    @RequirePermission("currency:edit")
    public Result<Void> update(@RequestBody SysCurrency currency) {
        adminCurrencyService.update(currency);
        return Result.success();
    }

    @Operation(summary = "更新汇率")
    @PatchMapping(value = "/{code}/rate", produces = MediaType.APPLICATION_JSON_VALUE)
    @RequirePermission("currency:rate")
    public Result<Void> updateRate(@PathVariable String code, @RequestParam BigDecimal rateToUsd) {
        adminCurrencyService.updateRate(code, rateToUsd);
        return Result.success();
    }

    @Operation(summary = "启用 / 停用币种")
    @PatchMapping(value = "/{id}/status", produces = MediaType.APPLICATION_JSON_VALUE)
    @RequirePermission("currency:edit")
    public Result<Void> toggleStatus(@PathVariable Long id, @RequestParam Integer status) {
        adminCurrencyService.toggleStatus(id, status);
        return Result.success();
    }

    @Operation(summary = "查看指定商户的币种配置")
    @GetMapping(value = "/merchant/{merchantId}", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<List<Map<String, Object>>> merchantCurrencies(@PathVariable Long merchantId) {
        return Result.success(adminCurrencyService.merchantCurrencies(merchantId));
    }

    @Operation(summary = "Admin 为商户批量配置币种")
    @PostMapping(value = "/merchant/{merchantId}/configure", produces = MediaType.APPLICATION_JSON_VALUE)
    @RequirePermission("currency:edit")
    public Result<Void> configureMerchantCurrencies(@PathVariable Long merchantId, @RequestBody List<IAdminCurrencyService.MerchantCurrencyConfigItem> configs) {
        adminCurrencyService.validateConfigs(configs);
        adminCurrencyService.applyMerchantCurrencyConfig(merchantId, configs);
        return Result.success();
    }
}
