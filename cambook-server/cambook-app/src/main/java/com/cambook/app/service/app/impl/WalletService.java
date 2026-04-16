package com.cambook.app.service.app.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper;
import com.cambook.common.context.MemberContext;
import com.cambook.app.common.payment.IPaymentStrategy;
import com.cambook.app.common.payment.PaymentResult;
import com.cambook.app.common.payment.PaymentStrategyFactory;
import com.cambook.app.domain.dto.RechargeDTO;
import com.cambook.app.domain.dto.WithdrawDTO;
import com.cambook.app.domain.vo.WalletVO;
import com.cambook.app.service.app.IWalletService;
import com.cambook.common.enums.CbCodeEnum;
import com.cambook.common.exception.BusinessException;
import com.cambook.dao.entity.CbWallet;
import com.cambook.dao.entity.CbWalletRecord;
import com.cambook.dao.mapper.CbWalletMapper;
import com.cambook.dao.mapper.CbWalletRecordMapper;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;

/**
 * 钱包服务实现
 *
 * <p>充值复用支付策略工厂，确保所有支付渠道统一管理。
 *
 * @author CamBook
 */
@Service
public class WalletService implements IWalletService {

    private final CbWalletMapper        walletMapper;
    private final CbWalletRecordMapper  walletRecordMapper;
    private final PaymentStrategyFactory paymentFactory;

    public WalletService(CbWalletMapper walletMapper,
                         CbWalletRecordMapper walletRecordMapper,
                         PaymentStrategyFactory paymentFactory) {
        this.walletMapper       = walletMapper;
        this.walletRecordMapper = walletRecordMapper;
        this.paymentFactory     = paymentFactory;
    }

    @Override
    public WalletVO getBalance() {
        Long memberId = MemberContext.currentId();
        CbWallet wallet = getOrCreateWallet(memberId);
        WalletVO vo = new WalletVO();
        vo.setBalance(wallet.getBalance());
        vo.setTotalRecharge(wallet.getTotalRecharge());
        vo.setTotalConsume(wallet.getTotalConsume());
        vo.setTotalWithdraw(wallet.getTotalWithdraw());
        return vo;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public String recharge(RechargeDTO dto) {
        Long memberId = MemberContext.currentId();
        IPaymentStrategy strategy = paymentFactory.getStrategy(dto.getPayType());
        // 充值使用虚拟订单 ID（使用 memberId * -1 标识充值业务）
        PaymentResult result = strategy.pay(-memberId, dto.getAmount(), memberId, null);

        if (result.isSuccess()) {
            CbWallet wallet = getOrCreateWallet(memberId);
            BigDecimal before = wallet.getBalance();
            BigDecimal after  = before.add(dto.getAmount());

            walletMapper.update(null,
                    new LambdaUpdateWrapper<CbWallet>()
                            .set(CbWallet::getBalance, after)
                            .set(CbWallet::getTotalRecharge, wallet.getTotalRecharge().add(dto.getAmount()))
                            .eq(CbWallet::getId, wallet.getId())
            );

            CbWalletRecord record = new CbWalletRecord();
            record.setMemberId(memberId);
            record.setRecordType(1);
            record.setAmount(dto.getAmount());
            record.setBeforeBalance(before);
            record.setAfterBalance(after);
            record.setBizNo(result.getThirdPartyNo());
            record.setRemark("账户充值");
            walletRecordMapper.insert(record);

            return result.getThirdPartyNo();
        }
        throw new BusinessException(CbCodeEnum.SERVER_ERROR);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void withdraw(WithdrawDTO dto) {
        Long memberId = MemberContext.currentId();
        CbWallet wallet = getOrCreateWallet(memberId);

        if (wallet.getBalance().compareTo(dto.getAmount()) < 0) {
            throw new BusinessException(CbCodeEnum.BALANCE_INSUFFICIENT);
        }

        BigDecimal before = wallet.getBalance();
        BigDecimal after  = before.subtract(dto.getAmount());

        walletMapper.update(null,
                new LambdaUpdateWrapper<CbWallet>()
                        .set(CbWallet::getBalance, after)
                        .set(CbWallet::getTotalWithdraw, wallet.getTotalWithdraw().add(dto.getAmount()))
                        .eq(CbWallet::getId, wallet.getId())
        );

        CbWalletRecord record = new CbWalletRecord();
        record.setMemberId(memberId);
        record.setRecordType(3);
        record.setAmount(dto.getAmount().negate());
        record.setBeforeBalance(before);
        record.setAfterBalance(after);
        record.setBizNo(dto.getAccount());
        record.setRemark("账户提现");
        walletRecordMapper.insert(record);
    }

    // ── 私有 ──────────────────────────────────────────────────────────────────

    private CbWallet getOrCreateWallet(Long memberId) {
        CbWallet wallet = walletMapper.selectOne(
                new LambdaQueryWrapper<CbWallet>().eq(CbWallet::getMemberId, memberId)
        );
        if (wallet == null) {
            wallet = new CbWallet();
            wallet.setMemberId(memberId);
            wallet.setUserType(1);
            wallet.setBalance(BigDecimal.ZERO);
            wallet.setTotalRecharge(BigDecimal.ZERO);
            wallet.setTotalWithdraw(BigDecimal.ZERO);
            wallet.setTotalConsume(BigDecimal.ZERO);
            wallet.setStatus(1);
            walletMapper.insert(wallet);
        }
        return wallet;
    }
}
