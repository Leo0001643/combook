package com.cambook.app.controller.admin;

import com.cambook.app.domain.dto.CategorySaveDTO;
import com.cambook.app.service.admin.IAdminCategoryService;
import com.cambook.common.annotation.RequirePermission;
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
 * Admin 端 - 服务类目管理
 */
@Tag(name = "Admin - 服务类目管理")
@RestController
@RequestMapping(value = "/admin/category", produces = MediaType.APPLICATION_JSON_VALUE)
@RequiredArgsConstructor
public class CategoryController {

    private final IAdminCategoryService adminCategoryService;

    @RequirePermission("category:list")
    @Operation(summary = "服务类目树列表")
    @GetMapping(value = "/list", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<List<CbServiceCategory>> list(@RequestParam(required = false) String keyword, @RequestParam(required = false) Integer status) {
        return Result.success(adminCategoryService.list(keyword, status));
    }

    @RequirePermission("category:add")
    @Operation(summary = "新增分类（支持 6 语言名称）")
    @PostMapping(produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> add(@Valid @RequestBody CategorySaveDTO dto) {
        adminCategoryService.add(dto);
        return Result.success();
    }

    @RequirePermission("category:edit")
    @Operation(summary = "修改分类（支持 6 语言名称）")
    @PutMapping(produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> edit(@Valid @RequestBody CategorySaveDTO dto) {
        adminCategoryService.edit(dto);
        return Result.success();
    }

    @RequirePermission("category:delete")
    @Operation(summary = "删除分类")
    @DeleteMapping(value = "/{id}", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> delete(@PathVariable Long id) {
        adminCategoryService.delete(id);
        return Result.success();
    }
}
