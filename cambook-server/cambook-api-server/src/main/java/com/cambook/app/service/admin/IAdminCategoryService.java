package com.cambook.app.service.admin;

import com.cambook.app.domain.dto.CategorySaveDTO;
import com.cambook.db.entity.CbServiceCategory;

import java.util.List;

/**
 * Admin 服务类目管理
 */
public interface IAdminCategoryService {

    List<CbServiceCategory> list(String keyword, Integer status);

    void add(CategorySaveDTO dto);

    void edit(CategorySaveDTO dto);

    void delete(Long id);
}
