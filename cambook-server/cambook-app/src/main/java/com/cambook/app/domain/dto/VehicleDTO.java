package com.cambook.app.domain.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

/**
 * 车辆新增 / 编辑 DTO
 *
 * @author CamBook
 */
@Data
@Schema(description = "车辆表单")
public class VehicleDTO {

    @Schema(description = "主键（编辑时必填）")
    private Long id;

    /**
     * 归属商户 ID（内部字段，不接受外部绑定）：
     * Merchant 控制器强制注入 JWT 中的 merchantId。
     */
    @Schema(hidden = true)
    @com.fasterxml.jackson.annotation.JsonIgnore
    private Long merchantId;

    @NotBlank(message = "车牌号不能为空")
    @Schema(description = "车牌号")
    private String plateNumber;

    @NotBlank(message = "品牌不能为空")
    @Schema(description = "品牌")
    private String brand;

    @Schema(description = "型号")
    private String model;

    @Schema(description = "车身颜色")
    private String color;

    @Min(2) @Max(20)
    @Schema(description = "座位数")
    private Integer seats;

    @Schema(description = "年检编号")
    private String inspectionCode;

    @Schema(description = "年检有效期 yyyy-MM-dd")
    private String inspectionExpiry;

    @Schema(description = "车辆图片 URL")
    private String photo;

    @Schema(description = "车辆多图（JSON 数组）")
    private String photos;

    @NotNull(message = "状态不能为空")
    @Schema(description = "状态：0=空闲 1=使用中 2=维修中")
    private Integer status;

    @Schema(description = "备注")
    private String remark;
}
