package com.cambook.db.service.impl;

import com.cambook.db.entity.CbTechnicianSettlementItem;
import com.cambook.db.mapper.CbTechnicianSettlementItemMapper;
import com.cambook.db.service.ICbTechnicianSettlementItemService;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.springframework.stereotype.Service;

/**
 * <p>
 * 技师结算明细：本次结算包含的订单及各自提成 服务实现类
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
@Service
public class CbTechnicianSettlementItemServiceImpl extends ServiceImpl<CbTechnicianSettlementItemMapper, CbTechnicianSettlementItem> implements ICbTechnicianSettlementItemService {

}
