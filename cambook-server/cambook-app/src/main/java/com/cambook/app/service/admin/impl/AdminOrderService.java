package com.cambook.app.service.admin.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.cambook.app.domain.dto.OrderQueryDTO;
import com.cambook.app.domain.vo.OrderVO;
import com.cambook.app.service.admin.IAdminOrderService;
import com.cambook.common.enums.CbCodeEnum;
import com.cambook.common.exception.BusinessException;
import com.cambook.common.result.PageResult;
import com.cambook.dao.entity.CbMember;
import com.cambook.dao.entity.CbOrder;
import com.cambook.dao.entity.CbOrderItem;
import com.cambook.dao.entity.CbTechnician;
import com.cambook.dao.mapper.CbMemberMapper;
import com.cambook.dao.mapper.CbOrderItemMapper;
import com.cambook.dao.mapper.CbOrderMapper;
import com.cambook.dao.mapper.CbTechnicianMapper;
import org.apache.commons.lang3.StringUtils;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
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

    private final CbOrderMapper      orderMapper;
    private final CbOrderItemMapper  orderItemMapper;
    private final CbMemberMapper     memberMapper;
    private final CbTechnicianMapper technicianMapper;

    public AdminOrderService(CbOrderMapper orderMapper,
                             CbOrderItemMapper orderItemMapper,
                             CbMemberMapper memberMapper,
                             CbTechnicianMapper technicianMapper) {
        this.orderMapper      = orderMapper;
        this.orderItemMapper  = orderItemMapper;
        this.memberMapper     = memberMapper;
        this.technicianMapper = technicianMapper;
    }

    @Override
    public PageResult<OrderVO> pageList(OrderQueryDTO query) {
        LambdaQueryWrapper<CbOrder> wrapper = new LambdaQueryWrapper<CbOrder>()
                .eq(query.getMerchantId() != null, CbOrder::getMerchantId, query.getMerchantId())
                .like(StringUtils.isNotBlank(query.getOrderNo()), CbOrder::getOrderNo, query.getOrderNo())
                .eq(query.getStatus() != null, CbOrder::getStatus, query.getStatus())
                .eq(query.getServiceMode() != null, CbOrder::getServiceMode, query.getServiceMode())
                .ge(StringUtils.isNotBlank(query.getStartDate()), CbOrder::getCreateTime,
                        StringUtils.isNotBlank(query.getStartDate())
                                ? LocalDateTime.of(LocalDate.parse(query.getStartDate()), LocalTime.MIN) : null)
                .le(StringUtils.isNotBlank(query.getEndDate()), CbOrder::getCreateTime,
                        StringUtils.isNotBlank(query.getEndDate())
                                ? LocalDateTime.of(LocalDate.parse(query.getEndDate()), LocalTime.MAX) : null)
                .orderByDesc(CbOrder::getCreateTime);

        Page<CbOrder> p = orderMapper.selectPage(new Page<>(query.getPage(), query.getSize()), wrapper);
        List<OrderVO> vos = p.getRecords().stream().map(OrderVO::from).collect(Collectors.toList());

        enrichNicknames(vos);

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
        upd.setPayTime(LocalDateTime.now());
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
}
