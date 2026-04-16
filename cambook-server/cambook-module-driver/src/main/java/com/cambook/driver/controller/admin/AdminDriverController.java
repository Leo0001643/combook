package com.cambook.driver.controller.admin;

import com.cambook.common.annotation.RequirePermission;
import com.cambook.common.result.PageResult;
import com.cambook.common.result.Result;
import com.cambook.driver.domain.dto.DriverAuditDTO;
import com.cambook.driver.domain.dto.DriverQueryDTO;
import com.cambook.driver.domain.vo.DriverVO;
import com.cambook.driver.service.admin.IAdminDriverService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * Admin 端 - 司机管理
 *
 * @author CamBook
 */
@Tag(name = "Admin - 司机管理")
@RestController
@RequestMapping("/admin/driver")
public class AdminDriverController {

    private final IAdminDriverService driverService;

    public AdminDriverController(IAdminDriverService driverService) {
        this.driverService = driverService;
    }

    @RequirePermission("driver:list")
    @Operation(summary = "分页查询司机列表")
    @GetMapping("/list")
    public Result<PageResult<DriverVO>> pageList(@Valid DriverQueryDTO query) {
        return Result.success(driverService.pageList(query));
    }

    @RequirePermission("driver:detail")
    @Operation(summary = "司机详情")
    @GetMapping("/{id}")
    public Result<DriverVO> detail(@PathVariable Long id) {
        return Result.success(driverService.getDetail(id));
    }

    @RequirePermission("driver:audit")
    @Operation(summary = "司机审核")
    @PostMapping("/audit")
    public Result<Void> audit(@Valid @RequestBody DriverAuditDTO dto) {
        driverService.audit(dto);
        return Result.success();
    }

    @RequirePermission("driver:bind")
    @Operation(summary = "绑定司机与车辆")
    @PostMapping("/{driverId}/bind-vehicle")
    public Result<Void> bindVehicle(@PathVariable Long driverId,
                                    @RequestParam Long vehicleId) {
        driverService.bindVehicle(driverId, vehicleId);
        return Result.success();
    }
}
