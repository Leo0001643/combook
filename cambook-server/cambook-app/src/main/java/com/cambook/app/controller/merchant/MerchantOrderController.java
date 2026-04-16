package com.cambook.app.controller.merchant;

import com.cambook.app.common.annotation.RequireMerchant;
import com.cambook.app.common.security.MerchantOwnershipGuard;
import com.cambook.app.domain.dto.OrderQueryDTO;
import com.cambook.app.domain.vo.OrderVO;
import com.cambook.app.service.admin.IAdminOrderService;
import com.cambook.common.result.PageResult;
import com.cambook.common.result.Result;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.web.bind.annotation.*;

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
    @GetMapping("/list")
    public Result<PageResult<OrderVO>> list(OrderQueryDTO query) {
        query.setMerchantId(MerchantOwnershipGuard.requireMerchantId());
        return Result.success(orderService.pageList(query));
    }

    @Operation(summary = "商户订单详情")
    @GetMapping("/{id}")
    public Result<OrderVO> detail(@PathVariable Long id) {
        OrderVO vo = orderService.getDetail(id);
        // 行级安全：校验订单归属当前商户，防止 IDOR 攻击
        MerchantOwnershipGuard.assertOwnership(vo.getMerchantId(), "订单", id);
        return Result.success(vo);
    }
}
