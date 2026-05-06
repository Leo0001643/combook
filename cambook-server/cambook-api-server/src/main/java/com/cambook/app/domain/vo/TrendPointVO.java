package com.cambook.app.domain.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.math.BigDecimal;

/**
 * 趋势图单个数据点 VO
 *
 * @author CamBook
 */
@Data
@Schema(description = "趋势图数据点")
public class TrendPointVO {

    @Schema(description = "时间标签（如 MM-dd / HH:mm / yyyy-MM）")
    private String label;

    @Schema(description = "订单数")
    private long orders;

    @Schema(description = "营收金额")
    private BigDecimal revenue;
}
