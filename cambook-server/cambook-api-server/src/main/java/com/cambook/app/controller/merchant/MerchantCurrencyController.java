package com.cambook.app.controller.merchant;

import com.cambook.app.service.admin.IAdminCurrencyService;
import com.cambook.common.context.MerchantContext;
import com.cambook.common.exception.BusinessException;
import com.cambook.common.result.Result;
import com.cambook.common.enums.CbCodeEnum;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * 商户端 — 币种配置
 */
@Tag(name = "Merchant - 币种配置")
@RestController
@RequestMapping(value = "/merchant/currency", produces = MediaType.APPLICATION_JSON_VALUE)
@RequiredArgsConstructor
public class MerchantCurrencyController {

    private final IAdminCurrencyService adminCurrencyService;

    @Operation(summary = "获取当前商户的币种配置（含全局可用列表）")
    @GetMapping(value = "/config", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<List<Map<String, Object>>> getConfig() {
        return Result.success(adminCurrencyService.merchantCurrencies(MerchantContext.getMerchantId()));
    }

    @Operation(summary = "获取当前商户已启用的币种（用于支付下拉选择）")
    @GetMapping(value = "/enabled", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<List<Map<String, Object>>> enabledCurrencies() {
        return Result.success(adminCurrencyService.enabledCurrencies(MerchantContext.getMerchantId()));
    }

    @Operation(summary = "商户保存自己的币种配置")
    @PostMapping(value = "/configure", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> configure(@RequestBody List<IAdminCurrencyService.MerchantCurrencyConfigItem> configs) {
        if (configs == null || configs.isEmpty()) throw new BusinessException(CbCodeEnum.PARAM_ERROR);
        Long merchantId = MerchantContext.getMerchantId();
        adminCurrencyService.validateConfigs(configs);
        adminCurrencyService.applyMerchantCurrencyConfig(merchantId, configs);
        return Result.success();
    }
}
