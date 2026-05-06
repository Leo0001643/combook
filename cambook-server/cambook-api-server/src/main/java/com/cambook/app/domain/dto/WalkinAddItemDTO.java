package com.cambook.app.domain.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import lombok.Data;

import java.math.BigDecimal;

/**
 * 散客接待 — 添加服务项 DTO
 *
 * @author CamBook
 */
@Data
@Schema(description = "添加散客服务项请求")
public class WalkinAddItemDTO {

    @Schema(description = "服务项目 ID（传 0 表示自定义服务）")
    private Long serviceItemId;

    @NotBlank(message = "服务名称不能为空")
    @Schema(description = "服务名称", requiredMode = Schema.RequiredMode.REQUIRED)
    private String serviceName;

    @Schema(description = "服务时长（分钟）")
    private Integer serviceDuration;

    @NotNull(message = "单价不能为空")
    @Positive(message = "单价必须为正数")
    @Schema(description = "单价", requiredMode = Schema.RequiredMode.REQUIRED)
    private BigDecimal unitPrice;

    @Schema(description = "技师 ID（可覆盖接待默认技师）")
    private Long technicianId;

    @Schema(description = "技师姓名")
    private String technicianName;
}
