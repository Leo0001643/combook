package com.cambook.app.service.admin.impl;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.cambook.app.service.admin.IAdminFinanceService;
import com.cambook.common.result.PageResult;
import com.cambook.db.entity.CbWallet;
import com.cambook.db.entity.CbWalletRecord;
import com.cambook.db.service.ICbWalletRecordService;
import com.cambook.db.service.ICbWalletService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.util.HashMap;
import java.util.Map;

/**
 * Admin 财务管理实现
 */
@Service
@RequiredArgsConstructor
public class AdminFinanceService implements IAdminFinanceService {

    private static final int RECORD_TYPE_RECHARGE = 1;
    private static final int RECORD_TYPE_WITHDRAW = 3;

    private final ICbWalletService       cbWalletService;
    private final ICbWalletRecordService cbWalletRecordService;

    @Override
    public Map<String, Object> overview() {
        BigDecimal totalBalance = cbWalletService.list().stream()
                .map(CbWallet::getBalance).filter(b -> b != null).reduce(BigDecimal.ZERO, BigDecimal::add);

        long totalRecords  = cbWalletRecordService.count();
        long rechargeCount = cbWalletRecordService.lambdaQuery().eq(CbWalletRecord::getRecordType, RECORD_TYPE_RECHARGE).count();
        long withdrawCount = cbWalletRecordService.lambdaQuery().eq(CbWalletRecord::getRecordType, RECORD_TYPE_WITHDRAW).count();
        BigDecimal totalRecharge = cbWalletRecordService.lambdaQuery()
                .eq(CbWalletRecord::getRecordType, RECORD_TYPE_RECHARGE).list().stream()
                .map(CbWalletRecord::getAmount).filter(a -> a != null).reduce(BigDecimal.ZERO, BigDecimal::add);

        Map<String, Object> data = new HashMap<>();
        data.put("totalBalance",  totalBalance);
        data.put("totalRecords",  totalRecords);
        data.put("rechargeCount", rechargeCount);
        data.put("withdrawCount", withdrawCount);
        data.put("totalRecharge", totalRecharge);
        return data;
    }

    @Override
    public PageResult<CbWalletRecord> records(int current, int size, Integer recordType) {
        var page = cbWalletRecordService.lambdaQuery()
                .eq(recordType != null, CbWalletRecord::getRecordType, recordType)
                .orderByDesc(CbWalletRecord::getCreateTime).page(new Page<>(current, size));
        return PageResult.of(page);
    }

    @Override
    public PageResult<CbWallet> wallets(int current, int size, Integer userType) {
        var page = cbWalletService.lambdaQuery()
                .eq(userType != null, CbWallet::getUserType, userType)
                .orderByDesc(CbWallet::getBalance).page(new Page<>(current, size));
        return PageResult.of(page);
    }
}
