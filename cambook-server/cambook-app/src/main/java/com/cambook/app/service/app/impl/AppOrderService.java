package com.cambook.app.service.app.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper;
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
import com.cambook.dao.entity.CbAddress;
import com.cambook.dao.entity.CbOrder;
import com.cambook.dao.entity.CbOrderItem;
import com.cambook.dao.entity.CbPayment;
import com.cambook.dao.entity.CbServiceItem;
import com.cambook.dao.mapper.CbAddressMapper;
import com.cambook.dao.mapper.CbOrderItemMapper;
import com.cambook.dao.mapper.CbOrderMapper;
import com.cambook.dao.mapper.CbPaymentMapper;
import com.cambook.dao.mapper.CbServiceItemMapper;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;

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
public class AppOrderService implements IAppOrderService {

    private final CbOrderMapper            orderMapper;
    private final CbOrderItemMapper        orderItemMapper;
    private final CbAddressMapper          addressMapper;
    private final CbPaymentMapper          paymentMapper;
    private final CbServiceItemMapper      serviceItemMapper;
    private final OrderStateMachine        stateMachine;
    private final PaymentStrategyFactory   paymentFactory;
    private final ApplicationEventPublisher eventPublisher;

    public AppOrderService(CbOrderMapper orderMapper,
                           CbOrderItemMapper orderItemMapper,
                           CbAddressMapper addressMapper,
                           CbPaymentMapper paymentMapper,
                           CbServiceItemMapper serviceItemMapper,
                           OrderStateMachine stateMachine,
                           PaymentStrategyFactory paymentFactory,
                           ApplicationEventPublisher eventPublisher) {
        this.orderMapper       = orderMapper;
        this.orderItemMapper   = orderItemMapper;
        this.addressMapper     = addressMapper;
        this.paymentMapper     = paymentMapper;
        this.serviceItemMapper = serviceItemMapper;
        this.stateMachine      = stateMachine;
        this.paymentFactory    = paymentFactory;
        this.eventPublisher    = eventPublisher;
    }

    // ── 创建预约订单 ────────────────────────────────────────────────────────

    @Override
    @Transactional(rollbackFor = Exception.class)
    public OrderVO createOrder(CreateOrderDTO dto) {
        Long memberId = MemberContext.currentId();

        // 1. 加载并校验服务地址
        CbAddress address = loadAddress(dto.getAddressId(), memberId);

        // 2. 服务端批量查价（防客户端价格篡改）
        Map<Long, CbServiceItem> serviceMap = loadServiceItems(dto.getItems());

        // 3. 计算订单总价（各服务项 unitPrice × qty 之和）
        BigDecimal total = dto.getItems().stream()
                .map(item -> serviceMap.get(item.getServiceItemId())
                        .getMemberPrice()
                        .multiply(BigDecimal.valueOf(item.getQty())))
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        // 4. 创建订单主记录（一笔订单属于客户本次 session）
        //    technician_id 取第一个技师（用于系统兼容性），多技师订单以 item 级别为准
        Long primaryTechId = dto.getItems().get(0).getTechnicianId();
        CbOrder order = buildOrder(memberId, address, dto, total, primaryTechId);
        orderMapper.insert(order);

        // 5. 创建服务项明细（每项关联各自的技师，支持并行服务）
        for (BookingItemDTO itemDTO : dto.getItems()) {
            CbServiceItem svc = serviceMap.get(itemDTO.getServiceItemId());
            CbOrderItem orderItem = new CbOrderItem();
            orderItem.setOrderId(order.getId());
            orderItem.setTechnicianId(itemDTO.getTechnicianId());   // ← 每项独立技师
            orderItem.setServiceItemId(itemDTO.getServiceItemId());
            orderItem.setServiceName(svc.getNameZh());              // 名称快照
            orderItem.setServiceDuration(svc.getDuration());        // 时长快照
            orderItem.setUnitPrice(svc.getMemberPrice());           // 价格快照（服务端）
            orderItem.setQty(itemDTO.getQty());
            orderItem.setSvcStatus(0);                              // 0=待服务
            orderItem.setRemark(itemDTO.getRemark());
            orderItemMapper.insert(orderItem);
        }

        // 6. 发起支付（策略模式路由）
        IPaymentStrategy strategy = paymentFactory.getStrategy(dto.getPayType());
        PaymentResult result = strategy.pay(order.getId(), total, memberId, null);

        if (result.isSuccess()) {
            recordPayment(order, total, memberId, result);
            transitionToPaid(order);

            // 7. 多技师并行场景：对每位参与的技师单独发布事件（推送接单通知）
            //    使用 distinct() 避免同一技师负责多个服务项时重复通知
            dto.getItems().stream()
                    .map(BookingItemDTO::getTechnicianId)
                    .distinct()
                    .forEach(techId -> eventPublisher.publishEvent(new OrderStatusChangedEvent(
                            this, order.getId(), memberId, techId,
                            OrderStatus.PENDING_PAYMENT.getCode(), OrderStatus.PENDING_ACCEPT.getCode()
                    )));
        }

        // 8. 返回含服务项的 OrderVO
        List<CbOrderItem> savedItems = orderItemMapper.selectActiveByOrderId(order.getId());
        return OrderVO.fromWithItems(order, savedItems);
    }

    // ── 我的订单列表 ────────────────────────────────────────────────────────

    @Override
    public PageResult<OrderVO> myOrders(Integer status, int page, int size) {
        Long memberId = MemberContext.currentId();
        LambdaQueryWrapper<CbOrder> wrapper = new LambdaQueryWrapper<CbOrder>()
                .eq(CbOrder::getMemberId, memberId)
                .eq(status != null, CbOrder::getStatus, status)
                .orderByDesc(CbOrder::getCreateTime);

        Page<CbOrder> p = orderMapper.selectPage(new Page<>(page, size), wrapper);
        List<OrderVO> records = p.getRecords().stream()
                .map(OrderVO::from)
                .collect(Collectors.toList());
        return PageResult.of(records, p.getTotal(), page, size);
    }

    // ── 订单详情 ────────────────────────────────────────────────────────────

    @Override
    public OrderVO getDetail(Long id) {
        Long memberId = MemberContext.currentId();
        CbOrder order = orderMapper.selectOne(
                new LambdaQueryWrapper<CbOrder>()
                        .eq(CbOrder::getId, id)
                        .eq(CbOrder::getMemberId, memberId)
        );
        if (order == null) throw new BusinessException(CbCodeEnum.ORDER_NOT_FOUND);
        List<CbOrderItem> items = orderItemMapper.selectActiveByOrderId(id);
        return OrderVO.fromWithItems(order, items);
    }

    // ── 取消订单 ────────────────────────────────────────────────────────────

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void cancel(CancelOrderDTO dto) {
        Long memberId = MemberContext.currentId();
        CbOrder order = orderMapper.selectOne(
                new LambdaQueryWrapper<CbOrder>()
                        .eq(CbOrder::getId, dto.getOrderId())
                        .eq(CbOrder::getMemberId, memberId)
        );
        if (order == null) throw new BusinessException(CbCodeEnum.ORDER_NOT_FOUND);

        stateMachine.transit(order.getStatus(), OrderStatus.CANCELLED.getCode());
        orderMapper.update(null,
                new LambdaUpdateWrapper<CbOrder>()
                        .set(CbOrder::getStatus, OrderStatus.CANCELLED.getCode())
                        .set(CbOrder::getCancelReason, dto.getReason())
                        .eq(CbOrder::getId, order.getId())
        );
        eventPublisher.publishEvent(new OrderStatusChangedEvent(
                this, order.getId(), memberId, order.getTechnicianId(),
                order.getStatus(), OrderStatus.CANCELLED.getCode()
        ));
    }

    // ── 私有工具方法 ────────────────────────────────────────────────────────

    private CbAddress loadAddress(Long addressId, Long memberId) {
        CbAddress address = addressMapper.selectOne(
                new LambdaQueryWrapper<CbAddress>()
                        .eq(CbAddress::getId, addressId)
                        .eq(CbAddress::getMemberId, memberId)
                        .eq(CbAddress::getStatus, 1)
        );
        if (address == null) throw new BusinessException(CbCodeEnum.DATA_NOT_FOUND);
        return address;
    }

    /** 批量从 cb_service_item 查价，防篡改，同时校验服务项存在且上架 */
    private Map<Long, CbServiceItem> loadServiceItems(List<BookingItemDTO> items) {
        Set<Long> ids = items.stream()
                .map(BookingItemDTO::getServiceItemId)
                .collect(Collectors.toSet());

        Map<Long, CbServiceItem> map = serviceItemMapper.selectBatchIds(ids)
                .stream()
                .filter(s -> s.getStatus() != null && s.getStatus() == 1) // 仅上架
                .collect(Collectors.toMap(CbServiceItem::getId, Function.identity()));

        ids.forEach(id -> {
            if (!map.containsKey(id))
                throw new BusinessException(CbCodeEnum.DATA_NOT_FOUND);
        });
        return map;
    }

    private CbOrder buildOrder(Long memberId, CbAddress address,
                               CreateOrderDTO dto, BigDecimal total, Long primaryTechId) {
        CbOrder order = new CbOrder();
        order.setOrderNo(generateOrderNo());
        order.setOrderType(1);            // 1=在线预约
        order.setMemberId(memberId);
        order.setTechnicianId(primaryTechId); // 主技师（兼容性保留）
        order.setAddressId(dto.getAddressId());
        order.setAddressDetail(address.getDetailAddress());
        order.setAddressLat(address.getLat());
        order.setAddressLng(address.getLng());
        order.setAppointTime(dto.getAppointTime());
        order.setPayType(dto.getPayType());
        order.setCouponId(dto.getCouponId());
        order.setOriginalAmount(total);
        order.setDiscountAmount(BigDecimal.ZERO);
        order.setPayAmount(total);
        order.setRemark(dto.getRemark());
        order.setStatus(OrderStatus.PENDING_PAYMENT.getCode());
        order.setIsReviewed(0);
        return order;
    }

    private void recordPayment(CbOrder order, BigDecimal total, Long memberId, PaymentResult result) {
        CbPayment payment = new CbPayment();
        payment.setPaymentNo(result.getThirdPartyNo());
        payment.setOrderId(order.getId());
        payment.setMemberId(memberId);
        payment.setAmount(total);
        payment.setPayType(order.getPayType());
        payment.setStatus(1);
        payment.setThirdPartyNo(result.getThirdPartyNo());
        payment.setRawResponse(result.getRawResponse());
        payment.setPayTime(System.currentTimeMillis() / 1000L);
        paymentMapper.insert(payment);
    }

    private void transitionToPaid(CbOrder order) {
        stateMachine.transit(OrderStatus.PENDING_PAYMENT.getCode(),
                OrderStatus.PENDING_ACCEPT.getCode());
        orderMapper.update(null,
                new LambdaUpdateWrapper<CbOrder>()
                        .set(CbOrder::getStatus, OrderStatus.PENDING_ACCEPT.getCode())
                        .set(CbOrder::getPayTime, System.currentTimeMillis() / 1000L)
                        .eq(CbOrder::getId, order.getId())
        );
        order.setStatus(OrderStatus.PENDING_ACCEPT.getCode());
    }

    private String generateOrderNo() {
        return "CB" + System.currentTimeMillis()
                + UUID.randomUUID().toString().substring(0, 6).toUpperCase();
    }
}
