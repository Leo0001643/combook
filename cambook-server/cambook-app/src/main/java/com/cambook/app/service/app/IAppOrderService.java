package com.cambook.app.service.app;

import com.cambook.app.domain.dto.CancelOrderDTO;
import com.cambook.app.domain.dto.CreateOrderDTO;
import com.cambook.app.domain.vo.OrderVO;
import com.cambook.common.result.PageResult;

/**
 * App 端订单服务
 *
 * @author CamBook
 */
public interface IAppOrderService {

    OrderVO createOrder(CreateOrderDTO dto);

    PageResult<OrderVO> myOrders(Integer status, int page, int size);

    OrderVO getDetail(Long id);

    void cancel(CancelOrderDTO dto);
}
