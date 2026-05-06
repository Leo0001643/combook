package com.cambook.db.service;

import com.cambook.db.entity.CbOrder;
import com.baomidou.mybatisplus.extension.service.IService;

/**
 * <p>
 * 订单表：核心业务表，含金额快照/状态流转/收益分配，全生命周期记录 服务类
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
public interface ICbOrderService extends IService<CbOrder> {

}
