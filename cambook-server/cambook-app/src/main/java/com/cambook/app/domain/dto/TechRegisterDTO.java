package com.cambook.app.domain.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Data;

/**
 * 技师端注册请求
 *
 * <p>注册校验规则：
 * <ol>
 *   <li>商户编号（merchantNo）必须对应真实且正常营业的商户</li>
 *   <li>手机号在技师表中必须唯一</li>
 *   <li>注册成功后账号进入待审核状态，审核通过方可登录</li>
 * </ol>
 *
 * @author CamBook
 */
@Data
@Schema(description = "技师端注册请求")
public class TechRegisterDTO {

    @NotBlank(message = "{tech.register.merchantNo.required}")
    @Schema(description = "所属商户编号，用于校验合法性", example = "M20240001")
    private String merchantNo;

    @NotBlank(message = "{tech.register.mobile.required}")
    @Pattern(regexp = "^\\+?[1-9]\\d{6,14}$", message = "{tech.register.mobile.invalid}")
    @Schema(description = "手机号（国际格式）", example = "+85512345678")
    private String mobile;

    @NotBlank(message = "{tech.register.password.required}")
    @Size(min = 6, max = 20, message = "{tech.register.password.size}")
    @Schema(description = "登录密码（6-20位）", example = "Abc12345")
    private String password;

    @NotBlank(message = "{tech.register.realName.required}")
    @Size(max = 50, message = "{tech.register.realName.size}")
    @Schema(description = "真实姓名（与证件一致）", example = "张三")
    private String realName;

    @Schema(description = "昵称（展示用）", example = "小张")
    private String nickname;

    @Schema(description = "语言偏好（zh/en/vi/km/ko/ja），默认 zh", example = "zh")
    private String lang;
}
