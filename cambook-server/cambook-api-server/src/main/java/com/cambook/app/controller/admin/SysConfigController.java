package com.cambook.app.controller.admin;

import com.cambook.app.domain.dto.SysConfigSaveDTO;
import com.cambook.app.service.admin.IAdminConfigService;
import com.cambook.common.annotation.RequirePermission;
import com.cambook.common.result.PageResult;
import com.cambook.common.result.Result;
import com.cambook.db.entity.SysConfig;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.*;

/**
 * Admin 端 - 系统参数配置
 */
@Tag(name = "Admin - 系统参数配置")
@RestController
@RequestMapping(value = "/admin/config", produces = MediaType.APPLICATION_JSON_VALUE)
@RequiredArgsConstructor
public class SysConfigController {

    private final IAdminConfigService adminConfigService;

    @RequirePermission("config:list")
    @Operation(summary = "参数配置分页列表")
    @GetMapping(value = "/list", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<PageResult<SysConfig>> list(
            @RequestParam(defaultValue = "1") int current, @RequestParam(defaultValue = "10") int size,
            @RequestParam(required = false) String configName, @RequestParam(required = false) String configKey,
            @RequestParam(required = false) String configGroup) {
        return Result.success(adminConfigService.page(current, size, configName, configKey, configGroup));
    }

    @RequirePermission("config:add")
    @Operation(summary = "新增参数")
    @PostMapping(produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> add(@Valid @RequestBody SysConfigSaveDTO dto) {
        adminConfigService.add(dto);
        return Result.success();
    }

    @RequirePermission("config:edit")
    @Operation(summary = "修改参数")
    @PutMapping(produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> edit(@Valid @RequestBody SysConfigSaveDTO dto) {
        adminConfigService.edit(dto);
        return Result.success();
    }

    @RequirePermission("config:delete")
    @Operation(summary = "删除参数")
    @DeleteMapping(value = "/{id}", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> delete(@PathVariable Long id) {
        adminConfigService.delete(id);
        return Result.success();
    }
}
