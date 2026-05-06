package com.cambook.app.controller.app;

import com.cambook.app.domain.dto.CancelOrderDTO;
import com.cambook.app.domain.dto.CreateOrderDTO;
import com.cambook.app.domain.vo.OrderVO;
import com.cambook.app.service.app.IAppOrderService;
import com.cambook.common.result.PageResult;
import com.cambook.common.result.Result;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.http.MediaType;

/**
 * App 端 - 订单
 *
 * @author CamBook
 */
@Tag(name = "App - 订单")
@RestController("appOrderController")
@RequestMapping("/app/order")
public class OrderController {

    private final IAppOrderService orderService;

    public OrderController(IAppOrderService orderService) {
        this.orderService = orderService;
    }

    /**
     * 创建预约订单
     *
     * <p>接受 JSON 请求体，支持在一次调用中预约多个服务项，每个项目可指定不同的技师。
     * 后端对服务项价格进行独立查询，保障价格安全。
     */
    @Operation(summary = "创建预约订单（支持多项目、多技师）")
    @PostMapping(produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<OrderVO> create(@Valid @RequestBody CreateOrderDTO dto) {
        return Result.success(orderService.createOrder(dto));
    }

    @Operation(summary = "我的订单列表")
    @GetMapping(value = "/list", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<PageResult<OrderVO>> myOrders(
            @RequestParam(required = false) Integer status,
            @RequestParam(defaultValue = "1")  int page,
            @RequestParam(defaultValue = "20") int size) {
        return Result.success(orderService.myOrders(status, page, size));
    }

    @Operation(summary = "订单详情")
    @GetMapping(value = "/{id}", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<OrderVO> detail(@PathVariable Long id) {
        return Result.success(orderService.getDetail(id));
    }

    @Operation(summary = "取消订单")
    @PostMapping(value = "/cancel", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> cancel(@Valid @ModelAttribute CancelOrderDTO dto) {
        orderService.cancel(dto);
        return Result.success();
    }
}
