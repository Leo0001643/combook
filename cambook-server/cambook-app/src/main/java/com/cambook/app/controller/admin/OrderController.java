package com.cambook.app.controller.admin;

import com.cambook.common.annotation.RequirePermission;
import com.cambook.app.domain.dto.OrderCreateRequest;
import com.cambook.app.domain.dto.OrderQueryDTO;
import com.cambook.app.domain.vo.OrderVO;
import com.cambook.app.service.admin.IAdminOrderService;
import com.cambook.common.result.PageResult;
import com.cambook.common.result.Result;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;

/**
 * Admin 端 - 订单管理
 *
 * @author CamBook
 */
@Tag(name = "Admin - 订单管理")
@RestController("adminOrderController")
@RequestMapping("/admin/order")
public class OrderController {

    private final IAdminOrderService orderService;

    public OrderController(IAdminOrderService orderService) {
        this.orderService = orderService;
    }

    @RequirePermission("order:list")
    @Operation(summary = "分页查询订单列表")
    @GetMapping("/list")
    public Result<PageResult<OrderVO>> pageList(@Valid OrderQueryDTO query) {
        return Result.success(orderService.pageList(query));
    }

    @RequirePermission("order:detail")
    @Operation(summary = "订单详情")
    @GetMapping("/{id}")
    public Result<OrderVO> detail(@PathVariable Long id) {
        return Result.success(orderService.getDetail(id));
    }

    @RequirePermission("order:add")
    @Operation(summary = "新增在线订单（到店/上门）")
    @PostMapping
    public Result<OrderVO> create(@Valid @RequestBody OrderCreateRequest req,
                                  @RequestParam Long merchantId) {
        req.setMerchantId(merchantId);
        return Result.success(orderService.create(req));
    }
}
