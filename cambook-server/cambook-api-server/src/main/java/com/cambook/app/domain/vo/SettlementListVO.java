package com.cambook.app.domain.vo;

import com.cambook.db.entity.CbTechnicianSettlement;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.math.BigDecimal;
import java.util.List;

/**
 * 技师结算列表 VO（含聚合摘要）
 *
 * @author CamBook
 */
@Data
@Schema(description = "技师结算列表")
public class SettlementListVO {

    @Schema(description = "结算单列表")
    private List<CbTechnicianSettlement> list;

    @Schema(description = "总记录数")
    private long total;

    @Schema(description = "待结算单数")
    private long pendingCount;

    @Schema(description = "待结算总金额")
    private BigDecimal pendingAmount;

    @Schema(description = "已结算总金额")
    private BigDecimal settledAmount;

    @Schema(description = "本月结算金额")
    private BigDecimal monthAmount;
}
