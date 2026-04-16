package com.cambook.driver.domain.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Future;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 创建派车单（App/Admin）
 *
 * @author CamBook
 */
@Data
@Schema(description = "创建派车单")
public class DispatchDTO {

    @NotNull(message = "订单ID不能为空")
    @Schema(description = "关联订单 ID")
    private Long orderId;

    @NotNull(message = "预约接送时间不能为空")
    @Future(message = "接送时间必须是未来时间")
    @Schema(description = "预约接送时间")
    private LocalDateTime pickupTime;

    @NotNull(message = "上车地址纬度不能为空")
    @DecimalMin(value = "-90.0",  message = "纬度范围-90到90")
    @DecimalMax(value = "90.0",   message = "纬度范围-90到90")
    @Schema(description = "上车地址纬度")
    private BigDecimal pickupLat;

    @NotNull(message = "上车地址经度不能为空")
    @DecimalMin(value = "-180.0", message = "经度范围-180到180")
    @DecimalMax(value = "180.0",  message = "经度范围-180到180")
    @Schema(description = "上车地址经度")
    private BigDecimal pickupLng;

    @NotNull(message = "目的地纬度不能为空")
    @DecimalMin(value = "-90.0",  message = "纬度范围-90到90")
    @DecimalMax(value = "90.0",   message = "纬度范围-90到90")
    @Schema(description = "目的地纬度")
    private BigDecimal destLat;

    @NotNull(message = "目的地经度不能为空")
    @DecimalMin(value = "-180.0", message = "经度范围-180到180")
    @DecimalMax(value = "180.0",  message = "经度范围-180到180")
    @Schema(description = "目的地经度")
    private BigDecimal destLng;

    @Size(max = 200, message = "目的地地址最多200字符")
    @Schema(description = "目的地详细地址")
    private String destAddress;

    @Schema(description = "指定司机 ID（不填则自动分配）")
    private Long driverId;

    @Size(max = 200, message = "备注最多200字符")
    @Schema(description = "备注")
    private String remark;
}
