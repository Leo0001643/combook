package com.cambook.app.service.merchant;

import com.cambook.app.domain.dto.CategorySaveDTO;
import com.cambook.db.entity.CbServiceCategory;

import java.util.List;

/**
 * 商户端 服务类目管理（写时复制模式）
 */
public interface IMerchantCategoryService {

    List<CbServiceCategory> list(Long merchantId, String keyword, Integer status);

    void add(Long merchantId, CategorySaveDTO dto);

    void edit(Long merchantId, Long id, CategorySaveDTO dto);

    void delete(Long merchantId, Long id);
}
