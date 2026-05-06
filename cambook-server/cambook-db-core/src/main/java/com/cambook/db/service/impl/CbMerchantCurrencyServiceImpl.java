package com.cambook.db.service.impl;

import com.cambook.db.entity.CbMerchantCurrency;
import com.cambook.db.mapper.CbMerchantCurrencyMapper;
import com.cambook.db.service.ICbMerchantCurrencyService;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.springframework.stereotype.Service;

/**
 * <p>
 * 商户币种配置：每家商户可独立启用不同结算货币，支持自定义汇率 服务实现类
 * </p>
 *
 * @author Baomidou
 * @since 2026-05-05
 */
@Service
public class CbMerchantCurrencyServiceImpl extends ServiceImpl<CbMerchantCurrencyMapper, CbMerchantCurrency> implements ICbMerchantCurrencyService {

}
