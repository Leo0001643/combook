package com.cambook.app.controller.admin;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.cambook.common.annotation.RequirePermission;
import com.cambook.common.result.PageResult;
import com.cambook.common.result.Result;
import com.cambook.dao.entity.SysDictData;
import com.cambook.dao.entity.SysDictType;
import com.cambook.dao.mapper.SysDictDataMapper;
import com.cambook.dao.mapper.SysDictTypeMapper;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Admin 端 - 字典管理
 */
@Tag(name = "Admin - 字典管理")
@RestController
@RequestMapping("/admin/dict")
public class DictController {

    private final SysDictTypeMapper typeMapper;
    private final SysDictDataMapper dataMapper;

    public DictController(SysDictTypeMapper typeMapper, SysDictDataMapper dataMapper) {
        this.typeMapper = typeMapper;
        this.dataMapper = dataMapper;
    }

    // ==================== 字典类型 ====================

    @RequirePermission("dict:list")
    @Operation(summary = "字典类型分页列表")
    @GetMapping("/type/list")
    public Result<PageResult<SysDictType>> typeList(
            @RequestParam(defaultValue = "1") int current,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(required = false) String dictName,
            @RequestParam(required = false) String dictType,
            @RequestParam(required = false) Integer status) {
        IPage<SysDictType> page = typeMapper.selectPage(new Page<>(current, size),
                new LambdaQueryWrapper<SysDictType>()
                        .like(dictName != null && !dictName.isBlank(), SysDictType::getDictName, dictName)
                        .like(dictType != null && !dictType.isBlank(), SysDictType::getDictType, dictType)
                        .eq(status != null, SysDictType::getStatus, status)
                        .orderByAsc(SysDictType::getId));
        return Result.success(PageResult.of(page));
    }

    @RequirePermission("dict:add")
    @Operation(summary = "新增字典类型")
    @PostMapping("/type")
    public Result<Void> addType(@RequestParam String dictName,
                                @RequestParam String dictType,
                                @RequestParam(required = false) String remark) {
        long cnt = typeMapper.selectCount(new LambdaQueryWrapper<SysDictType>().eq(SysDictType::getDictType, dictType));
        if (cnt > 0) return Result.fail(400, "字典类型标识已存在");
        SysDictType t = new SysDictType();
        t.setDictName(dictName);
        t.setDictType(dictType);
        t.setRemark(remark);
        t.setStatus(1);
        typeMapper.insert(t);
        return Result.success();
    }

    @RequirePermission("dict:edit")
    @Operation(summary = "修改字典类型")
    @PutMapping("/type")
    public Result<Void> editType(@RequestParam Long id,
                                 @RequestParam String dictName,
                                 @RequestParam(required = false) String remark,
                                 @RequestParam(required = false) Integer status) {
        SysDictType t = typeMapper.selectById(id);
        if (t == null) return Result.fail(400, "字典类型不存在");
        t.setDictName(dictName);
        t.setRemark(remark);
        if (status != null) t.setStatus(status);
        typeMapper.updateById(t);
        return Result.success();
    }

    @RequirePermission("dict:delete")
    @Operation(summary = "删除字典类型")
    @DeleteMapping("/type/{id}")
    public Result<Void> deleteType(@PathVariable Long id) {
        SysDictType t = typeMapper.selectById(id);
        if (t == null) return Result.fail(400, "字典类型不存在");
        dataMapper.delete(new LambdaQueryWrapper<SysDictData>().eq(SysDictData::getDictType, t.getDictType()));
        typeMapper.deleteById(id);
        return Result.success();
    }

    // ==================== 字典数据 ====================

    @RequirePermission("dict:list")
    @Operation(summary = "字典数据列表")
    @GetMapping("/data/list")
    public Result<List<SysDictData>> dataList(@RequestParam String dictType,
                                              @RequestParam(required = false) Integer status) {
        return Result.success(dataMapper.selectList(
                new LambdaQueryWrapper<SysDictData>()
                        .eq(SysDictData::getDictType, dictType)
                        .eq(status != null, SysDictData::getStatus, status)
                        .orderByAsc(SysDictData::getSort)));
    }

    @RequirePermission("dict:add")
    @Operation(summary = "新增字典数据")
    @PostMapping("/data")
    public Result<Void> addData(@RequestParam String dictType,
                                @RequestParam String labelZh,
                                @RequestParam String dictValue,
                                @RequestParam(required = false) String labelEn,
                                @RequestParam(required = false) String labelVi,
                                @RequestParam(required = false) String labelKm,
                                @RequestParam(defaultValue = "0") Integer sort,
                                @RequestParam(required = false) String remark) {
        SysDictData d = new SysDictData();
        d.setDictType(dictType);
        d.setLabelZh(labelZh);
        d.setDictValue(dictValue);
        d.setLabelEn(labelEn);
        d.setLabelVi(labelVi);
        d.setLabelKm(labelKm);
        d.setSort(sort);
        d.setRemark(remark);
        d.setStatus(1);
        dataMapper.insert(d);
        return Result.success();
    }

    @RequirePermission("dict:edit")
    @Operation(summary = "修改字典数据")
    @PutMapping("/data")
    public Result<Void> editData(@RequestParam Long id,
                                 @RequestParam String labelZh,
                                 @RequestParam String dictValue,
                                 @RequestParam(required = false) String labelEn,
                                 @RequestParam(required = false) String labelVi,
                                 @RequestParam(required = false) String labelKm,
                                 @RequestParam(defaultValue = "0") Integer sort,
                                 @RequestParam(required = false) String remark,
                                 @RequestParam(required = false) Integer status) {
        SysDictData d = dataMapper.selectById(id);
        if (d == null) return Result.fail(400, "字典数据不存在");
        d.setLabelZh(labelZh);
        d.setDictValue(dictValue);
        d.setLabelEn(labelEn);
        d.setLabelVi(labelVi);
        d.setLabelKm(labelKm);
        d.setSort(sort);
        d.setRemark(remark);
        if (status != null) d.setStatus(status);
        dataMapper.updateById(d);
        return Result.success();
    }

    @RequirePermission("dict:delete")
    @Operation(summary = "删除字典数据")
    @DeleteMapping("/data/{id}")
    public Result<Void> deleteData(@PathVariable Long id) {
        dataMapper.deleteById(id);
        return Result.success();
    }
}
