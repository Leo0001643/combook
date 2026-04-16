package com.cambook.driver.controller.admin;

import com.cambook.common.annotation.RequirePermission;
import com.cambook.common.result.PageResult;
import com.cambook.common.result.Result;
import com.cambook.driver.domain.dto.DispatchDTO;
import com.cambook.driver.domain.dto.DispatchQueryDTO;
import com.cambook.driver.domain.vo.DispatchVO;
import com.cambook.driver.service.admin.IDispatchService;
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
 * Admin 端 - 派车单管理
 *
 * @author CamBook
 */
@Tag(name = "Admin - 派车单管理")
@RestController
@RequestMapping("/admin/dispatch")
public class AdminDispatchController {

    private final IDispatchService dispatchService;

    public AdminDispatchController(IDispatchService dispatchService) {
        this.dispatchService = dispatchService;
    }

    @RequirePermission("dispatch:add")
    @Operation(summary = "创建派车单")
    @PostMapping
    public Result<DispatchVO> create(@Valid @RequestBody DispatchDTO dto) {
        return Result.success(dispatchService.create(dto));
    }

    @RequirePermission("dispatch:list")
    @Operation(summary = "分页查询派车单")
    @GetMapping("/list")
    public Result<PageResult<DispatchVO>> pageList(@Valid DispatchQueryDTO query) {
        return Result.success(dispatchService.pageList(query));
    }

    @RequirePermission("dispatch:detail")
    @Operation(summary = "派车单详情")
    @GetMapping("/{id}")
    public Result<DispatchVO> detail(@PathVariable Long id) {
        return Result.success(dispatchService.getDetail(id));
    }

    @RequirePermission("dispatch:assign")
    @Operation(summary = "重新分配司机")
    @PostMapping("/{id}/assign")
    public Result<Void> assign(@PathVariable Long id, @RequestParam Long driverId) {
        dispatchService.assignDriver(id, driverId);
        return Result.success();
    }

    @RequirePermission("dispatch:cancel")
    @Operation(summary = "取消派车单")
    @PostMapping("/{id}/cancel")
    public Result<Void> cancel(@PathVariable Long id, @RequestParam String reason) {
        dispatchService.cancel(id, reason);
        return Result.success();
    }
}
