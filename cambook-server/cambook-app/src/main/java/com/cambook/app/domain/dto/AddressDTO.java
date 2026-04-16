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
 * 新增 / 修改地址（App）
 *
 * @author CamBook
 */
@Data
@Schema(description = "地址请求")
public class AddressDTO {

    @Schema(description = "主键（修改时必填）")
    private Long id;

    @Size(max = 10, message = "标签最多10字")
    @Schema(description = "标签，如 家/公司/酒店")
    private String label;

    @NotBlank(message = "联系人不能为空")
    @Size(min = 2, max = 20, message = "联系人姓名2-20字符")
    @Schema(description = "联系人姓名")
    private String contactName;

    @NotBlank(message = "联系电话不能为空")
    @Pattern(regexp = "^\\+?[1-9]\\d{6,14}$", message = "联系电话格式不正确")
    @Schema(description = "联系电话")
    private String contactPhone;

    @NotBlank(message = "详细地址不能为空")
    @Size(min = 5, max = 200, message = "详细地址5-200字符")
    @Schema(description = "详细地址")
    private String detail;

    @DecimalMin(value = "-90.0", message = "纬度范围-90到90")
    @DecimalMax(value = "90.0",  message = "纬度范围-90到90")
    @Schema(description = "纬度", example = "11.5564")
    private BigDecimal lat;

    @DecimalMin(value = "-180.0", message = "经度范围-180到180")
    @DecimalMax(value = "180.0",  message = "经度范围-180到180")
    @Schema(description = "经度", example = "104.9282")
    private BigDecimal lng;

    @Schema(description = "是否设为默认：1是 0否")
    private Integer isDefault;
}
