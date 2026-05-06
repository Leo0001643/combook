package com.cambook.db.service;

import com.cambook.db.entity.CbPayment;
import com.baomidou.mybatisplus.extension.service.IService;

/**
 * <p>
 * 支付记录表：记录每次支付行为，保存三方回调原始报文，用于对账 服务类
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
public interface ICbPaymentService extends IService<CbPayment> {

}
