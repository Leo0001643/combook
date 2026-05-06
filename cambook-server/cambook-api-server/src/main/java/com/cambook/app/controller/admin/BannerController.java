package com.cambook.app.controller.admin;

import com.cambook.app.domain.dto.BannerDTO;
import com.cambook.app.service.admin.IBannerService;
import com.cambook.common.annotation.RequirePermission;
import com.cambook.common.result.Result;
import com.cambook.db.entity.CbBanner;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Admin 端 - Banner 管理
 */
@Tag(name = "Admin - Banner 管理")
@RestController
@RequestMapping(value = "/admin/banner", produces = MediaType.APPLICATION_JSON_VALUE)
@RequiredArgsConstructor
public class BannerController {

    private final IBannerService bannerService;

    @RequirePermission("banner:list")
    @Operation(summary = "Banner 列表")
    @GetMapping(value = "/list", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<List<CbBanner>> list(@RequestParam(required = false) String position, @RequestParam(required = false) Integer status) {
        return Result.success(bannerService.list(position, status));
    }

    @RequirePermission("banner:add")
    @Operation(summary = "新增 Banner")
    @PostMapping(produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> add(@Valid @RequestBody BannerDTO dto) {
        bannerService.add(dto);
        return Result.success();
    }

    @RequirePermission("banner:edit")
    @Operation(summary = "修改 Banner")
    @PutMapping(produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> edit(@Valid @RequestBody BannerDTO dto) {
        bannerService.edit(dto);
        return Result.success();
    }

    @RequirePermission("banner:delete")
    @Operation(summary = "删除 Banner")
    @DeleteMapping(value = "/{id}", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> delete(@PathVariable Long id) {
        bannerService.delete(id);
        return Result.success();
    }
}
