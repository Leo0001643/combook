package com.cambook.app.service.technician;

import com.cambook.app.domain.dto.AddOrderItemDTO;
import com.cambook.app.domain.vo.OrderVO;

import java.util.List;

/**
 * 技师端订单服务项管理接口
 *
 * <p>支持"一单多项"业务：技师在接单后可为同一客人追加服务项目，
 * 尚未开始的项目也可取消，最终统一结算。
 *
 * @author CamBook
 */
public interface ITechOrderItemService {

    /**
     * 向指定订单追加一个服务项。
     *
     * <p>前置校验：订单必须属于当前技师，且处于可追加状态（status 2-5，即接单至服务中）。
     *
     * @param orderId 目标订单 ID
     * @param dto     服务项信息
     * @return 追加后的订单完整服务项列表
     */
    List<OrderVO.OrderItemVO> addItem(Long orderId, AddOrderItemDTO dto);

    /**
     * 取消订单中一个尚未开始的服务项（svc_status=0）。
     *
     * <p>前置校验：订单属于当前技师，且该项目处于"待服务"状态。
     * 服务中或已完成的项目不允许取消。
     *
     * @param orderId 目标订单 ID
     * @param itemId  服务项 ID
     */
    void removeItem(Long orderId, Long itemId);

    /**
     * 获取指定订单的所有服务项列表。
     *
     * @param orderId 订单 ID
     * @return 服务项列表（按创建时间升序）
     */
    List<OrderVO.OrderItemVO> listItems(Long orderId);
}
