package com.cambook.db.service;

import com.cambook.db.entity.CbPaymentRecord;
import com.baomidou.mybatisplus.extension.service.IService;

/**
 * <p>
 * 支付流水：支持多种支付方式，一次结算可拆分多笔支付 服务类
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
public interface ICbPaymentRecordService extends IService<CbPaymentRecord> {

}
