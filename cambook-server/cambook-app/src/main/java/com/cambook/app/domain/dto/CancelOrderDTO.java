package com.cambook.app.domain.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Data;

/**
 * 取消订单（App）
 *
 * @author CamBook
 */
@Data
@Schema(description = "取消订单")
public class CancelOrderDTO {

    @NotNull(message = "订单ID不能为空")
    @Schema(description = "订单 ID")
    private Long orderId;

    @Size(max = 200, message = "取消原因最多200字")
    @Schema(description = "取消原因")
    private String reason;
}
