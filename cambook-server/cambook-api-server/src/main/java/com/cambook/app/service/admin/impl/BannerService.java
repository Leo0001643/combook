package com.cambook.app.service.admin.impl;

import com.cambook.app.domain.dto.BannerDTO;
import com.cambook.app.service.admin.IBannerService;
import com.cambook.common.enums.CbCodeEnum;
import com.cambook.common.exception.BusinessException;
import com.cambook.db.entity.CbBanner;
import com.cambook.db.service.ICbBannerService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;
import com.cambook.common.enums.CommonStatus;

/**
 * Banner 管理服务实现
 *
 * @author CamBook
 */
@Service
@RequiredArgsConstructor
public class BannerService implements IBannerService {

    private final ICbBannerService cbBannerService;

    @Override
    public List<CbBanner> list(String position, Integer status) {
        return cbBannerService.lambdaQuery()
                .eq(position != null && !position.isBlank(), CbBanner::getPosition, position)
                .eq(status != null, CbBanner::getStatus, status)
                .orderByAsc(CbBanner::getSort).list();
    }

    @Override
    public void add(BannerDTO dto) {
        CbBanner banner = new CbBanner();
        banner.setPosition(dto.getPosition());
        banner.setTitleZh(dto.getTitleZh());
        banner.setTitleEn(dto.getTitleEn());
        banner.setTitleVi(dto.getTitleVi());
        banner.setTitleKm(dto.getTitleKm());
        banner.setImageUrl(dto.getImageUrl());
        banner.setLinkType(dto.getLinkType() == null ? null : dto.getLinkType().byteValue());
        banner.setLinkValue(dto.getLinkValue());
        banner.setSort(dto.getSort() != null ? dto.getSort() : 0);
        banner.setStatus(dto.getStatus() != null ? dto.getStatus().byteValue() : CommonStatus.ENABLED.byteCode());
        banner.setStartTime(dto.getStartTime());
        banner.setEndTime(dto.getEndTime());
        cbBannerService.save(banner);
    }

    @Override
    public void edit(BannerDTO dto) {
        CbBanner banner = Optional.ofNullable(cbBannerService.getById(dto.getId()))
                .orElseThrow(() -> new BusinessException(CbCodeEnum.DATA_NOT_FOUND));

        banner.setPosition(dto.getPosition());
        banner.setTitleZh(dto.getTitleZh());
        banner.setTitleEn(dto.getTitleEn());
        banner.setTitleVi(dto.getTitleVi());
        banner.setTitleKm(dto.getTitleKm());
        banner.setImageUrl(dto.getImageUrl());
        banner.setLinkType(dto.getLinkType() == null ? null : dto.getLinkType().byteValue());
        banner.setLinkValue(dto.getLinkValue());
        banner.setSort(dto.getSort());
        banner.setStatus(dto.getStatus() == null ? null : dto.getStatus().byteValue());
        banner.setStartTime(dto.getStartTime());
        banner.setEndTime(dto.getEndTime());
        cbBannerService.updateById(banner);
    }

    @Override
    public void delete(Long id) {
        cbBannerService.removeById(id);
    }
}
