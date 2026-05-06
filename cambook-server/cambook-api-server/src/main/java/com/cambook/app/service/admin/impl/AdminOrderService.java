package com.cambook.app.service.admin.impl;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.cambook.app.common.event.OrderStatusChangedEvent;
import com.cambook.app.domain.dto.OrderCreateRequest;
import com.cambook.app.domain.dto.OrderQueryDTO;
import com.cambook.app.domain.vo.OrderVO;
import com.cambook.app.service.admin.IAdminOrderService;
import com.cambook.common.enums.CbCodeEnum;
import com.cambook.common.exception.BusinessException;
import com.cambook.common.result.PageResult;
import com.cambook.db.entity.CbMember;
import com.cambook.db.entity.CbOrder;
import com.cambook.db.entity.CbOrderItem;
import com.cambook.db.entity.CbServiceCategory;
import com.cambook.db.entity.CbTechnician;
import com.cambook.db.service.ICbMemberService;
import com.cambook.db.service.ICbOrderItemService;
import com.cambook.db.service.ICbOrderService;
import com.cambook.db.service.ICbServiceCategoryService;
import com.cambook.db.service.ICbTechnicianService;
import lombok.RequiredArgsConstructor;
import org.apache.commons.lang3.StringUtils;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.stream.Collectors;
import com.cambook.common.utils.DateUtils;

/**
 * Admin 端订单管理服务实现
 *
 * @author CamBook
 */
@Service
@RequiredArgsConstructor
public class AdminOrderService implements IAdminOrderService {

    private static final int ORDER_TYPE_BOOKING    = 1;
    private static final int ORDER_STATUS_PENDING  = 1;
    private static final int ORDER_STATUS_COMPLETE = 6;
    private static final int ORDER_STATUS_CANCEL   = 7;
    private static final int SVC_STATUS_PENDING    = 0;

    private final ICbOrderService           cbOrderService;
    private final ICbOrderItemService       cbOrderItemService;
    private final ICbMemberService          cbMemberService;
    private final ICbTechnicianService      cbTechnicianService;
    private final ICbServiceCategoryService cbServiceCategoryService;
    private final ApplicationEventPublisher eventPublisher;

    @Override
    public PageResult<OrderVO> pageList(OrderQueryDTO query) {
        var p = cbOrderService.lambdaQuery()
                .eq(query.getMerchantId()  != null, CbOrder::getMerchantId,  query.getMerchantId())
                .eq(query.getOrderType()   != null, CbOrder::getOrderType,   query.getOrderType())
                .like(StringUtils.isNotBlank(query.getOrderNo()), CbOrder::getOrderNo, query.getOrderNo())
                .eq(query.getStatus()      != null, CbOrder::getStatus,      query.getStatus())
                .eq(query.getServiceMode() != null, CbOrder::getServiceMode, query.getServiceMode())
                .ge(query.getStartDate()   != null, CbOrder::getCreateTime,  query.getStartDate())
                .le(query.getEndDate()     != null, CbOrder::getCreateTime,  query.getEndDate())
                .orderByDesc(CbOrder::getCreateTime)
                .page(new Page<>(query.getPage(), query.getSize()));

        List<OrderVO> vos = p.getRecords().stream().map(OrderVO::from).collect(Collectors.toList());
        enrichNicknames(vos);
        enrichOrderItems(vos);

        // keyword 后置过滤
        List<OrderVO> filtered = vos;
        if (StringUtils.isNotBlank(query.getKeyword())) {
            String kw = query.getKeyword().toLowerCase();
            filtered = vos.stream().filter(vo ->
                    (vo.getOrderNo()           != null && vo.getOrderNo().toLowerCase().contains(kw)) ||
                    (vo.getMemberNickname()     != null && vo.getMemberNickname().toLowerCase().contains(kw)) ||
                    (vo.getTechnicianNickname() != null && vo.getTechnicianNickname().toLowerCase().contains(kw)) ||
                    (vo.getTechnicianNo()       != null && vo.getTechnicianNo().toLowerCase().contains(kw))
            ).collect(Collectors.toList());
        }

        return PageResult.of(filtered, p.getTotal(), query.getPage(), query.getSize());
    }

    @Override
    public OrderVO getDetail(Long id) {
        CbOrder order = Optional.ofNullable(cbOrderService.getById(id))
                .orElseThrow(() -> new BusinessException(CbCodeEnum.ORDER_NOT_FOUND));
        OrderVO vo = OrderVO.from(order);
        enrichNicknames(List.of(vo));

        List<CbOrderItem> items = cbOrderItemService.lambdaQuery().eq(CbOrderItem::getOrderId, id).list();
        if (!items.isEmpty()) {
            vo.setOrderItems(items.stream().map(OrderVO.OrderItemVO::from).collect(Collectors.toList()));
        }
        return vo;
    }

    @Override
    public void cancel(Long id, String reason) {
        Optional.ofNullable(cbOrderService.getById(id))
                .orElseThrow(() -> new BusinessException(CbCodeEnum.ORDER_NOT_FOUND));
        cbOrderService.lambdaUpdate()
                .set(CbOrder::getStatus,       ORDER_STATUS_CANCEL)
                .set(CbOrder::getCancelReason, StringUtils.defaultIfBlank(reason, "管理员取消"))
                .eq(CbOrder::getId, id)
                .update();
    }

    @Override
    public void settle(Long id, BigDecimal paidAmount, String payRecords) {
        Optional.ofNullable(cbOrderService.getById(id))
                .orElseThrow(() -> new BusinessException(CbCodeEnum.ORDER_NOT_FOUND));
        cbOrderService.lambdaUpdate()
                .set(CbOrder::getStatus,     ORDER_STATUS_COMPLETE)
                .set(CbOrder::getPayAmount,  paidAmount)
                .set(CbOrder::getPayRecords, payRecords)
                .set(CbOrder::getPayTime,    DateUtils.nowSeconds())
                .eq(CbOrder::getId, id)
                .update();
    }

    @Override
    public void delete(Long id) {
        CbOrder order = Optional.ofNullable(cbOrderService.getById(id))
                .orElseThrow(() -> new BusinessException(CbCodeEnum.ORDER_NOT_FOUND));
        if (order.getStatus() != ORDER_STATUS_COMPLETE && order.getStatus() != ORDER_STATUS_CANCEL) {
            throw new BusinessException(CbCodeEnum.ORDER_STATUS_ILLEGAL, "仅已完成或已取消的订单可删除");
        }
        cbOrderService.removeById(id);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public OrderVO create(OrderCreateRequest req) {
        if (req.getMerchantId() == null) throw new BusinessException(CbCodeEnum.PARAM_ERROR, "merchantId 不能为空");

        String orderNo = "OL" + System.currentTimeMillis();
        CbOrder order = new CbOrder();
        order.setMerchantId(req.getMerchantId());
        order.setOrderNo(orderNo);
        order.setOrderType((byte)ORDER_TYPE_BOOKING);
        order.setServiceMode(req.getServiceMode() != null && req.getServiceMode() == 1);
        order.setMemberId(req.getMemberId() != null ? req.getMemberId() : 0L);
        order.setTechnicianId(req.getTechnicianId() != null ? req.getTechnicianId() : 0L);
        order.setAddressId(0L);
        order.setAddressDetail(StringUtils.defaultIfBlank(req.getAddressDetail(), ""));
        order.setAddressLat(BigDecimal.ZERO);
        order.setAddressLng(BigDecimal.ZERO);
        order.setAppointTime(req.getAppointTime() != null ? req.getAppointTime() : 0L);
        order.setStartTime(0L);
        order.setEndTime(0L);
        order.setRemark(StringUtils.defaultIfBlank(req.getRemark(), ""));
        order.setStatus((byte)ORDER_STATUS_PENDING);
        order.setDiscountAmount(BigDecimal.ZERO);
        order.setTransportFee(BigDecimal.ZERO);
        order.setCouponId(0L);
        order.setPayType((byte)0);
        order.setPayTime(0L);
        order.setTechIncome(BigDecimal.ZERO);
        order.setPlatformIncome(BigDecimal.ZERO);
        order.setIsReviewed((byte)0);

        BigDecimal total = req.getItems().stream()
                .map(i -> i.getUnitPrice().multiply(BigDecimal.valueOf(i.getQty() != null ? i.getQty() : 1)))
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        order.setOriginalAmount(total);
        order.setPayAmount(total);

        OrderCreateRequest.OrderItemReq first = req.getItems().get(0);
        order.setServiceItemId(first.getServiceItemId() != null ? first.getServiceItemId() : 0L);
        order.setServiceName(StringUtils.defaultIfBlank(first.getServiceName(), ""));
        order.setServiceDuration(first.getServiceDuration() != null ? first.getServiceDuration() : 0);

        cbOrderService.save(order);

        Long orderId = order.getId();
        List<CbOrderItem> items = new ArrayList<>();
        for (OrderCreateRequest.OrderItemReq itemReq : req.getItems()) {
            int dur = itemReq.getServiceDuration() != null && itemReq.getServiceDuration() > 0
                    ? itemReq.getServiceDuration()
                    : resolveItemDuration(itemReq.getServiceItemId());

            CbOrderItem item = new CbOrderItem();
            item.setOrderId(orderId);
            item.setServiceItemId(itemReq.getServiceItemId());
            item.setServiceName(StringUtils.defaultIfBlank(itemReq.getServiceName(), ""));
            item.setServiceDuration(dur);
            item.setUnitPrice(itemReq.getUnitPrice());
            item.setQty(itemReq.getQty() != null ? itemReq.getQty() : 1);
            item.setSvcStatus(Boolean.FALSE);
            item.setTechnicianId(req.getTechnicianId());
            items.add(item);
        }
        if (!items.isEmpty()) cbOrderItemService.saveBatch(items);

        OrderVO vo = OrderVO.from(order);
        if (req.getMemberNickname() != null) vo.setMemberNickname(req.getMemberNickname());
        if (req.getMemberMobile()   != null) vo.setMemberMobile(req.getMemberMobile());
        vo.setOrderItems(items.stream().map(OrderVO.OrderItemVO::from).collect(Collectors.toList()));

        Long techId = req.getTechnicianId() != null && req.getTechnicianId() > 0 ? req.getTechnicianId() : null;
        eventPublisher.publishEvent(new OrderStatusChangedEvent(this, orderId, order.getMemberId(), techId, 0, 1));

        return vo;
    }

    /** 批量补充会员昵称/手机和技师昵称，避免 N+1 查询 */
    private void enrichNicknames(List<OrderVO> vos) {
        Set<Long> memberIds     = vos.stream().map(OrderVO::getMemberId).filter(id -> id != null).collect(Collectors.toSet());
        Set<Long> technicianIds = vos.stream().map(OrderVO::getTechnicianId).filter(id -> id != null).collect(Collectors.toSet());

        Map<Long, CbMember>     memberMap = memberIds.isEmpty()     ? Map.of() : cbMemberService.listByIds(memberIds).stream().collect(Collectors.toMap(CbMember::getId, m -> m));
        Map<Long, CbTechnician> techMap   = technicianIds.isEmpty() ? Map.of() : cbTechnicianService.listByIds(technicianIds).stream().collect(Collectors.toMap(CbTechnician::getId, t -> t));

        vos.forEach(vo -> {
            if (vo.getMemberId() != null) {
                CbMember m = memberMap.get(vo.getMemberId());
                if (m != null) {
                    vo.setMemberNickname(StringUtils.defaultIfBlank(m.getNickname(), m.getMobile()));
                    vo.setMemberMobile(m.getMobile());
                }
            }
            if (vo.getTechnicianId() != null) {
                CbTechnician t = techMap.get(vo.getTechnicianId());
                if (t != null) {
                    vo.setTechnicianNickname(StringUtils.defaultIfBlank(t.getNickname(), t.getRealName()));
                    if (StringUtils.isBlank(vo.getTechnicianNo()))     vo.setTechnicianNo(t.getTechNo());
                    if (StringUtils.isBlank(vo.getTechnicianMobile())) vo.setTechnicianMobile(t.getMobile());
                }
            }
        });
    }

    /** 批量补充服务项明细（避免 N+1） */
    private void enrichOrderItems(List<OrderVO> vos) {
        if (vos.isEmpty()) return;
        List<Long> orderIds = vos.stream().map(OrderVO::getId).filter(id -> id != null).collect(Collectors.toList());
        if (orderIds.isEmpty()) return;

        List<CbOrderItem> allItems = cbOrderItemService.lambdaQuery().in(CbOrderItem::getOrderId, orderIds).list();

        List<Long> catIds = allItems.stream()
                .map(CbOrderItem::getServiceItemId).filter(id -> id != null).distinct()
                .collect(Collectors.toList());
        Map<Long, CbServiceCategory> catMap = catIds.isEmpty() ? Collections.emptyMap()
                : cbServiceCategoryService.listByIds(catIds).stream()
                .collect(Collectors.toMap(CbServiceCategory::getId, c -> c));

        Map<Long, List<CbOrderItem>> itemsByOrder = allItems.stream()
                .collect(Collectors.groupingBy(CbOrderItem::getOrderId));

        vos.forEach(vo -> {
            List<CbOrderItem> items = itemsByOrder.getOrDefault(vo.getId(), Collections.emptyList());
            if (!items.isEmpty()) {
                List<OrderVO.OrderItemVO> itemVos = items.stream().map(item -> {
                    OrderVO.OrderItemVO ivo = OrderVO.OrderItemVO.from(item);
                    if ((ivo.getServiceDuration() == null || ivo.getServiceDuration() == 0)
                            && item.getServiceItemId() != null) {
                        CbServiceCategory cat = catMap.get(item.getServiceItemId());
                        if (cat != null && cat.getDuration() != null && cat.getDuration() > 0) {
                            ivo.setServiceDuration(cat.getDuration());
                        }
                    }
                    return ivo;
                }).collect(Collectors.toList());
                vo.setOrderItems(itemVos);
            }
        });
    }

    private int resolveItemDuration(Long serviceItemId) {
        if (serviceItemId == null || serviceItemId <= 0) return 0;
        CbServiceCategory cat = cbServiceCategoryService.getById(serviceItemId);
        return (cat != null && cat.getDuration() != null) ? cat.getDuration() : 0;
    }
}
