package com.cambook.db.service;

import com.cambook.db.entity.CbDispatchOrder;
import com.baomidou.mybatisplus.extension.service.IService;

/**
 * <p>
 * 派车单表：记录接送服务完整生命周期，关联主订单，含司机/车辆/坐标信息 服务类
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
public interface ICbDispatchOrderService extends IService<CbDispatchOrder> {

}
