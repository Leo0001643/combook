package com.cambook.app.domain.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Data;

/**
 * 技师入驻申请（App）
 *
 * @author CamBook
 */
@Data
@Schema(description = "技师入驻申请")
public class TechnicianApplyDTO {

    @NotBlank(message = "真实姓名不能为空")
    @Size(min = 2, max = 20, message = "真实姓名2-20个字符")
    @Schema(description = "真实姓名")
    private String realName;

    @Pattern(regexp = "^[A-Z0-9]{6,20}$", message = "证件号格式不正确")
    @Schema(description = "证件号（护照/身份证）")
    private String idCard;

    @Pattern(regexp = "^https?://.+$", message = "证件正面图片必须为合法URL")
    @Schema(description = "证件正面照 URL")
    private String idCardFront;

    @Pattern(regexp = "^https?://.+$", message = "证件背面图片必须为合法URL")
    @Schema(description = "证件背面照 URL")
    private String idCardBack;

    @Schema(description = "技能标签 ID 列表（JSON 数组）", example = "[1,2,3]")
    private String skillTags;

    @Size(max = 500, message = "简介最多500字")
    @Schema(description = "个人简介")
    private String intro;

    @Schema(description = "所在城市")
    private String serviceCity;
}
