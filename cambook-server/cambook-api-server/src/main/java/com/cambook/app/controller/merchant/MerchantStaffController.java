package com.cambook.app.controller.merchant;

import com.cambook.app.common.annotation.RequireMerchant;
import com.cambook.app.common.security.MerchantOwnershipGuard;
import com.cambook.app.domain.dto.StaffSaveDTO;
import com.cambook.app.service.merchant.IMerchantStaffService;
import com.cambook.common.result.PageResult;
import com.cambook.common.result.Result;
import com.cambook.db.entity.CbMerchantStaff;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.*;

/**
 * 商户端 - 员工管理
 */
@RequireMerchant
@Tag(name = "商户端 - 员工管理")
@RestController
@RequestMapping(value = "/merchant/staff", produces = MediaType.APPLICATION_JSON_VALUE)
@RequiredArgsConstructor
public class MerchantStaffController {

    private final IMerchantStaffService merchantStaffService;

    @Operation(summary = "员工列表")
    @GetMapping(value = "/list", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<PageResult<CbMerchantStaff>> list(
            @RequestParam(defaultValue = "1") int page, @RequestParam(defaultValue = "10") int size,
            @RequestParam(required = false) String keyword, @RequestParam(required = false) Integer status,
            @RequestParam(required = false) Long deptId, @RequestParam(required = false) Long positionId) {
        return Result.success(merchantStaffService.list(MerchantOwnershipGuard.requireMerchantId(), page, size, keyword, status, deptId, positionId));
    }

    @Operation(summary = "新增员工")
    @PostMapping(value = "/add", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> add(@Valid @RequestBody StaffSaveDTO dto) {
        merchantStaffService.add(MerchantOwnershipGuard.requireMerchantId(), dto);
        return Result.success();
    }

    @Operation(summary = "编辑员工")
    @PostMapping(value = "/edit", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> edit(@Valid @RequestBody StaffSaveDTO dto) {
        merchantStaffService.edit(MerchantOwnershipGuard.requireMerchantId(), dto);
        return Result.success();
    }

    @Operation(summary = "修改员工状态")
    @PostMapping(value = "/status", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> updateStatus(@RequestParam Long id, @RequestParam Integer status) {
        merchantStaffService.updateStatus(MerchantOwnershipGuard.requireMerchantId(), id, status);
        return Result.success();
    }

    @Operation(summary = "删除员工")
    @PostMapping(value = "/delete", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> delete(@RequestParam Long id) {
        merchantStaffService.delete(MerchantOwnershipGuard.requireMerchantId(), id);
        return Result.success();
    }
}
