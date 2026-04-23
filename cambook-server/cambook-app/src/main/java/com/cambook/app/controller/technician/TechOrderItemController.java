package com.cambook.app.controller.technician;

import com.cambook.app.domain.dto.AddOrderItemDTO;
import com.cambook.app.domain.vo.OrderVO;
import com.cambook.app.service.technician.ITechOrderItemService;
import com.cambook.common.result.Result;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * 技师端 - 订单服务项管理
 *
 * <p>支持"一单多项"：技师接单后可为同一客人追加服务项目，
 * 未开始的项目也可取消，最终按所有有效项目统一结算。
 *
 * <p>所有接口均需 JWT 认证（由 AuthFilter 拦截 /tech/* 路径）。
 *
 * @author CamBook
 */
@Tag(name = "技师端 - 订单服务项", description = "一单多项追加与取消")
@RestController
@RequestMapping("/tech/order/{orderId}/item")
@RequiredArgsConstructor
public class TechOrderItemController {

    private final ITechOrderItemService itemService;

    @Operation(summary = "查询订单服务项列表")
    @GetMapping
    public Result<List<OrderVO.OrderItemVO>> list(@PathVariable Long orderId) {
        return Result.success(itemService.listItems(orderId));
    }

    @Operation(summary = "追加服务项", description = "向已接单/服务中的订单追加服务项目，自动重算订单金额")
    @PostMapping
    public Result<List<OrderVO.OrderItemVO>> add(@PathVariable Long orderId, @Valid @RequestBody AddOrderItemDTO dto) {
        return Result.success(itemService.addItem(orderId, dto));
    }

    @Operation(summary = "取消服务项", description = "取消指定的尚未开始的服务项（svc_status=0），自动重算订单金额")
    @DeleteMapping("/{itemId}")
    public Result<Void> remove(@PathVariable Long orderId, @PathVariable Long itemId) {
        itemService.removeItem(orderId, itemId);
        return Result.success();
    }
}
