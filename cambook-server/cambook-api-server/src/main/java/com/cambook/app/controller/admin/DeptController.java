package com.cambook.app.controller.admin;

import com.cambook.app.domain.dto.DeptSaveDTO;
import com.cambook.app.service.admin.IAdminDeptService;
import com.cambook.common.annotation.RequirePermission;
import com.cambook.common.result.Result;
import com.cambook.db.entity.SysDept;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Admin 端 - 部门管理
 */
@Tag(name = "Admin - 部门管理")
@RestController
@RequestMapping(value = "/admin/dept", produces = MediaType.APPLICATION_JSON_VALUE)
@RequiredArgsConstructor
public class DeptController {

    private final IAdminDeptService adminDeptService;

    @RequirePermission("dept:list")
    @Operation(summary = "部门树列表")
    @GetMapping(value = "/list", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<List<SysDept>> list(@RequestParam(required = false) String name, @RequestParam(required = false) Integer status) {
        return Result.success(adminDeptService.list(name, status));
    }

    @RequirePermission("dept:add")
    @Operation(summary = "新增部门")
    @PostMapping(produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> add(@Valid @RequestBody DeptSaveDTO dto) {
        adminDeptService.add(dto);
        return Result.success();
    }

    @RequirePermission("dept:edit")
    @Operation(summary = "修改部门")
    @PutMapping(produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> edit(@Valid @RequestBody DeptSaveDTO dto) {
        adminDeptService.edit(dto);
        return Result.success();
    }

    @RequirePermission("dept:delete")
    @Operation(summary = "删除部门")
    @DeleteMapping(value = "/{id}", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> delete(@PathVariable Long id) {
        adminDeptService.delete(id);
        return Result.success();
    }

    @RequirePermission("dept:edit")
    @Operation(summary = "修改部门状态")
    @PatchMapping(value = "/{id}/status", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> updateStatus(@PathVariable Long id, @RequestParam Integer status) {
        adminDeptService.updateStatus(id, status);
        return Result.success();
    }
}
