package com.cambook.app.controller;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.cambook.common.result.Result;
import com.cambook.dao.entity.SysDictData;
import com.cambook.dao.mapper.SysDictDataMapper;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * 公开字典查询接口
 *
 * <p>无需任何认证（Admin / Merchant / Member 均可访问），
 * 供前端所有角色加载字典下拉选项。
 * 仅提供只读查询，无新增 / 修改 / 删除操作。
 *
 * @author CamBook
 */
@Tag(name = "公共 - 字典查询")
@RestController
@RequestMapping("/common/dict")
public class CommonDictController {

    private final SysDictDataMapper dataMapper;

    public CommonDictController(SysDictDataMapper dataMapper) {
        this.dataMapper = dataMapper;
    }

    @Operation(summary = "按字典类型获取启用的字典数据项")
    @GetMapping("/data/list")
    public Result<List<SysDictData>> dataList(
            @RequestParam String dictType,
            @RequestParam(required = false) Integer status) {
        return Result.success(dataMapper.selectList(
                new LambdaQueryWrapper<SysDictData>()
                        .eq(SysDictData::getDictType, dictType)
                        .eq(status != null, SysDictData::getStatus, status)
                        .orderByAsc(SysDictData::getSort)));
    }
}
