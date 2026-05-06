package com.cambook.app.domain.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.time.LocalDate;

/**
 * 结算周期建议 VO
 *
 * @author CamBook
 */
@Data
@Schema(description = "结算周期建议")
public class SuggestPeriodVO {

    @Schema(description = "显示标签")
    private String label;

    @Schema(description = "周期开始日期")
    private LocalDate start;

    @Schema(description = "周期结束日期")
    private LocalDate end;

    @Schema(description = "结算模式：0=每笔, 1=日结, 2=周结, 3=月结")
    private int mode;
}
