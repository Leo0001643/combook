package com.cambook.app.controller.admin;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.cambook.common.annotation.RequirePermission;
import com.cambook.common.result.PageResult;
import com.cambook.common.result.Result;
import com.cambook.dao.entity.SysConfig;
import com.cambook.dao.mapper.SysConfigMapper;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.web.bind.annotation.*;

/**
 * Admin 端 - 系统参数配置
 */
@Tag(name = "Admin - 系统参数配置")
@RestController
@RequestMapping("/admin/config")
public class SysConfigController {

    private final SysConfigMapper configMapper;

    public SysConfigController(SysConfigMapper configMapper) {
        this.configMapper = configMapper;
    }

    @RequirePermission("config:list")
    @Operation(summary = "参数配置分页列表")
    @GetMapping("/list")
    public Result<PageResult<SysConfig>> list(
            @RequestParam(defaultValue = "1") int current,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(required = false) String configName,
            @RequestParam(required = false) String configKey,
            @RequestParam(required = false) String configGroup) {
        IPage<SysConfig> page = configMapper.selectPage(new Page<>(current, size),
                new LambdaQueryWrapper<SysConfig>()
                        .like(configName != null && !configName.isBlank(), SysConfig::getConfigName, configName)
                        .like(configKey != null && !configKey.isBlank(), SysConfig::getConfigKey, configKey)
                        .eq(configGroup != null && !configGroup.isBlank(), SysConfig::getConfigGroup, configGroup)
                        .orderByAsc(SysConfig::getId));
        return Result.success(PageResult.of(page));
    }

    @RequirePermission("config:add")
    @Operation(summary = "新增参数")
    @PostMapping
    public Result<Void> add(@RequestParam String configName,
                            @RequestParam String configKey,
                            @RequestParam String configValue,
                            @RequestParam(defaultValue = "custom") String configGroup,
                            @RequestParam(required = false) String remark) {
        long cnt = configMapper.selectCount(new LambdaQueryWrapper<SysConfig>().eq(SysConfig::getConfigKey, configKey));
        if (cnt > 0) return Result.fail(400, "参数键名已存在");
        SysConfig config = new SysConfig();
        config.setConfigName(configName);
        config.setConfigKey(configKey);
        config.setConfigValue(configValue);
        config.setConfigGroup(configGroup);
        config.setRemark(remark);
        config.setIsSystem(0);
        configMapper.insert(config);
        return Result.success();
    }

    @RequirePermission("config:edit")
    @Operation(summary = "修改参数")
    @PutMapping
    public Result<Void> edit(@RequestParam Long id,
                             @RequestParam String configName,
                             @RequestParam String configValue,
                             @RequestParam(required = false) String remark) {
        SysConfig config = configMapper.selectById(id);
        if (config == null) return Result.fail(400, "参数不存在");
        config.setConfigName(configName);
        config.setConfigValue(configValue);
        config.setRemark(remark);
        configMapper.updateById(config);
        return Result.success();
    }

    @RequirePermission("config:delete")
    @Operation(summary = "删除参数")
    @DeleteMapping("/{id}")
    public Result<Void> delete(@PathVariable Long id) {
        SysConfig config = configMapper.selectById(id);
        if (config == null) return Result.fail(400, "参数不存在");
        if (config.getIsSystem() != null && config.getIsSystem() == 1) return Result.fail(400, "内置参数不允许删除");
        configMapper.deleteById(id);
        return Result.success();
    }
}
