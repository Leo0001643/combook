package com.cambook.db.service.impl;

import com.cambook.db.entity.CbWallet;
import com.cambook.db.mapper.CbWalletMapper;
import com.cambook.db.service.ICbWalletService;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.springframework.stereotype.Service;

/**
 * <p>
 * 钱包主表：记录会员/技师/商户实时余额和统计数据，与流水表联合使用 服务实现类
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
@Service
public class CbWalletServiceImpl extends ServiceImpl<CbWalletMapper, CbWallet> implements ICbWalletService {

}
