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
import com.cambook.dao.entity.CbTechnician;
import com.cambook.dao.mapper.CbMemberMapper;
import com.cambook.dao.mapper.CbOrderMapper;
import com.cambook.dao.mapper.CbTechnicianMapper;
import org.apache.commons.lang3.StringUtils;
import org.springframework.stereotype.Service;

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
    private final CbMemberMapper     memberMapper;
    private final CbTechnicianMapper technicianMapper;

    public AdminOrderService(CbOrderMapper orderMapper,
                             CbMemberMapper memberMapper,
                             CbTechnicianMapper technicianMapper) {
        this.orderMapper      = orderMapper;
        this.memberMapper     = memberMapper;
        this.technicianMapper = technicianMapper;
    }

    @Override
    public PageResult<OrderVO> pageList(OrderQueryDTO query) {
        LambdaQueryWrapper<CbOrder> wrapper = new LambdaQueryWrapper<CbOrder>()
                // 商户范围隔离：null=admin看全量，非null=仅该商户数据
                .eq(query.getMerchantId() != null, CbOrder::getMerchantId, query.getMerchantId())
                .like(StringUtils.isNotBlank(query.getOrderNo()), CbOrder::getOrderNo, query.getOrderNo())
                .eq(query.getStatus() != null, CbOrder::getStatus, query.getStatus())
                .orderByDesc(CbOrder::getCreateTime);

        Page<CbOrder> p = orderMapper.selectPage(new Page<>(query.getPage(), query.getSize()), wrapper);
        List<OrderVO> vos = p.getRecords().stream().map(OrderVO::from).collect(Collectors.toList());

        enrichNicknames(vos);

        return PageResult.of(vos, p.getTotal(), query.getPage(), query.getSize());
    }

    @Override
    public OrderVO getDetail(Long id) {
        CbOrder order = orderMapper.selectById(id);
        if (order == null) throw new BusinessException(CbCodeEnum.ORDER_NOT_FOUND);
        OrderVO vo = OrderVO.from(order);
        enrichNicknames(List.of(vo));
        return vo;
    }

    /** 批量补充会员昵称和技师昵称，避免 N+1 查询 */
    private void enrichNicknames(List<OrderVO> vos) {
        Set<Long> memberIds     = vos.stream().map(OrderVO::getMemberId)     .filter(id -> id != null).collect(Collectors.toSet());
        Set<Long> technicianIds = vos.stream().map(OrderVO::getTechnicianId) .filter(id -> id != null).collect(Collectors.toSet());

        Map<Long, String> memberNickMap = memberIds.isEmpty() ? Map.of() :
                memberMapper.selectBatchIds(memberIds).stream()
                        .collect(Collectors.toMap(CbMember::getId,
                                m -> StringUtils.defaultIfBlank(m.getNickname(), m.getMobile())));

        Map<Long, String> techNickMap = technicianIds.isEmpty() ? Map.of() :
                technicianMapper.selectBatchIds(technicianIds).stream()
                        .collect(Collectors.toMap(CbTechnician::getId,
                                t -> StringUtils.defaultIfBlank(t.getNickname(), t.getRealName())));

        vos.forEach(vo -> {
            if (vo.getMemberId() != null) {
                vo.setMemberNickname(memberNickMap.getOrDefault(vo.getMemberId(), "#" + vo.getMemberId()));
            }
            if (vo.getTechnicianId() != null) {
                vo.setTechnicianNickname(techNickMap.getOrDefault(vo.getTechnicianId(), "#" + vo.getTechnicianId()));
            }
        });
    }
}
