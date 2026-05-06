package com.cambook.app.service.merchant;

import com.cambook.app.domain.dto.BannerDTO;
import com.cambook.db.entity.CbBanner;

import java.util.List;

/**
 * 商户端轮播图服务
 */
public interface IMerchantBannerService {

    List<CbBanner> list(Long merchantId, Integer status);

    void add(Long merchantId, BannerDTO dto);

    void edit(Long merchantId, BannerDTO dto);

    void delete(Long merchantId, Long id);

    void updateStatus(Long merchantId, Long id, Integer status);
}
