package com.cambook.app.service.admin;

import com.cambook.app.domain.dto.BannerDTO;

/**
 * Banner 管理服务
 *
 * @author CamBook
 */
public interface IBannerService {

    void add(BannerDTO dto);

    void edit(BannerDTO dto);

    void delete(Long id);
}
