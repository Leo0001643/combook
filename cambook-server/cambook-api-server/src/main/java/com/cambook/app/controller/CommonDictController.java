package com.cambook.app.controller;

import com.cambook.app.service.admin.IAdminDictService;
import com.cambook.common.result.Result;
import com.cambook.db.entity.SysDict;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * 公开字典查询接口
 *
 * <p>无需任何认证（Admin / Merchant / Member 均可访问），
 * 供前端所有角色加载字典下拉选项。仅提供只读查询，无新增 / 修改 / 删除操作。
 */
@Tag(name = "公共 - 字典查询")
@RestController
@RequestMapping(value = "/common/dict", produces = MediaType.APPLICATION_JSON_VALUE)
@RequiredArgsConstructor
public class CommonDictController {

    private final IAdminDictService adminDictService;

    @Operation(summary = "按字典类型获取启用的字典数据项")
    @GetMapping(value = "/data/list", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<List<SysDict>> dataList(@RequestParam String dictType, @RequestParam(required = false) Integer status) {
        return Result.success(adminDictService.dataList(dictType, status));
    }
}
