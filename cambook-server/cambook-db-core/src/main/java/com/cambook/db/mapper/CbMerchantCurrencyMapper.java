package com.cambook.db.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.cambook.db.entity.CbMerchantCurrency;

/**
 * <p>
 * 商户币种配置：每家商户可独立启用不同结算货币，支持自定义汇率 Mapper 接口
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
public interface CbMerchantCurrencyMapper extends BaseMapper<CbMerchantCurrency> {

}
