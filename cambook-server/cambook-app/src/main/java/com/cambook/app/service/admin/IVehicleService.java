package com.cambook.app.service.admin;

import com.baomidou.mybatisplus.core.metadata.IPage;
import com.cambook.app.domain.dto.VehicleDTO;
import com.cambook.app.domain.vo.VehicleVO;
import com.cambook.dao.entity.CbVehicle;

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

    /** 编辑 */
    void edit(VehicleDTO dto);

    /** 删除（逻辑删除） */
    void delete(Long id);

    /** 修改状态 */
    void updateStatus(Long id, Integer status);

    /** 按 ID 查询实体（供商户控制器做归属校验，不存在则抛异常） */
    CbVehicle getById(Long id);
}
