package com.cambook.driver.service.app;

import com.cambook.driver.domain.dto.DispatchDTO;
import com.cambook.driver.domain.dto.DriverApplyDTO;
import com.cambook.driver.domain.vo.DispatchVO;
import com.cambook.driver.domain.vo.DriverVO;

import java.util.List;

/**
 * App 端司机服务（司机自助端）
 *
 * @author CamBook
 */
public interface IAppDriverService {

    /** 申请成为司机 */
    void apply(DriverApplyDTO dto);

    /** 获取我的司机资料 */
    DriverVO getMyProfile();

    /** 更新在线状态 */
    void updateOnlineStatus(Integer status);

    /** 获取待接派车单列表 */
    List<DispatchVO> getPendingDispatches();

    /** 接单 */
    void acceptDispatch(Long dispatchId);

    /** 更新位置 */
    void updateLocation(Double lat, Double lng);
}
