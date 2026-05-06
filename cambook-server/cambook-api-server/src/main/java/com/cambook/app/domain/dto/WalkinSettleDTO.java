package com.cambook.app.domain.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PositiveOrZero;
import lombok.Data;

import java.math.BigDecimal;

/**
 * 散客接待结算 DTO
 *
 * @author CamBook
 */
@Data
@Schema(description = "散客接待结算请求")
public class WalkinSettleDTO {

    @NotNull(message = "实收金额不能为空")
    @PositiveOrZero(message = "实收金额不能为负数")
    @Schema(description = "实收金额", requiredMode = Schema.RequiredMode.REQUIRED)
    private BigDecimal paidAmount;

    @Schema(description = "备注")
    private String remark;
}
