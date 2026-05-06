package com.cambook.app.service.admin;

import com.cambook.common.result.PageResult;
import com.cambook.db.entity.CbWallet;
import com.cambook.db.entity.CbWalletRecord;

import java.util.Map;

/**
 * Admin 财务管理
 */
public interface IAdminFinanceService {

    Map<String, Object> overview();

    PageResult<CbWalletRecord> records(int current, int size, Integer recordType);

    PageResult<CbWallet> wallets(int current, int size, Integer userType);
}
