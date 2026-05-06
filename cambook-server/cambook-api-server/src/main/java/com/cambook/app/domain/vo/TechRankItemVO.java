package com.cambook.app.domain.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.math.BigDecimal;

/**
 * 技师排行榜单项 VO
 *
 * @author CamBook
 */
@Data
@Schema(description = "技师排行榜单项")
public class TechRankItemVO {

    @Schema(description = "技师 ID")
    private Long id;

    @Schema(description = "技师姓名")
    private String name;

    @Schema(description = "头像 URL")
    private String avatar;

    @Schema(description = "完成订单数")
    private long orderCount;

    @Schema(description = "总营收金额")
    private BigDecimal revenue;
}
