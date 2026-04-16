package com.cambook.app.controller.merchant;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.cambook.app.common.annotation.RequireMerchant;
import com.cambook.app.common.security.MerchantOwnershipGuard;
import com.cambook.common.exception.BusinessException;
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
 * 商户端 - 部门管理（严格隔离，仅可操作本商户数据）
 */
@RequireMerchant
@Tag(name = "商户端 - 部门管理")
@RestController
@RequestMapping("/merchant/dept")
@Validated
public class MerchantDeptController {

    private final SysDeptMapper deptMapper;

    public MerchantDeptController(SysDeptMapper deptMapper) {
        this.deptMapper = deptMapper;
    }

    @Operation(summary = "部门列表")
    @GetMapping("/list")
    public Result<List<SysDept>> list(@RequestParam(required = false) String name,
                                      @RequestParam(required = false) Integer status) {
        Long merchantId = MerchantOwnershipGuard.requireMerchantId();
        LambdaQueryWrapper<SysDept> q = new LambdaQueryWrapper<SysDept>()
                .eq(SysDept::getMerchantId, merchantId)
                .like(name != null && !name.isBlank(), SysDept::getName, name)
                .eq(status != null, SysDept::getStatus, status)
                .orderByAsc(SysDept::getSort);
        return Result.success(deptMapper.selectList(q));
    }

    @Operation(summary = "新增部门")
    @PostMapping
    public Result<Void> add(@NotBlank(message = "部门名称不能为空") @RequestParam String name,
                            @RequestParam(defaultValue = "0") Long parentId,
                            @RequestParam(defaultValue = "0") Integer sort,
                            @RequestParam(required = false) String leader,
                            @RequestParam(required = false) String phone,
                            @RequestParam(required = false) String email) {
        Long merchantId = MerchantOwnershipGuard.requireMerchantId();
        SysDept dept = new SysDept();
        dept.setMerchantId(merchantId);
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

    @Operation(summary = "修改部门")
    @PostMapping("/edit")
    public Result<Void> edit(@NotNull(message = "ID不能为空") @RequestParam Long id,
                             @NotBlank(message = "部门名称不能为空") @RequestParam String name,
                             @RequestParam(defaultValue = "0") Long parentId,
                             @RequestParam(defaultValue = "0") Integer sort,
                             @RequestParam(required = false) String leader,
                             @RequestParam(required = false) String phone,
                             @RequestParam(required = false) String email,
                             @RequestParam(required = false) Integer status) {
        Long merchantId = MerchantOwnershipGuard.requireMerchantId();
        SysDept dept = deptMapper.selectById(id);
        if (dept == null) throw new BusinessException("部门不存在");
        MerchantOwnershipGuard.assertOwnership(dept.getMerchantId(), "部门", id);
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

    @Operation(summary = "删除部门")
    @PostMapping("/{id}/delete")
    public Result<Void> delete(@PathVariable Long id) {
        Long merchantId = MerchantOwnershipGuard.requireMerchantId();
        SysDept dept = deptMapper.selectById(id);
        if (dept == null) throw new BusinessException("部门不存在");
        MerchantOwnershipGuard.assertOwnership(dept.getMerchantId(), "部门", id);
        long children = deptMapper.selectCount(
                new LambdaQueryWrapper<SysDept>()
                        .eq(SysDept::getParentId, id)
                        .eq(SysDept::getMerchantId, merchantId));
        if (children > 0) throw new BusinessException("存在子部门，不允许删除");
        deptMapper.deleteById(id);
        return Result.success();
    }

    @Operation(summary = "修改部门状态")
    @PostMapping("/{id}/status")
    public Result<Void> updateStatus(@PathVariable Long id, @RequestParam Integer status) {
        SysDept dept = deptMapper.selectById(id);
        if (dept == null) throw new BusinessException("部门不存在");
        MerchantOwnershipGuard.assertOwnership(dept.getMerchantId(), "部门", id);
        dept.setStatus(status);
        deptMapper.updateById(dept);
        return Result.success();
    }
}
