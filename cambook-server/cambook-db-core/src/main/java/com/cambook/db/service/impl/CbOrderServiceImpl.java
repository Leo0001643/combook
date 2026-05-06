package com.cambook.db.service.impl;

import com.cambook.db.entity.CbOrder;
import com.cambook.db.mapper.CbOrderMapper;
import com.cambook.db.service.ICbOrderService;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.springframework.stereotype.Service;

/**
 * <p>
 * 订单表：核心业务表，含金额快照/状态流转/收益分配，全生命周期记录 服务实现类
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
@Service
public class CbOrderServiceImpl extends ServiceImpl<CbOrderMapper, CbOrder> implements ICbOrderService {

}
