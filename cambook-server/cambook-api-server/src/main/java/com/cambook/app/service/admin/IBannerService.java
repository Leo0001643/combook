package com.cambook.app.service.admin;

import com.cambook.app.domain.dto.BannerDTO;
import com.cambook.db.entity.CbBanner;

import java.util.List;

/**
 * Banner 管理服务
 */
public interface IBannerService {

    List<CbBanner> list(String position, Integer status);

    void add(BannerDTO dto);

    void edit(BannerDTO dto);

    void delete(Long id);
}
