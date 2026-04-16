package com.cambook.app.common.payment.impl;

import com.cambook.app.common.payment.IPaymentStrategy;
import com.cambook.app.common.payment.PaymentResult;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;

/**
 * 现金支付策略
 *
 * <p>线下现金无需在线扣款，直接标记成功，由技师确认收款。
 *
 * @author CamBook
 */
@Component
public class CashPayStrategy implements IPaymentStrategy {

    private static final Logger log = LoggerFactory.getLogger(CashPayStrategy.class);

    @Override
    public int payType() {
        return 4;
    }

    @Override
    public PaymentResult pay(Long orderId, BigDecimal amount, Long memberId, String extra) {
        log.info("[Cash Pay] orderId={} amount={}", orderId, amount);
        return PaymentResult.ok("CASH-" + System.currentTimeMillis(), "{\"channel\":\"CASH\"}");
    }

    @Override
    public boolean refund(String paymentNo, BigDecimal amount) {
        log.info("[Cash Refund] paymentNo={} — handled offline", paymentNo);
        return true;
    }
}
