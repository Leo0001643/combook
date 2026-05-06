package com.cambook.app.service.merchant;

import com.cambook.app.domain.dto.StaffSaveDTO;
import com.cambook.common.result.PageResult;
import com.cambook.db.entity.CbMerchantStaff;

/**
 * 商户端 员工管理
 */
public interface IMerchantStaffService {

    PageResult<CbMerchantStaff> list(Long merchantId, int page, int size, String keyword, Integer status, Long deptId, Long positionId);

    void add(Long merchantId, StaffSaveDTO dto);

    void edit(Long merchantId, StaffSaveDTO dto);

    void updateStatus(Long merchantId, Long id, Integer status);

    void delete(Long merchantId, Long id);
}
