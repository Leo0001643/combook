package com.cambook.app.controller.admin;

import com.baomidou.mybatisplus.core.metadata.IPage;
import com.cambook.app.domain.dto.StaffDTO;
import com.cambook.app.domain.vo.StaffVO;
import com.cambook.app.service.admin.IStaffService;
import com.cambook.common.annotation.RequirePermission;
import com.cambook.common.result.Result;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.*;

import java.util.Arrays;
import java.util.List;
import java.util.stream.Collectors;

/**
 * Admin 端 - 员工管理（后台账号）
 *
 * @author CamBook
 */
@Tag(name = "Admin - 员工管理")
@RestController
@RequestMapping("/admin/staff")
public class StaffController {

    private final IStaffService staffService;

    public StaffController(IStaffService staffService) {
        this.staffService = staffService;
    }

    @RequirePermission("staff:list")
    @Operation(summary = "员工分页列表")
    @GetMapping(value = "/page", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<IPage<StaffVO>> page(
            @RequestParam(defaultValue = "1")  int     current,
            @RequestParam(defaultValue = "10") int     size,
            @RequestParam(required = false)    String  keyword,
            @RequestParam(required = false)    Integer status,
            @RequestParam(required = false)    Long    positionId) {
        return Result.success(staffService.page(current, size, keyword, status, positionId));
    }

    @RequirePermission("staff:add")
    @Operation(summary = "新增员工")
    @PostMapping(produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> add(@Valid @ModelAttribute StaffDTO dto) {
        staffService.add(dto);
        return Result.success();
    }

    @RequirePermission("staff:edit")
    @Operation(summary = "修改员工信息")
    @PutMapping(produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> edit(@Valid @ModelAttribute StaffDTO dto) {
        staffService.edit(dto);
        return Result.success();
    }

    @RequirePermission("staff:delete")
    @Operation(summary = "删除员工")
    @DeleteMapping(value = "/{id}", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> delete(@PathVariable Long id) {
        staffService.delete(id);
        return Result.success();
    }

    @RequirePermission("staff:edit")
    @Operation(summary = "修改员工状态（启用/停用）")
    @PatchMapping(value = "/{id}/status", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> updateStatus(@PathVariable Long id, @RequestParam Integer status) {
        staffService.updateStatus(id, status);
        return Result.success();
    }

    @RequirePermission("staff:edit")
    @Operation(summary = "员工角色分配")
    @PostMapping(value = "/{id}/roles", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> assignRoles(@PathVariable Long id, @RequestParam(defaultValue = "") String roleIds) {
        List<Long> ids = roleIds.isBlank() ? List.of()
                : Arrays.stream(roleIds.split(",")).filter(s -> !s.isBlank()).map(Long::parseLong).collect(Collectors.toList());
        staffService.assignRoles(id, ids);
        return Result.success();
    }
}
