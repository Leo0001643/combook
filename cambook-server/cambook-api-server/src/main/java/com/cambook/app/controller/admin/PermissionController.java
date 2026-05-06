package com.cambook.app.controller.admin;

import com.cambook.common.annotation.RequirePermission;
import com.cambook.app.domain.dto.PermissionDTO;
import com.cambook.app.domain.vo.PermissionVO;
import com.cambook.app.service.admin.IPermissionService;
import com.cambook.common.result.Result;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import org.springframework.http.MediaType;

/**
 * Admin 端 - 权限管理
 *
 * @author CamBook
 */
@Tag(name = "Admin - 权限管理")
@RestController
@RequestMapping("/admin/permission")
public class PermissionController {

    private final IPermissionService permissionService;

    public PermissionController(IPermissionService permissionService) {
        this.permissionService = permissionService;
    }

    @RequirePermission("permission:list")
    @Operation(summary = "查询管理端权限树")
    @GetMapping(value = "/tree", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<List<PermissionVO>> tree() {
        return Result.success(permissionService.tree());
    }

    @RequirePermission("permission:list")
    @Operation(summary = "查询商户端菜单树")
    @GetMapping(value = "/merchant-tree", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<List<PermissionVO>> merchantTree() {
        return Result.success(permissionService.merchantMenuTree());
    }

    @RequirePermission("permission:add")
    @Operation(summary = "新增权限")
    @PostMapping(produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> add(@Valid @ModelAttribute PermissionDTO dto) {
        permissionService.add(dto);
        return Result.success();
    }

    @RequirePermission("permission:edit")
    @Operation(summary = "修改权限")
    @PutMapping(produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> edit(@Valid @ModelAttribute PermissionDTO dto) {
        permissionService.edit(dto);
        return Result.success();
    }

    @RequirePermission("permission:delete")
    @Operation(summary = "删除权限")
    @DeleteMapping(value = "/{id}", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> delete(@PathVariable Long id) {
        permissionService.delete(id);
        return Result.success();
    }

    @RequirePermission("permission:edit")
    @Operation(summary = "移动权限节点", description = "将节点移动到指定父节点下，可同步更新排序值")
    @PutMapping(value = "/move", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> move(
            @RequestParam Long    id,
            @RequestParam Long    targetParentId,
            @RequestParam(required = false) Integer sort) {
        permissionService.move(id, targetParentId, sort);
        return Result.success();
    }
}
