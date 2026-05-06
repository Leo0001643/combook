package com.cambook.app.domain.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

/**
 * 修改散客接待基本信息 DTO
 *
 * @author CamBook
 */
@Data
@Schema(description = "修改散客接待基本信息请求")
public class WalkinUpdateDTO {

    @Schema(description = "客户姓名")
    private String memberName;

    @Schema(description = "客户手机号")
    private String memberMobile;

    @Schema(description = "技师 ID")
    private Long technicianId;

    @Schema(description = "技师姓名")
    private String technicianName;

    @Schema(description = "技师工号")
    private String technicianNo;

    @Schema(description = "技师手机号")
    private String technicianMobile;

    @Schema(description = "备注")
    private String remark;
}
