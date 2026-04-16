package com.cambook.app.controller.admin;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.cambook.common.annotation.RequirePermission;
import com.cambook.common.result.Result;
import com.cambook.dao.entity.SysDept;
import com.cambook.dao.mapper.SysDeptMapper;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Admin 端 - 部门管理
 */
@Tag(name = "Admin - 部门管理")
@RestController
@RequestMapping("/admin/dept")
@Validated
public class DeptController {

    private final SysDeptMapper deptMapper;

    public DeptController(SysDeptMapper deptMapper) {
        this.deptMapper = deptMapper;
    }

    @RequirePermission("dept:list")
    @Operation(summary = "部门树列表")
    @GetMapping("/list")
    public Result<List<SysDept>> list(@RequestParam(required = false) String name,
                                      @RequestParam(required = false) Integer status) {
        LambdaQueryWrapper<SysDept> q = new LambdaQueryWrapper<SysDept>()
                .like(name != null && !name.isBlank(), SysDept::getName, name)
                .eq(status != null, SysDept::getStatus, status)
                .orderByAsc(SysDept::getSort);
        return Result.success(deptMapper.selectList(q));
    }

    @RequirePermission("dept:add")
    @Operation(summary = "新增部门")
    @PostMapping
    public Result<Void> add(@NotBlank(message = "部门名称不能为空") @RequestParam String name,
                            @NotNull(message = "父级ID不能为空") @RequestParam Long parentId,
                            @RequestParam(defaultValue = "0") Integer sort,
                            @RequestParam(required = false) String leader,
                            @RequestParam(required = false) String phone,
                            @RequestParam(required = false) String email) {
        SysDept dept = new SysDept();
        dept.setName(name);
        dept.setParentId(parentId);
        dept.setSort(sort);
        dept.setLeader(leader);
        dept.setPhone(phone);
        dept.setEmail(email);
        dept.setStatus(1);
        deptMapper.insert(dept);
        return Result.success();
    }

    @RequirePermission("dept:edit")
    @Operation(summary = "修改部门")
    @PutMapping
    public Result<Void> edit(@NotNull(message = "ID不能为空") @RequestParam Long id,
                             @NotBlank(message = "部门名称不能为空") @RequestParam String name,
                             @NotNull(message = "父级ID不能为空") @RequestParam Long parentId,
                             @RequestParam(defaultValue = "0") Integer sort,
                             @RequestParam(required = false) String leader,
                             @RequestParam(required = false) String phone,
                             @RequestParam(required = false) String email,
                             @RequestParam(required = false) Integer status) {
        SysDept dept = deptMapper.selectById(id);
        if (dept == null) return Result.fail(400, "部门不存在");
        dept.setName(name);
        dept.setParentId(parentId);
        dept.setSort(sort);
        dept.setLeader(leader);
        dept.setPhone(phone);
        dept.setEmail(email);
        if (status != null) dept.setStatus(status);
        deptMapper.updateById(dept);
        return Result.success();
    }

    @RequirePermission("dept:delete")
    @Operation(summary = "删除部门")
    @DeleteMapping("/{id}")
    public Result<Void> delete(@PathVariable Long id) {
        long children = deptMapper.selectCount(new LambdaQueryWrapper<SysDept>().eq(SysDept::getParentId, id));
        if (children > 0) return Result.fail(400, "存在子部门，不允许删除");
        deptMapper.deleteById(id);
        return Result.success();
    }

    @RequirePermission("dept:edit")
    @Operation(summary = "修改部门状态")
    @PatchMapping("/{id}/status")
    public Result<Void> updateStatus(@PathVariable Long id, @RequestParam Integer status) {
        SysDept dept = deptMapper.selectById(id);
        if (dept == null) return Result.fail(400, "部门不存在");
        dept.setStatus(status);
        deptMapper.updateById(dept);
        return Result.success();
    }
}
