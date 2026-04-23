package com.cambook.app.service.technician.impl;

import com.cambook.app.domain.vo.HomeStatsVO;
import com.cambook.app.domain.vo.OrderVO;
import com.cambook.app.domain.vo.ScheduleItemVO;
import com.cambook.app.service.technician.ITechHomeService;
import com.cambook.common.context.MemberContext;
import com.cambook.common.utils.MapRowUtils;
import com.cambook.dao.entity.CbOrderItem;
import com.cambook.dao.mapper.CbOrderItemMapper;
import com.cambook.dao.mapper.CbOrderMapper;
import com.cambook.dao.mapper.CbReviewMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * 技师首页数据服务实现
 *
 * @author CamBook
 */
@Service
@RequiredArgsConstructor
public class TechHomeServiceImpl implements ITechHomeService {

    private final CbOrderMapper     orderMapper;
    private final CbOrderItemMapper orderItemMapper;
    private final CbReviewMapper    reviewMapper;

    @Override
    public HomeStatsVO getStats() {
        Long techId = MemberContext.getMemberId();
        HomeStatsVO vo = new HomeStatsVO();
        vo.setTodayOrders(orderMapper.countTodayOrders(techId));
        vo.setTodayCompleted(orderMapper.countTodayCompleted(techId));
        vo.setTodayAppointments(orderMapper.countTodayAppointments(techId));
        vo.setTodayCancelled(orderMapper.countTodayCancelled(techId));
        vo.setTodayIncome(orderMapper.sumTodayIncome(techId));
        vo.setTodayRating(reviewMapper.avgTodayRating(techId));
        return vo;
    }

    @Override
    public int getPendingOrderCount() {
        return orderMapper.pendingOrderCount(MemberContext.getMemberId());
    }

    @Override
    public List<ScheduleItemVO> getTodaySchedule() {
        Long techId = MemberContext.getMemberId();
        List<Map<String, Object>> rows = orderMapper.selectTodaySchedule(techId);
        if (rows == null || rows.isEmpty()) return Collections.emptyList();

        // 先组装基础 VO
        List<ScheduleItemVO> vos = rows.stream().map(this::toBaseVO).collect(Collectors.toList());

        // 批量加载所有订单的服务项（一次 SQL，无 N+1）
        List<Long> orderIds = vos.stream().map(ScheduleItemVO::getOrderId).collect(Collectors.toList());
        Map<Long, List<CbOrderItem>> itemsByOrder = orderItemMapper.selectByOrderIds(orderIds)
                .stream().collect(Collectors.groupingBy(CbOrderItem::getOrderId));

        // 将服务项合并到 VO
        vos.forEach(vo -> {
            List<CbOrderItem> items = itemsByOrder.getOrDefault(vo.getOrderId(), Collections.emptyList());
            vo.setItems(items.stream().map(OrderVO.OrderItemVO::from).collect(Collectors.toList()));
            vo.setItemCount(items.size());
            vo.setTotalDuration(items.stream().mapToInt(i -> i.getServiceDuration() * i.getQty()).sum());
            // 兼容旧字段：首项快照
            if (!items.isEmpty()) {
                CbOrderItem first = items.get(0);
                vo.setServiceName(first.getServiceName());
                vo.setServiceDuration(first.getServiceDuration());
            }
        });

        return vos;
    }

    private ScheduleItemVO toBaseVO(Map<String, Object> row) {
        ScheduleItemVO vo = new ScheduleItemVO();
        vo.setOrderId(MapRowUtils.toLongOrNull(row.get("orderId")));
        vo.setOrderNo(MapRowUtils.toStr(row.get("orderNo")));
        vo.setAppointTime(MapRowUtils.toLongOrNull(row.get("appointTime")));
        // serviceName / serviceDuration 由服务项批量加载后覆盖；此处作保底 fallback
        vo.setServiceName(MapRowUtils.toStr(row.get("serviceName")));
        vo.setServiceDuration(MapRowUtils.toInt(row.get("serviceDuration")));
        vo.setStatus(MapRowUtils.toInt(row.get("status")));
        vo.setPayAmount(MapRowUtils.toBigDecimal(row.get("payAmount")));
        vo.setTechIncome(MapRowUtils.toBigDecimal(row.get("techIncome")));
        vo.setMemberNickname(MapRowUtils.toStr(row.get("memberNickname")));
        vo.setMemberAvatar(MapRowUtils.toStr(row.get("memberAvatar")));
        return vo;
    }
}
