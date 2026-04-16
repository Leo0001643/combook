package com.cambook.app.service.app;

import com.cambook.app.domain.dto.LoginDTO;
import com.cambook.app.domain.vo.LoginVO;

/**
 * App 端认证服务
 *
 * @author CamBook
 */
public interface IAuthService {

    /**
     * 发送短信验证码
     */
    void sendSms(String mobile);

    /**
     * 短信验证码登录（自动注册）
     */
    LoginVO login(LoginDTO dto);
}
