package com.cambook.app.domain.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

/**
 * 创建订单（App）
 *
 * @author CamBook
 */
@Data
@Schema(description = "创建订单")
public class CreateOrderDTO {

    @NotNull(message = "服务项目不能为空")
    @Schema(description = "服务项目 ID")
    private Long serviceItemId;

    @NotNull(message = "技师不能为空")
    @Schema(description = "技师 ID")
    private Long technicianId;

    @NotNull(message = "服务地址不能为空")
    @Schema(description = "服务地址 ID")
    private Long addressId;

    @NotNull(message = "预约时间不能为空")
    @Schema(description = "预约时间（UTC 秒级时间戳）")
    private Long appointTime;

    @Schema(description = "使用的优惠券 ID")
    private Long couponId;

    @NotNull(message = "支付方式不能为空")
    @Min(value = 1, message = "支付方式不合法") @Max(value = 4, message = "支付方式不合法")
    @Schema(description = "支付方式：1ABA 2USDT 3余额 4现金")
    private Integer payType;

    @Schema(description = "备注", example = "请准时到达")
    private String remark;
}
