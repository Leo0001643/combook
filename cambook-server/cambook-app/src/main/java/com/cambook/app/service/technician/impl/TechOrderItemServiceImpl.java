package com.cambook.app.service.technician.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.cambook.app.domain.dto.AddOrderItemDTO;
import com.cambook.app.domain.vo.OrderVO;
import com.cambook.app.service.technician.ITechOrderItemService;
import com.cambook.common.context.MemberContext;
import com.cambook.common.enums.CbCodeEnum;
import com.cambook.common.exception.BusinessException;
import com.cambook.dao.entity.CbOrder;
import com.cambook.dao.entity.CbOrderItem;
import com.cambook.dao.mapper.CbOrderItemMapper;
import com.cambook.dao.mapper.CbOrderMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;
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

    /** 可追加服务项的订单状态范围：接单(2) / 前往(3) / 到达(4) / 服务中(5) */
    private static final List<Integer> ADDABLE_STATUSES = List.of(2, 3, 4, 5);

    private final CbOrderMapper     orderMapper;
    private final CbOrderItemMapper orderItemMapper;

    @Override
    @Transactional(rollbackFor = Exception.class)
    public List<OrderVO.OrderItemVO> addItem(Long orderId, AddOrderItemDTO dto) {
        CbOrder order = requireOwnOrder(orderId);

        if (!ADDABLE_STATUSES.contains(order.getStatus())) {
            throw new BusinessException(CbCodeEnum.ORDER_STATUS_ILLEGAL);
        }

        // 构建新服务项
        CbOrderItem item = new CbOrderItem();
        item.setOrderId(orderId);
        item.setServiceItemId(dto.getServiceItemId());
        item.setServiceName(dto.getServiceName());
        item.setServiceDuration(dto.getServiceDuration());
        item.setUnitPrice(dto.getUnitPrice());
        item.setQty(dto.getQty() != null ? dto.getQty() : 1);
        item.setSvcStatus(0);   // 0=待服务
        item.setRemark(dto.getRemark());
        // createTime / updateTime 由 MyBatis-Plus 自动填充（@TableField fill）
        orderItemMapper.insert(item);

        // 重新计算订单总金额
        recalcOrderAmount(order);

        return loadItems(orderId);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void removeItem(Long orderId, Long itemId) {
        requireOwnOrder(orderId);

        CbOrderItem item = orderItemMapper.selectOne(
                new LambdaQueryWrapper<CbOrderItem>()
                        .eq(CbOrderItem::getId, itemId)
                        .eq(CbOrderItem::getOrderId, orderId)
                        .eq(CbOrderItem::getDeleted, 0));
        if (item == null) {
            throw new BusinessException(CbCodeEnum.DATA_NOT_FOUND);
        }
        if (item.getSvcStatus() != 0) {
            // 服务中或已完成的项目不允许取消
            throw new BusinessException(CbCodeEnum.ORDER_CANNOT_CANCEL);
        }

        // 逻辑删除（@TableLogic 自动处理，底层执行 UPDATE SET deleted=1）
        orderItemMapper.deleteById(item.getId());

        // 重新计算订单总金额
        recalcOrderAmount(requireOwnOrder(orderId));
    }

    @Override
    public List<OrderVO.OrderItemVO> listItems(Long orderId) {
        requireOwnOrder(orderId);
        return loadItems(orderId);
    }

    // ── 私有工具 ─────────────────────────────────────────────────────────────

    /** 加载指定订单的所有有效服务项并转换为 VO */
    private List<OrderVO.OrderItemVO> loadItems(Long orderId) {
        return orderItemMapper.selectActiveByOrderId(orderId)
                .stream().map(OrderVO.OrderItemVO::from).collect(Collectors.toList());
    }

    /**
     * 重新根据服务项合计更新订单的 original_amount 和 pay_amount。
     * <p>仅更新金额字段，不改变订单状态。
     */
    private void recalcOrderAmount(CbOrder order) {
        List<CbOrderItem> items = orderItemMapper.selectActiveByOrderId(order.getId());
        BigDecimal total = items.stream()
                .map(i -> i.getUnitPrice().multiply(BigDecimal.valueOf(i.getQty())))
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        order.setOriginalAmount(total);
        // pay_amount = original - discount + transport（保留现有优惠与运费）
        BigDecimal discount  = order.getDiscountAmount()  != null ? order.getDiscountAmount()  : BigDecimal.ZERO;
        BigDecimal transport = order.getTransportFee()    != null ? order.getTransportFee()    : BigDecimal.ZERO;
        order.setPayAmount(total.subtract(discount).add(transport).max(BigDecimal.ZERO));
        orderMapper.updateById(order);
    }

    /** 校验订单属于当前技师并返回订单实体；不存在或无权限则抛出业务异常 */
    private CbOrder requireOwnOrder(Long orderId) {
        Long techId = MemberContext.getMemberId();
        CbOrder order = orderMapper.selectOne(
                new LambdaQueryWrapper<CbOrder>()
                        .eq(CbOrder::getId, orderId)
                        .eq(CbOrder::getTechnicianId, techId)
                        .eq(CbOrder::getDeleted, 0));
        if (order == null) {
            throw new BusinessException(CbCodeEnum.ORDER_NOT_FOUND);
        }
        return order;
    }
}
