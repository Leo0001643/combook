package com.cambook.app.controller.admin;

import com.cambook.app.service.admin.IAdminOperLogService;
import com.cambook.common.annotation.RequirePermission;
import com.cambook.common.result.PageResult;
import com.cambook.common.result.Result;
import com.cambook.db.entity.SysOperLog;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.*;

/**
 * Admin 端 - 操作日志管理
 */
@Tag(name = "Admin - 操作日志")
@RestController
@RequestMapping(value = "/admin/operlog", produces = MediaType.APPLICATION_JSON_VALUE)
@RequiredArgsConstructor
public class OperLogController {

    private final IAdminOperLogService adminOperLogService;

    @RequirePermission("log:list")
    @Operation(summary = "操作日志分页列表")
    @GetMapping(value = "/list", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<PageResult<SysOperLog>> list(
            @RequestParam(defaultValue = "1") int current, @RequestParam(defaultValue = "20") int size,
            @RequestParam(required = false) String title, @RequestParam(required = false) String operName,
            @RequestParam(required = false) String requestMethod, @RequestParam(required = false) Integer status) {
        return Result.success(adminOperLogService.page(current, size, title, operName, requestMethod, status));
    }

    @RequirePermission("log:delete")
    @Operation(summary = "删除操作日志")
    @DeleteMapping(value = "/{id}", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> delete(@PathVariable Long id) {
        adminOperLogService.delete(id);
        return Result.success();
    }

    @RequirePermission("log:delete")
    @Operation(summary = "清空操作日志")
    @DeleteMapping(value = "/clean", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> clean() {
        adminOperLogService.clean();
        return Result.success();
    }
}
