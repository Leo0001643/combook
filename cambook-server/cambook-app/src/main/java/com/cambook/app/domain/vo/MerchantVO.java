package com.cambook.app.domain.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.math.BigDecimal;

/**
 * 商户信息视图
 *
 * @author CamBook
 */
@Data
@Schema(description = "商户信息")
public class MerchantVO {

    @Schema(description = "商户 ID")
    private Long id;

    @Schema(description = "商户编号")
    private String merchantNo;

    @Schema(description = "商户名称（中文）")
    private String merchantNameZh;

    @Schema(description = "商户名称（英文）")
    private String merchantNameEn;

    @Schema(description = "Logo URL")
    private String logoUrl;

    @Schema(description = "联系人")
    private String contactPerson;

    @Schema(description = "联系手机")
    private String contactMobile;

    @Schema(description = "城市")
    private String city;

    @Schema(description = "地址（中文）")
    private String addressZh;

    @Schema(description = "纬度")
    private BigDecimal lat;

    @Schema(description = "经度")
    private BigDecimal lng;

    @Schema(description = "综合评分")
    private BigDecimal rating;

    @Schema(description = "营业时间（JSON）")
    private String businessHours;

    @Schema(description = "审核状态：0待审 1通过 2拒绝")
    private Integer auditStatus;

    @Schema(description = "状态：1正常 2停用")
    private Integer status;
}
