package com.cambook.app.service.admin;

import com.baomidou.mybatisplus.core.metadata.IPage;
import com.cambook.app.domain.dto.VehicleDTO;
import com.cambook.app.domain.vo.VehicleVO;
import com.cambook.db.entity.CbVehicle;

/**
 * 车辆管理 Service 接口
 *
 * @author CamBook
 */
public interface IVehicleService {

    /** 分页查询（merchantId=null时查全量，非null时仅该商户） */
    IPage<VehicleVO> page(int current, int size, String keyword, Integer status, Long merchantId);

    /** 新增 */
    void add(VehicleDTO dto);

    /** 编辑（管理端，不校验归属） */
    void edit(VehicleDTO dto);

    /** 编辑（商户端，校验数据归属） */
    void edit(VehicleDTO dto, Long merchantId);

    /** 删除（逻辑删除，管理端） */
    void delete(Long id);

    /** 删除（逻辑删除，商户端，校验数据归属） */
    void delete(Long id, Long merchantId);

    /** 修改状态（管理端） */
    void updateStatus(Long id, Integer status);

    /** 修改状态（商户端，校验数据归属） */
    void updateStatus(Long id, Integer status, Long merchantId);
}
