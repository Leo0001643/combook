package com.cambook.driver.domain.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Data;

/**
 * 司机入驻申请（App）
 *
 * @author CamBook
 */
@Data
@Schema(description = "司机入驻申请")
public class DriverApplyDTO {

    @NotBlank(message = "真实姓名不能为空")
    @Size(min = 2, max = 30, message = "真实姓名2-30字符")
    @Schema(description = "真实姓名")
    private String realName;

    @NotBlank(message = "手机号不能为空")
    @Pattern(regexp = "^\\+?[0-9]{8,15}$", message = "手机号格式不正确")
    @Schema(description = "手机号（含国家区号）")
    private String mobile;

    @NotBlank(message = "证件号不能为空")
    @Pattern(regexp = "^[A-Z0-9]{6,20}$", message = "证件号格式不正确（大写字母+数字，6-20位）")
    @Schema(description = "证件号（护照/身份证）")
    private String idCard;

    @Pattern(regexp = "^https?://.+$", message = "驾照正面图片必须为合法URL")
    @Schema(description = "驾照正面 URL")
    private String drivingLicenseFront;

    @Pattern(regexp = "^https?://.+$", message = "驾照背面图片必须为合法URL")
    @Schema(description = "驾照背面 URL")
    private String drivingLicenseBack;

    @NotBlank(message = "驾照类型不能为空")
    @Pattern(regexp = "^(KH|INT)$", message = "驾照类型不合法：KH或INT")
    @Schema(description = "驾照类型：KH柬埔寨驾照 INT国际驾照")
    private String licenseType;

    @Size(max = 200, message = "备注最多200字符")
    @Schema(description = "备注")
    private String remark;
}
