package com.cambook.app.domain.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.*;
import lombok.Data;

/**
 * 后台新增技师 DTO
 *
 * @author CamBook
 */
@Data
@Schema(description = "新增技师参数")
public class TechnicianCreateDTO {

    /**
     * 归属商户 ID（内部字段，不接受外部绑定）：
     * Admin 控制器可显式设置；Merchant 控制器强制注入 JWT 中的 merchantId。
     */
    @Schema(hidden = true)
    @com.fasterxml.jackson.annotation.JsonIgnore
    private Long merchantId;

    @NotBlank @Schema(description = "真实姓名")
    private String realName;

    @Schema(description = "昵称（展示名）")
    private String nickname;

    @NotBlank @Pattern(regexp = "^\\+?[0-9]{8,20}$", message = "手机号格式不正确")
    @Schema(description = "登录手机号")
    private String mobile;

    @Schema(description = "登录密码（明文，后台会加密存储）", defaultValue = "123456")
    private String password = "123456";

    @Min(1) @Max(2)
    @Schema(description = "性别：1男 2女", defaultValue = "1")
    private Integer gender = 1;

    @Schema(description = "国籍")
    private String nationality;

    @Schema(description = "服务城市")
    private String serviceCity;

    @Schema(description = "常用语言：zh/en/vi/km", defaultValue = "zh")
    private String lang = "zh";

    @Schema(description = "中文简介")
    private String introZh;

    @Schema(description = "头像 URL（通过 /admin/upload/image 上传后填入）")
    private String avatar;

    @Schema(description = "相册图片 URL 列表（JSON 数组字符串）")
    private String photos;

    @Schema(description = "展示视频 URL")
    private String videoUrl;

    @Schema(description = "技能标签（逗号分隔字符串，如 按摩,正骨；后台自动转 JSON 数组）")
    private String skillTags;

    @DecimalMin("0") @DecimalMax("100")
    @Schema(description = "分成比例(%)，默认 70", defaultValue = "70")
    private java.math.BigDecimal commissionRate = new java.math.BigDecimal("70");

    @Schema(description = "身高（cm）")
    private Integer height;

    @Schema(description = "体重（kg）")
    private java.math.BigDecimal weight;

    @Min(16) @Max(60)
    @Schema(description = "年龄")
    private Integer age;

    @Schema(description = "罩杯（A/B/C/D/E/F/G）")
    private String bust;

    @Schema(description = "所在省份")
    private String province;
}
