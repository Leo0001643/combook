package com.cambook.app.controller.merchant;

import com.cambook.app.common.annotation.RequireMerchant;
import com.cambook.app.common.security.MerchantOwnershipGuard;
import com.cambook.app.domain.dto.DeptSaveDTO;
import com.cambook.app.service.merchant.IMerchantDeptService;
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
 * 商户端 - 部门管理（严格隔离，仅可操作本商户数据）
 */
@RequireMerchant
@Tag(name = "商户端 - 部门管理")
@RestController
@RequestMapping(value = "/merchant/dept", produces = MediaType.APPLICATION_JSON_VALUE)
@RequiredArgsConstructor
public class MerchantDeptController {

    private final IMerchantDeptService merchantDeptService;

    @Operation(summary = "部门列表")
    @GetMapping(value = "/list", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<List<SysDept>> list(@RequestParam(required = false) String name, @RequestParam(required = false) Integer status) {
        return Result.success(merchantDeptService.list(MerchantOwnershipGuard.requireMerchantId(), name, status));
    }

    @Operation(summary = "新增部门")
    @PostMapping(produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> add(@Valid @RequestBody DeptSaveDTO dto) {
        merchantDeptService.add(MerchantOwnershipGuard.requireMerchantId(), dto);
        return Result.success();
    }

    @Operation(summary = "修改部门")
    @PostMapping(value = "/edit", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> edit(@Valid @RequestBody DeptSaveDTO dto) {
        merchantDeptService.edit(MerchantOwnershipGuard.requireMerchantId(), dto);
        return Result.success();
    }

    @Operation(summary = "删除部门")
    @PostMapping(value = "/{id}/delete", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> delete(@PathVariable Long id) {
        merchantDeptService.delete(MerchantOwnershipGuard.requireMerchantId(), id);
        return Result.success();
    }

    @Operation(summary = "修改部门状态")
    @PostMapping(value = "/{id}/status", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> updateStatus(@PathVariable Long id, @RequestParam Integer status) {
        merchantDeptService.updateStatus(MerchantOwnershipGuard.requireMerchantId(), id, status);
        return Result.success();
    }
}
