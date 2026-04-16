package com.cambook.app.service.app;

import com.cambook.app.domain.dto.RechargeDTO;
import com.cambook.app.domain.dto.WithdrawDTO;
import com.cambook.app.domain.vo.WalletVO;

/**
 * 钱包服务
 *
 * @author CamBook
 */
public interface IWalletService {

    WalletVO getBalance();

    /** 发起充值，返回支付跳转 URL */
    String recharge(RechargeDTO dto);

    void withdraw(WithdrawDTO dto);
}
