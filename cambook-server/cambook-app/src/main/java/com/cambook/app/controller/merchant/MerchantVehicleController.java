package com.cambook.app.controller.merchant;

import com.baomidou.mybatisplus.core.metadata.IPage;
import com.cambook.app.common.annotation.RequireMerchant;
import com.cambook.app.common.security.MerchantOwnershipGuard;
import com.cambook.app.domain.dto.VehicleDTO;
import com.cambook.app.domain.vo.VehicleVO;
import com.cambook.app.service.admin.IVehicleService;
import com.cambook.common.result.Result;
import com.cambook.dao.entity.CbVehicle;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import org.springframework.web.bind.annotation.*;

/**
 * 商户端 - 车辆管理（薄包装层）
 *
 * <p>复用 {@link IVehicleService}，所有写操作强制注入当前商户 ID 并执行
 * 行级安全（IDOR 防护）。{@code @RequireMerchant} 切面自动完成身份 + URI 双重校验。
 *
 * @author CamBook
 */
@RequireMerchant
@Tag(name = "商户端 - 车辆管理")
@RestController
@RequestMapping("/merchant/vehicle")
public class MerchantVehicleController {

    private final IVehicleService vehicleService;

    public MerchantVehicleController(IVehicleService vehicleService) {
        this.vehicleService = vehicleService;
    }

    @Operation(summary = "车辆列表")
    @GetMapping("/list")
    public Result<IPage<VehicleVO>> list(
            @RequestParam(defaultValue = "1")  int     current,
            @RequestParam(defaultValue = "10") int     size,
            @RequestParam(required = false)    String  keyword,
            @RequestParam(required = false)    Integer status) {
        Long merchantId = MerchantOwnershipGuard.requireMerchantId();
        return Result.success(vehicleService.page(current, size, keyword, status, merchantId));
    }

    @Operation(summary = "新增车辆")
    @PostMapping("/add")
    public Result<Void> add(@ModelAttribute VehicleDTO dto) {
        // merchantId 强制来自 JWT，忽略客户端传入值
        dto.setMerchantId(MerchantOwnershipGuard.requireMerchantId());
        vehicleService.add(dto);
        return Result.success();
    }

    @Operation(summary = "编辑车辆")
    @PostMapping("/edit")
    public Result<Void> edit(@ModelAttribute VehicleDTO dto) {
        CbVehicle entity = vehicleService.getById(dto.getId());
        MerchantOwnershipGuard.assertOwnership(entity.getMerchantId(), "车辆", dto.getId());
        vehicleService.edit(dto);
        return Result.success();
    }

    @Operation(summary = "删除车辆")
    @PostMapping("/{id}/delete")
    public Result<Void> delete(@PathVariable Long id) {
        CbVehicle entity = vehicleService.getById(id);
        MerchantOwnershipGuard.assertOwnership(entity.getMerchantId(), "车辆", id);
        vehicleService.delete(id);
        return Result.success();
    }

    @Operation(summary = "修改车辆状态")
    @PostMapping("/{id}/status")
    public Result<Void> updateStatus(
            @PathVariable Long id,
            @RequestParam @Min(0) @Max(2) Integer status) {
        CbVehicle entity = vehicleService.getById(id);
        MerchantOwnershipGuard.assertOwnership(entity.getMerchantId(), "车辆", id);
        vehicleService.updateStatus(id, status);
        return Result.success();
    }
}
