package com.cambook.app.service.app.impl;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.cambook.common.context.MemberContext;
import com.cambook.app.common.event.OrderStatusChangedEvent;
import com.cambook.app.common.payment.IPaymentStrategy;
import com.cambook.app.common.payment.PaymentResult;
import com.cambook.app.common.payment.PaymentStrategyFactory;
import com.cambook.app.common.statemachine.OrderStateMachine;
import com.cambook.app.common.statemachine.OrderStatus;
import com.cambook.app.domain.dto.CancelOrderDTO;
import com.cambook.app.domain.dto.CreateOrderDTO;
import com.cambook.app.domain.dto.CreateOrderDTO.BookingItemDTO;
import com.cambook.app.domain.vo.OrderVO;
import com.cambook.app.service.app.IAppOrderService;
import com.cambook.common.enums.CbCodeEnum;
import com.cambook.common.exception.BusinessException;
import com.cambook.common.result.PageResult;
import com.cambook.db.entity.CbAddress;
import com.cambook.db.entity.CbOrder;
import com.cambook.db.entity.CbOrderItem;
import com.cambook.db.entity.CbPayment;
import com.cambook.db.entity.CbServiceItem;
import com.cambook.db.service.ICbAddressService;
import com.cambook.db.service.ICbOrderItemService;
import com.cambook.db.service.ICbOrderService;
import com.cambook.db.service.ICbPaymentService;
import com.cambook.db.service.ICbServiceItemService;
import lombok.RequiredArgsConstructor;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;
import com.cambook.common.utils.DateUtils;

/**
 * App 端订单服务实现
 *
 * <h3>核心设计</h3>
 * <ul>
 *   <li>一次预约 → 一笔 {@code cb_order}（customer-centric）</li>
 *   <li>每个服务项 → 一条 {@code cb_order_item}，携带独立的 {@code technician_id}</li>
 *   <li>多名技师可并行服务同一订单中各自分配的项目</li>
 *   <li>服务端从 {@code cb_service_item} 查价，防篡改</li>
 * </ul>
 *
 * @author CamBook
 */
@Service
@RequiredArgsConstructor
public class AppOrderService implements IAppOrderService {

    private static final int ORDER_TYPE_ONLINE  = 1;
    private static final int ADDRESS_STATUS_OK  = 1;
    private static final int SVC_STATUS_PENDING = 0;
    private static final int PAYMENT_STATUS_OK  = 1;

    private final ICbOrderService         cbOrderService;
    private final ICbOrderItemService     cbOrderItemService;
    private final ICbAddressService       cbAddressService;
    private final ICbPaymentService       cbPaymentService;
    private final ICbServiceItemService   cbServiceItemService;
    private final OrderStateMachine       stateMachine;
    private final PaymentStrategyFactory  paymentFactory;
    private final ApplicationEventPublisher eventPublisher;

    // ── 创建预约订单 ────────────────────────────────────────────────────────

    @Override
    @Transactional(rollbackFor = Exception.class)
    public OrderVO createOrder(CreateOrderDTO dto) {
        Long memberId = MemberContext.currentId();

        CbAddress address = loadAddress(dto.getAddressId(), memberId);
        Map<Long, CbServiceItem> serviceMap = loadServiceItems(dto.getItems());

        BigDecimal total = dto.getItems().stream()
                .map(item -> serviceMap.get(item.getServiceItemId())
                        .getMemberPrice().multiply(BigDecimal.valueOf(item.getQty())))
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        Long primaryTechId = dto.getItems().get(0).getTechnicianId();
        CbOrder order = buildOrder(memberId, address, dto, total, primaryTechId);
        cbOrderService.save(order);

        for (BookingItemDTO itemDTO : dto.getItems()) {
            CbServiceItem svc = serviceMap.get(itemDTO.getServiceItemId());
            CbOrderItem orderItem = new CbOrderItem();
            orderItem.setOrderId(order.getId());
            orderItem.setTechnicianId(itemDTO.getTechnicianId());
            orderItem.setServiceItemId(itemDTO.getServiceItemId());
            orderItem.setServiceName(svc.getNameZh());
            orderItem.setServiceDuration(svc.getDuration());
            orderItem.setUnitPrice(svc.getMemberPrice());
            orderItem.setQty(itemDTO.getQty());
            orderItem.setSvcStatus(Boolean.FALSE);
            orderItem.setRemark(itemDTO.getRemark());
            cbOrderItemService.save(orderItem);
        }

        IPaymentStrategy strategy = paymentFactory.getStrategy(dto.getPayType());
        PaymentResult result = strategy.pay(order.getId(), total, memberId, null);

        if (result.isSuccess()) {
            recordPayment(order, total, memberId, result);
            transitionToPaid(order);

            dto.getItems().stream().map(BookingItemDTO::getTechnicianId).distinct()
                .forEach(techId -> eventPublisher.publishEvent(new OrderStatusChangedEvent(
                            this, order.getId(), memberId, techId,
                            OrderStatus.PENDING_PAYMENT.getCode(), OrderStatus.PENDING_ACCEPT.getCode())));
        }

        List<CbOrderItem> savedItems = cbOrderItemService.lambdaQuery().eq(CbOrderItem::getOrderId, order.getId()).list();
        return OrderVO.fromWithItems(order, savedItems);
    }

    // ── 我的订单列表 ────────────────────────────────────────────────────────

    @Override
    public PageResult<OrderVO> myOrders(Integer status, int page, int size) {
        Long memberId = MemberContext.currentId();
        var p = cbOrderService.lambdaQuery()
                .eq(CbOrder::getMemberId, memberId)
                .eq(status != null, CbOrder::getStatus, status)
                .orderByDesc(CbOrder::getCreateTime)
                .page(new Page<>(page, size));
        List<OrderVO> records = p.getRecords().stream().map(OrderVO::from).collect(Collectors.toList());
        return PageResult.of(records, p.getTotal(), page, size);
    }

    // ── 订单详情 ────────────────────────────────────────────────────────────

    @Override
    public OrderVO getDetail(Long id) {
        Long memberId = MemberContext.currentId();
        CbOrder order = Optional.ofNullable(
                cbOrderService.lambdaQuery()
                        .eq(CbOrder::getId, id)
                        .eq(CbOrder::getMemberId, memberId)
                        .one())
                .orElseThrow(() -> new BusinessException(CbCodeEnum.ORDER_NOT_FOUND));
        List<CbOrderItem> items = cbOrderItemService.lambdaQuery().eq(CbOrderItem::getOrderId, id).list();
        return OrderVO.fromWithItems(order, items);
    }

    // ── 取消订单 ────────────────────────────────────────────────────────────

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void cancel(CancelOrderDTO dto) {
        Long memberId = MemberContext.currentId();
        CbOrder order = Optional.ofNullable(
                cbOrderService.lambdaQuery()
                        .eq(CbOrder::getId, dto.getOrderId())
                        .eq(CbOrder::getMemberId, memberId)
                        .one())
                .orElseThrow(() -> new BusinessException(CbCodeEnum.ORDER_NOT_FOUND));

        stateMachine.transit(order.getStatus(), OrderStatus.CANCELLED.getCode());
        cbOrderService.lambdaUpdate()
                .set(CbOrder::getStatus,       OrderStatus.CANCELLED.getCode())
                .set(CbOrder::getCancelReason, dto.getReason())
                .eq(CbOrder::getId, order.getId())
                .update();

        eventPublisher.publishEvent(new OrderStatusChangedEvent(
                this, order.getId(), memberId, order.getTechnicianId(),
                order.getStatus(), OrderStatus.CANCELLED.getCode()));
    }

    // ── 私有工具方法 ────────────────────────────────────────────────────────

    private CbAddress loadAddress(Long addressId, Long memberId) {
        return Optional.ofNullable(
                cbAddressService.lambdaQuery()
                        .eq(CbAddress::getId, addressId)
                        .eq(CbAddress::getMemberId, memberId)
                        .one())
                .orElseThrow(() -> new BusinessException(CbCodeEnum.DATA_NOT_FOUND));
    }

    private Map<Long, CbServiceItem> loadServiceItems(List<BookingItemDTO> items) {
        Set<Long> ids = items.stream().map(BookingItemDTO::getServiceItemId).collect(Collectors.toSet());
        Map<Long, CbServiceItem> map = cbServiceItemService.listByIds(ids).stream()
                .filter(s -> s.getStatus() != null && s.getStatus() != null && s.getStatus().intValue() == 1)
                .collect(Collectors.toMap(CbServiceItem::getId, Function.identity()));
        ids.forEach(id -> {
            if (!map.containsKey(id)) throw new BusinessException(CbCodeEnum.DATA_NOT_FOUND);
        });
        return map;
    }

    private CbOrder buildOrder(Long memberId, CbAddress address, CreateOrderDTO dto, BigDecimal total, Long primaryTechId) {
        CbOrder order = new CbOrder();
        order.setOrderNo(generateOrderNo());
        order.setOrderType((byte)ORDER_TYPE_ONLINE);
        order.setMemberId(memberId);
        order.setTechnicianId(primaryTechId);
        order.setAddressId(dto.getAddressId());
        order.setAddressDetail(address.getDetail());
        order.setAddressLat(address.getLat());
        order.setAddressLng(address.getLng());
        order.setAppointTime(dto.getAppointTime());
        order.setPayType(dto.getPayType() == null ? null : dto.getPayType().byteValue());
        order.setCouponId(dto.getCouponId());
        order.setOriginalAmount(total);
        order.setDiscountAmount(BigDecimal.ZERO);
        order.setPayAmount(total);
        order.setRemark(dto.getRemark());
        order.setStatus((byte)OrderStatus.PENDING_PAYMENT.getCode());
        order.setIsReviewed((byte)0);
        return order;
    }

    private void recordPayment(CbOrder order, BigDecimal total, Long memberId, PaymentResult result) {
        CbPayment payment = new CbPayment();
        payment.setPaymentNo(result.getThirdPartyNo());
        payment.setOrderNo(order.getOrderNo());
        payment.setMemberId(memberId);
        payment.setAmount(total);
        payment.setPayType(order.getPayType());
        payment.setStatus((byte)PAYMENT_STATUS_OK);
        payment.setThirdTradeNo(result.getThirdPartyNo());
        payment.setNotifyData(result.getRawResponse());
        payment.setCreateTime(DateUtils.nowSeconds());
        cbPaymentService.save(payment);
    }

    private void transitionToPaid(CbOrder order) {
        stateMachine.transit(OrderStatus.PENDING_PAYMENT.getCode(), OrderStatus.PENDING_ACCEPT.getCode());
        cbOrderService.lambdaUpdate()
                .set(CbOrder::getStatus,  OrderStatus.PENDING_ACCEPT.getCode())
                .set(CbOrder::getPayTime, DateUtils.nowSeconds())
                .eq(CbOrder::getId, order.getId())
                .update();
        order.setStatus((byte)OrderStatus.PENDING_ACCEPT.getCode());
    }

    private String generateOrderNo() {
        return "CB" + System.currentTimeMillis() + UUID.randomUUID().toString().substring(0, 6).toUpperCase();
    }
}
