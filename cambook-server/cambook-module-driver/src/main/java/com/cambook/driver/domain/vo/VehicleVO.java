package com.cambook.driver.domain.vo;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

/**
 * 车辆视图
 *
 * @author CamBook
 */
@Data
@Schema(description = "车辆信息")
public class VehicleVO {

    @Schema(description = "车辆 ID")
    private Long id;

    @Schema(description = "车牌号")
    private String plateNumber;

    @Schema(description = "品牌")
    private String brand;

    @Schema(description = "车型")
    private String model;

    @Schema(description = "颜色")
    private String color;

    @Schema(description = "座位数")
    private Integer seats;

    @Schema(description = "车辆图片")
    private String photo;

    @Schema(description = "年检到期日")
    private String inspectionExpiry;

    @Schema(description = "状态：0空闲 1使用中 2维修中")
    private Integer status;
}
