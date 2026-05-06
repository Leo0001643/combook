package com.cambook.app.controller.merchant;

import com.cambook.app.common.annotation.RequireMerchant;
import com.cambook.app.common.security.MerchantOwnershipGuard;
import com.cambook.app.domain.dto.BannerDTO;
import com.cambook.app.service.merchant.IMerchantBannerService;
import com.cambook.common.result.Result;
import com.cambook.db.entity.CbBanner;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * 商户端 - 轮播图管理
 */
@RequireMerchant
@Tag(name = "商户端 - 轮播图管理")
@RestController
@RequestMapping(value = "/merchant/banner", produces = MediaType.APPLICATION_JSON_VALUE)
@RequiredArgsConstructor
public class MerchantBannerController {

    private final IMerchantBannerService merchantBannerService;

    @Operation(summary = "商户轮播图列表")
    @GetMapping(value = "/list", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<List<CbBanner>> list(@RequestParam(required = false) Integer status) {
        return Result.success(merchantBannerService.list(MerchantOwnershipGuard.requireMerchantId(), status));
    }

    @Operation(summary = "新增商户轮播图")
    @PostMapping(value = "/add", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> add(@RequestBody BannerDTO dto) {
        merchantBannerService.add(MerchantOwnershipGuard.requireMerchantId(), dto);
        return Result.success();
    }

    @Operation(summary = "编辑商户轮播图")
    @PostMapping(value = "/edit", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> edit(@RequestBody BannerDTO dto) {
        merchantBannerService.edit(MerchantOwnershipGuard.requireMerchantId(), dto);
        return Result.success();
    }

    @Operation(summary = "删除商户轮播图")
    @PostMapping(value = "/{id}/delete", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> delete(@PathVariable Long id) {
        merchantBannerService.delete(MerchantOwnershipGuard.requireMerchantId(), id);
        return Result.success();
    }

    @Operation(summary = "修改商户轮播图状态")
    @PostMapping(value = "/{id}/status", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> updateStatus(@PathVariable Long id, @RequestParam Integer status) {
        merchantBannerService.updateStatus(MerchantOwnershipGuard.requireMerchantId(), id, status);
        return Result.success();
    }
}
