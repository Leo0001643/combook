package com.cambook.app.domain.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Data;

import java.math.BigDecimal;

/**
 * 商户入驻申请（App/H5）
 *
 * @author CamBook
 */
@Data
@Schema(description = "商户入驻申请")
public class MerchantApplyDTO {

    @NotBlank(message = "商户名称不能为空")
    @Size(min = 2, max = 100, message = "商户名称2-100字符")
    @Schema(description = "商户名称（中文）")
    private String merchantNameZh;

    @Size(max = 100, message = "英文名称最多100字符")
    @Schema(description = "商户名称（英文）")
    private String merchantNameEn;

    @NotBlank(message = "联系人不能为空")
    @Size(min = 2, max = 20, message = "联系人2-20字符")
    @Schema(description = "联系人")
    private String contactPerson;

    @NotBlank(message = "联系手机号不能为空")
    @Pattern(regexp = "^\\+?[1-9]\\d{6,14}$", message = "联系手机号格式不正确")
    @Schema(description = "联系手机号")
    private String contactMobile;

    @NotBlank(message = "城市不能为空")
    @Schema(description = "城市")
    private String city;

    @NotBlank(message = "地址不能为空")
    @Size(min = 5, max = 300, message = "地址5-300字符")
    @Schema(description = "详细地址（中文）")
    private String addressZh;

    @DecimalMin(value = "-90.0", message = "纬度范围-90到90")
    @DecimalMax(value = "90.0",  message = "纬度范围-90到90")
    @Schema(description = "纬度")
    private BigDecimal lat;

    @DecimalMin(value = "-180.0", message = "经度范围-180到180")
    @DecimalMax(value = "180.0",  message = "经度范围-180到180")
    @Schema(description = "经度")
    private BigDecimal lng;

    @Schema(description = "营业时间配置（JSON）")
    private String businessHours;
}
