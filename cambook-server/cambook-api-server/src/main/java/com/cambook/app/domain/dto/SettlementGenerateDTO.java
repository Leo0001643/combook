package com.cambook.app.domain.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.math.BigDecimal;
import java.util.List;

/**
 * 手动生成结算单 DTO
 *
 * @author CamBook
 */
@Data
@Schema(description = "手动生成结算单请求")
public class SettlementGenerateDTO {

    @NotNull(message = "技师 ID 不能为空")
    @Schema(description = "技师 ID", requiredMode = Schema.RequiredMode.REQUIRED)
    private Long technicianId;

    @Schema(description = "技师姓名")
    private String technicianName;

    @Schema(description = "结算模式：0=每笔, 1=日结, 2=周结, 3=月结")
    private Integer settlementMode;

    @Schema(description = "周期开始日期（yyyy-MM-dd）")
    private String periodStart;

    @Schema(description = "周期结束日期（yyyy-MM-dd）")
    private String periodEnd;

    @Schema(description = "订单数")
    private Integer orderCount;

    @Schema(description = "服务总额")
    private BigDecimal totalRevenue;

    @Schema(description = "佣金类型：0=固定, 1=按比例")
    private Integer commissionType;

    @Schema(description = "佣金比例")
    private BigDecimal commissionRate;

    @Schema(description = "佣金金额")
    private BigDecimal commissionAmount;

    @Schema(description = "奖励金额")
    private BigDecimal bonusAmount;

    @Schema(description = "扣款金额")
    private BigDecimal deductionAmount;

    @Schema(description = "货币代码，默认 USD")
    private String currencyCode;

    @Schema(description = "货币符号")
    private String currencySymbol;

    @Schema(description = "备注")
    private String remark;

    @Schema(description = "结算明细列表")
    private List<Item> items;

    @Data
    @Schema(description = "结算明细项")
    public static class Item {
        private Long       orderId;
        private String     orderNo;
        private String     serviceName;
        private BigDecimal orderAmount;
        private BigDecimal commissionRate;
        private BigDecimal commissionAmount;
        private Long       serviceTime;
    }
}
