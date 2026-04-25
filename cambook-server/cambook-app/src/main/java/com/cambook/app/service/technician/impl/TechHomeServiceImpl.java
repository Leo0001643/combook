package com.cambook.app.service.technician.impl;

import com.cambook.app.domain.vo.HomeStatsVO;
import com.cambook.app.domain.vo.OrderVO;
import com.cambook.app.domain.vo.ScheduleItemVO;
import com.cambook.app.service.technician.ITechHomeService;
import com.cambook.common.context.MemberContext;
import com.cambook.common.utils.MapRowUtils;
import com.cambook.dao.entity.CbOrder;
import com.cambook.dao.entity.CbOrderItem;
import com.cambook.dao.entity.CbServiceCategory;
import com.cambook.dao.mapper.CbOrderItemMapper;
import com.cambook.dao.mapper.CbOrderMapper;
import com.cambook.dao.mapper.CbReviewMapper;
import com.cambook.dao.mapper.CbServiceCategoryMapper;
import com.cambook.dao.mapper.CbWalkinSessionMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;
import java.util.function.Function;

/**
 * 技师首页数据服务实现
 *
 * <p>今日安排合并两类订单来源：
 * <ol>
 *   <li>在线预约订单（cb_order, order_type=1）+ 服务项（cb_order_item）</li>
 *   <li>门店散客订单（cb_walkin_session）+ 服务项（cb_order, order_type=2）</li>
 * </ol>
 *
 * @author CamBook
 */
@Service
@RequiredArgsConstructor
public class TechHomeServiceImpl implements ITechHomeService {

    private final CbOrderMapper              orderMapper;
    private final CbOrderItemMapper          orderItemMapper;
    private final CbWalkinSessionMapper      walkinSessionMapper;
    private final CbReviewMapper             reviewMapper;
    private final CbServiceCategoryMapper    categoryMapper;

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

        List<ScheduleItemVO> result = new ArrayList<>();

        // ── 1. 在线预约订单（order_type=1）────────────────────────────────────
        result.addAll(buildOnlineSchedule(techId));

        // ── 2. 门店散客订单（walkin session）──────────────────────────────────
        result.addAll(buildWalkinSchedule(techId));

        // 按预约/签到时间升序统一排列
        result.sort(Comparator.comparingLong(vo -> vo.getAppointTime() == null ? 0L : vo.getAppointTime()));
        return result;
    }

    // ── 私有：在线订单 → ScheduleItemVO 列表 ────────────────────────────────────

    private List<ScheduleItemVO> buildOnlineSchedule(Long techId) {
        List<Map<String, Object>> rows = orderMapper.selectTodaySchedule(techId);
        if (rows == null || rows.isEmpty()) return Collections.emptyList();

        List<ScheduleItemVO> vos = rows.stream()
                .map(r -> toBaseVO(r, 1))
                .collect(Collectors.toList());

        // 批量加载「仅该技师负责的」服务项（无 N+1）
        List<Long> orderIds = vos.stream().map(ScheduleItemVO::getOrderId).collect(Collectors.toList());
        Map<Long, List<CbOrderItem>> itemsByOrder = orderItemMapper
                .selectByOrderIdsAndTechId(orderIds, techId)
                .stream()
                .collect(Collectors.groupingBy(CbOrderItem::getOrderId));

        // 批量查询服务分类名称（用于 nameI18n 多语言）
        List<Long> catIds = vos.stream()
                .flatMap(vo -> itemsByOrder.getOrDefault(vo.getOrderId(), Collections.emptyList()).stream())
                .map(CbOrderItem::getServiceItemId)
                .filter(id -> id != null)
                .distinct()
                .collect(Collectors.toList());
        Map<Long, CbServiceCategory> catById = catIds.isEmpty()
                ? Collections.emptyMap()
                : categoryMapper.selectBatchIds(catIds).stream()
                    .collect(Collectors.toMap(CbServiceCategory::getId, Function.identity()));

        vos.forEach(vo -> {
            List<CbOrderItem> items = itemsByOrder.getOrDefault(vo.getOrderId(), Collections.emptyList());
            List<OrderVO.OrderItemVO> itemVos = items.stream().map(item -> {
                OrderVO.OrderItemVO ivo = OrderVO.OrderItemVO.from(item);
                if (item.getServiceItemId() != null) {
                    ivo.setNameI18n(OrderVO.OrderItemVO.buildNameI18n(catById.get(item.getServiceItemId())));
                }
                return ivo;
            }).collect(Collectors.toList());
            vo.setItems(itemVos);
            vo.setItemCount(items.size());
            vo.setTotalDuration(items.stream().mapToInt(i -> i.getServiceDuration() * i.getQty()).sum());
            if (!items.isEmpty()) {
                CbOrderItem first = items.get(0);
                vo.setServiceName(first.getServiceName());
                vo.setServiceDuration(first.getServiceDuration());
            }
        });

        return vos;
    }

    // ── 私有：门店散客订单 → ScheduleItemVO 列表 ─────────────────────────────────

    private List<ScheduleItemVO> buildWalkinSchedule(Long techId) {
        List<Map<String, Object>> rows = walkinSessionMapper.selectTodayByTechId(techId);
        if (rows == null || rows.isEmpty()) return Collections.emptyList();

        List<ScheduleItemVO> vos = rows.stream()
                .map(r -> toBaseVO(r, 2))
                .collect(Collectors.toList());

        // 批量加载每个 session 下该技师负责的 walkin 服务项（cb_order, order_type=2）
        List<Long> sessionIds = vos.stream().map(ScheduleItemVO::getOrderId).collect(Collectors.toList());
        Map<Long, List<CbOrder>> itemsBySession = orderMapper
                .selectWalkinOrdersBySessionIds(sessionIds)
                .stream()
                .collect(Collectors.groupingBy(CbOrder::getSessionId));

        // 批量查询 walkin 服务分类多语言名
        List<Long> walkinCatIds = vos.stream()
                .flatMap(vo -> itemsBySession.getOrDefault(vo.getOrderId(), Collections.emptyList()).stream())
                .map(CbOrder::getServiceItemId)
                .filter(id -> id != null)
                .distinct()
                .collect(Collectors.toList());
        Map<Long, CbServiceCategory> walkinCatById = walkinCatIds.isEmpty()
                ? Collections.emptyMap()
                : categoryMapper.selectBatchIds(walkinCatIds).stream()
                    .collect(Collectors.toMap(CbServiceCategory::getId, Function.identity()));

        vos.forEach(vo -> {
            List<CbOrder> walkinOrders = itemsBySession.getOrDefault(vo.getOrderId(), Collections.emptyList());
            List<OrderVO.OrderItemVO> items = walkinOrders.stream().map(o -> {
                OrderVO.OrderItemVO ivo = OrderVO.OrderItemVO.fromWalkinOrder(o);
                if (o.getServiceItemId() != null) {
                    ivo.setNameI18n(OrderVO.OrderItemVO.buildNameI18n(walkinCatById.get(o.getServiceItemId())));
                }
                return ivo;
            }).collect(Collectors.toList());
            vo.setItems(items);
            vo.setItemCount(items.size());
            vo.setTotalDuration(walkinOrders.stream()
                    .mapToInt(o -> o.getServiceDuration() != null ? o.getServiceDuration() : 0)
                    .sum());
            if (!walkinOrders.isEmpty()) {
                CbOrder first = walkinOrders.get(0);
                vo.setServiceName(first.getServiceName());
                vo.setServiceDuration(first.getServiceDuration() != null ? first.getServiceDuration() : 0);
            }
        });

        return vos;
    }

    @Override
    public List<OrderVO> listOrders(List<Integer> statuses) {
        Long techId = MemberContext.getMemberId();

        // ── 1. 在线预约订单（order_type=1）──────────────────────────────────────
        List<Map<String, Object>> onlineRows = orderMapper.listTechOrders(techId, statuses);
        List<OrderVO> onlineVos = Collections.emptyList();
        if (onlineRows != null && !onlineRows.isEmpty()) {
            List<Long> orderIds = onlineRows.stream()
                    .map(r -> MapRowUtils.toLongOrNull(r.get("id")))
                    .collect(Collectors.toList());
            List<CbOrderItem> allItems = orderItemMapper
                    .selectByOrderIdsAndTechId(orderIds, techId);

            // 批量加载服务分类（用于 duration 兜底：若 service_duration=0 从分类补全）
            List<Long> onlineCatIds = allItems.stream()
                    .map(CbOrderItem::getServiceItemId)
                    .filter(id -> id != null)
                    .distinct()
                    .collect(Collectors.toList());
            Map<Long, CbServiceCategory> onlineCatMap = onlineCatIds.isEmpty()
                    ? Collections.emptyMap()
                    : categoryMapper.selectBatchIds(onlineCatIds).stream()
                            .collect(Collectors.toMap(CbServiceCategory::getId, Function.identity()));

            Map<Long, List<CbOrderItem>> itemsByOrder = allItems.stream()
                    .collect(Collectors.groupingBy(CbOrderItem::getOrderId));
            onlineVos = onlineRows.stream().map(r -> {
                Long orderId = MapRowUtils.toLongOrNull(r.get("id"));
                OrderVO vo = new OrderVO();
                vo.setId(orderId);
                vo.setOrderNo(MapRowUtils.toStr(r.get("orderNo")));
                vo.setOrderType(1);
                vo.setServiceMode(MapRowUtils.toInt(r.get("serviceMode")));
                vo.setStatus(MapRowUtils.toInt(r.get("status")));
                vo.setPayAmount(MapRowUtils.toBigDecimal(r.get("payAmount")));
                vo.setAppointTime(MapRowUtils.toLongOrNull(r.get("appointTime")));
                vo.setCreateTime(MapRowUtils.toLongOrNull(r.get("createTime")));
                vo.setStartTime(MapRowUtils.toLongOrNull(r.get("startTime")));
                vo.setEndTime(MapRowUtils.toLongOrNull(r.get("endTime")));
                vo.setRemark(MapRowUtils.toStr(r.get("remark")));
                vo.setMemberId(MapRowUtils.toLongOrNull(r.get("memberId")));
                vo.setMemberNickname(MapRowUtils.toStr(r.get("memberNickname")));
                vo.setMemberMobile(MapRowUtils.toStr(r.get("memberMobile")));
                vo.setServiceName(MapRowUtils.toStr(r.get("serviceName")));
                List<CbOrderItem> items = itemsByOrder.getOrDefault(orderId, Collections.emptyList());
                List<OrderVO.OrderItemVO> itemVos = items.stream().map(item -> {
                    OrderVO.OrderItemVO ivo = OrderVO.OrderItemVO.from(item);
                    // duration 兜底：若 service_duration = 0，从分类表补全
                    if ((ivo.getServiceDuration() == null || ivo.getServiceDuration() == 0)
                            && item.getServiceItemId() != null) {
                        CbServiceCategory cat = onlineCatMap.get(item.getServiceItemId());
                        if (cat != null && cat.getDuration() != null && cat.getDuration() > 0) {
                            ivo.setServiceDuration(cat.getDuration());
                        }
                    }
                    if (item.getServiceItemId() != null) {
                        ivo.setNameI18n(OrderVO.OrderItemVO.buildNameI18n(onlineCatMap.get(item.getServiceItemId())));
                    }
                    return ivo;
                }).collect(Collectors.toList());
                vo.setOrderItems(itemVos);
                return vo;
            }).collect(Collectors.toList());
        }

        // ── 2. 门店散客订单（cb_walkin_session + cb_order order_type=2）──────────
        List<Map<String, Object>> walkinRows = walkinSessionMapper.selectRecentByTechId(techId, statuses);
        List<OrderVO> walkinVos = Collections.emptyList();
        if (walkinRows != null && !walkinRows.isEmpty()) {
            List<Long> sessionIds = walkinRows.stream()
                    .map(r -> MapRowUtils.toLongOrNull(r.get("sessionId")))
                    .collect(Collectors.toList());
            // 批量加载每个 session 下的服务项（cb_order order_type=2）
            Map<Long, List<CbOrder>> walkinItemsBySession = orderMapper
                    .selectWalkinOrdersBySessionIds(sessionIds)
                    .stream()
                    .collect(Collectors.groupingBy(CbOrder::getSessionId));
            // 批量加载服务分类名称（多语言）
            List<Long> serviceIds = walkinRows.stream()
                    .flatMap(r -> {
                        Long sid = MapRowUtils.toLongOrNull(r.get("sessionId"));
                        List<CbOrder> items2 = walkinItemsBySession.getOrDefault(sid, Collections.emptyList());
                        return items2.stream()
                                .map(o -> o.getServiceItemId() != null ? o.getServiceItemId() : 0L);
                    })
                    .filter(id -> id > 0)
                    .distinct()
                    .collect(Collectors.toList());
            Map<Long, CbServiceCategory> categoryMap = serviceIds.isEmpty()
                    ? Collections.emptyMap()
                    : categoryMapper.selectBatchIds(serviceIds).stream()
                            .collect(Collectors.toMap(CbServiceCategory::getId, Function.identity()));

            walkinVos = walkinRows.stream().map(r -> {
                Long sessionId = MapRowUtils.toLongOrNull(r.get("sessionId"));
                OrderVO vo = new OrderVO();
                vo.setId(sessionId);
                vo.setOrderNo(MapRowUtils.toStr(r.get("orderNo")));
                vo.setOrderType(2);   // 门店散客
                vo.setServiceMode(2); // 店内服务
                vo.setStatus(MapRowUtils.toInt(r.get("mappedStatus")));
                vo.setPayAmount(MapRowUtils.toBigDecimal(r.get("payAmount")));
                vo.setAppointTime(MapRowUtils.toLongOrNull(r.get("appointTime")));
                vo.setCreateTime(MapRowUtils.toLongOrNull(r.get("createTime")));
                vo.setStartTime(MapRowUtils.toLongOrNull(r.get("startTime")));
                vo.setRemark(MapRowUtils.toStr(r.get("remark")));
                vo.setMemberNickname(MapRowUtils.toStr(r.get("memberNickname")));
                vo.setMemberMobile(MapRowUtils.toStr(r.get("memberMobile")));
                List<CbOrder> svcItems = walkinItemsBySession.getOrDefault(sessionId, Collections.emptyList());
                List<OrderVO.OrderItemVO> itemVos = svcItems.stream().map(o -> {
                    OrderVO.OrderItemVO iVO = new OrderVO.OrderItemVO();
                    iVO.setId(o.getId());
                    iVO.setServiceItemId(o.getServiceItemId());
                    iVO.setServiceName(o.getServiceName());
                    iVO.setServiceDuration(o.getServiceDuration() != null ? o.getServiceDuration() : 0);
                    iVO.setUnitPrice(o.getPayAmount());
                    iVO.setQty(1);
                    // 服务项状态：cb_order.status 5→服务中(1) 6→已完成(2) 其它→待服务(0)
                    int svcSt = switch (o.getStatus() == null ? -1 : o.getStatus()) {
                        case 5  -> 1;
                        case 6  -> 2;
                        default -> 0;
                    };
                    iVO.setSvcStatus(svcSt);
                    iVO.setStartTime(o.getStartTime());
                    iVO.setEndTime(o.getEndTime());
                    CbServiceCategory cat = o.getServiceItemId() != null
                            ? categoryMap.get(o.getServiceItemId()) : null;
                    if (cat != null) iVO.setNameI18n(OrderVO.OrderItemVO.buildNameI18n(cat));
                    return iVO;
                }).collect(Collectors.toList());
                vo.setOrderItems(itemVos);
                return vo;
            }).collect(Collectors.toList());
        }

        // ── 3. 合并，按创建时间倒序 ───────────────────────────────────────────────
        List<OrderVO> result = new ArrayList<>(onlineVos.size() + walkinVos.size());
        result.addAll(onlineVos);
        result.addAll(walkinVos);
        result.sort(Comparator.comparingLong((OrderVO v) -> v.getCreateTime() != null ? v.getCreateTime() : 0L).reversed());
        return result;
    }

    // ── 私有：Map 行 → ScheduleItemVO（orderType 由调用方注入）──────────────────

    private ScheduleItemVO toBaseVO(Map<String, Object> row, int orderType) {
        ScheduleItemVO vo = new ScheduleItemVO();
        // walkin 用 sessionId，online 用 orderId，列别名统一用 orderId/sessionId 均可
        Long id = MapRowUtils.toLongOrNull(row.get("orderId"));
        if (id == null) id = MapRowUtils.toLongOrNull(row.get("sessionId"));
        vo.setOrderId(id);
        vo.setOrderType(orderType);
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
