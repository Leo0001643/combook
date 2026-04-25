package com.cambook.dao.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.cambook.dao.entity.CbOrderItem;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

/**
 * 在线订单服务项明细 Mapper
 *
 * <p>基础 CRUD 继承 {@link BaseMapper}；批量查询见 {@code CbOrderItemMapper.xml}。
 *
 * @author CamBook
 */
@Mapper
public interface CbOrderItemMapper extends BaseMapper<CbOrderItem> {

    /** 查询指定订单下所有未删除的服务项（按 id 升序） */
    List<CbOrderItem> selectActiveByOrderId(@Param("orderId") Long orderId);

    /**
     * 按多个订单 ID 批量加载服务项（按 order_id, id 升序）
     * <p>适用于首页今日安排等需要一次性加载多订单项的场景，避免 N+1 查询。
     */
    List<CbOrderItem> selectByOrderIds(@Param("orderIds") List<Long> orderIds);

    /**
     * 按多个订单 ID + 技师 ID 批量加载该技师负责的服务项
     *
     * <p>多技师并行场景下，技师首页只应展示分配给自己的服务项，
     * 使用此方法过滤，避免展示其他技师负责的项目。
     */
    List<CbOrderItem> selectByOrderIdsAndTechId(
            @Param("orderIds") List<Long> orderIds,
            @Param("techId")   Long       techId);
}
