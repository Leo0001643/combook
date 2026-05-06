package com.cambook.app.service.app;

import com.cambook.app.domain.dto.TechnicianApplyDTO;
import com.cambook.app.domain.vo.TechnicianVO;
import com.cambook.common.result.PageResult;

/**
 * App 端技师服务
 *
 * @author CamBook
 */
public interface IAppTechnicianService {

    PageResult<TechnicianVO> nearbyList(double lat, double lng, int page, int size);

    TechnicianVO getDetail(Long id);

    void apply(TechnicianApplyDTO dto);

    TechnicianVO getMyProfile();
}
