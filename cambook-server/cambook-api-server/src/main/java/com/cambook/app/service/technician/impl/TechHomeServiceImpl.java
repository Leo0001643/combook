package com.cambook.app.service.technician.impl;

import com.cambook.app.common.statemachine.OrderStatus;
import com.cambook.app.domain.vo.HomeStatsVO;
import com.cambook.app.domain.vo.OrderVO;
import com.cambook.app.domain.vo.ScheduleItemVO;
import com.cambook.app.service.technician.ITechHomeService;
import com.cambook.common.context.MemberContext;
import com.cambook.common.enums.CbCodeEnum;
import com.cambook.common.exception.BusinessException;
import com.cambook.common.utils.DateUtils;
import com.cambook.db.entity.CbOrder;
import com.cambook.db.entity.CbOrderItem;
import com.cambook.db.mapper.CbReviewMapper;
import com.cambook.db.service.ICbOrderItemService;
import com.cambook.db.service.ICbOrderService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;
import java.util.Optional;

/**
 * 技师端首页与订单看板服务实现
 *
 * <p>统计类数据（今日接单数、今日收入）通过 {@code lambdaQuery + stream} 计算，
 * 避免自定义聚合 SQL，保持架构一致性。数据量级为单技师日单数，性能可接受。
 *
 * @author CamBook
 */
@Service
@RequiredArgsConstructor
public class TechHomeServiceImpl implements ITechHomeService {


    /** 有效订单状态（排除待支付=0、取消/退款系列） */
    private static final List<Integer> ACTIVE_STATUSES = List.of(
            OrderStatus.PENDING_ACCEPT.getCode(), OrderStatus.ACCEPTED.getCode(),
            OrderStatus.ARRIVING.getCode(),       OrderStatus.ARRIVED.getCode(),
            OrderStatus.IN_SERVICE.getCode(),     OrderStatus.COMPLETED.getCode()
    );

    /** 待执行状态：已支付但未完成 */
    private static final List<Integer> PENDING_STATUSES = List.of(
            OrderStatus.PENDING_ACCEPT.getCode(), OrderStatus.ACCEPTED.getCode(),
            OrderStatus.ARRIVING.getCode(),       OrderStatus.ARRIVED.getCode()
    );

    /** 终态取消/退款状态 */
    private static final List<Integer> CANCELLED_STATUSES = List.of(
            OrderStatus.CANCELLED.getCode(), OrderStatus.REFUNDING.getCode(), OrderStatus.REFUNDED.getCode()
    );

    private final ICbOrderService     cbOrderService;
    private final ICbOrderItemService cbOrderItemService;
    private final CbReviewMapper      cbReviewMapper;

    // ── 首页统计 ─────────────────────────────────────────────────────────────

    @Override
    public HomeStatsVO getStats() {
        Long techId    = currentTechId();
        long todayStart = DateUtils.todayStart();
        long todayEnd   = DateUtils.todayEnd();

        List<CbOrder> todayOrders = cbOrderService.lambdaQuery()
                .eq(CbOrder::getTechnicianId, techId).ge(CbOrder::getCreateTime, todayStart)
                .le(CbOrder::getCreateTime, todayEnd).in(CbOrder::getStatus, ACTIVE_STATUSES).list();

        long todayAll = todayOrders.size();
        long todayCompleted =  todayOrders.stream().filter(o -> o.getStatus() == OrderStatus.COMPLETED.getCode()).count();
        long todayCancelled = cbOrderService.lambdaQuery().eq(CbOrder::getTechnicianId, techId)
                .ge(CbOrder::getCreateTime, todayStart).le(CbOrder::getCreateTime, todayEnd)
                .in(CbOrder::getStatus, CANCELLED_STATUSES).count();

        BigDecimal todayIncome = todayOrders.stream()
                .filter(o -> o.getStatus() == OrderStatus.COMPLETED.getCode())
                .map(o -> o.getTechIncome() != null ? o.getTechIncome() : BigDecimal.ZERO)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        BigDecimal todayRating = cbReviewMapper.avgTodayRating(techId);

        HomeStatsVO vo = new HomeStatsVO();
        vo.setTodayOrders(todayAll);
        vo.setTodayCompleted(todayCompleted);
        vo.setTodayAppointments(todayAll);
        vo.setTodayCancelled(todayCancelled);
        vo.setTodayIncome(todayIncome);
        vo.setTodayRating(todayRating);
        return vo;
    }

    // ── 今日安排 ─────────────────────────────────────────────────────────────

    @Override
    public List<ScheduleItemVO> getTodaySchedule() {
        Long techId    = currentTechId();
        long todayStart = DateUtils.todayStart();
        long todayEnd   = DateUtils.todayEnd();

        List<CbOrder> orders = cbOrderService.lambdaQuery().eq(CbOrder::getTechnicianId, techId).ge(CbOrder::getAppointTime, todayStart)
                .le(CbOrder::getAppointTime, todayEnd).in(CbOrder::getStatus, ACTIVE_STATUSES).orderByAsc(CbOrder::getAppointTime).list();

        if (orders.isEmpty()) return Collections.emptyList();
        List<Long> orderIds = orders.stream().map(CbOrder::getId).collect(Collectors.toList());
        List<CbOrderItem> allItems = cbOrderItemService.lambdaQuery().in(CbOrderItem::getOrderId, orderIds).list();
        Map<Long, List<CbOrderItem>> itemsByOrder = allItems.stream().collect(Collectors.groupingBy(CbOrderItem::getOrderId));

        return orders.stream().map(o -> {
            ScheduleItemVO vo = new ScheduleItemVO();
            vo.setOrderId(o.getId());
            vo.setOrderNo(o.getOrderNo());
            vo.setOrderType(o.getOrderType() != null ? o.getOrderType().intValue() : 1);
            vo.setAppointTime(o.getAppointTime());
            vo.setStatus(o.getStatus() != null ? o.getStatus().intValue() : null);
            vo.setPayAmount(o.getPayAmount());
            vo.setTechIncome(o.getTechIncome());
            vo.setServiceName(o.getServiceName());
            vo.setServiceDuration(o.getServiceDuration());

            List<CbOrderItem> items = itemsByOrder.getOrDefault(o.getId(), Collections.emptyList());
            vo.setItems(items.stream().map(OrderVO.OrderItemVO::from).collect(Collectors.toList()));
            vo.setItemCount(items.size());
            vo.setTotalDuration(items.stream().mapToInt(i -> (i.getServiceDuration() != null ? i.getServiceDuration() : 0) * (i.getQty() != null ? i.getQty() : 1)).sum());
            return vo;
        }).collect(Collectors.toList());
    }

    // ── 待执行订单数（角标）───────────────────────────────────────────────────

    @Override
    public Long getPendingOrderCount() {
        Long techId = currentTechId();
        return cbOrderService.lambdaQuery().eq(CbOrder::getTechnicianId, techId).in(CbOrder::getStatus, PENDING_STATUSES).count();
    }

    // ── 订单列表 ─────────────────────────────────────────────────────────────

    @Override
    public List<OrderVO> listOrders(List<Integer> statuses) {
        Long techId = currentTechId();
        List<CbOrder> orders = cbOrderService.lambdaQuery().eq(CbOrder::getTechnicianId, techId)
        .in(statuses != null && !statuses.isEmpty(), CbOrder::getStatus, statuses)
        .orderByDesc(CbOrder::getCreateTime).list();

        List<OrderVO> vos = orders.stream().map(OrderVO::from).collect(Collectors.toList());
        enrichItems(vos);
        return vos;
    }

    // ── 私有工具 ─────────────────────────────────────────────────────────────

    private Long currentTechId() {
        Long id = Optional.ofNullable(MemberContext.currentId()).orElseThrow(() -> new BusinessException(CbCodeEnum.MEMBER_NOT_FOUND));
        return id;
    }

    private void enrichItems(List<OrderVO> vos) {
        if (vos.isEmpty()) return;
        List<Long> orderIds = vos.stream().map(OrderVO::getId).collect(Collectors.toList());
        Map<Long, List<CbOrderItem>> grouped = cbOrderItemService.lambdaQuery().in(CbOrderItem::getOrderId, orderIds).list()
                .stream().collect(Collectors.groupingBy(CbOrderItem::getOrderId));
        vos.forEach(vo -> {
            List<CbOrderItem> items = grouped.get(vo.getId());
            if (items != null) {
                vo.setOrderItems(items.stream().map(OrderVO.OrderItemVO::from).collect(Collectors.toList()));
            }
        });
    }

}
