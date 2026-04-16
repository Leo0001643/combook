package com.cambook.app.controller.admin;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.cambook.common.annotation.RequirePermission;
import com.cambook.app.domain.dto.BannerDTO;
import com.cambook.app.service.admin.IBannerService;
import com.cambook.common.result.Result;
import com.cambook.dao.entity.CbBanner;
import com.cambook.dao.mapper.CbBannerMapper;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Admin 端 - Banner 管理
 *
 * @author CamBook
 */
@Tag(name = "Admin - Banner 管理")
@RestController
@RequestMapping("/admin/banner")
public class BannerController {

    private final IBannerService bannerService;
    private final CbBannerMapper bannerMapper;

    public BannerController(IBannerService bannerService, CbBannerMapper bannerMapper) {
        this.bannerService = bannerService;
        this.bannerMapper = bannerMapper;
    }

    @RequirePermission("banner:list")
    @Operation(summary = "Banner 列表")
    @GetMapping("/list")
    public Result<List<CbBanner>> list(
            @RequestParam(required = false) String position,
            @RequestParam(required = false) Integer status) {
        return Result.success(bannerMapper.selectList(
                new LambdaQueryWrapper<CbBanner>()
                        .eq(position != null && !position.isBlank(), CbBanner::getPosition, position)
                        .eq(status != null, CbBanner::getStatus, status)
                        .orderByAsc(CbBanner::getSort)));
    }

    @RequirePermission("banner:add")
    @Operation(summary = "新增 Banner")
    @PostMapping
    public Result<Void> add(@Valid @ModelAttribute BannerDTO dto) {
        bannerService.add(dto);
        return Result.success();
    }

    @RequirePermission("banner:edit")
    @Operation(summary = "修改 Banner")
    @PutMapping
    public Result<Void> edit(@Valid @ModelAttribute BannerDTO dto) {
        bannerService.edit(dto);
        return Result.success();
    }

    @RequirePermission("banner:delete")
    @Operation(summary = "删除 Banner")
    @DeleteMapping("/{id}")
    public Result<Void> delete(@PathVariable Long id) {
        bannerService.delete(id);
        return Result.success();
    }
}
