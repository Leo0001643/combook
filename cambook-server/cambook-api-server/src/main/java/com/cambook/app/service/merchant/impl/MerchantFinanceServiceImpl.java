package com.cambook.app.service.merchant.impl;

import com.cambook.app.service.merchant.IMerchantFinanceService;
import com.cambook.common.utils.DateUtils;
import com.cambook.db.entity.CbMerchant;
import com.cambook.db.entity.CbOrder;
import com.cambook.db.service.ICbMerchantService;
import com.cambook.db.service.ICbOrderService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.function.Function;

/**
 * 商户端 财务管理实现
 */
@Service
@RequiredArgsConstructor
public class MerchantFinanceServiceImpl implements IMerchantFinanceService {

    private static final int ORDER_STATUS_COMPLETED = 4;

    private final ICbOrderService    cbOrderService;
    private final ICbMerchantService cbMerchantService;

    @Override
    public Map<String, Object> overview(Long merchantId) {
        CbMerchant merchant = cbMerchantService.getById(merchantId);

        List<CbOrder> completedOrders = cbOrderService.lambdaQuery()
                .eq(CbOrder::getMerchantId, merchantId).eq(CbOrder::getStatus, ORDER_STATUS_COMPLETED)
                .select(CbOrder::getPayAmount, CbOrder::getPlatformIncome, CbOrder::getTechIncome).list();
        BigDecimal totalRevenue  = sum(completedOrders, CbOrder::getPayAmount);
        BigDecimal platformFee   = sum(completedOrders, CbOrder::getPlatformIncome);
        BigDecimal techFee       = sum(completedOrders, CbOrder::getTechIncome);
        BigDecimal merchantRevenue = totalRevenue.subtract(platformFee).subtract(techFee);

        long todayStart = DateUtils.todayStart();
        List<CbOrder> todayOrders = cbOrderService.lambdaQuery()
                .eq(CbOrder::getMerchantId, merchantId).eq(CbOrder::getStatus, ORDER_STATUS_COMPLETED)
                .ge(CbOrder::getCreateTime, todayStart)
                .select(CbOrder::getPayAmount, CbOrder::getPlatformIncome, CbOrder::getTechIncome).list();
        BigDecimal todayRevenue  = sum(todayOrders, CbOrder::getPayAmount);
        BigDecimal todayPlatform = sum(todayOrders, CbOrder::getPlatformIncome);
        BigDecimal todayTech     = sum(todayOrders, CbOrder::getTechIncome);
        BigDecimal todayMerchant = todayRevenue.subtract(todayPlatform).subtract(todayTech);

        Map<String, Object> data = new LinkedHashMap<>();
        data.put("balance",         merchant != null ? merchant.getBalance() : BigDecimal.ZERO);
        data.put("commissionRate",  merchant != null ? merchant.getCommissionRate() : BigDecimal.ZERO);
        data.put("totalRevenue",    totalRevenue);
        data.put("platformFee",     platformFee);
        data.put("techFee",         techFee);
        data.put("merchantRevenue", merchantRevenue);
        data.put("todayRevenue",    todayRevenue);
        data.put("todayMerchant",   todayMerchant);
        data.put("completedOrders", completedOrders.size());
        return data;
    }

    private BigDecimal sum(List<CbOrder> orders, Function<CbOrder, BigDecimal> getter) {
        return orders.stream().map(getter).filter(v -> v != null).reduce(BigDecimal.ZERO, BigDecimal::add);
    }
}
