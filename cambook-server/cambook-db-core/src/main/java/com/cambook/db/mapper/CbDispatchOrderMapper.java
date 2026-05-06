package com.cambook.db.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.cambook.db.entity.CbDispatchOrder;

/**
 * <p>
 * 派车单表：记录接送服务完整生命周期，关联主订单，含司机/车辆/坐标信息 Mapper 接口
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
public interface CbDispatchOrderMapper extends BaseMapper<CbDispatchOrder> {

}
