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
}
