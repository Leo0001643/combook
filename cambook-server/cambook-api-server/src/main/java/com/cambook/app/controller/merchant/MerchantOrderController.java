package com.cambook.app.controller.merchant;

import com.cambook.app.common.annotation.RequireMerchant;
import com.cambook.app.common.security.MerchantOwnershipGuard;
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

import java.math.BigDecimal;
import org.springframework.http.MediaType;

/**
 * 商户端 - 订单管理（薄包装层）
 *
 * <p>复用 {@link IAdminOrderService}，仅将 merchantId 注入查询条件实现数据隔离。
 * {@code @RequireMerchant} 切面自动完成身份 + URI 双重安全校验。
 *
 * @author CamBook
 */
@RequireMerchant
@Tag(name = "商户端 - 订单管理")
@RestController
@RequestMapping("/merchant/order")
public class MerchantOrderController {

    private final IAdminOrderService orderService;

    public MerchantOrderController(IAdminOrderService orderService) {
        this.orderService = orderService;
    }

    @Operation(summary = "商户订单列表")
    @GetMapping(value = "/list", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<PageResult<OrderVO>> list(OrderQueryDTO query) {
        query.setMerchantId(MerchantOwnershipGuard.requireMerchantId());
        // 在线订单页面默认只查 order_type=1（在线预约）；门店散客订单由 WalkinSession 接口处理
        if (query.getOrderType() == null) {
            query.setOrderType(1);
        }
        return Result.success(orderService.pageList(query));
    }

    @Operation(summary = "商户订单详情")
    @GetMapping(value = "/{id}", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<OrderVO> detail(@PathVariable Long id) {
        OrderVO vo = orderService.getDetail(id);
        MerchantOwnershipGuard.assertOwnership(vo.getMerchantId(), "订单", id);
        return Result.success(vo);
    }

    @Operation(summary = "取消订单")
    @PatchMapping(value = "/{id}/cancel", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> cancel(@PathVariable Long id,
                               @RequestParam(defaultValue = "前台取消") String reason) {
        OrderVO vo = orderService.getDetail(id);
        MerchantOwnershipGuard.assertOwnership(vo.getMerchantId(), "订单", id);
        orderService.cancel(id, reason);
        return Result.success();
    }

    @Operation(summary = "结算订单（组合支付）")
    @PostMapping(value = "/{id}/settle", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> settle(@PathVariable Long id,
                               @RequestParam BigDecimal paidAmount,
                               @RequestParam(required = false) String payRecords) {
        OrderVO vo = orderService.getDetail(id);
        MerchantOwnershipGuard.assertOwnership(vo.getMerchantId(), "订单", id);
        orderService.settle(id, paidAmount, payRecords);
        return Result.success();
    }

    @Operation(summary = "删除订单")
    @DeleteMapping(value = "/{id}", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> delete(@PathVariable Long id) {
        OrderVO vo = orderService.getDetail(id);
        MerchantOwnershipGuard.assertOwnership(vo.getMerchantId(), "订单", id);
        orderService.delete(id);
        return Result.success();
    }

    @Operation(summary = "新增在线订单（到店/上门）")
    @PostMapping(produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<OrderVO> create(@Valid @RequestBody OrderCreateRequest req) {
        req.setMerchantId(MerchantOwnershipGuard.requireMerchantId());
        return Result.success(orderService.create(req));
    }
}
