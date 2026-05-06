package com.cambook.app.domain.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import lombok.Data;

import java.math.BigDecimal;

/**
 * 服务类目新增/编辑 DTO
 */
@Data
@Schema(description = "服务类目保存请求")
public class CategorySaveDTO {

    @Schema(description = "ID（编辑时必填）")
    private Long id;

    @Schema(description = "父级分类ID，顶级为0")
    private Long parentId = 0L;

    @NotBlank(message = "中文名称不能为空")
    @Schema(description = "中文名称")
    private String nameZh;

    @Schema(description = "英文名称")
    private String nameEn;

    @Schema(description = "越南语名称")
    private String nameVi;

    @Schema(description = "高棉语名称")
    private String nameKm;

    @Schema(description = "日语名称")
    private String nameJa;

    @Schema(description = "韩语名称")
    private String nameKo;

    @Schema(description = "图标URL")
    private String icon;

    @Schema(description = "价格")
    private BigDecimal price;

    @Schema(description = "服务时长（分钟）")
    private Integer duration;

    @Schema(description = "是否特殊项目：0否 1是")
    private Integer isSpecial = 0;

    @Schema(description = "排序值")
    private Integer sort = 0;

    @Schema(description = "状态：0禁用 1启用（编辑时用）")
    private Integer status;
}
