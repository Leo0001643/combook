package com.cambook.db.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.cambook.db.entity.CbWallet;

/**
 * <p>
 * 钱包主表：记录会员/技师/商户实时余额和统计数据，与流水表联合使用 Mapper 接口
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
public interface CbWalletMapper extends BaseMapper<CbWallet> {

}
