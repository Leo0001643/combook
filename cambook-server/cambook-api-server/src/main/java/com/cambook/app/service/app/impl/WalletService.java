package com.cambook.app.service.app.impl;

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
import com.cambook.db.entity.CbWallet;
import com.cambook.db.entity.CbWalletRecord;
import com.cambook.db.service.ICbWalletRecordService;
import com.cambook.db.service.ICbWalletService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import com.cambook.common.enums.CommonStatus;

/**
 * 钱包服务实现
 *
 * <p>充值复用支付策略工厂，确保所有支付渠道统一管理。
 *
 * @author CamBook
 */
@Service
@RequiredArgsConstructor
public class WalletService implements IWalletService {

    private static final int USER_TYPE_MEMBER = 1;
    private static final int RECORD_TYPE_RECHARGE  = 1;
    private static final int RECORD_TYPE_WITHDRAW  = 3;

    private final ICbWalletService       cbWalletService;
    private final ICbWalletRecordService cbWalletRecordService;
    private final PaymentStrategyFactory paymentFactory;

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
        PaymentResult result = strategy.pay(-memberId, dto.getAmount(), memberId, null);

        if (result.isSuccess()) {
            CbWallet wallet = getOrCreateWallet(memberId);
            BigDecimal before = wallet.getBalance();
            BigDecimal after  = before.add(dto.getAmount());

            cbWalletService.lambdaUpdate()
                    .set(CbWallet::getBalance,       after)
                    .set(CbWallet::getTotalRecharge, wallet.getTotalRecharge().add(dto.getAmount()))
                    .eq(CbWallet::getId, wallet.getId())
                    .update();

            CbWalletRecord record = new CbWalletRecord();
            record.setMemberId(memberId);
            record.setRecordType((byte)RECORD_TYPE_RECHARGE);
            record.setAmount(dto.getAmount());
            record.setBeforeBalance(before);
            record.setAfterBalance(after);
            record.setBizNo(result.getThirdPartyNo());
            record.setRemark("账户充值");
            cbWalletRecordService.save(record);

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

        cbWalletService.lambdaUpdate()
                .set(CbWallet::getBalance,      after)
                .set(CbWallet::getTotalWithdraw, wallet.getTotalWithdraw().add(dto.getAmount()))
                .eq(CbWallet::getId, wallet.getId())
                .update();

        CbWalletRecord record = new CbWalletRecord();
        record.setMemberId(memberId);
        record.setRecordType((byte)RECORD_TYPE_WITHDRAW);
        record.setAmount(dto.getAmount().negate());
        record.setBeforeBalance(before);
        record.setAfterBalance(after);
        record.setBizNo(dto.getAccount());
        record.setRemark("账户提现");
        cbWalletRecordService.save(record);
    }

    // ── 私有 ──────────────────────────────────────────────────────────────────

    private CbWallet getOrCreateWallet(Long memberId) {
        CbWallet wallet = cbWalletService.lambdaQuery().eq(CbWallet::getMemberId, memberId).one();
        if (wallet == null) {
            wallet = new CbWallet();
            wallet.setMemberId(memberId);
            wallet.setUserType((byte)USER_TYPE_MEMBER);
            wallet.setBalance(BigDecimal.ZERO);
            wallet.setTotalRecharge(BigDecimal.ZERO);
            wallet.setTotalWithdraw(BigDecimal.ZERO);
            wallet.setTotalConsume(BigDecimal.ZERO);
            wallet.setStatus(CommonStatus.ENABLED.byteCode());
            cbWalletService.save(wallet);
        }
        return wallet;
    }
}
