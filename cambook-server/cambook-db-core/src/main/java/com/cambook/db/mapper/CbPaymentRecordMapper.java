package com.cambook.db.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.cambook.db.entity.CbPaymentRecord;

/**
 * <p>
 * 支付流水：支持多种支付方式，一次结算可拆分多笔支付 Mapper 接口
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
public interface CbPaymentRecordMapper extends BaseMapper<CbPaymentRecord> {

}
