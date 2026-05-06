package com.cambook.app.domain.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import lombok.Data;

/**
 * 新建散客接待 DTO
 *
 * @author CamBook
 */
@Data
@Schema(description = "新建散客接待请求")
public class WalkinCreateDTO {

    @NotBlank(message = "手环号不能为空")
    @Schema(description = "手环号", requiredMode = Schema.RequiredMode.REQUIRED)
    private String wristbandNo;

    @Schema(description = "客户姓名")
    private String memberName;

    @Schema(description = "客户手机号")
    private String memberMobile;

    @Schema(description = "指定技师 ID")
    private Long technicianId;

    @Schema(description = "技师姓名")
    private String technicianName;

    @Schema(description = "技师工号")
    private String technicianNo;

    @Schema(description = "技师手机号")
    private String technicianMobile;

    @Schema(description = "备注")
    private String remark;

    @Schema(description = "服务项 JSON（createWithItems 时使用）")
    private String itemsJson;
}
