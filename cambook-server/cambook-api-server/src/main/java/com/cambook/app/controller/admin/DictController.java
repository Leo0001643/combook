package com.cambook.app.controller.admin;

import com.cambook.app.domain.dto.DictDataSaveDTO;
import com.cambook.app.domain.dto.DictTypeSaveDTO;
import com.cambook.app.service.admin.IAdminDictService;
import com.cambook.common.annotation.RequirePermission;
import com.cambook.common.result.PageResult;
import com.cambook.common.result.Result;
import com.cambook.db.entity.SysDict;
import com.cambook.db.entity.SysDictType;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Admin 端 - 字典管理
 */
@Tag(name = "Admin - 字典管理")
@RestController
@RequestMapping(value = "/admin/dict", produces = MediaType.APPLICATION_JSON_VALUE)
@RequiredArgsConstructor
public class DictController {

    private final IAdminDictService adminDictService;

    @RequirePermission("dict:list")
    @Operation(summary = "字典类型分页列表")
    @GetMapping(value = "/type/list", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<PageResult<SysDictType>> typeList(
            @RequestParam(defaultValue = "1") int current, @RequestParam(defaultValue = "10") int size,
            @RequestParam(required = false) String dictName, @RequestParam(required = false) String dictType,
            @RequestParam(required = false) Integer status) {
        return Result.success(adminDictService.typeList(current, size, dictName, dictType, status));
    }

    @RequirePermission("dict:add")
    @Operation(summary = "新增字典类型")
    @PostMapping(value = "/type", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> addType(@Valid @RequestBody DictTypeSaveDTO dto) {
        adminDictService.addType(dto);
        return Result.success();
    }

    @RequirePermission("dict:edit")
    @Operation(summary = "修改字典类型")
    @PutMapping(value = "/type", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> editType(@Valid @RequestBody DictTypeSaveDTO dto) {
        adminDictService.editType(dto);
        return Result.success();
    }

    @RequirePermission("dict:delete")
    @Operation(summary = "删除字典类型")
    @DeleteMapping(value = "/type/{id}", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> deleteType(@PathVariable Long id) {
        adminDictService.deleteType(id);
        return Result.success();
    }

    @RequirePermission("dict:list")
    @Operation(summary = "字典数据列表")
    @GetMapping(value = "/data/list", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<List<SysDict>> dataList(@RequestParam String dictType, @RequestParam(required = false) Integer status) {
        return Result.success(adminDictService.dataList(dictType, status));
    }

    @RequirePermission("dict:add")
    @Operation(summary = "新增字典数据")
    @PostMapping(value = "/data", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> addData(@Valid @RequestBody DictDataSaveDTO dto) {
        adminDictService.addData(dto);
        return Result.success();
    }

    @RequirePermission("dict:edit")
    @Operation(summary = "修改字典数据")
    @PutMapping(value = "/data", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> editData(@Valid @RequestBody DictDataSaveDTO dto) {
        adminDictService.editData(dto);
        return Result.success();
    }

    @RequirePermission("dict:delete")
    @Operation(summary = "删除字典数据")
    @DeleteMapping(value = "/data/{id}", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> deleteData(@PathVariable Long id) {
        adminDictService.deleteData(id);
        return Result.success();
    }
}
