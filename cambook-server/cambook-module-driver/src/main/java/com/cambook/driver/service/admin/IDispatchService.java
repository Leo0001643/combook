package com.cambook.driver.service.admin;

import com.cambook.driver.domain.dto.DispatchDTO;
import com.cambook.driver.domain.dto.DispatchQueryDTO;
import com.cambook.driver.domain.vo.DispatchVO;
import com.cambook.common.result.PageResult;

/**
 * 派车单管理服务
 *
 * @author CamBook
 */
public interface IDispatchService {

    /** 创建派车单（可手动指定司机，也可自动分配） */
    DispatchVO create(DispatchDTO dto);

    PageResult<DispatchVO> pageList(DispatchQueryDTO query);

    DispatchVO getDetail(Long id);

    /** 手动分配司机（派车单已存在，重新指派） */
    void assignDriver(Long dispatchId, Long driverId);

    /** 更新派车单状态（司机操作：接单/到达/完成等） */
    void updateStatus(Long dispatchId, Integer status);

    /** 取消派车单 */
    void cancel(Long dispatchId, String reason);
}
