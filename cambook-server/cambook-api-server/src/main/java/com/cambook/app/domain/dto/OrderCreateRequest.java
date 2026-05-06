package com.cambook.app.domain.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.math.BigDecimal;
import java.util.List;

/**
 * 后台/商户端新增在线订单请求体
 */
@Data
@Schema(description = "新增在线订单请求")
public class OrderCreateRequest {

    /** 由控制器注入，外部参数无效 */
    @Schema(hidden = true)
    private Long merchantId;

    @NotNull
    @Schema(description = "服务方式：1=上门服务 2=到店服务", required = true)
    private Integer serviceMode;

    @Schema(description = "客户昵称（匿名/散客时可自填）")
    private String memberNickname;

    @Schema(description = "客户手机号")
    private String memberMobile;

    @Schema(description = "关联会员 ID（可不填）")
    private Long memberId;

    @Schema(description = "技师 ID（可不填，后台分配）")
    private Long technicianId;

    @Schema(description = "上门地址（serviceMode=1 时填写）")
    private String addressDetail;

    @NotNull
    @Schema(description = "预约时间（Unix 秒）", required = true)
    private Long appointTime;

    @Schema(description = "备注")
    private String remark;

    @NotEmpty
    @Schema(description = "服务项列表", required = true)
    private List<OrderItemReq> items;

    @Data
    @Schema(description = "服务项")
    public static class OrderItemReq {

        @Min(1)
        @Schema(description = "服务项 ID", required = true)
        private Long serviceItemId;

        @Schema(description = "服务项名称快照")
        private String serviceName;

        @Schema(description = "服务时长（分钟）")
        private Integer serviceDuration;

        @NotNull
        @Schema(description = "单价", required = true)
        private BigDecimal unitPrice;

        @Schema(description = "数量", defaultValue = "1")
        private Integer qty = 1;
    }
}
