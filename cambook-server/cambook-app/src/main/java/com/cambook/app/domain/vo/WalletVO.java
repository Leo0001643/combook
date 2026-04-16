package com.cambook.app.domain.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.math.BigDecimal;

/**
 * 钱包信息视图
 *
 * @author CamBook
 */
@Data
@Schema(description = "钱包信息")
public class WalletVO {

    @Schema(description = "账户余额（USD）")
    private BigDecimal balance;

    @Schema(description = "累计充值（USD）")
    private BigDecimal totalRecharge;

    @Schema(description = "累计消费（USD）")
    private BigDecimal totalConsume;

    @Schema(description = "累计提现（USD）")
    private BigDecimal totalWithdraw;
}
