package com.cambook.app.controller.merchant;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.cambook.app.common.annotation.RequireMerchant;
import com.cambook.app.common.security.MerchantOwnershipGuard;
import com.cambook.app.domain.dto.BannerDTO;
import com.cambook.app.service.admin.IBannerService;
import com.cambook.common.exception.BusinessException;
import com.cambook.common.result.Result;
import com.cambook.dao.entity.CbBanner;
import com.cambook.dao.mapper.CbBannerMapper;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * 商户端 - 轮播图管理（薄包装层）
 *
 * <p>商户只能查看并管理属于自己的轮播图（merchant_id = 当前商户）。
 * 商户轮播图用于商户小程序主页展示，与平台公共轮播图相互独立。
 *
 * @author CamBook
 */
@RequireMerchant
@Tag(name = "商户端 - 轮播图管理")
@RestController
@RequestMapping("/merchant/banner")
public class MerchantBannerController {

    private final CbBannerMapper bannerMapper;
    private final IBannerService bannerService;

    public MerchantBannerController(CbBannerMapper bannerMapper, IBannerService bannerService) {
        this.bannerMapper  = bannerMapper;
        this.bannerService = bannerService;
    }

    @Operation(summary = "商户轮播图列表")
    @GetMapping("/list")
    public Result<List<CbBanner>> list(@RequestParam(required = false) Integer status) {
        Long merchantId = MerchantOwnershipGuard.requireMerchantId();
        return Result.success(bannerMapper.selectList(
                new LambdaQueryWrapper<CbBanner>()
                        .eq(CbBanner::getMerchantId, merchantId)
                        .eq(status != null, CbBanner::getStatus, status)
                        .orderByAsc(CbBanner::getSort)));
    }

    @Operation(summary = "新增商户轮播图")
    @PostMapping("/add")
    public Result<Void> add(@ModelAttribute BannerDTO dto) {
        Long merchantId = MerchantOwnershipGuard.requireMerchantId();
        CbBanner banner = new CbBanner();
        banner.setMerchantId(merchantId);   // 强制归属当前商户
        banner.setPosition(dto.getPosition() != null ? dto.getPosition() : "merchant_home");
        banner.setTitleZh(dto.getTitleZh());
        banner.setTitleEn(dto.getTitleEn());
        banner.setImageUrl(dto.getImageUrl());
        banner.setLinkType(dto.getLinkType() != null ? dto.getLinkType() : 0);
        banner.setLinkValue(dto.getLinkValue());
        banner.setSort(dto.getSort() != null ? dto.getSort() : 0);
        banner.setStatus(dto.getStatus() != null ? dto.getStatus() : 1);
        banner.setStartTime(dto.getStartTime());
        banner.setEndTime(dto.getEndTime());
        bannerMapper.insert(banner);
        return Result.success();
    }

    @Operation(summary = "编辑商户轮播图")
    @PostMapping("/edit")
    public Result<Void> edit(@ModelAttribute BannerDTO dto) {
        Long merchantId = MerchantOwnershipGuard.requireMerchantId();
        CbBanner banner = bannerMapper.selectById(dto.getId());
        if (banner == null) throw new BusinessException("轮播图不存在");
        // 行级安全：只能编辑自己的轮播图
        MerchantOwnershipGuard.assertOwnership(banner.getMerchantId(), "轮播图", dto.getId());
        banner.setTitleZh(dto.getTitleZh());
        banner.setTitleEn(dto.getTitleEn());
        banner.setImageUrl(dto.getImageUrl());
        banner.setLinkType(dto.getLinkType());
        banner.setLinkValue(dto.getLinkValue());
        if (dto.getSort() != null) banner.setSort(dto.getSort());
        if (dto.getStatus() != null) banner.setStatus(dto.getStatus());
        banner.setStartTime(dto.getStartTime());
        banner.setEndTime(dto.getEndTime());
        bannerMapper.updateById(banner);
        return Result.success();
    }

    @Operation(summary = "删除商户轮播图")
    @PostMapping("/{id}/delete")
    public Result<Void> delete(@PathVariable Long id) {
        Long merchantId = MerchantOwnershipGuard.requireMerchantId();
        CbBanner banner = bannerMapper.selectById(id);
        if (banner == null) throw new BusinessException("轮播图不存在");
        MerchantOwnershipGuard.assertOwnership(banner.getMerchantId(), "轮播图", id);
        bannerMapper.deleteById(id);
        return Result.success();
    }

    @Operation(summary = "修改轮播图状态")
    @PostMapping("/{id}/status")
    public Result<Void> updateStatus(@PathVariable Long id, @RequestParam Integer status) {
        Long merchantId = MerchantOwnershipGuard.requireMerchantId();
        CbBanner banner = bannerMapper.selectById(id);
        if (banner == null) throw new BusinessException("轮播图不存在");
        MerchantOwnershipGuard.assertOwnership(banner.getMerchantId(), "轮播图", id);
        banner.setStatus(status);
        bannerMapper.updateById(banner);
        return Result.success();
    }
}
