package com.cambook.app.service.merchant.impl;

import com.cambook.app.common.security.MerchantOwnershipGuard;
import com.cambook.app.domain.dto.BannerDTO;
import com.cambook.app.service.merchant.IMerchantBannerService;
import com.cambook.common.exception.BusinessException;
import com.cambook.db.entity.CbBanner;
import com.cambook.db.service.ICbBannerService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;
import com.cambook.common.enums.CommonStatus;

/**
 * 商户端轮播图服务实现
 */
@Service
@RequiredArgsConstructor
public class MerchantBannerServiceImpl implements IMerchantBannerService {

    private static final String DEFAULT_POSITION = "merchant_home";

    private final ICbBannerService cbBannerService;

    @Override
    public List<CbBanner> list(Long merchantId, Integer status) {
        return cbBannerService.lambdaQuery()
                .eq(CbBanner::getMerchantId, merchantId).eq(status != null, CbBanner::getStatus, status)
                .orderByAsc(CbBanner::getSort).list();
    }

    @Override
    public void add(Long merchantId, BannerDTO dto) {
        CbBanner banner = new CbBanner();
        banner.setMerchantId(merchantId);
        banner.setPosition(dto.getPosition() != null ? dto.getPosition() : DEFAULT_POSITION);
        banner.setTitleZh(dto.getTitleZh()); banner.setTitleEn(dto.getTitleEn()); banner.setImageUrl(dto.getImageUrl());
        banner.setLinkType(dto.getLinkType() != null ? dto.getLinkType().byteValue() : (byte) 0);
        banner.setLinkValue(dto.getLinkValue()); banner.setSort(dto.getSort() != null ? dto.getSort() : 0);
        banner.setStatus(dto.getStatus() != null ? dto.getStatus().byteValue() : CommonStatus.ENABLED.byteCode());
        banner.setStartTime(dto.getStartTime()); banner.setEndTime(dto.getEndTime());
        cbBannerService.save(banner);
    }

    @Override
    public void edit(Long merchantId, BannerDTO dto) {
        CbBanner banner = Optional.ofNullable(cbBannerService.getById(dto.getId())).orElseThrow(() -> new BusinessException("轮播图不存在"));
        MerchantOwnershipGuard.assertOwnership(banner.getMerchantId(), "轮播图", dto.getId());
        banner.setTitleZh(dto.getTitleZh()); banner.setTitleEn(dto.getTitleEn()); banner.setImageUrl(dto.getImageUrl());
        banner.setLinkType(dto.getLinkType() == null ? null : dto.getLinkType().byteValue());
        banner.setLinkValue(dto.getLinkValue());
        if (dto.getSort()   != null) banner.setSort(dto.getSort());
        if (dto.getStatus() != null) banner.setStatus(dto.getStatus().byteValue());
        banner.setStartTime(dto.getStartTime()); banner.setEndTime(dto.getEndTime());
        cbBannerService.updateById(banner);
    }

    @Override
    public void delete(Long merchantId, Long id) {
        CbBanner banner = Optional.ofNullable(cbBannerService.getById(id)).orElseThrow(() -> new BusinessException("轮播图不存在"));
        MerchantOwnershipGuard.assertOwnership(banner.getMerchantId(), "轮播图", id);
        cbBannerService.removeById(id);
    }

    @Override
    public void updateStatus(Long merchantId, Long id, Integer status) {
        CbBanner banner = Optional.ofNullable(cbBannerService.getById(id)).orElseThrow(() -> new BusinessException("轮播图不存在"));
        MerchantOwnershipGuard.assertOwnership(banner.getMerchantId(), "轮播图", id);
        banner.setStatus(status != null ? status.byteValue() : null);
        cbBannerService.updateById(banner);
    }
}
