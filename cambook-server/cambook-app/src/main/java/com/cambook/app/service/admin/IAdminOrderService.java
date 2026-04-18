package com.cambook.app.service.admin;

import com.cambook.app.domain.dto.OrderQueryDTO;
import com.cambook.app.domain.vo.OrderVO;
import com.cambook.common.result.PageResult;

/**
 * Admin 端订单管理服务
 *
 * @author CamBook
 */
public interface IAdminOrderService {

    PageResult<OrderVO> pageList(OrderQueryDTO query);

    OrderVO getDetail(Long id);

    /** 取消订单 */
    void cancel(Long id, String reason);

    /** 结算订单（支持组合支付） */
    void settle(Long id, java.math.BigDecimal paidAmount, String payRecords);

    /** 删除订单（仅允许已取消/已完成） */
    void delete(Long id);
}
