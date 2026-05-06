package com.cambook.app.common.payment.impl;

import com.cambook.app.common.payment.IPaymentStrategy;
import com.cambook.app.common.payment.PaymentResult;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;

/**
 * USDT 加密货币支付策略
 *
 * <p>监听链上转账事件，核验地址和金额后确认支付。
 *
 * @author CamBook
 */
@Component
public class UsdtPayStrategy implements IPaymentStrategy {

    private static final Logger log = LoggerFactory.getLogger(UsdtPayStrategy.class);

    @Override
    public int payType() {
        return 2;
    }

    @Override
    public PaymentResult pay(Long orderId, BigDecimal amount, Long memberId, String extra) {
        log.info("[USDT Pay] orderId={} amount={}", orderId, amount);
        // extra 中携带区块链收款地址，客户端转账后由 Webhook 回调更新支付状态
        return PaymentResult.ok("USDT-" + System.currentTimeMillis(), "{\"channel\":\"USDT\",\"address\":\"" + extra + "\"}");
    }

    @Override
    public boolean refund(String paymentNo, BigDecimal amount) {
        log.info("[USDT Refund] paymentNo={} amount={}", paymentNo, amount);
        // USDT 链上退款需要手动处理，记录退款请求即可
        return true;
    }
}
