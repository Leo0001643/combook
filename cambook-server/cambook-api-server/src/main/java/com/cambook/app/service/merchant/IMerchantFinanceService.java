package com.cambook.app.service.merchant;

import java.util.Map;

/**
 * 商户端 财务管理
 */
public interface IMerchantFinanceService {

    Map<String, Object> overview(Long merchantId);
}
