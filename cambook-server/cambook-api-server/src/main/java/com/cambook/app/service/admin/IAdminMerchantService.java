package com.cambook.app.service.admin;

import com.cambook.app.domain.dto.MerchantCreateDTO;
import com.cambook.common.result.PageResult;
import com.cambook.db.entity.CbMerchant;

import java.math.BigDecimal;

/**
 * Admin 商户管理服务
 */
public interface IAdminMerchantService {

    CbMerchant create(MerchantCreateDTO dto);

    PageResult<CbMerchant> page(int current, int size, String keyword, String city, Integer status, Integer auditStatus);

    CbMerchant detail(Long id);

    void updateStatus(Long id, Integer status);

    void audit(Long id, Integer auditStatus, String rejectReason);

    void updateCommission(Long id, BigDecimal commissionRate);

    void delete(Long id);
}
