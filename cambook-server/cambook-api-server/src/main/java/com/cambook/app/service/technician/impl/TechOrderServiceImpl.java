package com.cambook.app.service.technician.impl;

import com.cambook.app.common.statemachine.OrderStatus;
import com.cambook.app.common.statemachine.WalkinSessionStatus;
import com.cambook.app.service.technician.ITechOrderService;
import com.cambook.common.enums.CbCodeEnum;
import com.cambook.common.exception.BusinessException;
import com.cambook.db.entity.CbOrder;
import com.cambook.db.entity.CbWalkinSession;
import com.cambook.db.service.ICbOrderService;
import com.cambook.db.service.ICbWalkinSessionService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Optional;
import com.cambook.common.utils.DateUtils;

/**
 * 技师端订单操作服务实现
 *
 * @author CamBook
 */
@Service
@RequiredArgsConstructor
public class TechOrderServiceImpl implements ITechOrderService {

    private final ICbOrderService         cbOrderService;
    private final ICbWalkinSessionService cbWalkinSessionService;

    // ── 在线预约订单 ───────────────────────────────────────────────────────────

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void acceptOnline(Long techId, Long orderId) {
        requirePendingAccept(getOwnOrder(techId, orderId));
        cbOrderService.lambdaUpdate().set(CbOrder::getStatus, OrderStatus.ACCEPTED.getCode())
        .eq(CbOrder::getId, orderId).eq(CbOrder::getStatus, OrderStatus.PENDING_ACCEPT.getCode()).update();
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void rejectOnline(Long techId, Long orderId) {
        requirePendingAccept(getOwnOrder(techId, orderId));
        cbOrderService.lambdaUpdate().set(CbOrder::getStatus, OrderStatus.CANCELLED.getCode())
        .eq(CbOrder::getId, orderId).eq(CbOrder::getStatus, OrderStatus.PENDING_ACCEPT.getCode()).update();
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void startOnline(Long techId, Long orderId) {
        CbOrder order = getOwnOrder(techId, orderId);
        int st = order.getStatus();
        if (st != OrderStatus.ACCEPTED.getCode() && st != OrderStatus.ARRIVING.getCode() && st != OrderStatus.ARRIVED.getCode())
            throw new BusinessException(CbCodeEnum.ORDER_STATUS_ILLEGAL);
        cbOrderService.lambdaUpdate().set(CbOrder::getStatus, OrderStatus.IN_SERVICE.getCode())
        .set(CbOrder::getStartTime, DateUtils.nowSeconds()).in(CbOrder::getStatus, OrderStatus.ACCEPTED.getCode(), OrderStatus.ARRIVING.getCode(), OrderStatus.ARRIVED.getCode()).eq(CbOrder::getId, orderId).update();
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void completeOnline(Long techId, Long orderId) {
        CbOrder order = getOwnOrder(techId, orderId);
        if (order.getStatus() != OrderStatus.IN_SERVICE.getCode() && order.getStatus() != OrderStatus.ACCEPTED.getCode())
            throw new BusinessException(CbCodeEnum.ORDER_STATUS_ILLEGAL);
        long now = DateUtils.nowSeconds();
        boolean updated = cbOrderService.lambdaUpdate()
                .set(CbOrder::getStatus, OrderStatus.COMPLETED.getCode())
                .set(CbOrder::getEndTime, now)
                .set(order.getStartTime() == null || order.getStartTime() == 0, CbOrder::getStartTime, now)
                .in(CbOrder::getStatus, OrderStatus.ACCEPTED.getCode(), OrderStatus.IN_SERVICE.getCode())
                .eq(CbOrder::getId, orderId).update();
        if (!updated) throw new BusinessException(CbCodeEnum.ORDER_STATUS_ILLEGAL);
    }

    // ── 门店散客订单 ───────────────────────────────────────────────────────────

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void acceptWalkin(Long techId, Long sessionId) {
        requireCheckedIn(getOwnWalkin(techId, sessionId));
        cbWalkinSessionService.lambdaUpdate().set(CbWalkinSession::getStatus, WalkinSessionStatus.IN_SERVICE.getCode())
        .eq(CbWalkinSession::getId, sessionId).eq(CbWalkinSession::getStatus, WalkinSessionStatus.CHECKED_IN.getCode()).update();
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void rejectWalkin(Long techId, Long sessionId) {
        requireCheckedIn(getOwnWalkin(techId, sessionId));
        cbWalkinSessionService.lambdaUpdate().set(CbWalkinSession::getStatus, WalkinSessionStatus.CANCELLED.getCode())
        .eq(CbWalkinSession::getId, sessionId).eq(CbWalkinSession::getStatus, WalkinSessionStatus.CHECKED_IN.getCode()).update();
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void startWalkin(Long techId, Long sessionId) {
        CbWalkinSession s = getOwnWalkin(techId, sessionId);
        if (s.getStatus() != WalkinSessionStatus.CHECKED_IN.getCode() && s.getStatus() != WalkinSessionStatus.IN_SERVICE.getCode())
            throw new BusinessException(CbCodeEnum.ORDER_STATUS_ILLEGAL);
        boolean updated = cbWalkinSessionService.lambdaUpdate()
                .set(CbWalkinSession::getStatus, WalkinSessionStatus.IN_SERVICE.getCode())
                .set(CbWalkinSession::getServiceStartTime, DateUtils.nowSeconds())
                .in(CbWalkinSession::getStatus, WalkinSessionStatus.CHECKED_IN.getCode(), WalkinSessionStatus.IN_SERVICE.getCode())
                .eq(CbWalkinSession::getId, sessionId).update();
        if (!updated) throw new BusinessException(CbCodeEnum.ORDER_STATUS_ILLEGAL);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void completeWalkin(Long techId, Long sessionId) {
        CbWalkinSession s = getOwnWalkin(techId, sessionId);
        if (WalkinSessionStatus.of(s.getStatus()).map(WalkinSessionStatus::isTerminal).orElse(false)
                || s.getStatus() == WalkinSessionStatus.SERVICE_DONE.getCode())
            throw new BusinessException(CbCodeEnum.ORDER_STATUS_ILLEGAL);
        boolean updated = cbWalkinSessionService.lambdaUpdate()
                .set(CbWalkinSession::getStatus, WalkinSessionStatus.SERVICE_DONE.getCode())
                .notIn(CbWalkinSession::getStatus, WalkinSessionStatus.SERVICE_DONE.getCode(),
                        WalkinSessionStatus.SETTLED.getCode(), WalkinSessionStatus.CANCELLED.getCode())
                .eq(CbWalkinSession::getId, sessionId).update();
        if (!updated) throw new BusinessException(CbCodeEnum.ORDER_STATUS_ILLEGAL);
    }

    // ── 私有辅助 ──────────────────────────────────────────────────────────────

    private CbOrder getOwnOrder(Long techId, Long orderId) {
        CbOrder order = Optional.ofNullable(cbOrderService.getById(orderId))
        .filter(o -> Byte.valueOf((byte) 0).equals(o.getDeleted()))
        .orElseThrow(() -> new BusinessException(CbCodeEnum.ORDER_NOT_FOUND));
        if (!techId.equals(order.getTechnicianId())) throw new BusinessException(CbCodeEnum.NO_PERMISSION);
        return order;
    }

    private CbWalkinSession getOwnWalkin(Long techId, Long sessionId) {
        CbWalkinSession s = Optional.ofNullable(cbWalkinSessionService.getById(sessionId))
                .filter(w -> Byte.valueOf((byte) 0).equals(w.getDeleted()))
                .orElseThrow(() -> new BusinessException(CbCodeEnum.WALKIN_NOT_FOUND));
        if (!techId.equals(s.getTechnicianId())) throw new BusinessException(CbCodeEnum.NO_PERMISSION);
        return s;
    }

    private void requirePendingAccept(CbOrder order) {
        if (order.getStatus() != OrderStatus.PENDING_ACCEPT.getCode()) throw new BusinessException(CbCodeEnum.ORDER_STATUS_ILLEGAL);
    }

    private void requireCheckedIn(CbWalkinSession s) {
        if (s.getStatus() != WalkinSessionStatus.CHECKED_IN.getCode()) throw new BusinessException(CbCodeEnum.ORDER_STATUS_ILLEGAL);
    }
}
