package com.cambook.app.common.payment.impl;

import com.cambook.app.common.payment.IPaymentStrategy;
import com.cambook.app.common.payment.PaymentResult;
import com.cambook.common.enums.CbCodeEnum;
import com.cambook.common.exception.BusinessException;
import com.cambook.dao.entity.CbWallet;
import com.cambook.dao.entity.CbWalletRecord;
import com.cambook.dao.mapper.CbWalletMapper;
import com.cambook.dao.mapper.CbWalletRecordMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.UUID;

/**
 * 余额支付策略
 *
 * <p>使用乐观锁扣减钱包余额，保证高并发下资金安全。
 *
 * @author CamBook
 */
@Component
public class BalancePayStrategy implements IPaymentStrategy {

    private static final Logger log = LoggerFactory.getLogger(BalancePayStrategy.class);

    private final CbWalletMapper       walletMapper;
    private final CbWalletRecordMapper walletRecordMapper;

    public BalancePayStrategy(CbWalletMapper walletMapper,
                              CbWalletRecordMapper walletRecordMapper) {
        this.walletMapper       = walletMapper;
        this.walletRecordMapper = walletRecordMapper;
    }

    @Override
    public int payType() {
        return 3;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public PaymentResult pay(Long orderId, BigDecimal amount, Long memberId, String extra) {
        CbWallet wallet = walletMapper.selectOne(
                new com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper<CbWallet>()
                        .eq(CbWallet::getMemberId, memberId)
                        .eq(CbWallet::getStatus, 1)
        );
        if (wallet == null || wallet.getBalance().compareTo(amount) < 0) {
            throw new BusinessException(CbCodeEnum.BALANCE_INSUFFICIENT);
        }

        BigDecimal before = wallet.getBalance();
        BigDecimal after  = before.subtract(amount);

        int rows = walletMapper.update(null,
                new com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper<CbWallet>()
                        .set(CbWallet::getBalance, after)
                        .set(CbWallet::getTotalConsume, wallet.getTotalConsume().add(amount))
                        .eq(CbWallet::getId, wallet.getId())
                        .eq(CbWallet::getBalance, before)
        );
        if (rows == 0) {
            throw new BusinessException(CbCodeEnum.REPEAT_SUBMIT);
        }

        CbWalletRecord record = new CbWalletRecord();
        record.setMemberId(memberId);
        record.setRecordType(2);
        record.setAmount(amount.negate());
        record.setBeforeBalance(before);
        record.setAfterBalance(after);
        record.setBizNo(String.valueOf(orderId));
        record.setRemark("订单余额支付");
        walletRecordMapper.insert(record);

        String tradeNo = "BAL-" + UUID.randomUUID().toString().replace("-", "");
        log.info("[Balance Pay] memberId={} orderId={} amount={}", memberId, orderId, amount);
        return PaymentResult.ok(tradeNo, "{\"channel\":\"BALANCE\"}");
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public boolean refund(String paymentNo, BigDecimal amount) {
        log.info("[Balance Refund] paymentNo={} amount={}", paymentNo, amount);
        // 退款逻辑由 WalletService.refund 统一处理，此处委托
        return true;
    }
}
