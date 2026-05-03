package com.cambook.app.controller.technician;

import com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper;
import com.cambook.app.common.statemachine.OrderStatus;
import com.cambook.common.context.MemberContext;
import com.cambook.common.exception.BusinessException;
import com.cambook.common.result.Result;
import com.cambook.dao.entity.CbOrder;
import com.cambook.dao.entity.CbWalkinSession;
import com.cambook.dao.mapper.CbOrderMapper;
import com.cambook.dao.mapper.CbWalkinSessionMapper;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

/**
 * 技师端 - 订单操作（接单 / 拒单 / 开始服务 / 完成服务）
 *
 * <p>在线预约订单（order_type=1）和门店散客订单（walkin session）均支持完整生命周期。
 * <p>所有接口均需 JWT 认证（由 AuthFilter 拦截 /tech/*）。
 *
 * @author CamBook
 */
@Tag(name = "技师端 - 订单操作", description = "在线预约与门店散客订单的接单/拒单/开始服务/完成服务")
@RestController
@RequestMapping("/tech/order")
@RequiredArgsConstructor
public class TechOrderController {

    private final CbOrderMapper         orderMapper;
    private final CbWalkinSessionMapper walkinMapper;

    // ──────────────────────────────────────────────────────────────────────────
    // 在线预约订单（order_type = 1）
    // ──────────────────────────────────────────────────────────────────────────

    /** 接单（在线预约）：status 1 → 2 */
    @Operation(summary = "接单（在线预约）")
    @PostMapping("/{id}/accept")
    @Transactional(rollbackFor = Exception.class)
    public Result<Void> acceptOnline(@PathVariable Long id) {
        CbOrder order = getOwnOrder(id);
        if (order.getStatus() != OrderStatus.PENDING_ACCEPT.getCode()) {
            throw new BusinessException("当前订单状态不允许接单");
        }
        orderMapper.update(null, new LambdaUpdateWrapper<CbOrder>()
                .eq(CbOrder::getId, id)
                .eq(CbOrder::getStatus, OrderStatus.PENDING_ACCEPT.getCode())
                .set(CbOrder::getStatus, OrderStatus.ACCEPTED.getCode()));
        return Result.success();
    }

    /** 拒单（在线预约）：status 1 → 7 */
    @Operation(summary = "拒单（在线预约）")
    @PostMapping("/{id}/reject")
    @Transactional(rollbackFor = Exception.class)
    public Result<Void> rejectOnline(@PathVariable Long id) {
        CbOrder order = getOwnOrder(id);
        if (order.getStatus() != OrderStatus.PENDING_ACCEPT.getCode()) {
            throw new BusinessException("当前订单状态不允许拒单");
        }
        orderMapper.update(null, new LambdaUpdateWrapper<CbOrder>()
                .eq(CbOrder::getId, id)
                .eq(CbOrder::getStatus, OrderStatus.PENDING_ACCEPT.getCode())
                .set(CbOrder::getStatus, OrderStatus.CANCELLED.getCode()));
        return Result.success();
    }

    /** 开始服务（在线预约）：status 2/3/4 → 5，兼容跳过前往/到达步骤的场景 */
    @Operation(summary = "开始服务（在线预约）")
    @PostMapping("/{id}/start")
    @Transactional(rollbackFor = Exception.class)
    public Result<Void> startOnline(@PathVariable Long id) {
        CbOrder order = getOwnOrder(id);
        int st = order.getStatus();
        if (st != OrderStatus.ACCEPTED.getCode()
                && st != OrderStatus.ARRIVING.getCode()
                && st != OrderStatus.ARRIVED.getCode()) {
            throw new BusinessException("当前订单状态不允许开始服务");
        }
        orderMapper.update(null, new LambdaUpdateWrapper<CbOrder>()
                .eq(CbOrder::getId, id)
                .in(CbOrder::getStatus,
                        OrderStatus.ACCEPTED.getCode(),
                        OrderStatus.ARRIVING.getCode(),
                        OrderStatus.ARRIVED.getCode())
                .set(CbOrder::getStatus, OrderStatus.IN_SERVICE.getCode())
                .set(CbOrder::getStartTime, System.currentTimeMillis() / 1000L));
        return Result.success();
    }

    /** 完成服务（在线预约）：status 5 → 6，也兼容 2(ACCEPTED) 直接完成 */
    @Operation(summary = "完成服务（在线预约）")
    @PostMapping("/{id}/complete")
    @Transactional(rollbackFor = Exception.class)
    public Result<Void> completeOnline(@PathVariable Long id) {
        CbOrder order = getOwnOrder(id);
        int st = order.getStatus();
        if (st != OrderStatus.IN_SERVICE.getCode() && st != OrderStatus.ACCEPTED.getCode()) {
            throw new BusinessException("当前订单状态不允许完成服务");
        }
        // WHERE status = :currentStatus 防止并发修改覆盖非法状态
        long now = System.currentTimeMillis() / 1000L;
        int rows = orderMapper.update(null, new LambdaUpdateWrapper<CbOrder>()
                .eq(CbOrder::getId, id)
                .in(CbOrder::getStatus, OrderStatus.ACCEPTED.getCode(), OrderStatus.IN_SERVICE.getCode())
                .set(CbOrder::getStatus, OrderStatus.COMPLETED.getCode())
                .set(CbOrder::getEndTime, now)
                // 若 startTime 未设置（如跳过 start 直接 complete），补全为当前时间
                .set(order.getStartTime() == null || order.getStartTime() == 0,
                        CbOrder::getStartTime, now));
        if (rows == 0) throw new BusinessException("订单状态已变更，请刷新后重试");
        return Result.success();
    }

    // ──────────────────────────────────────────────────────────────────────────
    // 门店散客订单（walkin session，order_type = 2）
    // ──────────────────────────────────────────────────────────────────────────

    /** 接单（门店散客）：session status 0 → 1 */
    @Operation(summary = "接单（门店散客）")
    @PostMapping("/walkin/{sessionId}/accept")
    @Transactional(rollbackFor = Exception.class)
    public Result<Void> acceptWalkin(@PathVariable Long sessionId) {
        CbWalkinSession session = getOwnWalkin(sessionId);
        if (session.getStatus() != 0) {
            throw new BusinessException("当前门店订单状态不允许接单");
        }
        walkinMapper.update(null, new LambdaUpdateWrapper<CbWalkinSession>()
                .eq(CbWalkinSession::getId, sessionId)
                .eq(CbWalkinSession::getStatus, 0)
                .set(CbWalkinSession::getStatus, 1));
        return Result.success();
    }

    /** 拒单（门店散客）：session status 0 → 4 */
    @Operation(summary = "拒单（门店散客）")
    @PostMapping("/walkin/{sessionId}/reject")
    @Transactional(rollbackFor = Exception.class)
    public Result<Void> rejectWalkin(@PathVariable Long sessionId) {
        CbWalkinSession session = getOwnWalkin(sessionId);
        if (session.getStatus() != 0) {
            throw new BusinessException("当前门店订单状态不允许拒单");
        }
        walkinMapper.update(null, new LambdaUpdateWrapper<CbWalkinSession>()
                .eq(CbWalkinSession::getId, sessionId)
                .eq(CbWalkinSession::getStatus, 0)
                .set(CbWalkinSession::getStatus, 4));
        return Result.success();
    }

    /** 开始服务（门店散客）：session status 0 or 1 → 1 */
    @Operation(summary = "开始服务（门店散客）")
    @PostMapping("/walkin/{sessionId}/start")
    @Transactional(rollbackFor = Exception.class)
    public Result<Void> startWalkin(@PathVariable Long sessionId) {
        CbWalkinSession session = getOwnWalkin(sessionId);
        if (session.getStatus() != 0 && session.getStatus() != 1) {
            throw new BusinessException("当前门店订单状态不允许开始服务");
        }
        int rows = walkinMapper.update(null, new LambdaUpdateWrapper<CbWalkinSession>()
                .eq(CbWalkinSession::getId, sessionId)
                .in(CbWalkinSession::getStatus, 0, 1)
                .set(CbWalkinSession::getStatus, 1)
                .set(CbWalkinSession::getServiceStartTime, System.currentTimeMillis() / 1000L));
        if (rows == 0) throw new BusinessException("门店订单状态已变更，请刷新后重试");
        return Result.success();
    }

    /** 完成服务（门店散客）：session status 0/1/2 → 3 (已结算/已完成) */
    @Operation(summary = "完成服务（门店散客）")
    @PostMapping("/walkin/{sessionId}/complete")
    @Transactional(rollbackFor = Exception.class)
    public Result<Void> completeWalkin(@PathVariable Long sessionId) {
        CbWalkinSession session = getOwnWalkin(sessionId);
        int st = session.getStatus();
        if (st == 3 || st == 4) {
            throw new BusinessException("门店订单已完成或已取消，无法重复操作");
        }
        int rows = walkinMapper.update(null, new LambdaUpdateWrapper<CbWalkinSession>()
                .eq(CbWalkinSession::getId, sessionId)
                .notIn(CbWalkinSession::getStatus, 3, 4)   // 防并发：只要不是终态就允许完成
                .set(CbWalkinSession::getStatus, 3));       // 3=已结算 → Flutter 映射为 COMPLETED
        if (rows == 0) throw new BusinessException("门店订单状态已变更，请刷新后重试");
        return Result.success();
    }

    // ──────────────────────────────────────────────────────────────────────────
    // 私有辅助方法
    // ──────────────────────────────────────────────────────────────────────────

    private CbOrder getOwnOrder(Long id) {
        Long techId = MemberContext.getMemberId();
        if (techId == null) throw new BusinessException("未登录或登录已过期");
        CbOrder order = orderMapper.selectById(id);
        if (order == null || !Integer.valueOf(0).equals(order.getDeleted())) {
            throw new BusinessException("订单不存在");
        }
        if (!techId.equals(order.getTechnicianId())) {
            throw new BusinessException("无权操作此订单");
        }
        return order;
    }

    private CbWalkinSession getOwnWalkin(Long sessionId) {
        Long techId = MemberContext.getMemberId();
        if (techId == null) throw new BusinessException("未登录或登录已过期");
        CbWalkinSession s = walkinMapper.selectById(sessionId);
        if (s == null || !Integer.valueOf(0).equals(s.getDeleted())) {
            throw new BusinessException("门店订单不存在");
        }
        if (!techId.equals(s.getTechnicianId())) {
            throw new BusinessException("无权操作此门店订单");
        }
        return s;
    }
}
