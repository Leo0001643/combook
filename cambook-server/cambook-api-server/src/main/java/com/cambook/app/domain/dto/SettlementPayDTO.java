package com.cambook.app.domain.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

/**
 * 结算打款 DTO
 *
 * @author CamBook
 */
@Data
@Schema(description = "结算打款请求")
public class SettlementPayDTO {

    @Schema(description = "支付方式")
    private String paymentMethod;

    @Schema(description = "支付参考号")
    private String paymentRef;

    @Schema(description = "备注")
    private String remark;
}
