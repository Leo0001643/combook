package com.cambook.driver.service.admin;

import com.cambook.driver.domain.dto.VehicleDTO;
import com.cambook.driver.domain.vo.VehicleVO;
import com.cambook.common.result.PageResult;

import java.util.List;

/**
 * 车辆管理服务
 *
 * @author CamBook
 */
public interface IVehicleService {

    List<VehicleVO> listAll();

    void add(VehicleDTO dto);

    void edit(VehicleDTO dto);

    void delete(Long id);

    /** 查询空闲车辆（用于派单选择） */
    List<VehicleVO> listIdle();
}
