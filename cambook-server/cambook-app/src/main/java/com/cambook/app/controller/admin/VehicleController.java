package com.cambook.app.controller.admin;

import com.baomidou.mybatisplus.core.metadata.IPage;
import com.cambook.app.domain.dto.VehicleDTO;
import com.cambook.app.domain.vo.VehicleVO;
import com.cambook.app.service.admin.IVehicleService;
import com.cambook.common.annotation.RequirePermission;
import com.cambook.common.result.Result;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;

/**
 * Admin 端 - 车辆管理
 *
 * @author CamBook
 */
@Tag(name = "Admin - 车辆管理")
@RestController
@RequestMapping("/admin/vehicle")
public class VehicleController {

    private final IVehicleService vehicleService;

    public VehicleController(IVehicleService vehicleService) {
        this.vehicleService = vehicleService;
    }

    @RequirePermission("vehicle:list")
    @Operation(summary = "车辆分页列表")
    @GetMapping("/list")
    public Result<IPage<VehicleVO>> list(
            @RequestParam(defaultValue = "1")   int     current,
            @RequestParam(defaultValue = "10")  int     size,
            @RequestParam(required = false)     String  keyword,
            @RequestParam(required = false)     Integer status,
            @RequestParam(required = false)     Long    merchantId) {
        return Result.success(vehicleService.page(current, size, keyword, status, merchantId));
    }

    @RequirePermission("vehicle:add")
    @Operation(summary = "新增车辆")
    @PostMapping
    public Result<Void> add(@Valid @ModelAttribute VehicleDTO dto) {
        vehicleService.add(dto);
        return Result.success();
    }

    @RequirePermission("vehicle:edit")
    @Operation(summary = "编辑车辆信息")
    @PutMapping
    public Result<Void> edit(@Valid @ModelAttribute VehicleDTO dto) {
        vehicleService.edit(dto);
        return Result.success();
    }

    @RequirePermission("vehicle:delete")
    @Operation(summary = "删除车辆")
    @DeleteMapping("/{id}")
    public Result<Void> delete(@PathVariable Long id) {
        vehicleService.delete(id);
        return Result.success();
    }

    @RequirePermission("vehicle:edit")
    @Operation(summary = "修改车辆状态")
    @PatchMapping("/{id}/status")
    public Result<Void> updateStatus(@PathVariable Long id,
                                     @RequestParam Integer status) {
        vehicleService.updateStatus(id, status);
        return Result.success();
    }
}
