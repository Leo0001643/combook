package com.cambook.app.domain.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.util.List;

/**
 * 创建订单 DTO（App 客户端）
 *
 * <h3>业务规则</h3>
 * <ul>
 *   <li>一次预约对应一笔 {@code cb_order}，属于一个客户的一次服务 session</li>
 *   <li>每个服务项（{@code BookingItemDTO}）可指定不同的技师，支持多技师并行服务</li>
 *   <li>服务端从 {@code cb_service_item} 查价，防止客户端价格篡改</li>
 * </ul>
 *
 * @author CamBook
 */
@Data
@Schema(description = "创建预约订单")
public class CreateOrderDTO {

    @NotNull(message = "服务地址不能为空")
    @Schema(description = "收货/服务地址 ID")
    private Long addressId;

    @NotNull(message = "预约时间不能为空")
    @Schema(description = "预约服务开始时间（UTC 秒级时间戳）")
    private Long appointTime;

    @NotNull(message = "支付方式不能为空")
    @Min(value = 1, message = "支付方式不合法")
    @Max(value = 4, message = "支付方式不合法")
    @Schema(description = "支付方式：1=ABA  2=USDT  3=余额  4=现金")
    private Integer payType;

    @Schema(description = "使用的优惠券 ID（选填）")
    private Long couponId;

    @Schema(description = "订单备注（选填）")
    private String remark;

    @Valid
    @NotEmpty(message = "服务项目不能为空")
    @Schema(description = "服务项明细（至少一项；不同项可指定不同技师）")
    private List<BookingItemDTO> items;

    // ── 内嵌：单个服务项预约 ─────────────────────────────────────────────────

    @Data
    @Schema(description = "单个服务项预约信息")
    public static class BookingItemDTO {

        @NotNull(message = "技师不能为空")
        @Schema(description = "执行该服务项的技师 ID")
        private Long technicianId;

        @NotNull(message = "服务项目不能为空")
        @Schema(description = "服务项目 ID（对应 cb_service_item.id）")
        private Long serviceItemId;

        @Min(value = 1, message = "数量至少为 1")
        @Schema(description = "数量（默认 1）", example = "1")
        private int qty = 1;

        @Schema(description = "该项目的特殊备注（选填）")
        private String remark;
    }
}
