package com.cambook.app.domain.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotEmpty;
import lombok.Data;

import java.util.List;

/**
 * 批量结算打款 DTO
 *
 * @author CamBook
 */
@Data
@Schema(description = "批量结算打款请求")
public class SettlementBatchPayDTO {

    @NotEmpty(message = "结算单 ID 列表不能为空")
    @Schema(description = "结算单 ID 列表", requiredMode = Schema.RequiredMode.REQUIRED)
    private List<Long> ids;

    @Schema(description = "支付方式")
    private String paymentMethod;

    @Schema(description = "支付参考号")
    private String paymentRef;
}
