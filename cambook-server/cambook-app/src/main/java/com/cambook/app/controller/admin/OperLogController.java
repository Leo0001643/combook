package com.cambook.app.controller.admin;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.cambook.common.annotation.RequirePermission;
import com.cambook.common.result.PageResult;
import com.cambook.common.result.Result;
import com.cambook.dao.entity.SysOperLog;
import com.cambook.dao.mapper.SysOperLogMapper;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.web.bind.annotation.*;

/**
 * Admin 端 - 操作日志管理
 */
@Tag(name = "Admin - 操作日志")
@RestController
@RequestMapping("/admin/operlog")
public class OperLogController {

    private final SysOperLogMapper operLogMapper;

    public OperLogController(SysOperLogMapper operLogMapper) {
        this.operLogMapper = operLogMapper;
    }

    @RequirePermission("log:list")
    @Operation(summary = "操作日志分页列表")
    @GetMapping("/list")
    public Result<PageResult<SysOperLog>> list(
            @RequestParam(defaultValue = "1") int current,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(required = false) String title,
            @RequestParam(required = false) String operName,
            @RequestParam(required = false) String requestMethod,
            @RequestParam(required = false) Integer status) {
        IPage<SysOperLog> page = operLogMapper.selectPage(new Page<>(current, size),
                new LambdaQueryWrapper<SysOperLog>()
                        .like(title != null && !title.isBlank(), SysOperLog::getTitle, title)
                        .like(operName != null && !operName.isBlank(), SysOperLog::getOperName, operName)
                        .eq(requestMethod != null && !requestMethod.isBlank(), SysOperLog::getRequestMethod, requestMethod)
                        .eq(status != null, SysOperLog::getStatus, status)
                        .orderByDesc(SysOperLog::getOperTime));
        return Result.success(PageResult.of(page));
    }

    @RequirePermission("log:delete")
    @Operation(summary = "删除操作日志")
    @DeleteMapping("/{id}")
    public Result<Void> delete(@PathVariable Long id) {
        operLogMapper.deleteById(id);
        return Result.success();
    }

    @RequirePermission("log:delete")
    @Operation(summary = "清空操作日志")
    @DeleteMapping("/clean")
    public Result<Void> clean() {
        operLogMapper.delete(null);
        return Result.success();
    }
}
