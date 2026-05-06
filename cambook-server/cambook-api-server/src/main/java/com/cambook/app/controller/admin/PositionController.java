package com.cambook.app.controller.admin;

import com.cambook.common.annotation.RequirePermission;
import com.cambook.app.domain.dto.PositionDTO;
import com.cambook.app.domain.vo.PositionVO;
import com.cambook.app.service.admin.IPositionService;
import com.cambook.common.result.Result;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import org.springframework.http.MediaType;

/**
 * Admin 端 - 职位管理
 *
 * @author CamBook
 */
@Tag(name = "Admin - 职位管理")
@RestController
@RequestMapping("/admin/position")
public class PositionController {

    private final IPositionService positionService;

    public PositionController(IPositionService positionService) {
        this.positionService = positionService;
    }

    @RequirePermission("position:list")
    @Operation(summary = "职位列表")
    @GetMapping(value = "/list", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<List<PositionVO>> list() {
        return Result.success(positionService.list());
    }

    @RequirePermission("position:add")
    @Operation(summary = "新增职位")
    @PostMapping(produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> add(@Valid @ModelAttribute PositionDTO dto) {
        positionService.add(dto);
        return Result.success();
    }

    @RequirePermission("position:edit")
    @Operation(summary = "修改职位")
    @PutMapping(produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> edit(@Valid @ModelAttribute PositionDTO dto) {
        positionService.edit(dto);
        return Result.success();
    }

    @RequirePermission("position:delete")
    @Operation(summary = "删除职位")
    @DeleteMapping(value = "/{id}", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> delete(@PathVariable Long id) {
        positionService.delete(id);
        return Result.success();
    }

    @RequirePermission("position:edit")
    @Operation(summary = "修改职位状态")
    @PatchMapping(value = "/{id}/status", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> updateStatus(@PathVariable Long id,@RequestParam Integer status) {
        positionService.updateStatus(id, status);
        return Result.success();
    }
}
