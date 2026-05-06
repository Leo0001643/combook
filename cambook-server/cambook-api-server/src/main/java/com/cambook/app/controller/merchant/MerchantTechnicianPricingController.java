package com.cambook.app.controller.merchant;

import com.cambook.app.common.annotation.RequireMerchant;
import com.cambook.app.common.security.MerchantOwnershipGuard;
import com.cambook.app.service.merchant.IMerchantTechnicianPricingService;
import com.cambook.common.result.Result;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

/**
 * 商户端 - 技师服务专属定价管理
 */
@RequireMerchant
@Tag(name = "商户端 - 技师服务定价")
@RestController
@RequestMapping(value = "/merchant/technician/pricing", produces = MediaType.APPLICATION_JSON_VALUE)
@RequiredArgsConstructor
public class MerchantTechnicianPricingController {

    private final IMerchantTechnicianPricingService merchantTechnicianPricingService;

    @Operation(summary = "查询技师专属定价")
    @GetMapping(value = "/list", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<List<Map<String, Object>>> list(@RequestParam Long technicianId) {
        return Result.success(merchantTechnicianPricingService.list(MerchantOwnershipGuard.requireMerchantId(), technicianId));
    }

    @Operation(summary = "设置技师专属定价")
    @PostMapping(value = "/save", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> save(@RequestParam Long technicianId, @RequestParam Long serviceItemId, @RequestParam BigDecimal price) {
        merchantTechnicianPricingService.save(MerchantOwnershipGuard.requireMerchantId(), technicianId, serviceItemId, price);
        return Result.success();
    }

    @Operation(summary = "批量保存技师专属定价（覆盖式）")
    @PostMapping(value = "/saveAll", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> saveAll(@RequestParam Long technicianId, @RequestBody List<Map<String, Object>> items) {
        merchantTechnicianPricingService.saveAll(MerchantOwnershipGuard.requireMerchantId(), technicianId, items);
        return Result.success();
    }

    @Operation(summary = "删除技师专属定价")
    @PostMapping(value = "/delete", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> delete(@RequestParam Long technicianId, @RequestParam Long serviceItemId) {
        merchantTechnicianPricingService.delete(MerchantOwnershipGuard.requireMerchantId(), technicianId, serviceItemId);
        return Result.success();
    }
}
