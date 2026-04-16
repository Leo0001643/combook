package com.cambook.app.domain.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.math.BigDecimal;

/**
 * 提现申请（技师/商户）
 *
 * @author CamBook
 */
@Data
@Schema(description = "提现申请")
public class WithdrawDTO {

    @NotNull(message = "提现金额不能为空")
    @DecimalMin(value = "10.00", message = "最低提现金额为 10 USD")
    @Schema(description = "提现金额（USD）", example = "100.00")
    private BigDecimal amount;

    @NotBlank(message = "收款账号不能为空")
    @Schema(description = "收款账号（ABA 账号 / USDT 地址）")
    private String account;

    @NotBlank(message = "收款方式不能为空")
    @Schema(description = "收款方式：ABA / USDT_TRC20 / USDT_ERC20")
    private String withdrawType;
}
