package com.cambook.app.service.admin;

import com.cambook.app.domain.dto.TechnicianAuditDTO;
import com.cambook.app.domain.dto.TechnicianCreateDTO;
import com.cambook.app.domain.dto.TechnicianQueryDTO;
import com.cambook.app.domain.dto.TechnicianUpdateDTO;
import com.cambook.app.domain.vo.TechnicianVO;
import com.cambook.common.result.PageResult;

/**
 * Admin 端技师管理服务
 *
 * @author CamBook
 */
public interface IAdminTechnicianService {

    PageResult<TechnicianVO> pageList(TechnicianQueryDTO query);

    TechnicianVO getDetail(Long id);

    TechnicianVO create(TechnicianCreateDTO dto);

    void update(TechnicianUpdateDTO dto);

    void audit(TechnicianAuditDTO dto);

    void updateStatus(Long id, int status);

    void updateOnlineStatus(Long id, int onlineStatus);

    void setFeatured(Long id, int featured);

    void delete(Long id);

    /**
     * 强制技师下线（管理端操作，使该技师所有在线 Token 立即失效）
     *
     * @param techId 技师主键 ID
     */
    void forceLogout(Long techId);
}
