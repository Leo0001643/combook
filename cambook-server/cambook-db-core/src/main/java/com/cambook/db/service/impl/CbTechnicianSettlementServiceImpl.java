package com.cambook.db.service.impl;

import com.cambook.db.entity.CbTechnicianSettlement;
import com.cambook.db.mapper.CbTechnicianSettlementMapper;
import com.cambook.db.service.ICbTechnicianSettlementService;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.springframework.stereotype.Service;

/**
 * <p>
 * 技师结算批次：支持每笔/日结/周结/月结四种方式 服务实现类
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
@Service
public class CbTechnicianSettlementServiceImpl extends ServiceImpl<CbTechnicianSettlementMapper, CbTechnicianSettlement> implements ICbTechnicianSettlementService {

}
