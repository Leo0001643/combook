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
import com.cambook.app.domain.vo.OrderVO;
import com.cambook.app.service.app.IAppOrderService;
import com.cambook.common.enums.CbCodeEnum;
import com.cambook.common.exception.BusinessException;
import com.cambook.common.result.PageResult;
import com.cambook.dao.entity.CbAddress;
import com.cambook.dao.entity.CbOrder;
import com.cambook.dao.entity.CbPayment;
import com.cambook.dao.mapper.CbAddressMapper;
import com.cambook.dao.mapper.CbOrderMapper;
import com.cambook.dao.mapper.CbPaymentMapper;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * App 端订单服务实现
 *
 * <p>集成：策略模式（支付）+ 状态机（订单流转）+ 事件驱动（异步通知）
 *
 * @author CamBook
 */
@Service
public class AppOrderService implements IAppOrderService {

    private final CbOrderMapper           orderMapper;
    private final CbAddressMapper         addressMapper;
    private final CbPaymentMapper         paymentMapper;
    private final OrderStateMachine       stateMachine;
    private final PaymentStrategyFactory  paymentFactory;
    private final ApplicationEventPublisher eventPublisher;

    public AppOrderService(CbOrderMapper orderMapper,
                           CbAddressMapper addressMapper,
                           CbPaymentMapper paymentMapper,
                           OrderStateMachine stateMachine,
                           PaymentStrategyFactory paymentFactory,
                           ApplicationEventPublisher eventPublisher) {
        this.orderMapper    = orderMapper;
        this.addressMapper  = addressMapper;
        this.paymentMapper  = paymentMapper;
        this.stateMachine   = stateMachine;
        this.paymentFactory = paymentFactory;
        this.eventPublisher = eventPublisher;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public OrderVO createOrder(CreateOrderDTO dto) {
        Long memberId = MemberContext.currentId();

        // 加载地址快照
        CbAddress address = addressMapper.selectOne(
                new LambdaQueryWrapper<CbAddress>()
                        .eq(CbAddress::getId, dto.getAddressId())
                        .eq(CbAddress::getMemberId, memberId)
                        .eq(CbAddress::getStatus, 1)
        );
        if (address == null) {
            throw new BusinessException(CbCodeEnum.DATA_NOT_FOUND);
        }

        // 构建订单
        CbOrder order = new CbOrder();
        order.setOrderNo(generateOrderNo());
        order.setMemberId(memberId);
        order.setTechnicianId(dto.getTechnicianId());
        order.setServiceItemId(dto.getServiceItemId());
        order.setAddressId(dto.getAddressId());
        order.setAddressDetail(address.getDetailAddress());
        order.setAddressLat(address.getLat());
        order.setAddressLng(address.getLng());
        order.setAppointTime(dto.getAppointTime());
        order.setPayType(dto.getPayType());
        order.setOriginalAmount(BigDecimal.ZERO);
        order.setDiscountAmount(BigDecimal.ZERO);
        order.setPayAmount(BigDecimal.ZERO);
        order.setRemark(dto.getRemark());
        order.setStatus(OrderStatus.PENDING_PAYMENT.getCode());
        order.setIsReviewed(0);
        orderMapper.insert(order);

        // 发起支付（策略模式路由）
        IPaymentStrategy strategy = paymentFactory.getStrategy(dto.getPayType());
        PaymentResult result = strategy.pay(order.getId(), order.getPayAmount(), memberId, null);

        if (result.isSuccess()) {
            // 记录支付流水
            CbPayment payment = new CbPayment();
            payment.setPaymentNo(result.getThirdPartyNo());
            payment.setOrderId(order.getId());
            payment.setMemberId(memberId);
            payment.setAmount(order.getPayAmount());
            payment.setPayType(dto.getPayType());
            payment.setStatus(1);
            payment.setThirdPartyNo(result.getThirdPartyNo());
            payment.setRawResponse(result.getRawResponse());
            payment.setPayTime(LocalDateTime.now());
            paymentMapper.insert(payment);

            // 状态流转：待支付 → 待接单
            stateMachine.transit(OrderStatus.PENDING_PAYMENT.getCode(),
                    OrderStatus.PENDING_ACCEPT.getCode());
            orderMapper.update(null,
                    new LambdaUpdateWrapper<CbOrder>()
                            .set(CbOrder::getStatus, OrderStatus.PENDING_ACCEPT.getCode())
                            .set(CbOrder::getPayTime, LocalDateTime.now())
                            .eq(CbOrder::getId, order.getId())
            );
            order.setStatus(OrderStatus.PENDING_ACCEPT.getCode());

            // 发布事件（观察者模式，异步处理推送）
            eventPublisher.publishEvent(new OrderStatusChangedEvent(
                    this, order.getId(), memberId, dto.getTechnicianId(),
                    OrderStatus.PENDING_PAYMENT.getCode(), OrderStatus.PENDING_ACCEPT.getCode()
            ));
        }

        return OrderVO.from(order);
    }

    @Override
    public PageResult<OrderVO> myOrders(Integer status, int page, int size) {
        Long memberId = MemberContext.currentId();
        LambdaQueryWrapper<CbOrder> wrapper = new LambdaQueryWrapper<CbOrder>()
                .eq(CbOrder::getMemberId, memberId)
                .eq(status != null, CbOrder::getStatus, status)
                .orderByDesc(CbOrder::getCreateTime);

        Page<CbOrder> p = orderMapper.selectPage(new Page<>(page, size), wrapper);
        List<OrderVO> records = p.getRecords().stream().map(OrderVO::from).collect(Collectors.toList());
        return PageResult.of(records, p.getTotal(), page, size);
    }

    @Override
    public OrderVO getDetail(Long id) {
        Long memberId = MemberContext.currentId();
        CbOrder order = orderMapper.selectOne(
                new LambdaQueryWrapper<CbOrder>()
                        .eq(CbOrder::getId, id)
                        .eq(CbOrder::getMemberId, memberId)
        );
        if (order == null) throw new BusinessException(CbCodeEnum.ORDER_NOT_FOUND);
        return OrderVO.from(order);
    }

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

    // ── 工具方法 ────────────────────────────────────────────────────────────

    private String generateOrderNo() {
        return "CB" + System.currentTimeMillis() + UUID.randomUUID().toString().substring(0, 6).toUpperCase();
    }
}
