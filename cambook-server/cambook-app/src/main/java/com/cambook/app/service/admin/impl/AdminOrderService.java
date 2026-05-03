package com.cambook.app.service.admin.impl;

import com.cambook.app.common.event.OrderStatusChangedEvent;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.cambook.app.domain.dto.OrderCreateRequest;
import com.cambook.app.domain.dto.OrderQueryDTO;
import com.cambook.app.domain.vo.OrderVO;
import com.cambook.app.service.admin.IAdminOrderService;
import com.cambook.common.enums.CbCodeEnum;
import com.cambook.common.exception.BusinessException;
import com.cambook.common.result.PageResult;
import com.cambook.dao.entity.CbMember;
import com.cambook.dao.entity.CbOrder;
import com.cambook.dao.entity.CbOrderItem;
import com.cambook.dao.entity.CbServiceCategory;
import com.cambook.dao.entity.CbTechnician;
import com.cambook.dao.mapper.CbMemberMapper;
import com.cambook.dao.mapper.CbOrderItemMapper;
import com.cambook.dao.mapper.CbOrderMapper;
import com.cambook.dao.mapper.CbServiceCategoryMapper;
import com.cambook.dao.mapper.CbTechnicianMapper;
import org.apache.commons.lang3.StringUtils;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * Admin 端订单管理服务实现
 *
 * @author CamBook
 */
@Service
public class AdminOrderService implements IAdminOrderService {

    private final CbOrderMapper              orderMapper;
    private final CbOrderItemMapper          orderItemMapper;
    private final CbMemberMapper             memberMapper;
    private final CbTechnicianMapper         technicianMapper;
    private final CbServiceCategoryMapper    categoryMapper;
    private final ApplicationEventPublisher  eventPublisher;

    public AdminOrderService(CbOrderMapper orderMapper,
                             CbOrderItemMapper orderItemMapper,
                             CbMemberMapper memberMapper,
                             CbTechnicianMapper technicianMapper,
                             CbServiceCategoryMapper categoryMapper,
                             ApplicationEventPublisher eventPublisher) {
        this.orderMapper      = orderMapper;
        this.orderItemMapper  = orderItemMapper;
        this.memberMapper     = memberMapper;
        this.technicianMapper = technicianMapper;
        this.categoryMapper   = categoryMapper;
        this.eventPublisher   = eventPublisher;
    }

    @Override
    public PageResult<OrderVO> pageList(OrderQueryDTO query) {
        LambdaQueryWrapper<CbOrder> wrapper = new LambdaQueryWrapper<CbOrder>()
                .eq(query.getMerchantId() != null, CbOrder::getMerchantId, query.getMerchantId())
                .eq(query.getOrderType() != null, CbOrder::getOrderType, query.getOrderType())
                .like(StringUtils.isNotBlank(query.getOrderNo()), CbOrder::getOrderNo, query.getOrderNo())
                .eq(query.getStatus() != null, CbOrder::getStatus, query.getStatus())
                .eq(query.getServiceMode() != null, CbOrder::getServiceMode, query.getServiceMode())
                .ge(query.getStartDate() != null, CbOrder::getCreateTime, query.getStartDate())
                .le(query.getEndDate() != null, CbOrder::getCreateTime, query.getEndDate())
                .orderByDesc(CbOrder::getCreateTime);

        Page<CbOrder> p = orderMapper.selectPage(new Page<>(query.getPage(), query.getSize()), wrapper);
        List<OrderVO> vos = p.getRecords().stream().map(OrderVO::from).collect(Collectors.toList());

        enrichNicknames(vos);
        enrichOrderItems(vos);

        // keyword 后置过滤（支持订单号/昵称/技师编号模糊搜索）
        List<OrderVO> filtered = vos;
        if (StringUtils.isNotBlank(query.getKeyword())) {
            String kw = query.getKeyword().toLowerCase();
            filtered = vos.stream().filter(vo ->
                    (vo.getOrderNo()             != null && vo.getOrderNo().toLowerCase().contains(kw)) ||
                    (vo.getMemberNickname()       != null && vo.getMemberNickname().toLowerCase().contains(kw)) ||
                    (vo.getTechnicianNickname()   != null && vo.getTechnicianNickname().toLowerCase().contains(kw)) ||
                    (vo.getTechnicianNo()         != null && vo.getTechnicianNo().toLowerCase().contains(kw))
            ).collect(Collectors.toList());
        }

        return PageResult.of(filtered, p.getTotal(), query.getPage(), query.getSize());
    }

    @Override
    public OrderVO getDetail(Long id) {
        CbOrder order = orderMapper.selectById(id);
        if (order == null) throw new BusinessException(CbCodeEnum.ORDER_NOT_FOUND);
        OrderVO vo = OrderVO.from(order);
        enrichNicknames(List.of(vo));

        // 加载多服务项明细
        List<CbOrderItem> items = orderItemMapper.selectList(
                new LambdaQueryWrapper<CbOrderItem>().eq(CbOrderItem::getOrderId, id));
        if (!items.isEmpty()) {
            vo.setOrderItems(items.stream().map(OrderVO.OrderItemVO::from).collect(Collectors.toList()));
        }
        return vo;
    }

    @Override
    public void cancel(Long id, String reason) {
        CbOrder order = orderMapper.selectById(id);
        if (order == null) throw new BusinessException(CbCodeEnum.ORDER_NOT_FOUND);
        CbOrder upd = new CbOrder();
        upd.setId(id);
        upd.setStatus(7); // 7=取消
        upd.setCancelReason(StringUtils.defaultIfBlank(reason, "管理员取消"));
        orderMapper.updateById(upd);
    }

    @Override
    public void settle(Long id, java.math.BigDecimal paidAmount, String payRecords) {
        CbOrder order = orderMapper.selectById(id);
        if (order == null) throw new BusinessException(CbCodeEnum.ORDER_NOT_FOUND);
        CbOrder upd = new CbOrder();
        upd.setId(id);
        upd.setStatus(6); // 6=完成
        upd.setPayAmount(paidAmount);
        upd.setPayRecords(payRecords);
        upd.setPayTime(System.currentTimeMillis() / 1000L);
        orderMapper.updateById(upd);
    }

    @Override
    public void delete(Long id) {
        CbOrder order = orderMapper.selectById(id);
        if (order == null) throw new BusinessException(CbCodeEnum.ORDER_NOT_FOUND);
        if (order.getStatus() != 6 && order.getStatus() != 7) {
            throw new BusinessException(CbCodeEnum.ORDER_STATUS_ILLEGAL, "仅已完成或已取消的订单可删除");
        }
        orderMapper.deleteById(id);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public OrderVO create(OrderCreateRequest req) {
        if (req.getMerchantId() == null) {
            throw new BusinessException(CbCodeEnum.PARAM_ERROR, "merchantId 不能为空");
        }

        // 构建主订单（预约单，order_type=1）
        String orderNo = "OL" + System.currentTimeMillis();
        CbOrder order = new CbOrder();
        order.setMerchantId(req.getMerchantId());
        order.setOrderNo(orderNo);
        order.setOrderType(1);
        order.setServiceMode(req.getServiceMode());
        order.setMemberId(req.getMemberId() != null ? req.getMemberId() : 0L);
        order.setTechnicianId(req.getTechnicianId() != null ? req.getTechnicianId() : 0L);
        order.setAddressId(0L);          // 后台手动建单不关联地址簿
        order.setAddressDetail(StringUtils.defaultIfBlank(req.getAddressDetail(), ""));
        order.setAddressLat(java.math.BigDecimal.ZERO);
        order.setAddressLng(java.math.BigDecimal.ZERO);
        order.setAppointTime(req.getAppointTime() != null ? req.getAppointTime() : 0L);
        order.setStartTime(0L);
        order.setEndTime(0L);
        order.setRemark(StringUtils.defaultIfBlank(req.getRemark(), ""));
        order.setStatus(1); // 待接单
        order.setDiscountAmount(java.math.BigDecimal.ZERO);
        order.setTransportFee(java.math.BigDecimal.ZERO);
        order.setCouponId(0L);
        order.setPayType(0);
        order.setPayTime(0L);
        order.setTechIncome(java.math.BigDecimal.ZERO);
        order.setPlatformIncome(java.math.BigDecimal.ZERO);
        order.setIsReviewed(0);

        // 汇总金额
        BigDecimal total = req.getItems().stream()
                .map(i -> i.getUnitPrice().multiply(BigDecimal.valueOf(i.getQty() != null ? i.getQty() : 1)))
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        order.setOriginalAmount(total);
        order.setPayAmount(total);

        // 快照第一项服务名
        OrderCreateRequest.OrderItemReq first = req.getItems().get(0);
        order.setServiceItemId(first.getServiceItemId() != null ? first.getServiceItemId() : 0L);
        order.setServiceName(StringUtils.defaultIfBlank(first.getServiceName(), ""));
        order.setServiceDuration(first.getServiceDuration() != null ? first.getServiceDuration() : 0);

        orderMapper.insert(order);

        // 构建服务项
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
            item.setSvcStatus(0);
            item.setTechnicianId(req.getTechnicianId());
            items.add(item);
        }
        if (!items.isEmpty()) {
            items.forEach(orderItemMapper::insert);
        }

        OrderVO vo = OrderVO.from(order);
        if (req.getMemberNickname() != null) vo.setMemberNickname(req.getMemberNickname());
        if (req.getMemberMobile()   != null) vo.setMemberMobile(req.getMemberMobile());
        vo.setOrderItems(items.stream().map(OrderVO.OrderItemVO::from).collect(Collectors.toList()));

        // 发布订单事件 → OrderEventListener 异步推送 WS NEW_ORDER 给技师 + 触发语音播报
        Long techId = req.getTechnicianId() != null && req.getTechnicianId() > 0 ? req.getTechnicianId() : null;
        eventPublisher.publishEvent(
            new OrderStatusChangedEvent(this, orderId, order.getMemberId(), techId, 0, 1)
        );

        return vo;
    }

    /** 批量补充会员昵称/手机和技师昵称，避免 N+1 查询 */
    private void enrichNicknames(List<OrderVO> vos) {
        Set<Long> memberIds     = vos.stream().map(OrderVO::getMemberId)    .filter(id -> id != null).collect(Collectors.toSet());
        Set<Long> technicianIds = vos.stream().map(OrderVO::getTechnicianId).filter(id -> id != null).collect(Collectors.toSet());

        Map<Long, CbMember> memberMap = memberIds.isEmpty() ? Map.of() :
                memberMapper.selectBatchIds(memberIds).stream()
                        .collect(Collectors.toMap(CbMember::getId, m -> m));

        Map<Long, CbTechnician> techMap = technicianIds.isEmpty() ? Map.of() :
                technicianMapper.selectBatchIds(technicianIds).stream()
                        .collect(Collectors.toMap(CbTechnician::getId, t -> t));

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
                    if (StringUtils.isBlank(vo.getTechnicianNo())) {
                        vo.setTechnicianNo(t.getTechNo());
                    }
                    if (StringUtils.isBlank(vo.getTechnicianMobile())) {
                        vo.setTechnicianMobile(t.getMobile());
                    }
                }
            }
        });
    }

    /** 批量补充服务项明细（避免 N+1，含 duration 兜底） */
    private void enrichOrderItems(List<OrderVO> vos) {
        if (vos.isEmpty()) return;
        List<Long> orderIds = vos.stream().map(OrderVO::getId).filter(id -> id != null).collect(Collectors.toList());
        if (orderIds.isEmpty()) return;

        List<CbOrderItem> allItems = orderItemMapper.selectList(
                new LambdaQueryWrapper<CbOrderItem>()
                        .in(CbOrderItem::getOrderId, orderIds));

        // 批量加载分类（用于 duration 兜底）
        List<Long> catIds = allItems.stream()
                .map(CbOrderItem::getServiceItemId)
                .filter(id -> id != null)
                .distinct()
                .collect(Collectors.toList());
        Map<Long, CbServiceCategory> catMap = catIds.isEmpty() ? Collections.emptyMap()
                : categoryMapper.selectBatchIds(catIds).stream()
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

    /** 从服务分类表解析时长（兜底） */
    private int resolveItemDuration(Long serviceItemId) {
        if (serviceItemId == null || serviceItemId <= 0) return 0;
        CbServiceCategory cat = categoryMapper.selectById(serviceItemId);
        return (cat != null && cat.getDuration() != null) ? cat.getDuration() : 0;
    }
}
