package com.cambook.app.domain.vo;

import com.cambook.db.entity.CbTechnicianSettlement;
import com.cambook.db.entity.CbTechnicianSettlementItem;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.util.List;

/**
 * 结算单详情 VO
 *
 * @author CamBook
 */
@Data
@Schema(description = "结算单详情")
public class SettlementDetailVO {

    @Schema(description = "结算单信息")
    private CbTechnicianSettlement settlement;

    @Schema(description = "结算明细列表")
    private List<CbTechnicianSettlementItem> items;
}
