package com.cambook.app.controller.admin;

import com.cambook.common.annotation.RequirePermission;
import com.cambook.app.domain.dto.RoleDTO;
import com.cambook.app.domain.vo.PermissionVO;
import com.cambook.app.domain.vo.RoleVO;
import com.cambook.app.service.admin.IPermissionService;
import com.cambook.app.service.admin.IRoleService;
import com.cambook.common.result.Result;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;

import java.util.Arrays;
import java.util.List;
import java.util.stream.Collectors;
import org.springframework.http.MediaType;

/**
 * Admin 端 - 角色管理
 *
 * @author CamBook
 */
@Tag(name = "Admin - 角色管理")
@RestController
@RequestMapping("/admin/role")
public class RoleController {

    private final IRoleService       roleService;
    private final IPermissionService permissionService;

    public RoleController(IRoleService roleService, IPermissionService permissionService) {
        this.roleService       = roleService;
        this.permissionService = permissionService;
    }

    @RequirePermission("role:list")
    @Operation(summary = "角色列表")
    @GetMapping(value = "/list", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<List<RoleVO>> list() {
        return Result.success(roleService.list());
    }

    @RequirePermission("role:add")
    @Operation(summary = "新增角色")
    @PostMapping(produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> add(@Valid @ModelAttribute RoleDTO dto) {
        roleService.add(dto);
        return Result.success();
    }

    @RequirePermission("role:edit")
    @Operation(summary = "修改角色")
    @PutMapping(produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> edit(@Valid @ModelAttribute RoleDTO dto) {
        roleService.edit(dto);
        return Result.success();
    }

    @RequirePermission("role:delete")
    @Operation(summary = "删除角色")
    @DeleteMapping(value = "/{id}", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> delete(@PathVariable Long id) {
        roleService.delete(id);
        return Result.success();
    }


    @RequirePermission("role:edit")
    @Operation(summary = "查询角色已分配的权限 ID 列表")
    @GetMapping(value = "/{id}/permissions", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<List<Long>> getPermissions(@PathVariable Long id) {
        return Result.success(roleService.getPermissionIds(id));
    }

    @RequirePermission("role:edit")
    @Operation(summary = "保存角色权限分配（全量替换）")
    @PostMapping(value = "/{id}/permissions", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> savePermissions(@PathVariable Long id, @RequestParam(required = false, defaultValue = "") String permissionIds) {
        List<Long> ids = permissionIds.isBlank() ? List.of()
        : Arrays.stream(permissionIds.split(","))
        .filter(s -> !s.isBlank()).map(Long::parseLong).collect(Collectors.toList());
        roleService.savePermissions(id, ids);
        return Result.success();
    }

    @RequirePermission("permission:list")
    @Operation(summary = "查询全量权限树（用于角色分配选择）")
    @GetMapping(value = "/permission-tree", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<List<PermissionVO>> permissionTree() {
        return Result.success(permissionService.tree());
    }
}
