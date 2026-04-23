package com.cambook.app.controller.admin;

import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.cambook.common.annotation.RequirePermission;
import com.cambook.common.exception.BusinessException;
import com.cambook.common.result.Result;
import com.cambook.dao.entity.CbMerchantCurrency;
import com.cambook.dao.entity.SysCurrency;
import com.cambook.dao.mapper.CbMerchantCurrencyMapper;
import com.cambook.dao.mapper.SysCurrencyMapper;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.*;
import java.util.stream.Collectors;

/**
 * 超级管理员 — 币种管理
 *
 * <p>提供：
 * <ul>
 *   <li>全平台币种 CRUD（新增 / 编辑 / 停用）</li>
 *   <li>汇率手动更新</li>
 *   <li>查看指定商户已配置的币种</li>
 *   <li>为商户批量配置币种（管理员侧）</li>
 * </ul>
 *
 * @author CamBook
 */
@Tag(name = "Admin - 币种管理")
@RestController
@RequestMapping("/admin/currency")
public class CurrencyController {

    private final SysCurrencyMapper         currencyMapper;
    private final CbMerchantCurrencyMapper  merchantCurrencyMapper;

    public CurrencyController(SysCurrencyMapper currencyMapper,
                              CbMerchantCurrencyMapper merchantCurrencyMapper) {
        this.currencyMapper         = currencyMapper;
        this.merchantCurrencyMapper = merchantCurrencyMapper;
    }

    // ── 全平台币种 CRUD ───────────────────────────────────────────────────────

    @Operation(summary = "获取全部币种列表")
    @GetMapping("/list")
    public Result<List<SysCurrency>> list(@RequestParam(required = false) Integer status) {
        return Result.success(
                currencyMapper.selectList(
                        Wrappers.<SysCurrency>lambdaQuery()
                                .eq(status != null, SysCurrency::getStatus, status)
                                .orderByAsc(SysCurrency::getSortOrder)
                                .orderByAsc(SysCurrency::getId))
        );
    }

    @Operation(summary = "新增币种")
    @PostMapping
    @RequirePermission("currency:add")
    public Result<Void> add(@RequestBody SysCurrency currency) {
        // 代码唯一校验
        long exist = currencyMapper.selectCount(Wrappers.<SysCurrency>lambdaQuery()
                .eq(SysCurrency::getCurrencyCode, currency.getCurrencyCode().toUpperCase()));
        if (exist > 0) throw new BusinessException("货币代码已存在：" + currency.getCurrencyCode());
        currency.setCurrencyCode(currency.getCurrencyCode().toUpperCase());
        currency.setRateUpdateTime(System.currentTimeMillis() / 1000L);
        currency.setStatus(currency.getStatus() == null ? 1 : currency.getStatus());
        currencyMapper.insert(currency);
        return Result.success();
    }

    @Operation(summary = "编辑币种基本信息（不含汇率）")
    @PutMapping
    @RequirePermission("currency:edit")
    public Result<Void> update(@RequestBody SysCurrency currency) {
        if (currency.getId() == null) throw new BusinessException("ID 不能为空");
        currencyMapper.updateById(currency);
        return Result.success();
    }

    @Operation(summary = "更新汇率")
    @PatchMapping("/{code}/rate")
    @RequirePermission("currency:rate")
    public Result<Void> updateRate(@PathVariable String code,
                                   @RequestParam BigDecimal rateToUsd) {
        if (rateToUsd.compareTo(BigDecimal.ZERO) <= 0) throw new BusinessException("汇率必须大于 0");
        int rows = currencyMapper.update(null,
                Wrappers.<SysCurrency>lambdaUpdate()
                        .eq(SysCurrency::getCurrencyCode, code.toUpperCase())
                        .set(SysCurrency::getRateToUsd, rateToUsd)
                        .set(SysCurrency::getRateUpdateTime, System.currentTimeMillis() / 1000L));
        if (rows == 0) throw new BusinessException("币种不存在：" + code);
        return Result.success();
    }

    @Operation(summary = "启用 / 停用币种")
    @PatchMapping("/{id}/status")
    @RequirePermission("currency:edit")
    public Result<Void> toggleStatus(@PathVariable Long id,
                                     @RequestParam Integer status) {
        currencyMapper.update(null,
                Wrappers.<SysCurrency>lambdaUpdate()
                        .eq(SysCurrency::getId, id)
                        .set(SysCurrency::getStatus, status));
        return Result.success();
    }

    // ── 商户币种配置（Admin 侧管理）─────────────────────────────────────────

    @Operation(summary = "查看指定商户的币种配置")
    @GetMapping("/merchant/{merchantId}")
    public Result<List<Map<String, Object>>> merchantCurrencies(@PathVariable Long merchantId) {
        // 全局可用币种
        List<SysCurrency> allCurrencies = currencyMapper.selectList(
                Wrappers.<SysCurrency>lambdaQuery()
                        .eq(SysCurrency::getStatus, 1)
                        .orderByAsc(SysCurrency::getSortOrder));

        // 商户已配置的币种
        List<CbMerchantCurrency> merchantCurrencies = merchantCurrencyMapper.selectList(
                Wrappers.<CbMerchantCurrency>lambdaQuery()
                        .eq(CbMerchantCurrency::getMerchantId, merchantId));
        Map<String, CbMerchantCurrency> configMap = merchantCurrencies.stream()
                .collect(Collectors.toMap(CbMerchantCurrency::getCurrencyCode, c -> c));

        // 合并输出：全局列表 + 商户配置状态
        List<Map<String, Object>> result = allCurrencies.stream().map(c -> {
            CbMerchantCurrency mc = configMap.get(c.getCurrencyCode());
            Map<String, Object> item = new LinkedHashMap<>();
            item.put("currencyCode",  c.getCurrencyCode());
            item.put("currencyName",  c.getCurrencyName());
            item.put("currencyNameEn", c.getCurrencyNameEn());
            item.put("symbol",        c.getSymbol());
            item.put("flag",          c.getFlag());
            item.put("isCrypto",      c.getIsCrypto());
            item.put("globalRate",    c.getRateToUsd());
            item.put("decimalPlaces", c.getDecimalPlaces());
            item.put("enabled",       mc != null && mc.getStatus() == 1);
            item.put("isDefault",     mc != null && mc.getIsDefault() == 1);
            item.put("customRate",    mc != null ? mc.getCustomRate() : null);
            item.put("displayName",   mc != null ? mc.getDisplayName() : null);
            item.put("sortOrder",     mc != null ? mc.getSortOrder() : c.getSortOrder());
            return item;
        }).collect(Collectors.toList());

        return Result.success(result);
    }

    @Operation(summary = "Admin 为商户批量配置币种")
    @PostMapping("/merchant/{merchantId}/configure")
    @RequirePermission("currency:edit")
    public Result<Void> configureMerchantCurrencies(
            @PathVariable Long merchantId,
            @RequestBody List<MerchantCurrencyConfigItem> configs) {

        validateConfigs(configs);
        applyMerchantCurrencyConfig(merchantId, configs);
        return Result.success();
    }

    // ── Shared config logic ───────────────────────────────────────────────────

    public void applyMerchantCurrencyConfig(Long merchantId, List<MerchantCurrencyConfigItem> configs) {
        for (MerchantCurrencyConfigItem cfg : configs) {
            CbMerchantCurrency existing = merchantCurrencyMapper.selectOne(
                    Wrappers.<CbMerchantCurrency>lambdaQuery()
                            .eq(CbMerchantCurrency::getMerchantId, merchantId)
                            .eq(CbMerchantCurrency::getCurrencyCode, cfg.currencyCode));

            if (existing == null) {
                CbMerchantCurrency mc = new CbMerchantCurrency();
                mc.setMerchantId(merchantId);
                mc.setCurrencyCode(cfg.currencyCode);
                mc.setIsDefault(cfg.isDefault ? 1 : 0);
                mc.setCustomRate(cfg.customRate);
                mc.setDisplayName(cfg.displayName);
                mc.setSortOrder(cfg.sortOrder);
                mc.setStatus(cfg.enabled ? 1 : 0);
                merchantCurrencyMapper.insert(mc);
            } else {
                existing.setIsDefault(cfg.isDefault ? 1 : 0);
                existing.setCustomRate(cfg.customRate);
                existing.setDisplayName(cfg.displayName);
                existing.setSortOrder(cfg.sortOrder);
                existing.setStatus(cfg.enabled ? 1 : 0);
                merchantCurrencyMapper.updateById(existing);
            }
        }
    }

    public void validateConfigs(List<MerchantCurrencyConfigItem> configs) {
        long defaultCount = configs.stream().filter(c -> c.enabled && c.isDefault).count();
        if (defaultCount > 1) throw new BusinessException("只能设置一个默认收款币种");
        // 验证所有 code 都存在
        Set<String> codes = configs.stream().map(c -> c.currencyCode).collect(Collectors.toSet());
        long validCount = currencyMapper.selectCount(
                Wrappers.<SysCurrency>lambdaQuery()
                        .in(SysCurrency::getCurrencyCode, codes)
                        .eq(SysCurrency::getStatus, 1));
        if (validCount < codes.size()) throw new BusinessException("包含不存在或已停用的币种代码");
    }

    /** 商户币种配置请求体 */
    public static class MerchantCurrencyConfigItem {
        public String     currencyCode;
        public boolean    enabled    = false;
        public boolean    isDefault  = false;
        public BigDecimal customRate;
        public String     displayName;
        public int        sortOrder  = 0;
    }
}
