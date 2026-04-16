package com.cambook.app.common.payment;

import java.math.BigDecimal;

/**
 * 支付策略接口（策略模式）
 *
 * <p>新增支付方式只需新增实现类并注入工厂，无需修改已有代码（开闭原则）。
 *
 * @author CamBook
 */
public interface IPaymentStrategy {

    /**
     * 支付方式标识，与 {@code cb_payment.pay_type} 对应
     */
    int payType();

    /**
     * 发起支付
     *
     * @param orderId   业务订单 ID
     * @param amount    支付金额
     * @param memberId  用户 ID
     * @param extra     扩展参数（如钱包密码、链上地址等）
     * @return 支付结果
     */
    PaymentResult pay(Long orderId, BigDecimal amount, Long memberId, String extra);

    /**
     * 退款
     *
     * @param paymentNo 支付单号
     * @param amount    退款金额
     * @return 是否成功
     */
    boolean refund(String paymentNo, BigDecimal amount);
}
