package com.cambook.app.domain.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.math.BigDecimal;

/**
 * 散客接待 — 服务项 VO
 *
 * @author CamBook
 */
@Data
@Schema(description = "散客服务项信息")
public class WalkinItemVO {

    @Schema(description = "服务项订单 ID")
    private Long orderId;

    @Schema(description = "订单编号")
    private String orderNo;

    @Schema(description = "服务项目 ID")
    private Long serviceId;

    @Schema(description = "服务名称")
    private String name;

    @Schema(description = "服务时长（分钟）")
    private int duration;

    @Schema(description = "单价")
    private BigDecimal unitPrice;

    @Schema(description = "数量")
    private int qty;

    /** 前端服务状态：0=待服务, 1=服务中, 2=已完成 */
    @Schema(description = "前端服务状态：0=待服务, 1=服务中, 2=已完成")
    private int svcStatus;

    @Schema(description = "服务开始时间（Unix 秒）")
    private Long startTime;

    @Schema(description = "服务结束时间（Unix 秒）")
    private Long endTime;

    @Schema(description = "数据库订单状态码")
    private int dbStatus;
}
