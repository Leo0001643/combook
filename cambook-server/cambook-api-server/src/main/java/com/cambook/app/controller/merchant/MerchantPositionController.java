package com.cambook.app.controller.merchant;

import com.cambook.app.common.annotation.RequireMerchant;
import com.cambook.app.common.security.MerchantOwnershipGuard;
import com.cambook.app.domain.dto.PositionDTO;
import com.cambook.app.domain.vo.PositionVO;
import com.cambook.app.service.merchant.IMerchantPositionService;
import com.cambook.common.result.Result;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * 商户端 - 职位管理（严格隔离，仅可操作本商户数据）
 */
@RequireMerchant
@Tag(name = "商户端 - 职位管理")
@RestController
@RequestMapping(value = "/merchant/position", produces = MediaType.APPLICATION_JSON_VALUE)
@RequiredArgsConstructor
public class MerchantPositionController {

    private final IMerchantPositionService merchantPositionService;

    @Operation(summary = "职位列表")
    @GetMapping(value = "/list", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<List<PositionVO>> list() {
        return Result.success(merchantPositionService.list(MerchantOwnershipGuard.requireMerchantId()));
    }

    @Operation(summary = "新增职位")
    @PostMapping(produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> add(@Valid @RequestBody PositionDTO dto) {
        merchantPositionService.add(MerchantOwnershipGuard.requireMerchantId(), dto);
        return Result.success();
    }

    @Operation(summary = "修改职位")
    @PostMapping(value = "/edit", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> edit(@Valid @RequestBody PositionDTO dto) {
        merchantPositionService.edit(MerchantOwnershipGuard.requireMerchantId(), dto);
        return Result.success();
    }

    @Operation(summary = "删除职位")
    @PostMapping(value = "/{id}/delete", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> delete(@PathVariable Long id) {
        merchantPositionService.delete(MerchantOwnershipGuard.requireMerchantId(), id);
        return Result.success();
    }

    @Operation(summary = "修改职位状态")
    @PostMapping(value = "/{id}/status", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> updateStatus(@PathVariable Long id, @RequestParam Integer status) {
        merchantPositionService.updateStatus(MerchantOwnershipGuard.requireMerchantId(), id, status);
        return Result.success();
    }
}
