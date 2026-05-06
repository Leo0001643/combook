package com.cambook.db.service.impl;

import com.cambook.db.entity.CbDispatchOrder;
import com.cambook.db.mapper.CbDispatchOrderMapper;
import com.cambook.db.service.ICbDispatchOrderService;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.springframework.stereotype.Service;

/**
 * <p>
 * 派车单表：记录接送服务完整生命周期，关联主订单，含司机/车辆/坐标信息 服务实现类
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
@Service
public class CbDispatchOrderServiceImpl extends ServiceImpl<CbDispatchOrderMapper, CbDispatchOrder> implements ICbDispatchOrderService {

}
