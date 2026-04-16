package com.cambook.driver.domain.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Data;

/**
 * 车辆信息（Admin）
 *
 * @author CamBook
 */
@Data
@Schema(description = "车辆信息")
public class VehicleDTO {

    @Schema(description = "主键（修改时必填）")
    private Long id;

    @NotBlank(message = "车牌号不能为空")
    @Pattern(regexp = "^[A-Z0-9\\u4e00-\\u9fa5]{2,10}$", message = "车牌号格式不合法")
    @Schema(description = "车牌号", example = "PP-12345")
    private String plateNumber;

    @NotBlank(message = "品牌不能为空")
    @Size(max = 50, message = "品牌名称最多50字符")
    @Schema(description = "品牌，如 Toyota")
    private String brand;

    @NotBlank(message = "车型不能为空")
    @Size(max = 50, message = "车型名称最多50字符")
    @Schema(description = "车型，如 Camry")
    private String model;

    @Schema(description = "车辆颜色", example = "白色")
    private String color;

    @NotNull(message = "座位数不能为空")
    @Min(value = 2, message = "座位数最少2") @Max(value = 50, message = "座位数最多50")
    @Schema(description = "座位数")
    private Integer seats;

    @Pattern(regexp = "^[A-Z0-9]{0,20}$", message = "年检编号格式不正确")
    @Schema(description = "年检编号")
    private String inspectionCode;

    @Schema(description = "年检到期日（yyyy-MM-dd）")
    private String inspectionExpiry;

    @Pattern(regexp = "^https?://.+$", message = "车辆图片必须为合法URL")
    @Schema(description = "车辆图片 URL")
    private String photo;

    @Schema(description = "备注")
    private String remark;
}
