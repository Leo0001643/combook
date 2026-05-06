package com.cambook.app.domain.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.math.BigDecimal;

/**
 * 技师结算摘要 VO
 *
 * @author CamBook
 */
@Data
@Schema(description = "技师结算摘要")
public class TechnicianSummaryVO {

    @Schema(description = "历史累计收入")
    private BigDecimal totalEarnings;

    @Schema(description = "本月收入")
    private BigDecimal monthEarnings;

    @Schema(description = "待结算单数")
    private long pendingCount;

    @Schema(description = "待结算金额")
    private BigDecimal pendingAmount;

    @Schema(description = "历史结算单总数")
    private long settlementCount;
}
