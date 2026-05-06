package com.cambook.app.service.admin;

import com.cambook.db.entity.CbMerchantCurrency;
import com.cambook.db.entity.SysCurrency;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

/**
 * 币种管理（超级管理员和商户共用）
 */
public interface IAdminCurrencyService {

    List<SysCurrency> list(Integer status);

    void add(SysCurrency currency);

    void update(SysCurrency currency);

    void updateRate(String code, BigDecimal rateToUsd);

    void toggleStatus(Long id, Integer status);

    List<Map<String, Object>> merchantCurrencies(Long merchantId);

    void applyMerchantCurrencyConfig(Long merchantId, List<MerchantCurrencyConfigItem> configs);

    void validateConfigs(List<MerchantCurrencyConfigItem> configs);

    List<Map<String, Object>> enabledCurrencies(Long merchantId);

    /** 商户币种配置请求体 */
    class MerchantCurrencyConfigItem {
        public String     currencyCode;
        public boolean    enabled    = false;
        public boolean    isDefault  = false;
        public BigDecimal customRate;
        public String     displayName;
        public int        sortOrder  = 0;
    }
}
