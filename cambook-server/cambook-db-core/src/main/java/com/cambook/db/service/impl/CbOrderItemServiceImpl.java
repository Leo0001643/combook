package com.cambook.db.service.impl;

import com.cambook.db.entity.CbOrderItem;
import com.cambook.db.mapper.CbOrderItemMapper;
import com.cambook.db.service.ICbOrderItemService;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.springframework.stereotype.Service;

/**
 * <p>
 * 在线订单服务项明细 服务实现类
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
@Service
public class CbOrderItemServiceImpl extends ServiceImpl<CbOrderItemMapper, CbOrderItem> implements ICbOrderItemService {

}
