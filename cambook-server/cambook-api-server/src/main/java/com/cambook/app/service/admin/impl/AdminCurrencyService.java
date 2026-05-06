package com.cambook.app.service.admin.impl;

import com.cambook.app.service.admin.IAdminCurrencyService;
import com.cambook.common.enums.CommonStatus;
import com.cambook.common.exception.BusinessException;
import com.cambook.db.entity.CbMerchantCurrency;
import com.cambook.db.entity.SysCurrency;
import com.cambook.db.service.ICbMerchantCurrencyService;
import com.cambook.db.service.ISysCurrencyService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.util.*;
import java.util.stream.Collectors;
import com.cambook.common.utils.DateUtils;
import com.cambook.common.enums.CbCodeEnum;

/**
 * 币种管理实现
 */
@Service
@RequiredArgsConstructor
public class AdminCurrencyService implements IAdminCurrencyService {

    private static final int          STATUS_ACTIVE          = CommonStatus.ENABLED.getCode();
    private static final List<String> DEFAULT_CURRENCY_CODES = List.of("USD", "USDT");

    private final ISysCurrencyService        sysCurrencyService;
    private final ICbMerchantCurrencyService cbMerchantCurrencyService;

    @Override
    public List<SysCurrency> list(Integer status) {
        return sysCurrencyService.lambdaQuery()
                .eq(status != null, SysCurrency::getStatus, status)
                .orderByAsc(SysCurrency::getSortOrder).orderByAsc(SysCurrency::getId).list();
    }

    @Override
    public void add(SysCurrency currency) {
        boolean exists = sysCurrencyService.lambdaQuery().eq(SysCurrency::getCurrencyCode, currency.getCurrencyCode().toUpperCase()).exists();
        if (exists) throw new BusinessException(CbCodeEnum.CURRENCY_CODE_EXISTS);
        currency.setCurrencyCode(currency.getCurrencyCode().toUpperCase());
        currency.setRateUpdateTime(DateUtils.nowSeconds());
        currency.setStatus(currency.getStatus() == null ? (byte) STATUS_ACTIVE : currency.getStatus());
        sysCurrencyService.save(currency);
    }

    @Override
    public void update(SysCurrency currency) {
        if (currency.getId() == null) throw new BusinessException(CbCodeEnum.PARAM_ERROR);
        sysCurrencyService.updateById(currency);
    }

    @Override
    public void updateRate(String code, BigDecimal rateToUsd) {
        if (rateToUsd.compareTo(BigDecimal.ZERO) <= 0) throw new BusinessException(CbCodeEnum.PARAM_ERROR);
        boolean updated = sysCurrencyService.lambdaUpdate()
                .set(SysCurrency::getRateToUsd, rateToUsd).set(SysCurrency::getRateUpdateTime, DateUtils.nowSeconds())
                .eq(SysCurrency::getCurrencyCode, code.toUpperCase()).update();
        if (!updated) throw new BusinessException(CbCodeEnum.CURRENCY_NOT_FOUND);
    }

    @Override
    public void toggleStatus(Long id, Integer status) {
        sysCurrencyService.lambdaUpdate().set(SysCurrency::getStatus, status).eq(SysCurrency::getId, id).update();
    }

    @Override
    public List<Map<String, Object>> merchantCurrencies(Long merchantId) {
        List<SysCurrency> all = sysCurrencyService.lambdaQuery().eq(SysCurrency::getStatus, STATUS_ACTIVE).orderByAsc(SysCurrency::getSortOrder).list();
        Map<String, CbMerchantCurrency> configMap = cbMerchantCurrencyService.lambdaQuery()
                .eq(CbMerchantCurrency::getMerchantId, merchantId).list()
                .stream().collect(Collectors.toMap(CbMerchantCurrency::getCurrencyCode, c -> c));
        return all.stream().map(c -> {
            CbMerchantCurrency mc = configMap.get(c.getCurrencyCode());
            Map<String, Object> item = new LinkedHashMap<>();
            item.put("currencyCode",   c.getCurrencyCode());
            item.put("currencyName",   c.getCurrencyName());
            item.put("currencyNameEn", c.getCurrencyNameEn());
            item.put("symbol",         c.getSymbol());
            item.put("flag",           c.getFlag());
            item.put("isCrypto",       c.getIsCrypto());
            item.put("globalRate",     c.getRateToUsd());
            item.put("decimalPlaces",  c.getDecimalPlaces());
            item.put("enabled",        mc != null && mc.getStatus() == STATUS_ACTIVE);
            item.put("isDefault",      mc != null && mc.getIsDefault() == STATUS_ACTIVE);
            item.put("customRate",     mc != null ? mc.getCustomRate() : null);
            item.put("displayName",    mc != null ? mc.getDisplayName() : null);
            item.put("sortOrder",      mc != null ? mc.getSortOrder() : c.getSortOrder());
            return item;
        }).collect(Collectors.toList());
    }

    @Override
    public void applyMerchantCurrencyConfig(Long merchantId, List<MerchantCurrencyConfigItem> configs) {
        for (MerchantCurrencyConfigItem cfg : configs) {
            CbMerchantCurrency existing = cbMerchantCurrencyService.lambdaQuery()
                    .eq(CbMerchantCurrency::getMerchantId, merchantId).eq(CbMerchantCurrency::getCurrencyCode, cfg.currencyCode).one();
            if (existing == null) {
                CbMerchantCurrency mc = new CbMerchantCurrency();
                mc.setMerchantId(merchantId);
                mc.setCurrencyCode(cfg.currencyCode);
                mc.setIsDefault(cfg.isDefault ? (byte) CommonStatus.ENABLED.getCode() : (byte) CommonStatus.DISABLED.getCode());
                mc.setCustomRate(cfg.customRate);
                mc.setDisplayName(cfg.displayName);
                mc.setSortOrder(cfg.sortOrder);
                mc.setStatus(cfg.enabled ? (byte) CommonStatus.ENABLED.getCode() : (byte) CommonStatus.DISABLED.getCode());
                cbMerchantCurrencyService.save(mc);
            } else {
                existing.setIsDefault(cfg.isDefault ? (byte) CommonStatus.ENABLED.getCode() : (byte) CommonStatus.DISABLED.getCode());
                existing.setCustomRate(cfg.customRate);
                existing.setDisplayName(cfg.displayName);
                existing.setSortOrder(cfg.sortOrder);
                existing.setStatus(cfg.enabled ? (byte) CommonStatus.ENABLED.getCode() : (byte) CommonStatus.DISABLED.getCode());
                cbMerchantCurrencyService.updateById(existing);
            }
        }
    }

    @Override
    public void validateConfigs(List<MerchantCurrencyConfigItem> configs) {
        long defaultCount = configs.stream().filter(c -> c.enabled && c.isDefault).count();
        if (defaultCount > 1) throw new BusinessException(CbCodeEnum.CURRENCY_DEFAULT_CONFLICT);
        Set<String> codes = configs.stream().map(c -> c.currencyCode).collect(Collectors.toSet());
        long validCount = sysCurrencyService.lambdaQuery().in(SysCurrency::getCurrencyCode, codes).eq(SysCurrency::getStatus, STATUS_ACTIVE).count();
        if (validCount < codes.size()) throw new BusinessException(CbCodeEnum.CURRENCY_INVALID);
    }

    @Override
    public List<Map<String, Object>> enabledCurrencies(Long merchantId) {
        List<CbMerchantCurrency> configs = cbMerchantCurrencyService.lambdaQuery()
                .eq(CbMerchantCurrency::getMerchantId, merchantId).eq(CbMerchantCurrency::getStatus, STATUS_ACTIVE).list();
        if (configs.isEmpty()) return defaultCurrencies();

        Map<String, CbMerchantCurrency> configMap = configs.stream().collect(Collectors.toMap(CbMerchantCurrency::getCurrencyCode, c -> c));
        List<SysCurrency> globalList = sysCurrencyService.lambdaQuery()
                .in(SysCurrency::getCurrencyCode, configMap.keySet()).eq(SysCurrency::getStatus, STATUS_ACTIVE).list();

        return globalList.stream().sorted(Comparator.comparingInt((SysCurrency c) -> {
            CbMerchantCurrency mc = configMap.get(c.getCurrencyCode());
            return mc != null ? mc.getSortOrder() : 999;
        })).map(c -> {
            CbMerchantCurrency mc = configMap.get(c.getCurrencyCode());
            Map<String, Object> item = new LinkedHashMap<>();
            item.put("currencyCode",   c.getCurrencyCode());
            item.put("currencyName",   mc.getDisplayName() != null ? mc.getDisplayName() : c.getCurrencyName());
            item.put("currencyNameEn", c.getCurrencyNameEn());
            item.put("symbol",         c.getSymbol());
            item.put("flag",           c.getFlag());
            item.put("isCrypto",       c.getIsCrypto());
            item.put("decimalPlaces",  c.getDecimalPlaces());
            item.put("isDefault",      mc.getIsDefault() == 1);
            item.put("rateToUsd",      mc.getCustomRate() != null ? mc.getCustomRate() : c.getRateToUsd());
            return item;
        }).collect(Collectors.toList());
    }

    private List<Map<String, Object>> defaultCurrencies() {
        return sysCurrencyService.lambdaQuery()
                .in(SysCurrency::getCurrencyCode, DEFAULT_CURRENCY_CODES).eq(SysCurrency::getStatus, STATUS_ACTIVE)
                .orderByAsc(SysCurrency::getSortOrder).list().stream().map(c -> {
                    Map<String, Object> item = new LinkedHashMap<>();
                    item.put("currencyCode",   c.getCurrencyCode());
                    item.put("currencyName",   c.getCurrencyName());
                    item.put("currencyNameEn", c.getCurrencyNameEn());
                    item.put("symbol",         c.getSymbol());
                    item.put("flag",           c.getFlag());
                    item.put("isCrypto",       c.getIsCrypto());
                    item.put("decimalPlaces",  c.getDecimalPlaces());
                    item.put("isDefault",      "USD".equals(c.getCurrencyCode()));
                    item.put("rateToUsd",      c.getRateToUsd());
                    return item;
                }).collect(Collectors.toList());
    }
}
