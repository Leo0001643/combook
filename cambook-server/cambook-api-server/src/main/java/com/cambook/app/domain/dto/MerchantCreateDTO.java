package com.cambook.app.domain.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.*;
import lombok.Data;

import java.math.BigDecimal;

/**
 * 后台新增商户 DTO
 *
 * @author CamBook
 */
@Data
@Schema(description = "新增商户参数")
public class MerchantCreateDTO {

    // ── 基本信息 ────────────────────────────────────────────────────────────
    @NotBlank @Schema(description = "商户中文名称")
    private String merchantNameZh;

    @Schema(description = "商户英文名称")
    private String merchantNameEn;

    @Min(1) @Max(2)
    @Schema(description = "经营类型：1个人 2企业", defaultValue = "1")
    private Integer businessType = 1;

    @Schema(description = "所在城市")
    private String city;

    @Schema(description = "详细地址（中文）")
    private String addressZh;

    @Schema(description = "营业范围描述")
    private String businessScope;

    @Schema(description = "营业面积/规模")
    private String businessArea;

    // ── 营业执照 ────────────────────────────────────────────────────────────
    @Schema(description = "营业执照号码")
    private String businessLicenseNo;

    @Schema(description = "营业执照照片 URL")
    private String businessLicensePic;

    // ── 联系信息 ────────────────────────────────────────────────────────────
    @Schema(description = "联系人姓名")
    private String contactPerson;

    @Schema(description = "联系人手机号")
    private String contactMobile;

    // ── 账号设置 ────────────────────────────────────────────────────────────
    @Pattern(regexp = "^[a-zA-Z0-9]{4,20}$", message = "用户名只允许字母和数字，4-20位")
    @Schema(description = "登录用户名（字母数字，4-20位，可选）")
    private String username;

    @NotBlank @Pattern(regexp = "^\\+?[0-9]{8,20}$", message = "手机号格式不正确")
    @Schema(description = "登录手机号")
    private String mobile;

    @Schema(description = "登录密码（默认 123456）", defaultValue = "123456")
    private String password = "123456";

    @DecimalMin("0") @DecimalMax("100")
    @Schema(description = "平台佣金比例(%)，默认 20", defaultValue = "20")
    private BigDecimal commissionRate = new BigDecimal("20");

    // ── 媒体资料 ────────────────────────────────────────────────────────────
    @Schema(description = "商户 Logo URL")
    private String logo;

    @Schema(description = "商户相册图片 URL 列表（JSON 数组字符串）")
    private String photos;

    @Schema(description = "展示视频 URL")
    private String videoUrl;
}
