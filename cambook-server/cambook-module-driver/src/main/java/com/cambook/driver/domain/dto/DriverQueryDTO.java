package com.cambook.driver.domain.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import lombok.Data;

/**
 * 司机列表查询（Admin）
 *
 * @author CamBook
 */
@Data
@Schema(description = "司机查询条件")
public class DriverQueryDTO {

    @Schema(description = "真实姓名（模糊）")
    private String realName;

    @Min(value = 0) @Max(value = 2)
    @Schema(description = "审核状态：0待审 1在职 2停职")
    private Integer status;

    @Min(value = 0) @Max(value = 2)
    @Schema(description = "在线状态：0离线 1待命 2执行中")
    private Integer onlineStatus;

    @Schema(description = "绑定车辆 ID")
    private Long vehicleId;

    @Min(1) @Schema(description = "页码", defaultValue = "1")
    private int page = 1;

    @Min(1) @Max(100) @Schema(description = "每页条数", defaultValue = "20")
    private int size = 20;
}
