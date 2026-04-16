package com.cambook.app.domain.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.math.BigDecimal;

/**
 * 钱包充值（App）
 *
 * @author CamBook
 */
@Data
@Schema(description = "钱包充值")
public class RechargeDTO {

    @NotNull(message = "充值金额不能为空")
    @DecimalMin(value = "1.00", message = "充值金额最低 1 USD")
    @Schema(description = "充值金额（USD）", example = "50.00")
    private BigDecimal amount;

    @NotNull(message = "支付方式不能为空")
    @Min(value = 1) @Max(value = 2)
    @Schema(description = "支付方式：1ABA 2USDT")
    private Integer payType;
}
