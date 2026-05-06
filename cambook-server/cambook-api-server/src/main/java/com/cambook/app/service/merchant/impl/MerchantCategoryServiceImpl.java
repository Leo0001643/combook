package com.cambook.app.service.merchant.impl;

import com.cambook.app.domain.dto.CategorySaveDTO;
import com.cambook.app.service.merchant.IMerchantCategoryService;
import com.cambook.common.enums.CbCodeEnum;
import com.cambook.common.exception.BusinessException;
import com.cambook.db.entity.CbServiceCategory;
import com.cambook.db.service.ICbServiceCategoryService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.Comparator;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;
import java.util.Optional;
import com.cambook.common.enums.CommonStatus;

/**
 * 商户端 服务类目管理实现（写时复制模式）
 */
@Service
@RequiredArgsConstructor
public class MerchantCategoryServiceImpl implements IMerchantCategoryService {

    private final ICbServiceCategoryService cbServiceCategoryService;

    @Override
    public List<CbServiceCategory> list(Long merchantId, String keyword, Integer status) {
        int displayStatus = status != null ? status : 1;

        List<CbServiceCategory> allPrivate = cbServiceCategoryService.lambdaQuery()
                .eq(CbServiceCategory::getMerchantId, merchantId).orderByAsc(CbServiceCategory::getSort).list();
        Set<Long> overriddenIds = allPrivate.stream()
                .filter(c -> c.getSourceCategoryId() != null).map(CbServiceCategory::getSourceCategoryId).collect(Collectors.toSet());

        List<CbServiceCategory> privateList = allPrivate.stream()
                .filter(c -> c.getStatus() != null && c.getStatus() == displayStatus)
                .filter(c -> keyword == null || keyword.isBlank() || (c.getNameZh() != null && c.getNameZh().contains(keyword)))
                .collect(Collectors.toList());

        List<CbServiceCategory> platformList = cbServiceCategoryService.lambdaQuery()
                .isNull(CbServiceCategory::getMerchantId)
                .eq(CbServiceCategory::getStatus, displayStatus)
                .like(keyword != null && !keyword.isBlank(), CbServiceCategory::getNameZh, keyword)
                .orderByAsc(CbServiceCategory::getSort).list();

        platformList.removeIf(c -> overriddenIds.contains(c.getId()));
        platformList.addAll(privateList);
        platformList.sort(Comparator.comparingInt((CbServiceCategory c) -> c.getSort() != null ? c.getSort() : 0).thenComparingLong(CbServiceCategory::getId));
        return platformList;
    }

    @Override
    public void add(Long merchantId, CategorySaveDTO dto) {
        CbServiceCategory cat = new CbServiceCategory();
        cat.setMerchantId(merchantId);
        cat.setParentId(dto.getParentId() != null ? dto.getParentId() : 0L);
        cat.setNameZh(dto.getNameZh()); cat.setNameEn(dto.getNameEn()); cat.setNameVi(dto.getNameVi());
        cat.setNameKm(dto.getNameKm()); cat.setNameJa(dto.getNameJa()); cat.setNameKo(dto.getNameKo());
        cat.setIcon(dto.getIcon()); cat.setPrice(dto.getPrice()); cat.setDuration(dto.getDuration());
        cat.setIsSpecial(dto.getIsSpecial() != null && dto.getIsSpecial() != 0);
        cat.setSort(dto.getSort() != null ? dto.getSort() : 0);
        cat.setStatus(dto.getStatus() != null ? dto.getStatus().byteValue() : CommonStatus.ENABLED.byteCode());
        cbServiceCategoryService.save(cat);
    }

    @Override
    public void edit(Long merchantId, Long id, CategorySaveDTO dto) {
        CbServiceCategory cat = Optional.ofNullable(cbServiceCategoryService.getById(id)).orElseThrow(() -> new BusinessException(CbCodeEnum.DATA_NOT_FOUND));

        if (cat.getMerchantId() == null) {
            // 平台类目 → 写时复制
            CbServiceCategory existing = cbServiceCategoryService.lambdaQuery()
                    .eq(CbServiceCategory::getMerchantId, merchantId).eq(CbServiceCategory::getSourceCategoryId, id).one();
            if (existing != null) {
                cat = existing;
            } else {
                CbServiceCategory copy = copyFrom(cat, merchantId, id);
                applyFields(copy, dto); cbServiceCategoryService.save(copy); return;
            }
        } else if (!merchantId.equals(cat.getMerchantId())) {
            throw new BusinessException(CbCodeEnum.NO_PERMISSION);
        }
        applyFields(cat, dto);
        cbServiceCategoryService.updateById(cat);
    }

    @Override
    public void delete(Long merchantId, Long id) {
        CbServiceCategory cat = Optional.ofNullable(cbServiceCategoryService.getById(id)).orElseThrow(() -> new BusinessException(CbCodeEnum.DATA_NOT_FOUND));

        if (cat.getMerchantId() == null) {
            CbServiceCategory existing = cbServiceCategoryService.lambdaQuery()
                    .eq(CbServiceCategory::getMerchantId, merchantId).eq(CbServiceCategory::getSourceCategoryId, id).one();
            if (existing != null) { cbServiceCategoryService.removeById(existing.getId()); }
            else {
                CbServiceCategory tombstone = copyFrom(cat, merchantId, id);
                tombstone.setStatus(CommonStatus.DISABLED.byteCode()); cbServiceCategoryService.save(tombstone);
            }
            return;
        }
        if (!merchantId.equals(cat.getMerchantId())) throw new BusinessException(CbCodeEnum.NO_PERMISSION);
        cbServiceCategoryService.removeById(id);
    }

    private CbServiceCategory copyFrom(CbServiceCategory src, Long merchantId, Long sourceId) {
        CbServiceCategory copy = new CbServiceCategory();
        copy.setMerchantId(merchantId); copy.setSourceCategoryId(sourceId);
        copy.setParentId(src.getParentId()); copy.setNameZh(src.getNameZh()); copy.setNameEn(src.getNameEn());
        copy.setNameVi(src.getNameVi()); copy.setNameKm(src.getNameKm()); copy.setNameJa(src.getNameJa()); copy.setNameKo(src.getNameKo());
        copy.setIcon(src.getIcon()); copy.setPrice(src.getPrice()); copy.setDuration(src.getDuration());
        copy.setIsSpecial(src.getIsSpecial()); copy.setSort(src.getSort()); copy.setStatus(src.getStatus());
        return copy;
    }

    private void applyFields(CbServiceCategory cat, CategorySaveDTO dto) {
        if (dto.getNameZh()    != null) cat.setNameZh(dto.getNameZh());
        if (dto.getNameEn()    != null) cat.setNameEn(dto.getNameEn());
        if (dto.getNameVi()    != null) cat.setNameVi(dto.getNameVi());
        if (dto.getNameKm()    != null) cat.setNameKm(dto.getNameKm());
        if (dto.getNameJa()    != null) cat.setNameJa(dto.getNameJa());
        if (dto.getNameKo()    != null) cat.setNameKo(dto.getNameKo());
        if (dto.getIcon()      != null) cat.setIcon(dto.getIcon());
        if (dto.getPrice()     != null) cat.setPrice(dto.getPrice());
        if (dto.getDuration()  != null) cat.setDuration(dto.getDuration());
        if (dto.getIsSpecial() != null) cat.setIsSpecial(dto.getIsSpecial() != 0);
        if (dto.getSort()      != null) cat.setSort(dto.getSort());
        if (dto.getStatus()    != null) cat.setStatus(dto.getStatus().byteValue());
    }
}
