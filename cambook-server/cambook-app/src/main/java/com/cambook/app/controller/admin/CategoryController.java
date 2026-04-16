package com.cambook.app.controller.admin;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.cambook.common.annotation.RequirePermission;
import com.cambook.common.result.Result;
import com.cambook.dao.entity.CbServiceCategory;
import com.cambook.dao.mapper.CbServiceCategoryMapper;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Admin 端 - 服务类目管理
 */
@Tag(name = "Admin - 服务类目管理")
@RestController
@RequestMapping("/admin/category")
public class CategoryController {

    private final CbServiceCategoryMapper categoryMapper;

    public CategoryController(CbServiceCategoryMapper categoryMapper) {
        this.categoryMapper = categoryMapper;
    }

    @RequirePermission("category:list")
    @Operation(summary = "服务类目树列表")
    @GetMapping("/list")
    public Result<List<CbServiceCategory>> list(
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) Integer status) {
        return Result.success(categoryMapper.selectList(
                new LambdaQueryWrapper<CbServiceCategory>()
                        .like(keyword != null && !keyword.isBlank(), CbServiceCategory::getNameZh, keyword)
                        .eq(status != null, CbServiceCategory::getStatus, status)
                        .orderByAsc(CbServiceCategory::getSort)));
    }

    @RequirePermission("category:add")
    @Operation(summary = "新增分类")
    @PostMapping
    public Result<Void> add(@RequestParam(defaultValue = "0") Long parentId,
                            @RequestParam String nameZh,
                            @RequestParam(required = false) String nameEn,
                            @RequestParam(required = false) String nameKm,
                            @RequestParam(required = false) String icon,
                            @RequestParam(defaultValue = "0") Integer sort) {
        CbServiceCategory cat = new CbServiceCategory();
        cat.setParentId(parentId);
        cat.setNameZh(nameZh);
        cat.setNameEn(nameEn);
        cat.setNameKm(nameKm);
        cat.setIcon(icon);
        cat.setSort(sort);
        cat.setStatus(1);
        categoryMapper.insert(cat);
        return Result.success();
    }

    @RequirePermission("category:edit")
    @Operation(summary = "修改分类")
    @PutMapping
    public Result<Void> edit(@RequestParam Long id,
                             @RequestParam String nameZh,
                             @RequestParam(required = false) String nameEn,
                             @RequestParam(required = false) String nameKm,
                             @RequestParam(required = false) String icon,
                             @RequestParam(defaultValue = "0") Integer sort,
                             @RequestParam(required = false) Integer status) {
        CbServiceCategory cat = categoryMapper.selectById(id);
        if (cat == null) return Result.fail(400, "分类不存在");
        cat.setNameZh(nameZh);
        cat.setNameEn(nameEn);
        cat.setNameKm(nameKm);
        cat.setIcon(icon);
        cat.setSort(sort);
        if (status != null) cat.setStatus(status);
        categoryMapper.updateById(cat);
        return Result.success();
    }

    @RequirePermission("category:delete")
    @Operation(summary = "删除分类")
    @DeleteMapping("/{id}")
    public Result<Void> delete(@PathVariable Long id) {
        long children = categoryMapper.selectCount(
                new LambdaQueryWrapper<CbServiceCategory>().eq(CbServiceCategory::getParentId, id));
        if (children > 0) return Result.fail(400, "存在子分类，请先删除子分类");
        categoryMapper.deleteById(id);
        return Result.success();
    }
}
