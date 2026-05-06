package com.cambook.db.service;

import com.cambook.db.entity.CbWallet;
import com.baomidou.mybatisplus.extension.service.IService;

/**
 * <p>
 * 钱包主表：记录会员/技师/商户实时余额和统计数据，与流水表联合使用 服务类
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
public interface ICbWalletService extends IService<CbWallet> {

}
