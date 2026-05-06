package com.cambook.db.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.cambook.db.entity.CbOrderItem;
import org.apache.ibatis.annotations.Param;

import java.util.List;

/**
 * 订单服务项 Mapper
 *
 * <p>多技师并行设计：每条 {@code cb_order_item} 关联独立 {@code technician_id}，
 * 批量查询方法见 {@code CbOrderItemMapper.xml}。
 *
 * @author CamBook
 */
public interface CbOrderItemMapper extends BaseMapper<CbOrderItem> {

    /** 查询指定订单下所有未删除的服务项（按 id 升序） */
    List<CbOrderItem> selectActiveByOrderId(@Param("orderId") Long orderId);

    /**
     * 按多个订单 ID 批量加载服务项（避免 N+1）
     *
     * @param orderIds 订单 ID 列表
     */
    List<CbOrderItem> selectByOrderIds(@Param("orderIds") List<Long> orderIds);

    /**
     * 按多个订单 ID + 技师 ID 批量加载服务项
     *
     * <p>多技师并行场景：技师首页只展示分配给自己的服务项。
     */
    List<CbOrderItem> selectByOrderIdsAndTechId(@Param("orderIds") List<Long> orderIds,
                                                  @Param("techId") Long techId);
}
