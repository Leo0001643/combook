package com.cambook.app.domain.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import lombok.Data;

/**
 * 商户公告新增/编辑 DTO
 */
@Data
@Schema(description = "商户公告保存请求")
public class AnnouncementSaveDTO {

    @Schema(description = "ID（编辑时必填）")
    private Long id;

    @NotBlank(message = "标题不能为空")
    @Schema(description = "公告标题")
    private String title;

    @NotBlank(message = "内容不能为空")
    @Schema(description = "公告内容")
    private String content;

    @Schema(description = "公告类型")
    private Integer type;

    @Schema(description = "目标类型：0全部 1部门")
    private Integer targetType = 0;

    @Schema(description = "状态：0草稿 1已发布")
    private Integer status = 0;

    @Schema(description = "部门ID（targetType=1时填写）")
    private Long deptId;

    @Schema(description = "部门名称")
    private String deptName;
}
