package com.cambook.app.controller.technician;

import com.cambook.app.service.technician.ITechOrderService;
import com.cambook.common.context.MemberContext;
import com.cambook.common.result.Result;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.*;

/**
 * 技师端 - 订单操作（接单 / 拒单 / 开始服务 / 完成服务）
 *
 * <p>在线预约订单（order_type=1）和门店散客订单（walkin session）均支持完整生命周期。
 *
 * @author CamBook
 */
@Tag(name = "技师端 - 订单操作", description = "在线预约与门店散客订单的接单/拒单/开始服务/完成服务")
@RestController
@RequestMapping(value = "/tech/order", produces = MediaType.APPLICATION_JSON_VALUE)
@RequiredArgsConstructor
public class TechOrderController {

    private final ITechOrderService techOrderService;

    // ── 在线预约订单（order_type = 1）────────────────────────────────────────

    @Operation(summary = "接单（在线预约）")
    @PostMapping(value = "/{id}/accept", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> acceptOnline(@PathVariable Long id) {
        techOrderService.acceptOnline(MemberContext.getMemberId(), id);
        return Result.success();
    }

    @Operation(summary = "拒单（在线预约）")
    @PostMapping(value = "/{id}/reject", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> rejectOnline(@PathVariable Long id) {
        techOrderService.rejectOnline(MemberContext.getMemberId(), id);
        return Result.success();
    }

    @Operation(summary = "开始服务（在线预约）")
    @PostMapping(value = "/{id}/start", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> startOnline(@PathVariable Long id) {
        techOrderService.startOnline(MemberContext.getMemberId(), id);
        return Result.success();
    }

    @Operation(summary = "完成服务（在线预约）")
    @PostMapping(value = "/{id}/complete", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> completeOnline(@PathVariable Long id) {
        techOrderService.completeOnline(MemberContext.getMemberId(), id);
        return Result.success();
    }

    // ── 门店散客订单（walkin session）────────────────────────────────────────

    @Operation(summary = "接单（门店散客）")
    @PostMapping(value = "/walkin/{sessionId}/accept", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> acceptWalkin(@PathVariable Long sessionId) {
        techOrderService.acceptWalkin(MemberContext.getMemberId(), sessionId);
        return Result.success();
    }

    @Operation(summary = "拒单（门店散客）")
    @PostMapping(value = "/walkin/{sessionId}/reject", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> rejectWalkin(@PathVariable Long sessionId) {
        techOrderService.rejectWalkin(MemberContext.getMemberId(), sessionId);
        return Result.success();
    }

    @Operation(summary = "开始服务（门店散客）")
    @PostMapping(value = "/walkin/{sessionId}/start", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> startWalkin(@PathVariable Long sessionId) {
        techOrderService.startWalkin(MemberContext.getMemberId(), sessionId);
        return Result.success();
    }

    @Operation(summary = "完成服务（门店散客）")
    @PostMapping(value = "/walkin/{sessionId}/complete", produces = MediaType.APPLICATION_JSON_VALUE)
    public Result<Void> completeWalkin(@PathVariable Long sessionId) {
        techOrderService.completeWalkin(MemberContext.getMemberId(), sessionId);
        return Result.success();
    }
}
