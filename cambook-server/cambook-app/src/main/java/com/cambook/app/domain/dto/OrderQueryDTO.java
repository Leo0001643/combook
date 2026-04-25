package com.cambook.app.domain.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.Pattern;
import lombok.Data;

/**
 * 订单查询条件（Admin）
 *
 * @author CamBook
 */
@Data
@Schema(description = "订单查询条件")
public class OrderQueryDTO {

    /**
     * 商户范围隔离（内部字段，不接受外部绑定）：
     * - null  → Admin：查全量
     * - 非null → Merchant 控制器注入，外部参数传入的值会被强制覆盖
     */
    @Schema(hidden = true)
    @com.fasterxml.jackson.annotation.JsonIgnore
    private Long merchantId;

    @Pattern(regexp = "^[A-Z0-9]{0,32}$", message = "订单号格式不正确")
    @Schema(description = "订单号")
    private String orderNo;

    @Schema(description = "关键词（订单号 / 用户昵称 / 技师编号）")
    private String keyword;

    @Schema(description = "会员 ID")
    private Long memberId;

    @Schema(description = "技师 ID")
    private Long technicianId;

    @Min(value = 1) @Max(value = 2)
    @Schema(description = "订单类型：1=在线预约 2=门店散客")
    private Integer orderType;

    @Min(value = 0) @Max(value = 9)
    @Schema(description = "订单状态：0-9")
    private Integer status;

    @Min(value = 1) @Max(value = 2)
    @Schema(description = "服务方式：1=上门服务 2=到店服务")
    private Integer serviceMode;

    @Schema(description = "下单时间范围起始（UTC 秒级时间戳，含）", example = "1735689600")
    private Long startDate;

    @Schema(description = "下单时间范围结束（UTC 秒级时间戳，含）", example = "1767139200")
    private Long endDate;

    @Min(1) @Schema(description = "页码", defaultValue = "1")
    private int page = 1;

    @Min(1) @Max(100) @Schema(description = "每页条数", defaultValue = "20")
    private int size = 20;
}
