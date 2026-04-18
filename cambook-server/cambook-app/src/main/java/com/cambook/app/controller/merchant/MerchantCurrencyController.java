package com.cambook.app.controller.merchant;

import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.cambook.app.controller.admin.CurrencyController;
import com.cambook.common.context.MerchantContext;
import com.cambook.common.exception.BusinessException;
import com.cambook.common.result.Result;
import com.cambook.dao.entity.CbMerchantCurrency;
import com.cambook.dao.entity.SysCurrency;
import com.cambook.dao.mapper.CbMerchantCurrencyMapper;
import com.cambook.dao.mapper.SysCurrencyMapper;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.web.bind.annotation.*;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * 商户端 — 币种配置
 *
 * <p>商户可查看并自助配置自己接受的结算货币，无需管理员干预。
 * 商户只能在平台已启用的全局币种中选择。
 *
 * @author CamBook
 */
@Tag(name = "Merchant - 币种配置")
@RestController
@RequestMapping("/merchant/currency")
public class MerchantCurrencyController {

    private final SysCurrencyMapper        currencyMapper;
    private final CbMerchantCurrencyMapper merchantCurrencyMapper;
    private final CurrencyController       currencyController;

    public MerchantCurrencyController(SysCurrencyMapper currencyMapper,
                                      CbMerchantCurrencyMapper merchantCurrencyMapper,
                                      CurrencyController currencyController) {
        this.currencyMapper        = currencyMapper;
        this.merchantCurrencyMapper = merchantCurrencyMapper;
        this.currencyController    = currencyController;
    }

    @Operation(summary = "获取当前商户的币种配置（含全局可用列表）")
    @GetMapping("/config")
    public Result<List<Map<String, Object>>> getConfig() {
        Long merchantId = MerchantContext.getMerchantId();
        return currencyController.merchantCurrencies(merchantId);
    }

    @Operation(summary = "获取当前商户已启用的币种（用于支付下拉选择）")
    @GetMapping("/enabled")
    public Result<List<Map<String, Object>>> enabledCurrencies() {
        Long merchantId = MerchantContext.getMerchantId();

        // 商户已启用的配置
        List<CbMerchantCurrency> configs = merchantCurrencyMapper.selectList(
                Wrappers.<CbMerchantCurrency>lambdaQuery()
                        .eq(CbMerchantCurrency::getMerchantId, merchantId)
                        .eq(CbMerchantCurrency::getStatus, 1));

        if (configs.isEmpty()) {
            // 商户未配置任何币种时，返回全局默认（USD + USDT）
            return Result.success(defaultCurrencies());
        }

        // 按商户排序拉取详情
        Map<String, CbMerchantCurrency> configMap = configs.stream()
                .collect(Collectors.toMap(CbMerchantCurrency::getCurrencyCode, c -> c));

        List<SysCurrency> globalList = currencyMapper.selectList(
                Wrappers.<SysCurrency>lambdaQuery()
                        .in(SysCurrency::getCurrencyCode, configMap.keySet())
                        .eq(SysCurrency::getStatus, 1));

        List<Map<String, Object>> result = globalList.stream()
                .sorted(Comparator.comparingInt((SysCurrency c) -> {
                    CbMerchantCurrency mc = configMap.get(c.getCurrencyCode());
                    return mc != null ? mc.getSortOrder() : 999;
                }))
                .map(c -> {
                    CbMerchantCurrency mc = configMap.get(c.getCurrencyCode());
                    Map<String, Object> item = new LinkedHashMap<>();
                    item.put("currencyCode",  c.getCurrencyCode());
                    item.put("currencyName",  mc.getDisplayName() != null ? mc.getDisplayName() : c.getCurrencyName());
                    item.put("currencyNameEn", c.getCurrencyNameEn());
                    item.put("symbol",        c.getSymbol());
                    item.put("flag",          c.getFlag());
                    item.put("isCrypto",      c.getIsCrypto());
                    item.put("decimalPlaces", c.getDecimalPlaces());
                    item.put("isDefault",     mc.getIsDefault() == 1);
                    // 实效汇率：自定义优先，fallback 全局
                    item.put("rateToUsd",     mc.getCustomRate() != null ? mc.getCustomRate() : c.getRateToUsd());
                    return item;
                })
                .collect(Collectors.toList());

        return Result.success(result);
    }

    @Operation(summary = "商户保存自己的币种配置")
    @PostMapping("/configure")
    public Result<Void> configure(@RequestBody List<CurrencyController.MerchantCurrencyConfigItem> configs) {
        if (configs == null || configs.isEmpty()) throw new BusinessException("配置列表不能为空");
        Long merchantId = MerchantContext.getMerchantId();
        currencyController.validateConfigs(configs);
        currencyController.applyMerchantCurrencyConfig(merchantId, configs);
        return Result.success();
    }

    // ── Private ───────────────────────────────────────────────────────────────

    private List<Map<String, Object>> defaultCurrencies() {
        List<SysCurrency> list = currencyMapper.selectList(
                Wrappers.<SysCurrency>lambdaQuery()
                        .in(SysCurrency::getCurrencyCode, "USD", "USDT")
                        .eq(SysCurrency::getStatus, 1)
                        .orderByAsc(SysCurrency::getSortOrder));
        List<Map<String, Object>> result = new ArrayList<>();
        for (SysCurrency c : list) {
            Map<String, Object> item = new LinkedHashMap<>();
            item.put("currencyCode",  c.getCurrencyCode());
            item.put("currencyName",  c.getCurrencyName());
            item.put("currencyNameEn", c.getCurrencyNameEn());
            item.put("symbol",        c.getSymbol());
            item.put("flag",          c.getFlag());
            item.put("isCrypto",      c.getIsCrypto());
            item.put("decimalPlaces", c.getDecimalPlaces());
            item.put("isDefault",     "USD".equals(c.getCurrencyCode()));
            item.put("rateToUsd",     c.getRateToUsd());
            result.add(item);
        }
        return result;
    }
}
