package com.cambook.app.service.admin.impl;

import com.cambook.app.domain.dto.BannerDTO;
import com.cambook.app.service.admin.IBannerService;
import com.cambook.common.enums.CbCodeEnum;
import com.cambook.common.exception.BusinessException;
import com.cambook.dao.entity.CbBanner;
import com.cambook.dao.mapper.CbBannerMapper;
import org.springframework.stereotype.Service;

/**
 * Banner 管理服务实现
 *
 * @author CamBook
 */
@Service
public class BannerService implements IBannerService {

    private final CbBannerMapper bannerMapper;

    public BannerService(CbBannerMapper bannerMapper) {
        this.bannerMapper = bannerMapper;
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
        banner.setLinkType(dto.getLinkType());
        banner.setLinkValue(dto.getLinkValue());
        banner.setSort(dto.getSort() != null ? dto.getSort() : 0);
        banner.setStatus(dto.getStatus() != null ? dto.getStatus() : 1);
        banner.setStartTime(dto.getStartTime());
        banner.setEndTime(dto.getEndTime());
        bannerMapper.insert(banner);
    }

    @Override
    public void edit(BannerDTO dto) {
        CbBanner banner = bannerMapper.selectById(dto.getId());
        if (banner == null) throw new BusinessException(CbCodeEnum.DATA_NOT_FOUND);

        banner.setPosition(dto.getPosition());
        banner.setTitleZh(dto.getTitleZh());
        banner.setTitleEn(dto.getTitleEn());
        banner.setTitleVi(dto.getTitleVi());
        banner.setTitleKm(dto.getTitleKm());
        banner.setImageUrl(dto.getImageUrl());
        banner.setLinkType(dto.getLinkType());
        banner.setLinkValue(dto.getLinkValue());
        banner.setSort(dto.getSort());
        banner.setStatus(dto.getStatus());
        banner.setStartTime(dto.getStartTime());
        banner.setEndTime(dto.getEndTime());
        bannerMapper.updateById(banner);
    }

    @Override
    public void delete(Long id) {
        bannerMapper.deleteById(id);
    }
}
