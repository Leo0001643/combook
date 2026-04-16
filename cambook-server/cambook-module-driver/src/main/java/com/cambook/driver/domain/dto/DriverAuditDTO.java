package com.cambook.driver.domain.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Data;

/**
 * 司机审核（Admin）
 *
 * @author CamBook
 */
@Data
@Schema(description = "司机审核")
public class DriverAuditDTO {

    @NotNull(message = "司机ID不能为空")
    @Schema(description = "司机 ID")
    private Long id;

    @NotNull(message = "审核结果不能为空")
    @Min(value = 1) @Max(value = 2)
    @Schema(description = "审核结果：1通过 2拒绝")
    private Integer status;

    @Size(max = 200, message = "拒绝原因最多200字")
    @Schema(description = "拒绝原因（拒绝时必填）")
    private String rejectReason;
}
