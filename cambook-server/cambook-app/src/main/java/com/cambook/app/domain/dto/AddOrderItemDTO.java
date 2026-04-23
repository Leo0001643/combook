package com.cambook.app.domain.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Data;

import java.math.BigDecimal;

/**
 * 向订单追加服务项请求体
 *
 * <p>技师在服务进行中或接单后，可为同一客人追加服务项目而无需新建订单。
 *
 * @author CamBook
 */
@Data
@Schema(description = "向订单追加服务项")
public class AddOrderItemDTO {

    @NotNull
    @Schema(description = "服务项 ID（服务项目表主键）")
    private Long serviceItemId;

    @NotBlank
    @Size(max = 200)
    @Schema(description = "服务名称（快照）")
    private String serviceName;

    @NotNull
    @Min(1)
    @Schema(description = "服务时长（分钟）")
    private Integer serviceDuration;

    @NotNull
    @Schema(description = "单价（USD）")
    private BigDecimal unitPrice;

    @Min(1)
    @Schema(description = "数量，默认 1", defaultValue = "1")
    private Integer qty = 1;

    @Size(max = 200)
    @Schema(description = "备注（可选）")
    private String remark;
}
