package com.cambook.driver.service.admin;

import com.cambook.driver.domain.dto.DriverAuditDTO;
import com.cambook.driver.domain.dto.DriverQueryDTO;
import com.cambook.driver.domain.vo.DriverVO;
import com.cambook.common.result.PageResult;

/**
 * Admin 端司机管理服务
 *
 * @author CamBook
 */
public interface IAdminDriverService {

    PageResult<DriverVO> pageList(DriverQueryDTO query);

    DriverVO getDetail(Long id);

    void audit(DriverAuditDTO dto);

    /** 绑定司机与车辆 */
    void bindVehicle(Long driverId, Long vehicleId);
}
