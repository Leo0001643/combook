package com.cambook.app.service.admin.impl;

import com.cambook.app.domain.dto.CategorySaveDTO;
import com.cambook.app.service.admin.IAdminCategoryService;
import com.cambook.common.enums.CbCodeEnum;
import com.cambook.common.exception.BusinessException;
import com.cambook.db.entity.CbServiceCategory;
import com.cambook.db.service.ICbServiceCategoryService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;
import com.cambook.common.enums.CommonStatus;

/**
 * Admin 服务类目管理实现
 */
@Service
@RequiredArgsConstructor
public class AdminCategoryService implements IAdminCategoryService {

    private final ICbServiceCategoryService cbServiceCategoryService;

    @Override
    public List<CbServiceCategory> list(String keyword, Integer status) {
        return cbServiceCategoryService.lambdaQuery()
                .like(keyword != null && !keyword.isBlank(), CbServiceCategory::getNameZh, keyword)
                .eq(status != null, CbServiceCategory::getStatus, status)
                .orderByAsc(CbServiceCategory::getSort).list();
    }

    @Override
    public void add(CategorySaveDTO dto) {
        CbServiceCategory cat = new CbServiceCategory();
        cat.setParentId(dto.getParentId() != null ? dto.getParentId() : 0L);
        cat.setNameZh(dto.getNameZh());     cat.setNameEn(dto.getNameEn());
        cat.setNameVi(dto.getNameVi());     cat.setNameKm(dto.getNameKm());
        cat.setNameJa(dto.getNameJa());     cat.setNameKo(dto.getNameKo());
        cat.setIcon(dto.getIcon());         cat.setPrice(dto.getPrice());
        cat.setDuration(dto.getDuration()); cat.setSort(dto.getSort() != null ? dto.getSort() : 0);
        cat.setIsSpecial(dto.getIsSpecial() != null && dto.getIsSpecial() != 0);
        cat.setStatus(CommonStatus.ENABLED.byteCode());
        cbServiceCategoryService.save(cat);
    }

    @Override
    public void edit(CategorySaveDTO dto) {
        CbServiceCategory cat = Optional.ofNullable(cbServiceCategoryService.getById(dto.getId())).orElseThrow(() -> new BusinessException(CbCodeEnum.DATA_NOT_FOUND));
        cat.setNameZh(dto.getNameZh());
        cat.setNameEn(dto.getNameEn());
        cat.setNameVi(dto.getNameVi());
        cat.setNameKm(dto.getNameKm());
        cat.setNameJa(dto.getNameJa());
        cat.setNameKo(dto.getNameKo());
        cat.setIcon(dto.getIcon());
        if (dto.getPrice()    != null) cat.setPrice(dto.getPrice());
        if (dto.getDuration() != null) cat.setDuration(dto.getDuration());
        if (dto.getIsSpecial() != null) cat.setIsSpecial(dto.getIsSpecial() != 0);
        cat.setSort(dto.getSort() != null ? dto.getSort() : 0);
        if (dto.getStatus() != null) cat.setStatus(dto.getStatus().byteValue());
        cbServiceCategoryService.updateById(cat);
    }

    @Override
    public void delete(Long id) {
        long children = cbServiceCategoryService.lambdaQuery().eq(CbServiceCategory::getParentId, id).count();
        if (children > 0) throw new BusinessException(CbCodeEnum.CATEGORY_HAS_CHILDREN);
        cbServiceCategoryService.removeById(id);
    }
}
