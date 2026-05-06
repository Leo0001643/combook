package com.cambook.app.controller.merchant;

import com.cambook.app.common.annotation.RequireMerchant;
import com.cambook.app.common.security.MerchantOwnershipGuard;
import com.cambook.app.domain.dto.CategorySaveDTO;
import com.cambook.app.service.merchant.IMerchantCategoryService;
import com.cambook.common.result.Result;
import com.cambook.db.entity.CbServiceCategory;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * 商户端 - 服务类目管理（写时复制模式）
 */
@RequireMerchant
@Tag(name = "商户端 - 服务类目")
@RestController
@RequestMapping(value = "/merchant/category", produces = MediaType.APPLICATION_JSON_VALUE)
@RequiredArgsConstructor
public class MerchantCategoryController {

    private final IMerchantCategoryService merchantCategoryService;

    @Operation(summary = "服务类目列表（平台公共 + 本商户私有，已克隆的平台类目自动去重）")
    @GetMapping(value = "/list", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<List<CbServiceCategory>> list(@RequestParam(required = false) String keyword, @RequestParam(required = false) Integer status) {
        return Result.success(merchantCategoryService.list(MerchantOwnershipGuard.requireMerchantId(), keyword, status));
    }

    @Operation(summary = "新增私有服务类目（支持 6 语言名称）")
    @PostMapping(value = "/add", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> add(@Valid @RequestBody CategorySaveDTO dto) {
        merchantCategoryService.add(MerchantOwnershipGuard.requireMerchantId(), dto);
        return Result.success();
    }

    @Operation(summary = "编辑服务类目（平台类目自动写时复制为商户私有副本，支持 6 语言名称）")
    @PostMapping(value = "/edit", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> edit(@Valid @RequestBody CategorySaveDTO dto) {
        merchantCategoryService.edit(MerchantOwnershipGuard.requireMerchantId(), dto.getId(), dto);
        return Result.success();
    }

    @Operation(summary = "删除服务类目（私有类目直接删除；平台类目自动创建隐藏副本以从列表移除）")
    @PostMapping(value = "/{id}/delete", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> delete(@PathVariable Long id) {
        merchantCategoryService.delete(MerchantOwnershipGuard.requireMerchantId(), id);
        return Result.success();
    }
}
