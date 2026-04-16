package com.cambook.app.service.admin;

import com.cambook.app.domain.dto.AdminLoginDTO;
import com.cambook.app.domain.vo.LoginVO;

/**
 * Admin 端认证服务
 *
 * @author CamBook
 */
public interface IAdminAuthService {

    LoginVO login(AdminLoginDTO dto);

    void logout();
}
