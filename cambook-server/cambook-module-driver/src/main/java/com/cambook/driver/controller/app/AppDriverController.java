package com.cambook.driver.controller.app;

import com.cambook.common.result.Result;
import com.cambook.driver.domain.dto.DriverApplyDTO;
import com.cambook.driver.domain.vo.DispatchVO;
import com.cambook.driver.domain.vo.DriverVO;
import com.cambook.driver.service.app.IAppDriverService;
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

import java.util.List;

/**
 * App 端 - 司机自助
 *
 * @author CamBook
 */
@Tag(name = "App - 司机端")
@RestController
@RequestMapping("/app/driver")
public class AppDriverController {

    private final IAppDriverService driverService;

    public AppDriverController(IAppDriverService driverService) {
        this.driverService = driverService;
    }

    @Operation(summary = "申请成为司机")
    @PostMapping("/apply")
    public Result<Void> apply(@Valid @RequestBody DriverApplyDTO dto) {
        driverService.apply(dto);
        return Result.success();
    }

    @Operation(summary = "我的司机资料")
    @GetMapping("/mine")
    public Result<DriverVO> mine() {
        return Result.success(driverService.getMyProfile());
    }

    @Operation(summary = "更新在线状态：0离线 1待命 2执行中")
    @PostMapping("/online-status")
    public Result<Void> onlineStatus(@RequestParam Integer status) {
        driverService.updateOnlineStatus(status);
        return Result.success();
    }

    @Operation(summary = "获取待接派车单列表")
    @GetMapping("/dispatches/pending")
    public Result<List<DispatchVO>> pendingDispatches() {
        return Result.success(driverService.getPendingDispatches());
    }

    @Operation(summary = "接单")
    @PostMapping("/dispatches/{id}/accept")
    public Result<Void> accept(@PathVariable Long id) {
        driverService.acceptDispatch(id);
        return Result.success();
    }

    @Operation(summary = "上报当前位置")
    @PostMapping("/location")
    public Result<Void> location(@RequestParam Double lat, @RequestParam Double lng) {
        driverService.updateLocation(lat, lng);
        return Result.success();
    }
}
