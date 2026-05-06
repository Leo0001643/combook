package com.cambook.db.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.cambook.db.entity.CbPayment;

/**
 * <p>
 * 支付记录表：记录每次支付行为，保存三方回调原始报文，用于对账 Mapper 接口
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
public interface CbPaymentMapper extends BaseMapper<CbPayment> {

}
