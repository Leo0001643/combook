package com.cambook.app.service.merchant;

import com.cambook.app.domain.dto.PositionDTO;
import com.cambook.app.domain.vo.PositionVO;

import java.util.List;

/**
 * 商户端职位服务
 */
public interface IMerchantPositionService {

    List<PositionVO> list(Long merchantId);

    void add(Long merchantId, PositionDTO dto);

    void edit(Long merchantId, PositionDTO dto);

    void delete(Long merchantId, Long id);

    void updateStatus(Long merchantId, Long id, Integer status);
}
