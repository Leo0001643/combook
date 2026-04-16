package com.cambook.app.service.admin;

import com.baomidou.mybatisplus.core.metadata.IPage;
import com.cambook.app.domain.dto.StaffDTO;
import com.cambook.app.domain.vo.StaffVO;

/**
 * 员工（后台账号）管理服务
 *
 * @author CamBook
 */
public interface IStaffService {

    IPage<StaffVO> page(int current, int size, String keyword, Integer status, Long positionId);

    void add(StaffDTO dto);

    void edit(StaffDTO dto);

    void delete(Long id);

    void updateStatus(Long id, Integer status);

    void assignRoles(Long userId, java.util.List<Long> roleIds);
}
