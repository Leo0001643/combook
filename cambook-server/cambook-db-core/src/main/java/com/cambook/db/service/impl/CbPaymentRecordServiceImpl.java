package com.cambook.db.service.impl;

import com.cambook.db.entity.CbPaymentRecord;
import com.cambook.db.mapper.CbPaymentRecordMapper;
import com.cambook.db.service.ICbPaymentRecordService;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.springframework.stereotype.Service;

/**
 * <p>
 * 支付流水：支持多种支付方式，一次结算可拆分多笔支付 服务实现类
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
@Service
public class CbPaymentRecordServiceImpl extends ServiceImpl<CbPaymentRecordMapper, CbPaymentRecord> implements ICbPaymentRecordService {

}
