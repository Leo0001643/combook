package com.cambook.driver.domain.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import lombok.Data;

/**
 * 派车单查询（Admin）
 *
 * @author CamBook
 */
@Data
@Schema(description = "派车单查询条件")
public class DispatchQueryDTO {

    @Schema(description = "司机 ID")
    private Long driverId;

    @Schema(description = "订单 ID")
    private Long orderId;

    @Min(value = 0) @Max(value = 9)
    @Schema(description = "状态：0待接 1接单 2前往 3到达 4服务中 5完成 9取消")
    private Integer status;

    @Schema(description = "开始日期（yyyy-MM-dd）")
    private String startDate;

    @Schema(description = "结束日期（yyyy-MM-dd）")
    private String endDate;

    @Min(1) @Schema(description = "页码", defaultValue = "1")
    private int page = 1;

    @Min(1) @Max(100) @Schema(description = "每页条数", defaultValue = "20")
    private int size = 20;
}
