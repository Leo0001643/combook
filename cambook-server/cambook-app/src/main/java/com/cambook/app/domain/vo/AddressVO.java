package com.cambook.app.domain.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.math.BigDecimal;

/**
 * 地址视图
 *
 * @author CamBook
 */
@Data
@Schema(description = "地址信息")
public class AddressVO {

    @Schema(description = "地址 ID")
    private Long id;

    @Schema(description = "标签")
    private String label;

    @Schema(description = "联系人")
    private String contactName;

    @Schema(description = "联系电话（脱敏）")
    private String contactPhone;

    @Schema(description = "详细地址")
    private String detail;

    @Schema(description = "纬度")
    private BigDecimal lat;

    @Schema(description = "经度")
    private BigDecimal lng;

    @Schema(description = "是否默认：1是 0否")
    private Integer isDefault;
}
