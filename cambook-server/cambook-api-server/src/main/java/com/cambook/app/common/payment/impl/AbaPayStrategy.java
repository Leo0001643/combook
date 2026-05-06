package com.cambook.app.common.payment.impl;

import com.cambook.app.common.payment.IPaymentStrategy;
import com.cambook.app.common.payment.PaymentResult;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;

/**
 * ABA Pay 支付策略
 *
 * <p>对接柬埔寨 ABA Bank 扫码支付网关。
 * 实际接入时替换 {@code createQrCode} 为真实 API 调用。
 *
 * @author CamBook
 */
@Component
public class AbaPayStrategy implements IPaymentStrategy {

    private static final Logger log = LoggerFactory.getLogger(AbaPayStrategy.class);

    @Override
    public int payType() {
        return 1;
    }

    @Override
    public PaymentResult pay(Long orderId, BigDecimal amount, Long memberId, String extra) {
        log.info("[ABA Pay] orderId={} amount={}", orderId, amount);
        // TODO: 调用 ABA Gateway API，获取支付二维码并记录流水号
        // String qrContent = abaGateway.createQrCode(orderId, amount);
        return PaymentResult.ok("ABA-" + System.currentTimeMillis(), "{\"channel\":\"ABA\"}");
    }

    @Override
    public boolean refund(String paymentNo, BigDecimal amount) {
        log.info("[ABA Refund] paymentNo={} amount={}", paymentNo, amount);
        // TODO: 调用 ABA 退款 API
        return true;
    }
}
