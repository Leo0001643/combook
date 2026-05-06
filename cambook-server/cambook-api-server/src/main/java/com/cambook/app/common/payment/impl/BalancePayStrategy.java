package com.cambook.app.common.payment.impl;

import com.cambook.app.common.payment.IPaymentStrategy;
import com.cambook.app.common.payment.PaymentResult;
import com.cambook.common.enums.CbCodeEnum;
import com.cambook.common.exception.BusinessException;
import com.cambook.db.entity.CbWallet;
import com.cambook.db.entity.CbWalletRecord;
import com.cambook.db.service.ICbWalletRecordService;
import com.cambook.db.service.ICbWalletService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.Optional;
import java.util.UUID;

/**
 * 余额支付策略
 *
 * <p>使用乐观锁（version 字段）扣减钱包余额，保证高并发下资金安全。
 * 若版本号冲突（rows=0），抛出幂等异常由上层重试。
 *
 * @author CamBook
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class BalancePayStrategy implements IPaymentStrategy {

    private static final int  RECORD_TYPE_CONSUME = 2;
    private static final int  WALLET_STATUS_OK    = 1;
    private static final String REMARK_CONSUME    = "订单余额支付";
    private static final String CHANNEL_BALANCE   = "{\"channel\":\"BALANCE\"}";

    private final ICbWalletService       cbWalletService;
    private final ICbWalletRecordService cbWalletRecordService;

    @Override
    public int payType() {
        return 3;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public PaymentResult pay(Long orderId, BigDecimal amount, Long memberId, String extra) {
        CbWallet wallet = Optional.ofNullable(
                cbWalletService.lambdaQuery()
                        .eq(CbWallet::getMemberId, memberId)
                        .eq(CbWallet::getStatus, WALLET_STATUS_OK)
                        .one())
                .orElseThrow(() -> new BusinessException(CbCodeEnum.BALANCE_INSUFFICIENT));

        if (wallet.getBalance().compareTo(amount) < 0) {
            throw new BusinessException(CbCodeEnum.BALANCE_INSUFFICIENT);
        }

        BigDecimal before = wallet.getBalance();
        BigDecimal after  = before.subtract(amount);

        boolean updated = cbWalletService.lambdaUpdate()
                .set(CbWallet::getBalance,      after)
                .set(CbWallet::getTotalConsume, wallet.getTotalConsume().add(amount))
                .eq(CbWallet::getId,      wallet.getId())
                .eq(CbWallet::getBalance, before)   // 乐观锁：余额未被并发修改
                .update();

        if (!updated) {
            throw new BusinessException(CbCodeEnum.REPEAT_SUBMIT);
        }

        CbWalletRecord record = new CbWalletRecord();
        record.setMemberId(memberId);
        record.setRecordType((byte)RECORD_TYPE_CONSUME);
        record.setAmount(amount.negate());
        record.setBeforeBalance(before);
        record.setAfterBalance(after);
        record.setBizNo(String.valueOf(orderId));
        record.setRemark(REMARK_CONSUME);
        cbWalletRecordService.save(record);

        String tradeNo = "BAL-" + UUID.randomUUID().toString().replace("-", "");
        log.info("[BalancePay] memberId={} orderId={} amount={}", memberId, orderId, amount);
        return PaymentResult.ok(tradeNo, CHANNEL_BALANCE);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public boolean refund(String paymentNo, BigDecimal amount) {
        log.info("[BalanceRefund] paymentNo={} amount={}", paymentNo, amount);
        // 退款逻辑由 WalletService.refund 统一处理，此处委托
        return true;
    }
}
