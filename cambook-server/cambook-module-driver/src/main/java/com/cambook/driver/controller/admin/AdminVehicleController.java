package com.cambook.driver.controller.admin;

import com.cambook.common.annotation.RequirePermission;
import com.cambook.common.result.Result;
import com.cambook.driver.domain.dto.VehicleDTO;
import com.cambook.driver.domain.vo.VehicleVO;
import com.cambook.driver.service.admin.IVehicleService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * Admin 端 - 车辆管理
 *
 * @author CamBook
 */
@Tag(name = "Admin - 车辆管理")
@RestController
@RequestMapping("/admin/vehicle")
public class AdminVehicleController {

    private final IVehicleService vehicleService;

    public AdminVehicleController(IVehicleService vehicleService) {
        this.vehicleService = vehicleService;
    }

    @RequirePermission("vehicle:list")
    @Operation(summary = "车辆列表")
    @GetMapping("/list")
    public Result<List<VehicleVO>> list() {
        return Result.success(vehicleService.listAll());
    }

    @RequirePermission("vehicle:list")
    @Operation(summary = "空闲车辆（派单用）")
    @GetMapping("/idle")
    public Result<List<VehicleVO>> idle() {
        return Result.success(vehicleService.listIdle());
    }

    @RequirePermission("vehicle:add")
    @Operation(summary = "新增车辆")
    @PostMapping
    public Result<Void> add(@Valid @RequestBody VehicleDTO dto) {
        vehicleService.add(dto);
        return Result.success();
    }

    @RequirePermission("vehicle:edit")
    @Operation(summary = "修改车辆")
    @PutMapping
    public Result<Void> edit(@Valid @RequestBody VehicleDTO dto) {
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
}
