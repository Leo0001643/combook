package com.cambook.app.service.technician.impl;

import com.cambook.app.common.statemachine.OrderStatus;
import com.cambook.app.domain.dto.AddOrderItemDTO;
import com.cambook.app.domain.vo.OrderVO;
import com.cambook.app.service.technician.ITechOrderItemService;
import com.cambook.common.context.MemberContext;
import com.cambook.common.enums.CbCodeEnum;
import com.cambook.common.exception.BusinessException;
import com.cambook.db.entity.CbOrder;
import com.cambook.db.entity.CbOrderItem;
import com.cambook.db.service.ICbOrderItemService;
import com.cambook.db.service.ICbOrderService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

/**
 * 技师端订单服务项管理实现
 *
 * <p>一单多项的核心逻辑：追加/取消服务项，自动重新计算订单总金额。
 *
 * @author CamBook
 */
@Service
@RequiredArgsConstructor
public class TechOrderItemServiceImpl implements ITechOrderItemService {

    /** 可追加服务项的订单状态范围：接单 / 前往 / 到达 / 服务中 */
    private static final List<Integer> ADDABLE_STATUSES = List.of(
            OrderStatus.ACCEPTED.getCode(), OrderStatus.ARRIVING.getCode(),
            OrderStatus.ARRIVED.getCode(),  OrderStatus.IN_SERVICE.getCode()
    );

    private static final int SVC_STATUS_PENDING = 0;

    private final ICbOrderService     cbOrderService;
    private final ICbOrderItemService cbOrderItemService;

    @Override
    @Transactional(rollbackFor = Exception.class)
    public List<OrderVO.OrderItemVO> addItem(Long orderId, AddOrderItemDTO dto) {
        CbOrder order = requireOwnOrder(orderId);

        if (!ADDABLE_STATUSES.contains(order.getStatus())) {
            throw new BusinessException(CbCodeEnum.ORDER_STATUS_ILLEGAL);
        }

        CbOrderItem item = new CbOrderItem();
        item.setOrderId(orderId);
        item.setTechnicianId(MemberContext.getMemberId());
        item.setServiceItemId(dto.getServiceItemId());
        item.setServiceName(dto.getServiceName());
        item.setServiceDuration(dto.getServiceDuration());
        item.setUnitPrice(dto.getUnitPrice());
        item.setQty(dto.getQty() != null ? dto.getQty() : 1);
        item.setSvcStatus(Boolean.FALSE);
        item.setRemark(dto.getRemark());
        cbOrderItemService.save(item);

        recalcOrderAmount(order);
        return loadItems(orderId);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void removeItem(Long orderId, Long itemId) {
        requireOwnOrder(orderId);

        CbOrderItem item = Optional.ofNullable(cbOrderItemService.lambdaQuery().eq(CbOrderItem::getId, itemId).eq(CbOrderItem::getOrderId, orderId).eq(CbOrderItem::getDeleted, Boolean.FALSE).one()).orElseThrow(() -> new BusinessException(CbCodeEnum.DATA_NOT_FOUND));
        if (Boolean.TRUE.equals(item.getSvcStatus())) {
            throw new BusinessException(CbCodeEnum.ORDER_CANNOT_CANCEL);
        }

        cbOrderItemService.removeById(item.getId());
        recalcOrderAmount(requireOwnOrder(orderId));
    }

    @Override
    public List<OrderVO.OrderItemVO> listItems(Long orderId) {
        requireOwnOrder(orderId);
        return loadItems(orderId);
    }

    // ── 私有工具 ─────────────────────────────────────────────────────────────

    private List<OrderVO.OrderItemVO> loadItems(Long orderId) {
        return cbOrderItemService.lambdaQuery().eq(CbOrderItem::getOrderId, orderId).list()
                .stream().map(OrderVO.OrderItemVO::from).collect(Collectors.toList());
    }

    private void recalcOrderAmount(CbOrder order) {
        List<CbOrderItem> items = cbOrderItemService.lambdaQuery().eq(CbOrderItem::getOrderId, order.getId()).list();
        BigDecimal total = items.stream()
                .map(i -> i.getUnitPrice().multiply(BigDecimal.valueOf(i.getQty())))
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        order.setOriginalAmount(total);
        BigDecimal discount  = order.getDiscountAmount()  != null ? order.getDiscountAmount()  : BigDecimal.ZERO;
        BigDecimal transport = order.getTransportFee()    != null ? order.getTransportFee()    : BigDecimal.ZERO;
        order.setPayAmount(total.subtract(discount).add(transport).max(BigDecimal.ZERO));
        cbOrderService.updateById(order);
    }

    /**
     * 校验当前技师对订单有操作权限并返回订单实体。
     *
     * <p>多技师并行场景下，技师对订单的权限来源有两处：
     * <ol>
     *   <li>主技师：{@code cb_order.technician_id = techId}</li>
     *   <li>项目技师：{@code cb_order_item.technician_id = techId}</li>
     * </ol>
     */
    private CbOrder requireOwnOrder(Long orderId) {
        Long techId = MemberContext.getMemberId();
        CbOrder order = cbOrderService.lambdaQuery().eq(CbOrder::getId, orderId).eq(CbOrder::getDeleted, Boolean.FALSE).one();
        Optional.ofNullable(order).orElseThrow(() -> new BusinessException(CbCodeEnum.ORDER_NOT_FOUND));

        boolean isPrimaryTech = techId.equals(order.getTechnicianId());
        boolean isItemTech    = !isPrimaryTech && cbOrderItemService.lambdaQuery().eq(CbOrderItem::getOrderId,      orderId)
                .eq(CbOrderItem::getTechnicianId, techId).eq(CbOrderItem::getDeleted, Boolean.FALSE).exists();
        if (!isPrimaryTech && !isItemTech) throw new BusinessException(CbCodeEnum.ORDER_NOT_FOUND);
        return order;
    }
}
