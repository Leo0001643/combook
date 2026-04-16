package com.cambook.app.domain.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.util.List;

/**
 * 登录成功响应
 *
 * @author CamBook
 */
@Data
@Schema(description = "登录响应")
public class LoginVO {

    @Schema(description = "JWT Token")
    private String token;

    @Schema(description = "Token 过期时间（Unix 秒）")
    private long expiresAt;

    @Schema(description = "用户类型：member / technician / merchant / admin")
    private String userType;

    @Schema(description = "用户 ID")
    private Long userId;

    @Schema(description = "是否首次登录")
    private boolean firstLogin;

    @Schema(description = "权限码列表（Admin 端返回，用于前端菜单过滤）")
    private List<String> permissions;

    @Schema(description = "商户名称（商户端返回）")
    private String merchantName;

    @Schema(description = "商户 Logo URL（商户端返回）")
    private String merchantLogo;

    @Schema(description = "商户手机号（商户端返回）")
    private String merchantMobile;

    @Schema(description = "员工真实姓名（员工账号登录时返回，用于欢迎词显示）")
    private String staffName;

    @Schema(description = "是否为员工账号登录（true=员工，false=商户主）")
    private boolean staff;

    public static LoginVO of(String token, long expiresAt, String userType, Long userId, boolean firstLogin) {
        LoginVO vo = new LoginVO();
        vo.setToken(token);
        vo.setExpiresAt(expiresAt);
        vo.setUserType(userType);
        vo.setUserId(userId);
        vo.setFirstLogin(firstLogin);
        return vo;
    }

    public static LoginVO of(String token, long expiresAt, String userType, Long userId,
                              boolean firstLogin, List<String> permissions) {
        LoginVO vo = of(token, expiresAt, userType, userId, firstLogin);
        vo.setPermissions(permissions);
        return vo;
    }
}
