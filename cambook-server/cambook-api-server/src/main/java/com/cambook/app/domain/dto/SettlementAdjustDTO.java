package com.cambook.app.domain.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.math.BigDecimal;

/**
 * 调整结算金额 DTO
 *
 * @author CamBook
 */
@Data
@Schema(description = "调整结算金额请求")
public class SettlementAdjustDTO {

    @Schema(description = "奖励金额")
    private BigDecimal bonusAmount;

    @Schema(description = "扣款金额")
    private BigDecimal deductionAmount;

    @Schema(description = "备注")
    private String remark;
}
