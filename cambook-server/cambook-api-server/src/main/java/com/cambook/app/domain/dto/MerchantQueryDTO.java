package com.cambook.app.domain.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import lombok.Data;

/**
 * 商户列表查询（Admin）
 *
 * @author CamBook
 */
@Data
@Schema(description = "商户查询条件")
public class MerchantQueryDTO {

    @Schema(description = "商户名称（模糊）")
    private String merchantName;

    @Schema(description = "城市")
    private String city;

    @Min(value = 0) @Max(value = 2)
    @Schema(description = "审核状态：0待审 1通过 2拒绝")
    private Integer auditStatus;

    @Schema(description = "状态：1正常 2停用")
    private Integer status;

    @Min(1) @Schema(description = "页码", defaultValue = "1")
    private int page = 1;

    @Min(1) @Max(100) @Schema(description = "每页条数", defaultValue = "20")
    private int size = 20;
}
