package com.cambook.driver.domain.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 派车单视图
 *
 * @author CamBook
 */
@Data
@Schema(description = "派车单信息")
public class DispatchVO {

    @Schema(description = "派车单 ID")
    private Long id;

    @Schema(description = "派车单号")
    private String dispatchNo;

    @Schema(description = "关联订单 ID")
    private Long orderId;

    @Schema(description = "司机信息（内嵌）")
    private DriverVO driver;

    @Schema(description = "车辆信息（内嵌）")
    private VehicleVO vehicle;

    @Schema(description = "上车地址纬度")
    private BigDecimal pickupLat;

    @Schema(description = "上车地址经度")
    private BigDecimal pickupLng;

    @Schema(description = "目的地纬度")
    private BigDecimal destLat;

    @Schema(description = "目的地经度")
    private BigDecimal destLng;

    @Schema(description = "目的地地址")
    private String destAddress;

    @Schema(description = "预约接送时间")
    private LocalDateTime pickupTime;

    @Schema(description = "实际接到时间")
    private LocalDateTime actualPickupTime;

    @Schema(description = "完成时间")
    private LocalDateTime finishTime;

    @Schema(description = "状态：0待接 1接单 2前往 3到达 4服务中 5完成 9取消")
    private Integer status;

    @Schema(description = "备注")
    private String remark;

    @Schema(description = "创建时间")
    private LocalDateTime createTime;
}
