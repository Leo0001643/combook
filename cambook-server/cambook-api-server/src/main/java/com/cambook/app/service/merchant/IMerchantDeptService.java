package com.cambook.app.service.merchant;

import com.cambook.app.domain.dto.DeptSaveDTO;
import com.cambook.db.entity.SysDept;

import java.util.List;

/**
 * 商户端 部门管理
 */
public interface IMerchantDeptService {

    List<SysDept> list(Long merchantId, String name, Integer status);

    void add(Long merchantId, DeptSaveDTO dto);

    void edit(Long merchantId, DeptSaveDTO dto);

    void delete(Long merchantId, Long id);

    void updateStatus(Long merchantId, Long id, Integer status);
}
