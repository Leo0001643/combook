package com.cambook.db.service.impl;

import com.cambook.db.entity.CbPayment;
import com.cambook.db.mapper.CbPaymentMapper;
import com.cambook.db.service.ICbPaymentService;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.springframework.stereotype.Service;

/**
 * <p>
 * 支付记录表：记录每次支付行为，保存三方回调原始报文，用于对账 服务实现类
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
@Service
public class CbPaymentServiceImpl extends ServiceImpl<CbPaymentMapper, CbPayment> implements ICbPaymentService {

}
